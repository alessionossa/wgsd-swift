import ExtrasBase64
import AsyncDNSResolver

public class WGSDClient {
    
    public typealias WGSDQueryResult = Result<[String: String],Error>
    
    private let resolver: AsyncDNSResolver
    
    public init(ipAddress: String, port: UInt16) throws {
        var options = CAresDNSResolver.Options.default
        options.servers = [ipAddress]
        options.tcpPort = port
        options.udpPort = port
        resolver = try AsyncDNSResolver(options: options)
    }
    
    /// Query the DNS server to get informations about endpoints identified by public keys in `peersPubKey`.
    /// - Parameters:
    ///   - dnsServer: IP address of server with WGSD
    ///   - port: WGSD Server port
    ///   - dnsZone: Custom DNS zone, it must be the same of the one set on server
    ///   - peersPubKey: Array of Base64 encoded public keys of peers you want to request endpoint informations
    @available(*, renamed: "queryServer(dnsZone:peersPubKey:)")
    public func queryServer(dnsZone: String, peersPubKey: [String], closure: @escaping (WGSDQueryResult) -> ()) {
        Task {
            do {
                let result = try await queryServer(dnsZone: dnsZone, peersPubKey: peersPubKey)
                closure(.success(result))
            } catch {
                closure(.failure(error))
            }
        }
    }
    
    
    public func queryServer(dnsZone: String, peersPubKey: [String]) async throws -> [String : String] {
        
        var endpoints = [String: String]()
        for peerPubKey in peersPubKey {
            
            do {
                let base32Key = try WGSDClient.base32Encoded(from: peerPubKey).lowercased()
                
                let completeZone = base32Key + "._wireguard._udp." + dnsZone
                
                let resultSRV = try await resolver.querySRV(name: completeZone)
                
                // AsyncDNSResolver (c-ares) does not support "additionional records" in DNS response,
                // so we query manually for A records
                let resultA = try await resolver.queryA(name: completeZone)
                
                guard let port = resultSRV.first?.port,
                      let stringAddress = resultA.first?.address.address
                else { continue }
                
                endpoints[peerPubKey] = "\(stringAddress):\(port)"
            } catch let error as AsyncDNSResolver.Error where (error.source as? CAresError) == CAresError(code: 4) {
                print("Record not found")
            } catch {
                print("Error: \(error)")
                throw error
            }
        }

        return endpoints
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

/*
extension Array where Element == UInt8 {
    func bytesToHex(spacing: String) -> String {
        var hexString: String = ""
        var count = self.count
        for byte in self
        {
            hexString.append(String(format:"%02X", byte))
            count = count - 1
            if count > 0
            {
                hexString.append(spacing)
            }
        }
        return hexString
    }
}
 */
