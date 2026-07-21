import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/features/subscriptions/data/subscription_parser/country_code_extractor.dart';
import 'package:v2net/features/subscriptions/data/subscription_parser/custom_json_parser.dart';

void main() {
  final parser = CustomJsonParser(Talker(), CountryCodeExtractor());

  group('CustomJsonParser.parse', () {
    test('parses the vnext outbound shape and fills every field', () {
      final json = jsonEncode([
        {
          'remarks': '🇩🇪 Germany #1',
          'outbounds': [
            {
              'tag': 'proxy',
              'protocol': 'vless',
              'settings': {
                'vnext': [
                  {
                    'address': 'vnext.example.com',
                    'port': 443,
                    'users': [
                      {'id': 'uuid-vnext'},
                    ],
                  },
                ],
              },
            },
            {'tag': 'direct', 'protocol': 'freedom', 'settings': {}},
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers, hasLength(1));
      final server = servers.first;
      expect(server.id, equals('vnext.example.com:443:uuid-vnext'));
      expect(server.subscriptionId, equals('my-subscription'));
      expect(server.title, equals('🇩🇪 Germany #1'));
      expect(server.countryCode, equals('DE'));
    });

    test('parses the flat address outbound shape with a string port', () {
      final json = jsonEncode([
        {
          'remarks': 'Flat Server',
          'outbounds': [
            {
              'tag': 'proxy',
              'protocol': 'vless',
              'settings': {
                'address': 'flat.example.com',
                'port': '8443',
                'users': [
                  {'id': 'uuid-flat'},
                ],
              },
            },
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers.single.id, equals('flat.example.com:8443:uuid-flat'));
    });

    test('matches outbound tags starting with "proxy-"', () {
      final json = jsonEncode([
        {
          'remarks': 'Server',
          'outbounds': [
            {
              'tag': 'proxy-1',
              'settings': {
                'address': 'host.example.com',
                'port': 443,
                'users': [
                  {'id': 'uuid'},
                ],
              },
            },
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers, hasLength(1));
    });

    test('skips an object with no proxy outbound at all', () {
      final json = jsonEncode([
        {
          'remarks': 'No Proxy Here',
          'outbounds': [
            {'tag': 'direct', 'settings': {}},
            {'tag': 'block', 'settings': {}},
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers, isEmpty);
    });

    test('skips objects with an invalid or out-of-range port', () {
      final json = jsonEncode([
        _serverWithPort(0),
        _serverWithPort(70000),
        {
          'remarks': 'Bad',
          'outbounds': [
            {
              'tag': 'proxy',
              'settings': {'address': 'host.example.com', 'port': 'abc'},
            },
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers, isEmpty);
    });

    test('defaults the title to "Unknown Server" when remarks is missing', () {
      final json = jsonEncode([
        {
          'outbounds': [
            {
              'tag': 'proxy',
              'settings': {
                'address': 'host.example.com',
                'port': 443,
                'users': [
                  {'id': 'uuid'},
                ],
              },
            },
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers.single.title, equals('Unknown Server'));
    });

    test('builds id without a uuid segment when users is empty', () {
      final json = jsonEncode([
        {
          'remarks': 'No Users',
          'outbounds': [
            {
              'tag': 'proxy',
              'settings': {
                'address': 'host.example.com',
                'port': 443,
                'users': [],
              },
            },
          ],
        },
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers.single.id, equals('host.example.com:443'));
    });

    test('skips a broken object but keeps the valid ones around it', () {
      final json = jsonEncode([
        {
          'remarks': 'Valid One',
          'outbounds': [
            {
              'tag': 'proxy',
              'settings': {
                'address': 'host.example.com',
                'port': 443,
                'users': [
                  {'id': 'uuid'},
                ],
              },
            },
          ],
        },
        {'remarks': 'Broken, no outbounds key at all'},
      ]);

      final servers = parser.parse(json, 'my-subscription');

      expect(servers, hasLength(1));
      expect(servers.single.title, equals('Valid One'));
    });

    test('throws when the top-level JSON value is not an array', () {
      expect(
        () => parser.parse(jsonEncode({'not': 'an array'}), 'sub'),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'strips geosite:/geoip: entries (unresolvable without geosite.dat)',
      () {
        final json = jsonEncode([
          {
            'remarks': 'Server',
            'outbounds': [
              {
                'tag': 'proxy',
                'settings': {
                  'address': 'host.example.com',
                  'port': 443,
                  'users': [
                    {'id': 'uuid'},
                  ],
                },
              },
            ],
            'routing': {
              'rules': [
                {
                  'type': 'field',
                  'outboundTag': 'direct',
                  'domain': ['geosite:category-ru', 'domain:example.com'],
                },
                {
                  'type': 'field',
                  'outboundTag': 'direct',
                  'ip': ['geoip:cn', '10.0.0.0/8'],
                },
                {
                  'type': 'field',
                  'outboundTag': 'block',
                  'domain': ['geosite:category-ads'],
                },
                {
                  'type': 'field',
                  'outboundTag': 'direct',
                  'protocol': ['bittorrent'],
                },
              ],
            },
          },
        ]);

        final servers = parser.parse(json, 'my-subscription');
        final routing =
            jsonDecode(servers.single.configJson)['routing']
                as Map<String, dynamic>;
        final rules = (routing['rules'] as List).cast<Map<String, dynamic>>();

        expect(rules, hasLength(3));
        expect(rules[0]['domain'], equals(['domain:example.com']));
        expect(rules[1]['ip'], equals(['10.0.0.0/8']));
        expect(rules[2]['protocol'], equals(['bittorrent']));
      },
    );
  });
}

Map<String, dynamic> _serverWithPort(int port) => {
  'remarks': 'Bad Port $port',
  'outbounds': [
    {
      'tag': 'proxy',
      'settings': {
        'address': 'host.example.com',
        'port': port,
        'users': [
          {'id': 'uuid'},
        ],
      },
    },
  ],
};
