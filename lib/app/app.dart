import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reader/l10n/app_localizations.dart';

import 'router.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  Locale _localeFromTag(String tag) {
    // Accept both BCP-47 ("zh-Hant") and underscore ("zh_Hant") formats.
    final parts =
        tag.replaceAll('_', '-').split('-').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return Locale(tag);

    final languageCode = parts[0];
    String? scriptCode;
    String? countryCode;

    String normalizeScript(String s) =>
        s.length != 4 ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

    if (parts.length >= 2) {
      final p1 = parts[1];
      if (p1.length == 4) {
        scriptCode = normalizeScript(p1);
      } else if (p1.length == 2 || p1.length == 3) {
        countryCode = p1.toUpperCase();
      }
    }

    if (parts.length >= 3) {
      final p2 = parts[2];
      if (scriptCode == null && p2.length == 4) {
        scriptCode = normalizeScript(p2);
      } else if (countryCode == null && (p2.length == 2 || p2.length == 3)) {
        countryCode = p2.toUpperCase();
      }
    }

    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final localeTag = appSettings?.localeTag;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appSettings?.themeMode ?? ThemeMode.system,
      locale: (localeTag == null) ? null : _localeFromTag(localeTag),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
