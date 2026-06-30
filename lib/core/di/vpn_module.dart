import 'package:injectable/injectable.dart';
import 'package:v2net/core/platform/vpn_api.g.dart';

@module
abstract class VpnModule {
  @lazySingleton
  VpnConnection get vpnConnection => VpnConnection();
}
