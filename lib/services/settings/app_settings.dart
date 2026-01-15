import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final raw = json['themeMode'];
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppSettings(themeMode: mode);
  }
}

