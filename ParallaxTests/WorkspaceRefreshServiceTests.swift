import XCTest
@testable import Parallax

final class WorkspaceRefreshServiceTests: XCTestCase {
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

    func testMetadataBacksWorkspaceWhenFolderNameIsUnparseable() async throws {
        let workspaceRoot = tempDirectory.appendingPathComponent("workspaces", isDirectory: true)
        let workspaceFolder = workspaceRoot.appendingPathComponent("opaque-folder-name", isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceFolder, withIntermediateDirectories: true)

        let metadataURL = tempDirectory.appendingPathComponent("workspaces.json")
        let metadataStore = WorkspaceMetadataStore(fileURL: metadataURL)
        try await metadataStore.upsert(
            workspacePath: workspaceFolder.path,
            sourceRepoPath: "/tmp/repos/my__repo",
            branchName: "agent/feature-task"
        )

        let refreshService = WorkspaceRefreshService(
            basePath: workspaceRoot.path,
            metadataStore: metadataStore
        )
        let workspaces = await refreshService.loadWorkspaces(repositories: [])
        let workspace = try XCTUnwrap(workspaces.first)

        XCTAssertEqual(workspaces.count, 1)
        XCTAssertEqual(workspace.path, workspaceFolder.path)
        XCTAssertEqual(workspace.repoName, "my__repo")
        XCTAssertEqual(workspace.taskName, "feature-task")
        XCTAssertEqual(workspace.sourceRepoPath, "/tmp/repos/my__repo")
        XCTAssertEqual(workspace.branchName, "agent/feature-task")
        XCTAssertTrue(workspace.canMergeBack)
    }

    func testRefreshKeepsMetadataForUnparseableWorkspaceFolder() async throws {
        let workspaceRoot = tempDirectory.appendingPathComponent("workspaces", isDirectory: true)
        let workspaceFolder = workspaceRoot.appendingPathComponent("opaque-folder-name", isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceFolder, withIntermediateDirectories: true)

        let metadataURL = tempDirectory.appendingPathComponent("workspaces.json")
        let metadataStore = WorkspaceMetadataStore(fileURL: metadataURL)
        try await metadataStore.upsert(
            workspacePath: workspaceFolder.path,
            sourceRepoPath: "/tmp/repos/my__repo",
            branchName: "agent/feature-task"
        )

        let refreshService = WorkspaceRefreshService(
            basePath: workspaceRoot.path,
            metadataStore: metadataStore
        )
        _ = await refreshService.loadWorkspaces(repositories: [])

        let metadata = await metadataStore.load()
        let key = metadataStore.normalizedPath(workspaceFolder.path)
        XCTAssertNotNil(metadata[key])
    }

    func testScanFailureFallsBackToMetadataWithoutDeletingEntries() async throws {
        let workspaceRootFile = tempDirectory.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: workspaceRootFile, options: .atomic)

        let actualWorkspaceRoot = tempDirectory.appendingPathComponent("workspaces", isDirectory: true)
        let workspaceFolder = actualWorkspaceRoot.appendingPathComponent("opaque-folder-name", isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceFolder, withIntermediateDirectories: true)

        let metadataURL = tempDirectory.appendingPathComponent("workspaces.json")
        let metadataStore = WorkspaceMetadataStore(fileURL: metadataURL)
        try await metadataStore.upsert(
            workspacePath: workspaceFolder.path,
            sourceRepoPath: "/tmp/repos/my__repo",
            branchName: "agent/feature-task"
        )

        let refreshService = WorkspaceRefreshService(
            basePath: workspaceRootFile.path,
            metadataStore: metadataStore
        )
        let workspaces = await refreshService.loadWorkspaces(repositories: [])
        let workspace = try XCTUnwrap(workspaces.first)

        XCTAssertEqual(workspaces.count, 1)
        XCTAssertEqual(workspace.path, workspaceFolder.path)
        XCTAssertEqual(workspace.repoName, "my__repo")
        XCTAssertEqual(workspace.taskName, "feature-task")
        XCTAssertTrue(workspace.canMergeBack)

        let metadata = await metadataStore.load()
        let key = metadataStore.normalizedPath(workspaceFolder.path)
        XCTAssertNotNil(metadata[key])
    }
}
