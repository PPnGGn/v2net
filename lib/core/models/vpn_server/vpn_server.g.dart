// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vpn_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VpnServer _$VpnServerFromJson(Map<String, dynamic> json) => _VpnServer(
  id: json['id'] as String,
  subscriptionId: json['subscriptionId'] as String,
  countryCode: json['countryCode'] as String,
  title: json['title'] as String,
  configJson: json['configJson'] as String,
);

Map<String, dynamic> _$VpnServerToJson(_VpnServer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subscriptionId': instance.subscriptionId,
      'countryCode': instance.countryCode,
      'title': instance.title,
      'configJson': instance.configJson,
    };
