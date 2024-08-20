import ExtrasBase64
import Resolver
import os
import DNS

public class WGSDClient {
        
    public typealias WGSDQueryResult = Result<[String: String],Error>
    
    private let resolver: Resolver
    
    public init(ipAddress: String, port: UInt16) {
        resolver = Resolver(nameserver: ["\(ipAddress):\(port)"])
    }
    
    /// Query the DNS server to get informations about endpoints identified by public keys in `peersPubKey`.
    /// - Parameters:
    ///   - dnsServer: IP address of server with WGSD
    ///   - port: WGSD Server port
    ///   - dnsZone: Custom DNS zone, it must be the same of the one set on server
    ///   - peersPubKey: Array of Base64 encoded public keys of peers you want to request endpoint informations
    public func queryServer(dnsZone: String, peersPubKey: [String], closure: @escaping (WGSDQueryResult) -> ()) {
        
        var endpoints = [String: String]()
        for peerPubKey in peersPubKey {
            
            do {
                let base32Key = try WGSDClient.base32Encoded(from: peerPubKey).lowercased()
                
                let completeZone = base32Key + "._wireguard._udp." + dnsZone
                
                // print("Querying for \(completeZone)")
                
                let result = try resolver.query(completeZone, type: .service)
                os_log("result: %{public}s", result.debugDescription)
                
                let answer = result.answers.first
                
                guard let serviceRecord = answer as? ServiceRecord else { return }
                let port = serviceRecord.port
                
                var stringAddress: String = ""
                for additionalAnswer in result.additional {
                    guard let hostRecord = additionalAnswer as? HostRecord<IPv4> else { continue }

                    stringAddress = hostRecord.ip.presentation
                }
                guard !stringAddress.isEmpty else { return }
                
                guard let peerKey32 = result.questions.first?.name.components(separatedBy: ".").first,
                      let peerKey = try? WGSDClient.base64Encoded(from: peerKey32)
                else { return }
                
                endpoints[peerKey] = "\(stringAddress):\(port)"
            } catch let error {
                print("Error with \(peerPubKey)")
                print(error.localizedDescription)
                
                if let resolverError = error as? ResolverError {
                    switch resolverError {
                    case .error(let detail):
                        os_log("ERROR DETAIL: %{public}s", detail)
                    }
                }
            }
            
        }
        
        closure(.success(endpoints))

    }
    
    private static func base32Encoded(from base64String: String) throws -> String {
        let keyBytes = try Base64.decode(string: base64String)
        let base32Key = Base32.encodeToString(bytes: keyBytes)
        
        return base32Key
    }
    
    private static func base64Encoded(from base32String: String) throws -> String {
        let keyBytes = try Base32.decode(string: base32String)
        let base64Key = Base64.encodeToString(bytes: keyBytes)
        
        return base64Key
    }
}
