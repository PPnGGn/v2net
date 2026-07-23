import Flutter
import NetworkExtension
import os

private let appLog = Logger(subsystem: "vpn.oko", category: "vpnstatus")

final class VpnConnectionImpl: NSObject, VpnConnection {

    private static let extensionBundleID = "vpn.oko.XrayTunnel"
    private static let socksPort = 10808
    private static let maxReconnectAttempts = 3

    private let eventReceiver: VpnEventReceiver
    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private var trafficTimer: Timer?
    private var connectedAt: Date?
    private var lastSentStatus: VpnStatus?

    // Auto-reconnect
    private var userInitiatedStop = false
    private var reconnectAttempts = 0
    private var lastStartOptions: [String: NSObject]?

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.eventReceiver = VpnEventReceiver(binaryMessenger: binaryMessenger)
        super.init()
        
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStatusChange()
        }
    }

    deinit {
        if let obs = statusObserver { NotificationCenter.default.removeObserver(obs) }
    }


    func start(config: VpnConfigMessage, completion: @escaping (Result<VpnResult, Error>) -> Void) {
        userInitiatedStop = false
        reconnectAttempts = 0
        
        loadOrCreateManager { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.success(VpnResult(successful: false, error: error.localizedDescription)))
            case .success(let manager):
                self?.startTunnel(manager: manager, config: config, completion: completion)
            }
        }
    }

    func stop(completion: @escaping (Result<VpnResult, Error>) -> Void) {
        userInitiatedStop = true
        stopTrafficPolling()
        manager?.isOnDemandEnabled = false
        manager?.saveToPreferences { _ in }
        manager?.connection.stopVPNTunnel()
        completion(.success(VpnResult(successful: true)))
    }

    func getStatus() throws -> VpnStatusMessage {
        let status: VpnStatus = manager.map { vpnStatus(from: $0.connection.status) } ?? .disconnected
        let connectedAtMs = connectedAt.map { Int64($0.timeIntervalSince1970 * 1000) }
        return VpnStatusMessage(status: status, connectedAtEpochMs: connectedAtMs)
    }


    private func loadOrCreateManager(
        completion: @escaping (Result<NETunnelProviderManager, Error>) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            let existing = managers?.first {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?
                    .providerBundleIdentifier == Self.extensionBundleID
            }
             
            let manager: NETunnelProviderManager
            if let existing {
                appLog.notice("loadOrCreateManager: reusing existing manager (count=\(managers?.count ?? 0, privacy: .public))")
                manager = existing
            } else {
                appLog.notice("loadOrCreateManager: creating NEW manager (count=\(managers?.count ?? 0, privacy: .public))")
                manager = NETunnelProviderManager()
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = Self.extensionBundleID
                proto.serverAddress = "v2net"
                manager.protocolConfiguration = proto
                manager.localizedDescription = "v2net"
            }
            
            manager.isEnabled = true
            manager.onDemandRules = [NEOnDemandRuleConnect()]
            manager.isOnDemandEnabled = true
            self?.manager = manager
            completion(.success(manager))
        }
    }

    private func startTunnel(
        manager: NETunnelProviderManager,
        config: VpnConfigMessage,
        completion: @escaping (Result<VpnResult, Error>) -> Void
    ) {
        manager.saveToPreferences { error in
            if let error {
                completion(.success(VpnResult(successful: false, error: error.localizedDescription)))
                return
            }
            manager.loadFromPreferences { error in
                if let error {
                    completion(.success(VpnResult(successful: false, error: error.localizedDescription)))
                    return
                }
                do {
                    let options: [String: NSObject] = [
                        "configJson": config.configJson as NSObject,
                        "socksPort": NSNumber(value: Self.socksPort),
                    ]
                    self.lastStartOptions = options
                    let session = manager.connection as! NETunnelProviderSession
                    appLog.notice("startTunnel: calling startVPNTunnel; current status.rawValue=\(session.status.rawValue, privacy: .public)")
                    
                    try session.startVPNTunnel(options: options)
                    appLog.notice("startTunnel: startVPNTunnel returned OK")
                    completion(.success(VpnResult(successful: true)))
                } catch {
                    appLog.error("startTunnel: startVPNTunnel THREW: \(error.localizedDescription, privacy: .public)")
                    completion(.success(VpnResult(successful: false, error: error.localizedDescription)))
                }
            }
        }
    }

    private func handleStatusChange() {
        guard let connection = manager?.connection else {
            appLog.error("handleStatusChange: manager/connection is nil — status dropped")
            return
        }
        let status = connection.status
        appLog.notice("handleStatusChange: NEVPNStatus.rawValue=\(status.rawValue, privacy: .public) -> \(String(describing: self.vpnStatus(from: status)), privacy: .public)")

        if (status == .disconnected || status == .invalid),
           !userInitiatedStop,
           reconnectAttempts < Self.maxReconnectAttempts {
            reconnectAttempts += 1
            appLog.notice("handleStatusChange: unexpected disconnect (rawValue=\(status.rawValue, privacy: .public)); scheduling app-level retry \(self.reconnectAttempts, privacy: .public)/\(Self.maxReconnectAttempts, privacy: .public)")
            scheduleReconnect()
            return
        }

        switch status {
        case .connected:
            if connectedAt == nil { connectedAt = Date() }
            reconnectAttempts = 0
            startTrafficPolling()
        case .disconnected, .invalid:
            connectedAt = nil
            stopTrafficPolling()
        default:
            break
        }

        let vpnStat = vpnStatus(from: status)

        if vpnStat == lastSentStatus {
            appLog.notice("handleStatusChange: duplicate \(String(describing: vpnStat), privacy: .public) suppressed")
            return
        }
        lastSentStatus = vpnStat

        let connectedAtMs = connectedAt.map { Int64($0.timeIntervalSince1970 * 1000) }
        let msg = VpnStatusMessage(status: vpnStat, connectedAtEpochMs: connectedAtMs)
        eventReceiver.onStatusChanged(message: msg) { _ in }
    }

    private func scheduleReconnect() {
        let delay = pow(2.0, Double(reconnectAttempts))  
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self,
                  !self.userInitiatedStop,
                  let manager = self.manager,
                  let session = manager.connection as? NETunnelProviderSession,
                  session.status == .disconnected || session.status == .invalid,
                  let options = self.lastStartOptions
            else { return }
            do {
                appLog.notice("scheduleReconnect: retrying startVPNTunnel (attempt \(self.reconnectAttempts, privacy: .public)/\(Self.maxReconnectAttempts, privacy: .public))")
                try session.startVPNTunnel(options: options)
            } catch {
                appLog.error("scheduleReconnect: startVPNTunnel threw: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func vpnStatus(from status: NEVPNStatus) -> VpnStatus {
        switch status {
        case .invalid, .disconnected: return .disconnected
        case .connecting, .reasserting: return .connecting
        case .connected: return .connected
        case .disconnecting: return .disconnecting
        @unknown default: return .disconnected
        }
    }

    private func startTrafficPolling() {
        guard trafficTimer == nil else { return }
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollTraffic()
            self?.pollLogs()
        }
    }

    private func stopTrafficPolling() {
        trafficTimer?.invalidate()
        trafficTimer = nil
    }

    private func pollTraffic() {
        guard let session = manager?.connection as? NETunnelProviderSession,
              session.status == .connected
        else { return }

        let request = Data("traffic".utf8)
        try? session.sendProviderMessage(request) { [weak self] responseData in
            guard let responseData,
                  let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let uplink = json["uplink"] as? Int64,
                  let downlink = json["downlink"] as? Int64
            else { return }

            let msg = VpnTrafficMessage(uplinkBytes: uplink, downlinkBytes: downlink)
            self?.eventReceiver.onTraffic(message: msg) { _ in }
        }
    }

    private func pollLogs() {
        guard let session = manager?.connection as? NETunnelProviderSession,
              session.status == .connected
        else { return }

        let request = Data("logs".utf8)
        try? session.sendProviderMessage(request) { [weak self] responseData in
            guard let self,
                  let responseData,
                  let entries = try? JSONSerialization.jsonObject(with: responseData) as? [[String: Any]]
            else { return }

            for entry in entries {
                let msg = VpnLogMessage(
                    level: entry["level"] as? String ?? "info",
                    message: entry["message"] as? String ?? "",
                    source: entry["source"] as? String ?? "core",
                    timestampMs: (entry["timestampMs"] as? NSNumber)?.int64Value ?? 0
                )
                self.eventReceiver.onLog(message: msg) { _ in }
            }
        }
    }
}
