import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeTag,
  });

  final ThemeMode themeMode;
  // null => follow system language.
  final String? localeTag;

  AppSettings copyWith({ThemeMode? themeMode, String? localeTag}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeTag: localeTag,
    );
  }

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'localeTag': localeTag,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final raw = json['themeMode'];
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final localeTag = json['localeTag'];
    return AppSettings(
      themeMode: mode,
      localeTag: localeTag is String && localeTag.trim().isNotEmpty ? localeTag : null,
    );
  }
}
