import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:v2net/core/common/result.dart';
import 'package:v2net/entities/models/vpn_server.dart';
import 'country_code_extractor.dart';
import 'custom_json_parser.dart';
import 'subscription_fetcher.dart';
import 'vless_uri_parser.dart';
import 'xray_config_builder.dart';

abstract class ISubscriptionParserService {
  /// Parses a subscription URL or a raw vless:// link into a list of servers.
  Future<Result<List<VpnServer>>> parseFromInput(String input);
}

@LazySingleton(as: ISubscriptionParserService)
class SubscriptionParserServiceImpl implements ISubscriptionParserService {
  final Talker _talker;
  final SubscriptionFetcher _fetcher;
  final VlessUriParser _vlessUriParser;
  final CustomJsonParser _customJsonParser;

  SubscriptionParserServiceImpl(Talker talker)
      : _talker = talker,
        _fetcher = SubscriptionFetcher(),
        _vlessUriParser = VlessUriParser(talker, XrayConfigBuilder(), CountryCodeExtractor()),
        _customJsonParser = CustomJsonParser(talker, CountryCodeExtractor());

  @override
  Future<Result<List<VpnServer>>> parseFromInput(String input) async {
    try {
      final cleanInput = input.trim();
      final List<VpnServer> servers = [];
      String textToParse = cleanInput;

      // Input is either an http(s) subscription URL or a direct vless:// link.
      final lowerInput = cleanInput.toLowerCase();
      if (lowerInput.startsWith('http://') || lowerInput.startsWith('https://')) {
        _talker.debug('Parser: обнаружен URL, скачиваем данные...');
        textToParse = await _fetcher.fetchText(cleanInput);
      } else if (!_vlessUriParser.isVless(cleanInput)) {
        return const Failure('Неизвестный формат ввода. Ожидается http(s) ссылка или vless://');
      }

      // Detect the content shape and pick the matching parsing strategy.
      if (textToParse.trim().startsWith('[')) {
        // Raw JSON array (custom outbound format).
        _talker.debug('Parser: обнаружен сырой JSON массив');
        servers.addAll(_customJsonParser.parse(textToParse, cleanInput));
      } else if (_vlessUriParser.isVless(textToParse)) {
        // Plain text with one or more vless:// links.
        _talker.debug('Parser: обнаружены прямые ссылки (URI)');
        servers.addAll(_vlessUriParser.parseLines(textToParse, cleanInput));
      } else {
        // Base64-encoded subscription (standard format).
        _talker.debug('Parser: обнаружен Base64, расшифровываем...');
        final decodedText = _fetcher.decodeBase64(textToParse);
        servers.addAll(_vlessUriParser.parseLines(decodedText, cleanInput));
      }

      if (servers.isEmpty) {
        return const Failure('Не удалось найти ни одного поддерживаемого сервера в ответе');
      }

      _talker.info('Parser: успешно распарсено серверов: ${servers.length}');
      return Success(servers);

    } catch (e, st) {
      _talker.handle(e, st, 'Parser: критическая ошибка при обработке');
      return Failure('Не удалось обработать данные: $e');
    }
  }
}
