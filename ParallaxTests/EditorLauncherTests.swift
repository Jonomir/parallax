import XCTest
@testable import Parallax

final class EditorLauncherTests: XCTestCase {
    func testApplicationNameMapping() {
        XCTAssertEqual(EditorLauncher.applicationName(for: "zed"), "Zed")
        XCTAssertEqual(EditorLauncher.applicationName(for: "cursor"), "Cursor")
        XCTAssertEqual(EditorLauncher.applicationName(for: "code"), "Visual Studio Code")
        XCTAssertEqual(EditorLauncher.applicationName(for: "goland"), "GoLand")
    }

    func testApplicationNameMappingForUnknownEditor() {
        XCTAssertNil(EditorLauncher.applicationName(for: "unknown-editor"))
    }
}
