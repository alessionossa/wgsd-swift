//import Resolver
import ExtrasBase64
import Resolver

public struct wgsd_swift {
    
    public typealias Endpoint = (String, UInt16)
    
    /// Query the DNS server to get informations about endpoints identified by public keys in `peersPubKey`.
    /// - Parameters:
    ///   - dnsServer: IP address of server with WGSD
    ///   - port: WGSD Server port
    ///   - dnsZone: Custom DNS zone, it must be the same of the one set on server
    ///   - peersPubKey: Array of Base64 encoded public keys of peers you want to request endpoint informations
    static public func queryServer(dnsServer: String, port: UInt16, dnsZone: String, peersPubKey: [String], closure: @escaping ([String: Endpoint]) -> ()) {
        
        var endpoints = [String: Endpoint]()
        
        let resolver = Resolver(nameserver: ["\(dnsServer):\(port)"])
        
        for peerPubKey in peersPubKey {
            
            do {
                let base32Key = try wgsd_swift.base32Encoded(from: peerPubKey)
                
                let completeZone = base32Key + "._wireguard._udp." + dnsZone
                
                let result = try resolver.discover(completeZone)
                
                if let response = result.first {
                    let address = response.address
                    
                    if let port = response.port {
                        endpoints[peerPubKey] = (address, UInt16(port))
                    } else {
                        print("Missing port information for \(peerPubKey)")
                    }
                    
                } else {
                    print("No response for \(peerPubKey)")
                }
            } catch let error {
                print("Error with \(peerPubKey)")
                print(error.localizedDescription)
            }
            
        }
        
        closure(endpoints)

    }
    
    private static func base32Encoded(from base64String: String) throws -> String {
        let keyBytes = try Base64.decode(string: base64String)
        var base32Key = Base32.encodeString(bytes: keyBytes)
        
        // Manually add padding until https://github.com/swift-extras/swift-extras-base64/issues/30 is fixed
        let padding: String
        switch base32Key.count % 8 {
            case 2:
                padding = "======"
            case 4:
                padding = "===="
            case 5:
                padding = "==="
            case 7:
                padding = "=="
            default:
                padding = ""
        }
        base32Key = base32Key + padding
        
        return base32Key
    }
}
