import 'package:flutter/material.dart';

const String unknownLanguageTag = 'unknown';

class LanguageIdentity {
  const LanguageIdentity({
    required this.rawTag,
    required this.normalizedTag,
    required this.compareKey,
    required this.displayKey,
  });

  factory LanguageIdentity.fromTag(String? tag) {
    final raw = (tag ?? '').trim();
    final normalized = normalizeLanguageTag(raw);
    final compareKey = canonicalLanguageIdentityTag(normalized);
    return LanguageIdentity(
      rawTag: raw,
      normalizedTag: normalized,
      compareKey: compareKey,
      displayKey: compareKey,
    );
  }

  final String rawTag;
  final String normalizedTag;
  final String compareKey;
  final String displayKey;

  bool get isKnown => compareKey != unknownLanguageTag;
}

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
    ...?(scriptCode == null ? null : [scriptCode]),
    ...?(regionCode == null ? null : [regionCode]),
  ];
  return out.join('-');
}

String canonicalLanguageIdentityTag(String tag) {
  final normalized = normalizeLanguageTag(tag);
  if (normalized.isEmpty || normalized == 'und') return unknownLanguageTag;

  final locale = localeFromLanguageTag(normalized);
  final languageCode = locale.languageCode.trim().toLowerCase();
  final scriptCode = locale.scriptCode?.trim();
  final countryCode = locale.countryCode?.trim().toUpperCase();

  if (languageCode.isEmpty || languageCode == 'und') return unknownLanguageTag;

  if (languageCode == 'zh') {
    if (scriptCode == 'Hant' ||
        countryCode == 'TW' ||
        countryCode == 'HK' ||
        countryCode == 'MO') {
      return 'zh-Hant';
    }
    return 'zh-Hans';
  }

  return languageCode;
}

String normalizeAppLocaleTag(String tag) {
  final normalized = normalizeLanguageTag(tag);
  if (normalized.isEmpty) return '';
  return switch (canonicalLanguageIdentityTag(normalized)) {
    'zh-Hant' => 'zh-Hant',
    'zh-Hans' => 'zh',
    'en' => 'en',
    _ => normalized,
  };
}

String runtimeLanguageTagForAppLocale(
  String? appLocaleTag,
  Locale systemLocale,
) {
  final raw = (appLocaleTag ?? '').trim();
  if (raw.isNotEmpty) return normalizeLanguageTag(raw);
  return languageTagForLocale(systemLocale);
}

String defaultTargetLanguageTagForAppLocale(
  String? appLocaleTag,
  Locale systemLocale,
) {
  final compareKey = canonicalLanguageIdentityTag(
    runtimeLanguageTagForAppLocale(appLocaleTag, systemLocale),
  );
  return compareKey == unknownLanguageTag ? 'en' : compareKey;
}

Locale supportedAppLocaleForTag(String? languageTag) {
  final compareKey = canonicalLanguageIdentityTag(languageTag ?? '');
  return switch (compareKey) {
    'zh-Hant' => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
    ),
    'zh-Hans' => const Locale('zh'),
    _ => const Locale('en'),
  };
}

bool isKnownLanguageIdentityTag(String? tag) {
  if (tag == null || tag.trim().isEmpty) return false;
  return canonicalLanguageIdentityTag(tag) != unknownLanguageTag;
}

String? canonicalKnownLanguageTagOrNull(String? tag) {
  final compareKey = canonicalLanguageIdentityTag(tag ?? '');
  if (compareKey == unknownLanguageTag) return null;
  return compareKey;
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
  final ui = languageTagForLocale(
    supportedAppLocaleForTag(languageTagForLocale(uiLocale)),
  );
  final tag = canonicalLanguageIdentityTag(languageTag);

  final isUiZh = ui.startsWith('zh');
  final isUiZhHant = ui.startsWith('zh-Hant');

  if (!isUiZh) {
    return switch (tag) {
      'en' => 'English',
      'zh-Hans' => 'Chinese (Simplified)',
      'zh-Hant' => 'Chinese (Traditional)',
      'zh' => 'Chinese',
      'ja' => 'Japanese',
      'ko' => 'Korean',
      'fr' => 'French',
      'de' => 'German',
      'es' => 'Spanish',
      'ru' => 'Russian',
      unknownLanguageTag => normalizeLanguageTag(languageTag),
      _ =>
        normalizeLanguageTag(languageTag).isEmpty
            ? languageTag
            : normalizeLanguageTag(languageTag),
    };
  }

  if (isUiZhHant) {
    return switch (tag) {
      'en' => '英文',
      'zh-Hans' => '简体中文',
      'zh-Hant' => '繁體中文',
      'zh' => '中文',
      'ja' => '日文',
      'ko' => '韓文',
      'fr' => '法文',
      'de' => '德文',
      'es' => '西班牙文',
      'ru' => '俄文',
      unknownLanguageTag => normalizeLanguageTag(languageTag),
      _ =>
        normalizeLanguageTag(languageTag).isEmpty
            ? languageTag
            : normalizeLanguageTag(languageTag),
    };
  }

  // zh (Simplified)
  return switch (tag) {
    'en' => '英文',
    'zh-Hans' => '简体中文',
    'zh-Hant' => '繁體中文',
    'zh' => '中文',
    'ja' => '日文',
    'ko' => '韩文',
    'fr' => '法文',
    'de' => '德文',
    'es' => '西班牙文',
    'ru' => '俄文',
    unknownLanguageTag => normalizeLanguageTag(languageTag),
    _ =>
      normalizeLanguageTag(languageTag).isEmpty
          ? languageTag
          : normalizeLanguageTag(languageTag),
  };
}
