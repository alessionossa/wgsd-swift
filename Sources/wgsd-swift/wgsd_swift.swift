import DNSClient
import NIO
import ExtrasBase64
import NIOPosix

public struct wgsd_swift {
    
    public typealias Endpoint = (String, UInt16)
    
    /// Query the DNS server to get informations about endpoints identified by public keys in `peersPubKey`.
    /// - Parameters:
    ///   - dnsServer: IP address of server with WGSD
    ///   - port: WGSD Server port
    ///   - dnsZone: Custom DNS zone, it must be the same of the one set on server
    ///   - peersPubKey: Array of Base64 encoded public keys of peers you want to request endpoint informations
    static public func queryServer(loopGroup: MultiThreadedEventLoopGroup, dnsClient: DNSClient, dnsServer: String, port: UInt16, dnsZone: String, peersPubKey: [String], closure: @escaping ([String: Endpoint]) -> ()) {
        
//        var futures: [EventLoopFuture<[ResourceRecord<SRVRecord>]>] = []
        var futures: [EventLoopFuture<()>] = []
        
        var endpoints = [String: Endpoint]()
        
//        var loopGroup: MultiThreadedEventLoopGroup!
//        var dnsClient: DNSClient!
//        
//        do {
//            let serverSocketAddress = try SocketAddress(ipAddress: dnsServer, port: Int(port))
//            loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//            dnsClient = try DNSClient.connect(on: loopGroup, config: [serverSocketAddress]).wait()
//        } catch let error {
//            print("Error \(error)")
//        }
        
        do {
            for peerPubKey in peersPubKey {
//                let loop = loopGroup.next()
                
                let keyBytes = try Base64.decode(string: peerPubKey)
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
                
                let completeZone = base32Key + "._wireguard._udp." + dnsZone
                
//                let recordsFuture = dnsClient.getSRVRecords(from: completeZone)
//
//                recordsFuture.whenSuccess { records in
//                    print("Salamella")
//                    dump(records)
//                }
//                recordsFuture.whenFailure { error in
//                    print("Error sdsd: \(error.localizedDescription)")
//                }
//
//                let resFuture = recordsFuture.map { records in
//                    print("Lookup for \(peerPubKey):")
//                    dump(records)
//                }
                
                dnsClient.getSRVRecords(from: completeZone)
                    .whenComplete { result in
                        switch result {
                        case .failure(let error):
                            print(error.localizedDescription)
                        case .success(let answers):
                            dump(answers)
                        }
                    }
                
                
                
//                futures.append(resFuture)
            }
            
//            let resp = EventLoopFuture.reduce(into: endpoints, futures, on: loopGroup.next()) { val, inputVal in
//                print("Reducing")
//            }
//            let futureResult = EventLoopFuture.reduce(0, futures, on: loopGroup.next()) { [ResourceRecord<SRVRecord>] -> Int in
//                return 1
//            }
//
//            resp.whenSuccess { records in
//                print("Ended")
//                closure(records)
//                if records.isEmpty {
//                    print("\(peerPubKey) no SRV records found")
//                }
//
//                for record in records {
//                    print("Lookup for \(peerPubKey):")
//                    dump(record)
//                    print(record.resource.weight)
//                    print(record.resource.priority)
//                    print(record.resource.domainName.string)
//                }
//            }

//            resp.whenFailure({ error in
//                print("Error: \(error)")
//            })
            
//            resp.whenComplete { _ in
//                try! loopGroup.syncShutdownGracefully()
//            }
        } catch {
            print("Error: \(error)")
        }

    }
}
