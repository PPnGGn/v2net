import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionFetcher {
  // Downloads subscription content from a URL, with a 10s timeout.
  Future<String> fetchText(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Таймаут: сервер не ответил за 10 секунд'),
    );
    if (response.statusCode != 200) {
      throw Exception('HTTP ошибка: ${response.statusCode}');
    }
    return response.body;
  }

  // Decodes a (possibly unpadded, standard or URL-safe) Base64 string.
  String decodeBase64(String str) {
    String normalized = str.replaceAll(RegExp(r'\s+'), '');
    final padding = normalized.length % 4;
    if (padding != 0) {
      normalized += '=' * (4 - padding);
    }
    try {
      return utf8.decode(base64Decode(normalized));
    } catch (_) {
      return utf8.decode(base64Url.decode(normalized));
    }
  }
}
