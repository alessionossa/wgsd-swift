import XCTest
@testable import wgsd_swift
import NIO
import DNSClient

final class wgsd_swiftTests: XCTestCase {
    
    func testExample() throws {
        
        let expectation = self.expectation(description: "Query 1")
        
        let client = try WGSDClient.init(ipAddress: "164.90.235.103", port: 5356)
        
        client.queryServer(dnsZone: "exampleniodns.org.",
                           peersPubKey: ["F9dNYWfLLMYBwNXMgnmoOW8W66WNwUogr+rvWaTW4gU="]
        ){ endpoints in
            print("Got the results:")
            print(endpoints)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
}
