
import 'package:pigeon/pigeon.dart';

class VpnMessage{
  String? connected;
}

class VpnResult{
  bool? successful;
  bool? hasError;
  String? error;
}
/// Вызов из Flutter в натив
@HostApi()
abstract class VpnConnection {
  @async
  VpnResult start();
  @async
  VpnResult stop();
}

/// Вызов из натива вo Flutter
@FlutterApi()
abstract class ConnectionReceiver{
  void onStatusChanged(VpnMessage message);
}


