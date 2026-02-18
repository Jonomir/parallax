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
}
