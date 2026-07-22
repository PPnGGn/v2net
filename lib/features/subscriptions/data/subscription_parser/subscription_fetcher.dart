import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionResponse {
  final String body;
  final String? profileTitle;
  SubscriptionResponse({required this.body, this.profileTitle});
}

class SubscriptionFetcher {
  Future<String> fetchText(String url) async => (await fetch(url)).body;

  Future<SubscriptionResponse> fetch(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw Exception('Timeout: server did not respond in 10 seconds'),
        );
    if (response.statusCode != 200) {
      throw Exception('HTTP error: ${response.statusCode}');
    }
    return SubscriptionResponse(
      body: response.body,
      profileTitle: _decodeProfileTitle(response.headers['profile-title']),
    );
  }

  String? _decodeProfileTitle(String? header) {
    if (header == null || header.isEmpty) return null;
    final raw = header.startsWith('base64:')
        ? header.substring('base64:'.length)
        : header;
    try {
      final decoded = decodeBase64(raw).trim();
      return decoded.isNotEmpty ? decoded : null;
    } catch (_) {
      return header.trim().isNotEmpty ? header.trim() : null;
    }
  }

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
