import XCTest
@testable import Word2Vec

class word2vec_swiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(word2vec_swift().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
