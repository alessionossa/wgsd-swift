import DNSClient
import NIO
import ExtrasBase64

public class WGSDClient {
    
    public typealias WGSDQueryResult = Result<[String: String],Error>
    
    private var loopGroup: MultiThreadedEventLoopGroup
    private var dnsClient: DNSClient
    
    public init(ipAddress: String, port: Int) throws {
        let serverSocketAddress = try SocketAddress(ipAddress: ipAddress, port: port)
        
        loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        dnsClient = try DNSClient.connect(on: loopGroup, config: [serverSocketAddress]).wait()
    }
    
    /// Query the DNS server to get informations about endpoints identified by public keys in `peersPubKey`.
    /// - Parameters:
    ///   - dnsZone: Custom DNS zone, it must be the same of the one set on server
    ///   - peersPubKey: Array of Base64 encoded public keys of peers you want to request endpoint informations
    ///   - closure: Result of the query
    public func queryServer(dnsZone: String, peersPubKey: [String], closure: @escaping (WGSDQueryResult) -> ()) {
        
        var futures: [EventLoopFuture<Message>] = []
        
        do {
            for peerPubKey in peersPubKey {
                // let loop = loopGroup.next()
                
                let base32Key = try WGSDClient.base32Encoded(from: peerPubKey).lowercased()
                
                let completeZone = base32Key + "._wireguard._udp." + dnsZone
                
                let recordsFuture = dnsClient.sendQuery(forHost: completeZone, type: .srv, additionalOptions: nil)
                
                futures.append(recordsFuture)
            }
            
            let emptyEndpoints = [String: String]()
            let resp = EventLoopFuture.reduce(into: emptyEndpoints, futures, on: loopGroup.next()) { endpointsStorage, newMessage in
                let answer = newMessage.answers.first
                
                guard case .srv(let srvRecord) = answer else { return }
                let port = srvRecord.resource.port
                
                var stringAddress: String = ""
                for additionalAnswer in newMessage.additionalData {
                    guard case .a(let aRecord) = additionalAnswer else { continue }

                    stringAddress = aRecord.resource.stringAddress
                }
                guard !stringAddress.isEmpty else { return }
                
                guard let questionLabels = newMessage.questions.first?.labels,
                      let bytes = questionLabels.first?.label,
                      let peerKey32 = String(bytes: bytes, encoding: .utf8),
                      let peerKey = try? WGSDClient.base64Encoded(from: peerKey32)
                else { return }
                
                endpointsStorage[peerKey] = "\(stringAddress):\(port)"
            }

            resp.whenSuccess { records in
                closure(.success(records))
            }

            resp.whenFailure({ error in
                print("Error: \(error)")
                closure(.failure(error))
            })
            
            /*
            resp.whenComplete { _ in
                try! self.loopGroup.syncShutdownGracefully()
            }
             */
        } catch {
            print("Error: \(error)")
        }

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
