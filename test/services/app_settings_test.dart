import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleur/services/settings/app_settings.dart';
import 'package:fleur/theme/seed_color_presets.dart';

void main() {
  test('AppSettings defaults useDynamicColor to true', () {
    const s = AppSettings();
    expect(s.useDynamicColor, isTrue);
  });

  test('AppSettings defaults seedColorPreset to blue', () {
    const s = AppSettings();
    expect(s.seedColorPreset, SeedColorPreset.blue);
  });

  test('AppSettings persists useDynamicColor in JSON', () {
    final s = const AppSettings().copyWith(useDynamicColor: false);
    final json = s.toJson();
    expect(json['useDynamicColor'], isFalse);

    final restored = AppSettings.fromJson(json.cast<String, Object?>());
    expect(restored.useDynamicColor, isFalse);
  });

  test('AppSettings persists seedColorPreset in JSON', () {
    final s = const AppSettings().copyWith(
      seedColorPreset: SeedColorPreset.pink,
    );
    final json = s.toJson();
    expect(json['seedColorPreset'], SeedColorPreset.pink.name);

    final restored = AppSettings.fromJson(json.cast<String, Object?>());
    expect(restored.seedColorPreset, SeedColorPreset.pink);
  });

  test('AppSettings.fromJson defaults missing useDynamicColor to true', () {
    final restored = AppSettings.fromJson(<String, Object?>{
      'themeMode': ThemeMode.dark.name,
    });
    expect(restored.useDynamicColor, isTrue);
  });

  test('AppSettings.fromJson defaults unknown seedColorPreset to blue', () {
    final restored = AppSettings.fromJson(<String, Object?>{
      'seedColorPreset': 'totally_not_a_preset',
    });
    expect(restored.seedColorPreset, SeedColorPreset.blue);
  });

  test('AppSettings persists Miniflux entries limit in JSON', () {
    final s = const AppSettings().copyWith(minifluxEntriesLimit: 800);
    final json = s.toJson();
    expect(json['minifluxEntriesLimit'], 800);

    final restored = AppSettings.fromJson(json.cast<String, Object?>());
    expect(restored.minifluxEntriesLimit, 800);
  });

  test('AppSettings.fromJson defaults missing Miniflux entries limit', () {
    final restored = AppSettings.fromJson(<String, Object?>{});
    expect(restored.minifluxEntriesLimit, 400);
  });

  test('AppSettings allows unlimited Miniflux entries limit (0)', () {
    final s = const AppSettings().copyWith(minifluxEntriesLimit: 0);
    final restored = AppSettings.fromJson(s.toJson().cast<String, Object?>());
    expect(restored.minifluxEntriesLimit, 0);
  });

  test('AppSettings persists Miniflux web fetch mode in JSON', () {
    final s = const AppSettings().copyWith(
      minifluxWebFetchMode: MinifluxWebFetchMode.serverFetchContent,
    );
    final json = s.toJson();
    expect(json['minifluxWebFetchMode'], 'serverFetchContent');

    final restored = AppSettings.fromJson(json.cast<String, Object?>());
    expect(
      restored.minifluxWebFetchMode,
      MinifluxWebFetchMode.serverFetchContent,
    );
  });
}
