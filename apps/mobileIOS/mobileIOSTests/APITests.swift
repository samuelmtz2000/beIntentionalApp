import XCTest
@testable import mobileIOS

final class APITests: XCTestCase {
    func testAPIBase() throws {
        let client = APIClient(baseURL: URL(string: "http://localhost:4000")!)
        // smoke: ensure methods exist and generic compile
        XCTAssertNotNil(client)
    }
}

