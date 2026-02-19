import XCTest
@testable import Parallax

final class WorkspaceMetadataStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try super.tearDownWithError()
    }

    func testUpsertLoadAndDelete() async throws {
        let fileURL = tempDirectory.appendingPathComponent("workspaces.json")
        let store = WorkspaceMetadataStore(fileURL: fileURL)
        let workspacePath = "/tmp/workspaces/repo__task"

        try await store.upsert(
            workspacePath: workspacePath,
            sourceRepoPath: "/tmp/repos/repo",
            branchName: "agent/task"
        )

        let loaded = await store.load()
        let key = store.normalizedPath(workspacePath)
        let metadata = try XCTUnwrap(loaded[key])
        XCTAssertEqual(metadata.workspacePath, key)
        XCTAssertEqual(metadata.sourceRepoPath, "/tmp/repos/repo")
        XCTAssertEqual(metadata.branchName, "agent/task")

        try await store.delete(workspacePath: workspacePath)
        let afterDelete = await store.load()
        XCTAssertTrue(afterDelete.isEmpty)
    }

    func testPersistReplacesContents() async throws {
        let fileURL = tempDirectory.appendingPathComponent("workspaces.json")
        let store = WorkspaceMetadataStore(fileURL: fileURL)

        let workspacePath = store.normalizedPath("/tmp/workspaces/repo__task")
        let metadata = WorkspaceMetadata(
            workspacePath: workspacePath,
            sourceRepoPath: "/tmp/repos/repo",
            branchName: "agent/task",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        try await store.persist([workspacePath: metadata])

        let loaded = await store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[workspacePath], metadata)
    }

    func testLoadCanonicalizesLegacyPaths() async throws {
        let fileURL = tempDirectory.appendingPathComponent("workspaces.json")
        let store = WorkspaceMetadataStore(fileURL: fileURL)

        let realWorkspaceRoot = tempDirectory.appendingPathComponent("real", isDirectory: true)
        let aliasWorkspaceRoot = tempDirectory.appendingPathComponent("alias", isDirectory: true)
        try FileManager.default.createDirectory(at: realWorkspaceRoot, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: aliasWorkspaceRoot,
            withDestinationURL: realWorkspaceRoot
        )

        let workspaceAlias = aliasWorkspaceRoot.appendingPathComponent("repo__task", isDirectory: true)
        let sourceAlias = aliasWorkspaceRoot.appendingPathComponent("source-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceAlias, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceAlias, withIntermediateDirectories: true)

        let raw = WorkspaceMetadataFile(workspaces: [
            workspaceAlias.path: WorkspaceMetadata(
                workspacePath: workspaceAlias.path,
                sourceRepoPath: sourceAlias.path,
                branchName: "agent/task",
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let data = try JSONEncoder().encode(raw)
        try data.write(to: fileURL, options: .atomic)

        let loaded = await store.load()
        let canonicalWorkspacePath = store.normalizedPath(workspaceAlias.path)
        let metadata = try XCTUnwrap(loaded[canonicalWorkspacePath])

        XCTAssertEqual(metadata.workspacePath, canonicalWorkspacePath)
        XCTAssertEqual(metadata.sourceRepoPath, store.normalizedPath(sourceAlias.path))
        XCTAssertEqual(loaded.count, 1)
    }
}
