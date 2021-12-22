import XCTest
@testable import wgsd_swift
import NIO
import DNSClient

final class wgsd_swiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(wgsd_swift().text, "Hello, World!")
    }
}
