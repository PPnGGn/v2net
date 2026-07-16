import 'dart:async';

import 'package:v2net/features/vpn/data/vpn_api.g.dart';

/// Bridges native tunnel status pushes (pigeon) into a stream.
class VpnStatusReceiver implements ConnectionReceiver {
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get status => _controller.stream;

  void register() => ConnectionReceiver.setUp(this);

  @override
  void onStatusChanged(VpnMessage message) {
    _controller.add(message.connected ?? false);
  }
}
