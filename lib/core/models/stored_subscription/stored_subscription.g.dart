// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoredSubscription _$StoredSubscriptionFromJson(Map<String, dynamic> json) =>
    _StoredSubscription(
      subscription: Subscription.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
      servers: (json['servers'] as List<dynamic>)
          .map((e) => VpnServer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StoredSubscriptionToJson(_StoredSubscription instance) =>
    <String, dynamic>{
      'subscription': instance.subscription,
      'servers': instance.servers,
    };
