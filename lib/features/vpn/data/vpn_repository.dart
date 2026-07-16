import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/models/vpn_server.dart';
import 'package:v2net/core/result.dart';
import 'package:v2net/features/vpn/data/vpn_api.g.dart';
import 'package:v2net/features/vpn/data/vpn_status_receiver.dart';

@lazySingleton
class VpnRepository {
  final Talker _talker;
  final VpnConnection _vpnConnection;
  final VpnStatusReceiver _statusReceiver;

  VpnRepository(this._talker, this._vpnConnection, this._statusReceiver);

  Stream<bool> get connectionStatus => _statusReceiver.status;

  Future<Result<void>> start(VpnServer server) async {
    try {
      _talker.debug('Попытка запуска VPN с сервером: ${server.title}');
      final result = await _vpnConnection.start(server.rawCode);

      if (result.successful == true) {
        _talker.info('Ядро Xray успешно запущено');
        return const Success(null);
      } else {
        final errorMsg = result.error ?? 'Неизвестная ошибка ядра Xray';
        _talker.error('Ошибка на стороне Kotlin: $errorMsg');
        return Failure(errorMsg);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Критический сбой моста при старте');
      return Failure('Системный сбой: ${e.toString()}', e);
    }
  }

  Future<Result<void>> stop() async {
    try {
      _talker.debug('Остановка VPN...');
      final result = await _vpnConnection.stop();

      if (result.successful == true) {
        _talker.info('Ядро Xray остановлено');
        return const Success(null);
      } else {
        final errorMsg = result.error ?? 'Неизвестная ошибка остановки';
        _talker.error('Ошибка остановки: $errorMsg');
        return Failure(errorMsg);
      }
    } catch (e, st) {
      _talker.handle(e, st, 'Критический сбой моста при остановке');
      return Failure('Системный сбой: ${e.toString()}', e);
    }
  }
}
