import 'dart:async';
import 'dart:collection';
import 'package:injectable/injectable.dart';
import 'package:v2net/features/vpn/data/vpn_api.g.dart';

@lazySingleton
class XrayLogStore {
  static const _maxEntries = 500;

  final ListQueue<VpnLogMessage> _entries = ListQueue<VpnLogMessage>();
  final _controller = StreamController<List<VpnLogMessage>>.broadcast();

  List<VpnLogMessage> get history => List.unmodifiable(_entries);

  Stream<List<VpnLogMessage>> get stream => _controller.stream;

  void add(VpnLogMessage entry) {
    _entries.addLast(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    _controller.add(history);
  }

  void clear() {
    _entries.clear();
    _controller.add(history);
  }
}
