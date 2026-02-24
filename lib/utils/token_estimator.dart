int estimateTokens(String text) {
  final sample = text.trim();
  if (sample.isEmpty) return 0;

  final runes = sample.runes.toList(growable: false);
  final total = runes.length;
  if (total == 0) return 0;

  var cjk = 0;
  for (final code in runes) {
    if (_isCjkLike(code)) cjk++;
  }

  // Rough heuristic:
  // - CJK languages are closer to 1 char ~= 1 token
  // - Latin languages: ~4 chars ~= 1 token
  final ratio = cjk / total;
  final base = ratio >= 0.3 ? total : (total / 4).ceil();
  return base + 32; // Small overhead for metadata/system prompts.
}

bool _isCjkLike(int codePoint) {
  // CJK Unified Ideographs
  if (codePoint >= 0x4E00 && codePoint <= 0x9FFF) return true;
  // CJK Unified Ideographs Extension A
  if (codePoint >= 0x3400 && codePoint <= 0x4DBF) return true;
  // Hiragana / Katakana
  if (codePoint >= 0x3040 && codePoint <= 0x30FF) return true;
  // Hangul syllables
  if (codePoint >= 0xAC00 && codePoint <= 0xD7AF) return true;
  return false;
}

