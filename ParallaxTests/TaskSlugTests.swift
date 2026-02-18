import XCTest
@testable import Parallax

final class TaskSlugTests: XCTestCase {
    func testSlugNormalizesWhitespaceAndCase() throws {
        let slug = try TaskSlug(raw: "  Fix Login BUG  ")
        XCTAssertEqual(slug.value, "fix-login-bug")
    }

    func testSlugRejectsInvalidCharacters() {
        XCTAssertThrowsError(try TaskSlug(raw: "feat/new-ui"))
    }

    func testSlugRejectsTraversalStyleValues() {
        XCTAssertThrowsError(try TaskSlug(raw: ".."))
        XCTAssertThrowsError(try TaskSlug(raw: "a..b"))
    }

    func testSlugCollapsesRepeatedSeparators() throws {
        let slug = try TaskSlug(raw: "task___name---v1")
        XCTAssertEqual(slug.value, "task_name-v1")
    }
}
