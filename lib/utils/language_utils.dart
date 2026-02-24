import 'package:flutter/material.dart';

Locale localeFromLanguageTag(String tag) {
  final normalized = normalizeLanguageTag(tag);
  if (normalized.isEmpty) return const Locale('und');
  final parts = normalized.split('-');
  final languageCode = parts.isEmpty ? 'und' : parts.first;
  String? scriptCode;
  String? countryCode;

  if (parts.length >= 2) {
    final p1 = parts[1];
    if (p1.length == 4) {
      scriptCode = p1;
    } else if (p1.length == 2 || p1.length == 3) {
      countryCode = p1;
    }
  }
  if (parts.length >= 3) {
    final p2 = parts[2];
    if (scriptCode == null && p2.length == 4) {
      scriptCode = p2;
    } else if (countryCode == null && (p2.length == 2 || p2.length == 3)) {
      countryCode = p2;
    }
  }

  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}

String normalizeLanguageTag(String tag) {
  final raw = tag.trim();
  if (raw.isEmpty) return '';
  final parts = raw
      .replaceAll('_', '-')
      .split('-')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '';

  final languageCode = parts.first.toLowerCase();
  String? scriptCode;
  String? regionCode;

  for (final p in parts.skip(1)) {
    if (p.length == 4 && scriptCode == null) {
      scriptCode = '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}';
      continue;
    }
    if ((p.length == 2 || p.length == 3) && regionCode == null) {
      regionCode = p.toUpperCase();
      continue;
    }
  }

  final out = <String>[
    languageCode,
    if (scriptCode != null) scriptCode,
    if (regionCode != null) regionCode,
  ];
  return out.join('-');
}

String languageTagForLocale(Locale locale) {
  final languageCode = locale.languageCode.trim().isEmpty
      ? 'und'
      : locale.languageCode.trim();
  final scriptCode = locale.scriptCode?.trim();
  final countryCode = locale.countryCode?.trim();
  final out = <String>[
    languageCode,
    if (scriptCode != null && scriptCode.isNotEmpty) scriptCode,
    if (countryCode != null && countryCode.isNotEmpty) countryCode,
  ];
  return normalizeLanguageTag(out.join('-'));
}

String localizedLanguageNameForTag(Locale uiLocale, String languageTag) {
  final ui = languageTagForLocale(uiLocale);
  final tag = normalizeLanguageTag(languageTag);

  final isUiZh = ui.startsWith('zh');
  final isUiZhHant = ui.startsWith('zh-Hant');

  if (!isUiZh) {
    return switch (tag) {
      'en' => 'English',
      'zh' => 'Chinese',
      'zh-Hant' => 'Chinese (Traditional)',
      'ja' => 'Japanese',
      'ko' => 'Korean',
      'fr' => 'French',
      'de' => 'German',
      'es' => 'Spanish',
      'ru' => 'Russian',
      _ => tag,
    };
  }

  if (isUiZhHant) {
    return switch (tag) {
      'en' => '英文',
      'zh' => '中文',
      'zh-Hant' => '中文（繁體）',
      'ja' => '日文',
      'ko' => '韓文',
      'fr' => '法文',
      'de' => '德文',
      'es' => '西班牙文',
      'ru' => '俄文',
      _ => tag,
    };
  }

  // zh (Simplified)
  return switch (tag) {
    'en' => '英文',
    'zh' => '中文',
    'zh-Hant' => '中文（繁體）',
    'ja' => '日文',
    'ko' => '韩文',
    'fr' => '法文',
    'de' => '德文',
    'es' => '西班牙文',
    'ru' => '俄文',
    _ => tag,
  };
}
