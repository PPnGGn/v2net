part of 'vpn_service_cubit.dart';

@freezed
abstract class VpnServiceState with _$VpnServiceState {
  const factory VpnServiceState.initial() = _Initial;
  const factory VpnServiceState.connecting() = _Connecting;
  const factory VpnServiceState.connected(VpnServer server) = _Connected;
  const factory VpnServiceState.disconnected() = _Disconnected;
  const factory VpnServiceState.error(String message) = _Error;
}
