import XCTest
@testable import Parallax

final class PathContainmentTests: XCTestCase {
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

    func testDescendantCheckHandlesSymlinkedBaseForMissingTargetLeaf() throws {
        let realBase = tempDirectory.appendingPathComponent("real-base", isDirectory: true)
        let symlinkBase = tempDirectory.appendingPathComponent("link-base", isDirectory: true)

        try FileManager.default.createDirectory(at: realBase, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: symlinkBase,
            withDestinationURL: realBase
        )

        let target = symlinkBase.appendingPathComponent("repo__task", isDirectory: true)
        XCTAssertTrue(PathContainment.isDescendant(target, of: symlinkBase))
    }

    func testDescendantCheckRejectsOutsidePath() throws {
        let base = tempDirectory.appendingPathComponent("base", isDirectory: true)
        let outside = tempDirectory.appendingPathComponent("outside/repo__task", isDirectory: true)

        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        XCTAssertFalse(PathContainment.isDescendant(outside, of: base))
    }
}
