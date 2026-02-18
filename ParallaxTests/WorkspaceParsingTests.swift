import XCTest
@testable import Parallax

final class WorkspaceParsingTests: XCTestCase {
    func testFolderParsingUsesLastSeparator() throws {
        let workspace = try XCTUnwrap(
            Workspace.fromFolderName("my__repo__feature-task", basePath: "/tmp/workspaces")
        )

        XCTAssertEqual(workspace.repoName, "my__repo")
        XCTAssertEqual(workspace.taskName, "feature-task")
    }

    func testFolderParsingRejectsMissingSeparator() {
        XCTAssertNil(Workspace.fromFolderName("no-separator", basePath: "/tmp/workspaces"))
    }
}
