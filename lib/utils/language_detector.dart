class LanguageDetector {
  LanguageDetector._();

  /// Best-effort language tag detection.
  ///
  /// Returns a BCP-47-ish language tag (e.g. "en", "zh", "ja", "ko", "ru"),
  /// or `null` when uncertain.
  static String? detectLanguageTag(String text) {
    final sample = _sampleText(text, maxRunes: 2000);
    if (sample.isEmpty) return null;

    var cjk = 0;
    var ja = 0;
    var ko = 0;
    var latin = 0;
    var cyrillic = 0;

    for (final code in sample.runes) {
      if (_isCjk(code)) {
        cjk++;
        continue;
      }
      if (_isHiraganaOrKatakana(code)) {
        ja++;
        continue;
      }
      if (_isHangul(code)) {
        ko++;
        continue;
      }
      if (_isCyrillic(code)) {
        cyrillic++;
        continue;
      }
      if (_isLatinLetter(code)) {
        latin++;
        continue;
      }
    }

    // Strong signals first.
    if (ja >= 24 && ja > latin) return 'ja';
    if (ko >= 24 && ko > latin) return 'ko';
    if (cyrillic >= 24 && cyrillic > latin) return 'ru';

    // CJK is ambiguous (zh/ja/ko). If CJK is dominant, assume zh.
    final totalSignal = cjk + ja + ko + latin + cyrillic;
    if (totalSignal <= 0) return null;

    if (cjk >= 48 && cjk >= latin && ja < 12 && ko < 12) return 'zh';

    // Fallback: Latin-heavy content.
    if (latin >= 48 && latin > cjk) return 'en';

    return null;
  }

  static String _sampleText(String text, {required int maxRunes}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final runes = trimmed.runes.toList(growable: false);
    if (runes.length <= maxRunes) return trimmed;
    return String.fromCharCodes(runes.take(maxRunes));
  }

  static bool _isCjk(int codePoint) {
    return (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0x3400 && codePoint <= 0x4DBF);
  }

  static bool _isHiraganaOrKatakana(int codePoint) =>
      codePoint >= 0x3040 && codePoint <= 0x30FF;

  static bool _isHangul(int codePoint) =>
      codePoint >= 0xAC00 && codePoint <= 0xD7AF;

  static bool _isCyrillic(int codePoint) =>
      codePoint >= 0x0400 && codePoint <= 0x04FF;

  static bool _isLatinLetter(int codePoint) {
    if (codePoint >= 0x41 && codePoint <= 0x5A) return true;
    if (codePoint >= 0x61 && codePoint <= 0x7A) return true;
    return false;
  }
}

