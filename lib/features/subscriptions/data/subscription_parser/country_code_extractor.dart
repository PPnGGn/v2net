class CountryCodeExtractor {
  // Extracts a 2-letter country code from a pair of regional-indicator flag emoji.
  String extract(String remarks) {
    final runes = remarks.runes.toList();
    if (runes.length >= 2 &&
        runes[0] >= 0x1F1E6 &&
        runes[0] <= 0x1F1FF &&
        runes[1] >= 0x1F1E6 &&
        runes[1] <= 0x1F1FF) {
      final code1 = runes[0] - 0x1F1A5;
      final code2 = runes[1] - 0x1F1A5;
      if (code1 >= 0x41 && code1 <= 0x5A && code2 >= 0x41 && code2 <= 0x5A) {
        return '${String.fromCharCode(code1)}${String.fromCharCode(code2)}';
      }
    }
    return 'XX';
  }
}
