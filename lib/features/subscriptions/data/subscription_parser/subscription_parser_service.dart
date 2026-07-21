import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/models/vpn_server/vpn_server.dart';
import 'package:v2net/core/result.dart';
import 'country_code_extractor.dart';
import 'custom_json_parser.dart';
import 'shadowsocks_uri_parser.dart';
import 'subscription_fetcher.dart';
import 'vless_uri_parser.dart';
import 'xray_config_builder.dart';

@lazySingleton
class SubscriptionParserService {
  final Talker _talker;
  final SubscriptionFetcher _fetcher;
  final VlessUriParser _vlessUriParser;
  final ShadowsocksUriParser _shadowsocksUriParser;
  final CustomJsonParser _customJsonParser;

  SubscriptionParserService(Talker talker)
    : _talker = talker,
      _fetcher = SubscriptionFetcher(),
      _vlessUriParser = VlessUriParser(
        talker,
        XrayConfigBuilder(),
        CountryCodeExtractor(),
      ),
      _shadowsocksUriParser = ShadowsocksUriParser(
        talker,
        XrayConfigBuilder(),
        CountryCodeExtractor(),
      ),
      _customJsonParser = CustomJsonParser(talker, CountryCodeExtractor());

  Future<Result<List<VpnServer>>> parseFromInput(String input) async {
    try {
      final cleanInput = input.trim();
      final List<VpnServer> servers = [];
      String textToParse = cleanInput;

      // User can paste either a subscription URL or a direct vless://ss:// link.
      final lowerInput = cleanInput.toLowerCase();
      if (lowerInput.startsWith('http://') ||
          lowerInput.startsWith('https://')) {
        _talker.debug('Parser: found a URL, fetching...');
        textToParse = await _fetcher.fetchText(cleanInput);
      } else if (!_isDirectLink(cleanInput)) {
        return const Failure(
          'Unknown input format. Expected an http(s) link, vless:// or ss://',
        );
      }

      final trimmed = textToParse.trim();
      if (trimmed.startsWith('[')) {
        // Raw JSON array (custom outbound format).
        _talker.debug('Parser: found a raw JSON array');
        servers.addAll(_customJsonParser.parse(textToParse, cleanInput));
      } else {
        // Plain text (or base64) with a mix of vless:// / ss:// links.
        String decoded = textToParse;
        if (!_isDirectLink(trimmed)) {
          _talker.debug('Parser: found base64, decoding...');
          decoded = _fetcher.decodeBase64(textToParse);
        } else {
          _talker.debug('Parser: found direct links (URI)');
        }
        servers.addAll(_vlessUriParser.parseLines(decoded, cleanInput));
        servers.addAll(_shadowsocksUriParser.parseLines(decoded, cleanInput));
      }

      if (servers.isEmpty) {
        return const Failure('No supported servers were found in the response');
      }

      _talker.info('Parser: successfully parsed ${servers.length} server(s)');
      return Success(servers);
    } catch (e, st) {
      _talker.handle(e, st, 'Parser: unhandled error while processing');
      return Failure('Failed to process the data: $e');
    }
  }

  bool _isDirectLink(String s) =>
      _vlessUriParser.isVless(s) || _shadowsocksUriParser.isShadowsocks(s);
}
