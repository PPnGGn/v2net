import 'package:injectable/injectable.dart';
import 'package:v2net/features/vpn/data/vpn_api.g.dart';
import 'package:v2net/features/vpn/data/vpn_status_receiver.dart';

@module
abstract class VpnModule {
  @lazySingleton
  VpnConnection get vpnConnection => VpnConnection();

  @lazySingleton
  VpnStatusReceiver get vpnStatusReceiver => VpnStatusReceiver()..register();
}
