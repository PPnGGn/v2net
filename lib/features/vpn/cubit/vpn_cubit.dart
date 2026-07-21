import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/models/vpn_server/vpn_server.dart';
import 'package:v2net/core/result.dart';
import 'package:v2net/features/vpn/data/vpn_api.g.dart';
import 'package:v2net/features/vpn/data/vpn_repository.dart';
import 'package:v2net/features/vpn/data/vpn_session_store.dart';

part 'vpn_state.dart';
part 'vpn_cubit.freezed.dart';

@lazySingleton
class VpnCubit extends Cubit<VpnState> {
  VpnCubit({
    required VpnRepository repository,
    required VpnSessionStore sessionStore,
    required Talker talker,
  }) : _repository = repository,
       _sessionStore = sessionStore,
       _talker = talker,
       super(const VpnState.disconnected()) {
    _currentServer = _sessionStore.load();
    _statusSubscription = _repository.status.listen(_onNativeStatus);
    _trafficSubscription = _repository.traffic.listen(_onTraffic);
    _syncStatus();
  }

  static const _connectTimeout = Duration(seconds: 15);
  final VpnRepository _repository;
  final VpnSessionStore _sessionStore;
  final Talker _talker;

  late final StreamSubscription<VpnStatusMessage> _statusSubscription;
  late final StreamSubscription<VpnTrafficMessage> _trafficSubscription;
  VpnServer? _currentServer;
  DateTime? _connectedAt;
  Timer? _connectTimer;

  Future<void> connect(VpnServer server) async {
    if (state is _Connecting ||
        state is _Connected ||
        state is _Disconnecting) {
      _talker.debug('Cubit: connect ignored, state: $state');
      return;
    }

    _talker.debug('Cubit: connecting to ${server.title}');
    _currentServer = server;
    unawaited(_sessionStore.save(server));
    emit(const VpnState.connecting());

    final result = await _repository.start(server);
    switch (result) {
      case Success():
        _talker.info('Cubit: core started, waiting for tunnel confirmation');
        _startConnectTimeout();
      case Failure(:final message):
        _talker.error('Cubit: connect failed -> $message');
        _clearSession();
        emit(VpnState.error(message));
    }
  }

  Future<void> disconnect() async {
    if (state is _Disconnected || state is _Disconnecting) {
      _talker.debug('Cubit: disconnect ignored, state: $state');
      return;
    }

    _talker.debug('Cubit: disconnecting VPN');
    _connectTimer?.cancel();
    emit(const VpnState.disconnecting());

    final result = await _repository.stop();
    if (result case Failure(:final message)) {
      _talker.error('Cubit: disconnect failed -> $message');
      emit(VpnState.error(message));
    }
  }

  Future<void> _syncStatus() async {
    try {
      final status = await _repository.getStatus();
      _talker.debug('Cubit: getStatus on start -> ${status.status}');
      _onNativeStatus(status);
    } catch (e, st) {
      _talker.handle(e, st, 'Cubit: getStatus failed');
    }
  }

  void _onNativeStatus(VpnStatusMessage message) {
    _talker.debug('Cubit: native status -> ${message.status}');
    switch (message.status) {
      case VpnStatus.connecting:
        if (state is! _Connecting) emit(const VpnState.connecting());
        _startConnectTimeout();
      case VpnStatus.connected:
        _connectTimer?.cancel();
        final server = _currentServer;
        if (server == null) {
          _talker.warning('Cubit: connected from native with no known server');
          return;
        }
        _connectedAt = DateTime.now();
        emit(VpnState.connected(server, connectedAt: _connectedAt!));
      case VpnStatus.disconnecting:
        _connectTimer?.cancel();
        emit(const VpnState.disconnecting());
      case VpnStatus.disconnected:
        _connectTimer?.cancel();
        _clearSession();
        emit(const VpnState.disconnected());
      case VpnStatus.error:
        _connectTimer?.cancel();
        _clearSession();
        emit(VpnState.error(message.error ?? 'VPN error'));
    }
  }

  void _onTraffic(VpnTrafficMessage traffic) {
    final current = state;
    if (current is _Connected) {
      emit(
        current.copyWith(
          uplinkBytes: traffic.uplinkBytes,
          downlinkBytes: traffic.downlinkBytes,
        ),
      );
    }
  }

  void _startConnectTimeout() {
    _connectTimer?.cancel();
    _connectTimer = Timer(_connectTimeout, () {
      if (state is! _Connecting) return;
      _talker.error('Cubit: timed out waiting for tunnel confirmation');
      _clearSession();
      unawaited(_repository.stop());
      emit(const VpnState.error('Tunnel did not come up within 15 seconds'));
    });
  }

  void _clearSession() {
    _currentServer = null;
    _connectedAt = null;
    unawaited(_sessionStore.clear());
  }

  @override
  Future<void> close() {
    _connectTimer?.cancel();
    _statusSubscription.cancel();
    _trafficSubscription.cancel();
    return super.close();
  }
}
