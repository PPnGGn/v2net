import NetworkExtension

final class PacketFlowBridge: NSObject, IosPacketFlowProtocol {
    private let flow: NEPacketTunnelFlow
    private let queue = DispatchQueue(label: "com.v2net.packetflow.read")
    private let semaphore = DispatchSemaphore(value: 0)
    private var buffer: [Data] = []
    private let bufferLock = NSLock()
    private var closed = false

    init(flow: NEPacketTunnelFlow) {
        self.flow = flow
        super.init()
        pump()
    }

    private func pump() {
        flow.readPackets { [weak self] packets, _ in
            guard let self, !self.closed else { return }
            self.bufferLock.lock()
            self.buffer.append(contentsOf: packets)
            self.bufferLock.unlock()
            for _ in packets {
                self.semaphore.signal()
            }
            self.pump()
        }
    }

    func close() {
        closed = true
        semaphore.signal()
    }

    func readPacket() throws -> Data {
        semaphore.wait()
        bufferLock.lock()
        defer { bufferLock.unlock() }
        guard !buffer.isEmpty else {
            throw NSError(domain: "com.v2net.PacketTunnel", code: 3, userInfo: [NSLocalizedDescriptionKey: "flow closed"])
        }
        return buffer.removeFirst()
    }

    func writePacket(_ packet: Data?) throws {
        guard let packet else { return }
        let family: NSNumber = (packet.first.map { $0 >> 4 } == 6) ? AF_INET6 as NSNumber : AF_INET as NSNumber
        flow.writePackets([packet], withProtocols: [family])
    }
}

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private var flowBridge: PacketFlowBridge?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let configJson = options?["configJson"] as? String,
              let socksPort = options?["socksPort"] as? NSNumber
        else {
            completionHandler(NSError(
                domain: "com.v2net.PacketTunnel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Missing configJson/socksPort in tunnel options"]
            ))
            return
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = NEIPv4Settings(addresses: ["10.10.10.2"], subnetMasks: ["255.255.255.0"])
        settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        settings.mtu = 1500
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "1.0.0.1"])

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self else { return }
            if let error {
                completionHandler(error)
                return
            }

            let bridge = PacketFlowBridge(flow: self.packetFlow)
            self.flowBridge = bridge

            var startError: NSError?
            let ok = IosStart(configJson, bridge, socksPort.intValue, &startError)
            if !ok {
                completionHandler(startError ?? NSError(
                    domain: "com.v2net.PacketTunnel",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "IosStart failed"]
                ))
                return
            }

            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        var stopError: NSError?
        _ = IosStop(&stopError)
        flowBridge?.close()
        flowBridge = nil
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override func wake() {
        // Add code here to wake up.
    }
}
