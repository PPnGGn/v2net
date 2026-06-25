import 'package:pigeon/pigeon.dart';

class VpnMessage {
  bool? connected;
}

class VpnResult {
  bool? successful;
  bool? hasError;
  String? error;
}

/// Flutter -> native
@HostApi()
abstract class VpnConnection {
  @async
  VpnResult start(String configJson);

  @async
  VpnResult stop();
}

/// native -> Flutter
@FlutterApi()
abstract class ConnectionReceiver {
  void onStatusChanged(VpnMessage message);
}