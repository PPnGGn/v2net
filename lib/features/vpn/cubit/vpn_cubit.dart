import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/models/vpn_server.dart';
import 'package:v2net/core/result.dart';
import 'package:v2net/features/vpn/data/vpn_repository.dart';

part 'vpn_state.dart';
part 'vpn_cubit.freezed.dart';

@lazySingleton
class VpnCubit extends Cubit<VpnState> {
  VpnCubit({required VpnRepository repository, required Talker talker})
    : _repository = repository,
      _talker = talker,
      super(const VpnState.disconnected()) {
    _statusSubscription = _repository.connectionStatus.listen(_onNativeStatus);
  }

  static const _connectTimeout = Duration(seconds: 15);

  final VpnRepository _repository;
  final Talker _talker;

  late final StreamSubscription<bool> _statusSubscription;
  VpnServer? _currentServer;
  Timer? _connectTimer;

  Future<void> connect(VpnServer server) async {
    if (state is _Connecting || state is _Connected) {
      _talker.debug('Cubit: connect проигнорирован, состояние: $state');
      return;
    }

    _talker.debug('Cubit: Инициируем подключение к ${server.title}');
    _currentServer = server;
    emit(const VpnState.connecting());

    final result = await _repository.start(server);

    switch (result) {
      case Success():
        // core started; connected is emitted from _onNativeStatus once the
        // tunnel actually comes up, not here
        _talker.info('Cubit: ядро запущено, ждём подтверждения туннеля');
        _startConnectTimeout();
      case Failure(:final message):
        _talker.error('Cubit: Ошибка подключения -> $message');
        _currentServer = null;
        emit(VpnState.error(message));
    }
  }

  Future<void> disconnect() async {
    if (state is _Disconnected || state is _Connecting) {
      _talker.debug('Cubit: disconnect проигнорирован, состояние: $state');
      return;
    }

    _talker.debug('Cubit: Инициируем отключение VPN');
    _connectTimer?.cancel();

    final result = await _repository.stop();

    switch (result) {
      case Success():
        _talker.info('Cubit: VPN успешно отключен');
        _currentServer = null;
        emit(const VpnState.disconnected());
      case Failure(:final message):
        _talker.error('Cubit: Ошибка отключения -> $message');
        emit(VpnState.error(message));
    }
  }

  void _onNativeStatus(bool connected) {
    _talker.debug('Cubit: нативный статус туннеля -> connected=$connected');
    _connectTimer?.cancel();

    if (connected) {
      final server = _currentServer;
      // null after a timeout already turned into an error state
      if (server != null) {
        _talker.info('Cubit: туннель поднят (${server.title})');
        emit(VpnState.connected(server));
      }
    } else {
      switch (state) {
        case _Connecting():
          _talker.error('Cubit: туннель не поднялся');
          _currentServer = null;
          emit(const VpnState.error('Не удалось установить VPN-туннель'));
        case _Connected():
          _talker.warning('Cubit: туннель остановлен извне');
          _currentServer = null;
          emit(const VpnState.disconnected());
        default:
          break;
      }
    }
  }

  void _startConnectTimeout() {
    _connectTimer?.cancel();
    _connectTimer = Timer(_connectTimeout, () {
      if (state is! _Connecting) return;
      _talker.error('Cubit: таймаут ожидания подтверждения туннеля');
      _currentServer = null;
      _repository.stop();
      emit(const VpnState.error('Туннель не поднялся за 15 секунд'));
    });
  }

  @override
  Future<void> close() {
    _connectTimer?.cancel();
    _statusSubscription.cancel();
    return super.close();
  }
}
