import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings/app_settings.dart';
import '../services/settings/app_settings_store.dart';

final appSettingsStoreProvider = Provider<AppSettingsStore>((ref) {
  return AppSettingsStore();
});

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(appSettingsStoreProvider).load();
  }

  Future<void> save(AppSettings next) async {
    state = AsyncValue.data(next);
    await ref.read(appSettingsStoreProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final cur = state.valueOrNull ?? const AppSettings();
    await save(cur.copyWith(themeMode: mode));
  }

  Future<void> setLocaleTag(String? localeTag) async {
    final cur = state.valueOrNull ?? const AppSettings();
    await save(cur.copyWith(localeTag: localeTag));
  }

  Future<void> setLayoutMode(AppLayoutMode layoutMode) async {
    final cur = state.valueOrNull ?? const AppSettings();
    await save(cur.copyWith(layoutMode: layoutMode));
  }

  Future<void> setAutoMarkRead(bool value) async {
    final cur = state.valueOrNull ?? const AppSettings();
    await save(cur.copyWith(autoMarkRead: value));
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
