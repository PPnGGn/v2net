import 'package:freezed_annotation/freezed_annotation.dart';

part 'vpn_server.freezed.dart';
part 'vpn_server.g.dart';

@freezed
abstract class VpnServer with _$VpnServer {
  const factory VpnServer({
    required String id,
    required String subscriptionId, 
    required String countryCode,
    required String title,
    required String rawCode,
  }) = _VpnServer;

  factory VpnServer.fromJson(Map<String, dynamic> json) =>
      _$VpnServerFromJson(json);
}