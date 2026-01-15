import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import '../theme/app_theme.dart';
import '../providers/app_settings_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Reader',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appSettings?.themeMode ?? ThemeMode.system,
      routerConfig: router,
    );
  }
}
