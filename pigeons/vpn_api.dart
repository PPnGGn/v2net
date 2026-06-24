import 'package:pigeon/pigeon.dart';

class VpnMessage {
  bool? connected;
}

class VpnResult {
  bool? successful;
  bool? hasError;
  String? error;
}

/// Вызов из Flutter в натив
@HostApi()
abstract class VpnConnection {
  @async
  // Добавлен параметр configJson. Теперь Flutter обязан передавать конфиг.
  VpnResult start(String configJson);

  @async
  VpnResult stop();
}

/// Вызов из натива вo Flutter
@FlutterApi()
abstract class ConnectionReceiver {
  void onStatusChanged(VpnMessage message);
}