import XCTest
@testable import Parallax

final class AppSettingsTests: XCTestCase {
    func testValidatedForSaveTrimsValues() throws {
        let settings = AppSettings(
            rootPaths: ["  ~/Projects  "],
            editor: "zed",
            workspaceRoot: "  ~/Parallax  "
        )

        let validated = try settings.validatedForSave()
        XCTAssertEqual(validated.rootPaths, ["~/Projects"])
        XCTAssertEqual(validated.workspaceRoot, "~/Parallax")
    }

    func testValidatedForSaveRejectsEmptyRootPaths() {
        let settings = AppSettings(
            rootPaths: ["   "],
            editor: "zed",
            workspaceRoot: "~/Parallax"
        )

        XCTAssertThrowsError(try settings.validatedForSave())
    }

    func testValidatedForSaveRejectsRelativeWorkspaceRoot() {
        let settings = AppSettings(
            rootPaths: ["~/Projects"],
            editor: "zed",
            workspaceRoot: "relative/path"
        )

        XCTAssertThrowsError(try settings.validatedForSave())
    }
}
