import 'dart:convert';

import 'package:crypto/crypto.dart';

class PromptTemplate {
  PromptTemplate._();

  static const String varContent = 'content';
  static const String varLanguage = 'language';
  static const String varTitle = 'title';

  static String token(String name) => '{{${name.trim()}}}';

  static String render(
    String template, {
    required Map<String, String> variables,
  }) {
    var out = template;
    for (final entry in variables.entries) {
      out = out.replaceAll(token(entry.key), entry.value);
    }
    return out;
  }

  static String hash(String template) {
    final bytes = utf8.encode(template.trim());
    final digest = sha256.convert(bytes);
    // First 128 bits is plenty for cache keys.
    return digest.toString().substring(0, 32);
  }
}

