import XCTest
@testable import database_kit

final class database_kitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(database_kit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
