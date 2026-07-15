import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/entities/models/vpn_server.dart';
import 'country_code_extractor.dart';

class CustomJsonParser {
  final Talker _talker;
  final CountryCodeExtractor _countryCodeExtractor;

  CustomJsonParser(this._talker, this._countryCodeExtractor);

  // Parses the custom JSON outbound array format into servers.
  List<VpnServer> parse(String rawJson, String sourceId) {
    final list = jsonDecode(rawJson) as List<dynamic>;
    final List<VpnServer> result = [];

    for (final item in list) {
      try {
        final config = item as Map<String, dynamic>;
        final title = config['remarks'] as String? ?? 'Unknown Server';
        final outbounds = config['outbounds'] as List<dynamic>;

        // Only the "proxy" (or "proxy-*") outbound carries the actual server.
        final proxyOutbound = outbounds.cast<Map<String, dynamic>>().firstWhereOrNull((o) {
          final tag = o['tag'] as String? ?? '';
          return tag == 'proxy' || tag.startsWith('proxy-');
        });

        if (proxyOutbound == null) continue;

        final settings = proxyOutbound['settings'] as Map<String, dynamic>;
        final addressPort = _extractAddressPort(settings);
        if (addressPort == null) continue;

        final address = addressPort.$1;
        final port = addressPort.$2;
        final uuid = addressPort.$3;

        result.add(VpnServer(
          id: uuid.isNotEmpty ? '$address:$port:$uuid' : '$address:$port',
          subscriptionId: sourceId,
          title: title,
          countryCode: _countryCodeExtractor.extract(title),
          rawCode: jsonEncode(config),
        ));
      } catch (e) {
        _talker.warning('Parser: пропущен битый JSON объект -> $e');
      }
    }
    return result;
  }

  // Extracts (address, port, uuid) from either a "vnext" or a flat "address" outbound shape.
  (String, int, String)? _extractAddressPort(Map<String, dynamic> settings) {
    if (settings.containsKey('vnext')) {
      final vnext = settings['vnext'] as List<dynamic>;
      if (vnext.isEmpty) return null;
      final node = vnext[0] as Map<String, dynamic>;
      final port = _parsePort(node['port']);
      if (port == null) return null;
      return (node['address'] as String, port, _extractUuid(node));
    }
    if (settings.containsKey('address')) {
      final port = _parsePort(settings['port']);
      if (port == null) return null;
      return (settings['address'] as String, port, _extractUuid(settings));
    }
    return null;
  }

  // Reads the first user's id (uuid) from a vnext/settings node, if present.
  String _extractUuid(Map<String, dynamic> node) {
    final users = node['users'] as List<dynamic>?;
    if (users == null || users.isEmpty) return '';
    final user = users[0] as Map<String, dynamic>?;
    return user?['id'] as String? ?? '';
  }

  // Parses a port from either an int or a numeric string, validating its range.
  int? _parsePort(dynamic value) {
    final port = value is int ? value : (value is String ? int.tryParse(value) : null);
    if (port == null || port <= 0 || port > 65535) return null;
    return port;
  }
}
