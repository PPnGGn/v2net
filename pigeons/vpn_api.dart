import 'package:pigeon/pigeon.dart';

/// Lifecycle of the VPN tunnel. The native side is the source of truth and
/// pushes every transition through [VpnEventReceiver.onStatusChanged].
enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

/// Everything the native side needs to bring up a tunnel for one server.
class VpnConfigMessage {
  String configJson;
  String? serverId;
  String? title;
}

/// A status transition. [error] is only meaningful for [VpnStatus.error].
class VpnStatusMessage {
  VpnStatus status;
  String? error;
}

/// A single log line emitted by the core (xray / tun2socks).
class VpnLogMessage {
  String level;
  String message;
  String source;
  int timestampMs;
}

/// Cumulative traffic counters since the tunnel came up.
class VpnTrafficMessage {
  int uplinkBytes;
  int downlinkBytes;
}

/// Result of a start/stop request.
class VpnResult {
  bool successful;
  String? error;
}

/// Flutter -> native
@HostApi()
abstract class VpnConnection {
  @async
  VpnResult start(VpnConfigMessage config);

  @async
  VpnResult stop();

  /// Source of truth queried on resume to re-sync the UI.
  VpnStatusMessage getStatus();
}

/// native -> Flutter
@FlutterApi()
abstract class VpnEventReceiver {
  void onStatusChanged(VpnStatusMessage message);

  void onLog(VpnLogMessage message);

  void onTraffic(VpnTrafficMessage message);
}
