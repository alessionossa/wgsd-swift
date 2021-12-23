import XCTest
@testable import wgsd_swift

final class wgsd_swiftTests: XCTestCase {
    func testExample() throws {
        
        let expectation = self.expectation(description: "Query 1")
        
        wgsd_swift.queryServer(dnsServer: "164.90.235.103",
                               port: 5356,
                               dnsZone: "exampleniodns.org.",
                               peersPubKey: ["F9dNYWfLLMYBwNXMgnmoOW8W66WNwUogr+rvWaTW4gU="]
        ){ endpoints in
            print("Got the results:")
            print(endpoints)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
}
