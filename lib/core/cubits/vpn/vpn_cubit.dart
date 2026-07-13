import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/common/result.dart';
import 'package:v2net/core/repositories/vpn_repository.dart';
import 'package:v2net/entities/models/vpn_server.dart';

part 'vpn_state.dart';
part 'vpn_cubit.freezed.dart';

@lazySingleton
class VpnCubit extends Cubit<VpnState> {
  VpnCubit({
    required IVpnRepository repository,
    required Talker talker,
  })  : _repository = repository,
        _talker = talker,
        super(const VpnState.disconnected());

  final IVpnRepository _repository;
  final Talker _talker;

  Future<void> connect(VpnServer server) async {
    _talker.debug('Cubit: Инициируем подключение к ${server.title}');
    emit(const VpnState.connecting());

    final result = await _repository.start(server);

    switch (result) {
      case Success():
        _talker.info('Cubit: VPN успешно подключен (${server.title})');
        emit(VpnState.connected(server));
      case Failure(:final message):
        _talker.error('Cubit: Ошибка подключения -> $message');
        emit(VpnState.error(message));
    }
  }

  Future<void> disconnect() async {
    _talker.debug('Cubit: Инициируем отключение VPN');

    final result = await _repository.stop();

    switch (result) {
      case Success():
        _talker.info('Cubit: VPN успешно отключен');
        emit(const VpnState.disconnected());
      case Failure(:final message):
        _talker.error('Cubit: Ошибка отключения -> $message');
        emit(VpnState.error(message));
    }
  }
}
