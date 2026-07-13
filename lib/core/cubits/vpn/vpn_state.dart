part of 'vpn_cubit.dart';

@freezed
abstract class VpnState with _$VpnState {
  const factory VpnState.initial() = _Initial;
  const factory VpnState.connecting() = _Connecting;
  const factory VpnState.connected(VpnServer server) = _Connected;
  const factory VpnState.disconnected() = _Disconnected;
  const factory VpnState.error(String message) = _Error;
}
