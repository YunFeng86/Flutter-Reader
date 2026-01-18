import 'package:flutter/material.dart';

class AppSettings {
  static const _Unset _unset = _Unset();

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeTag,
    this.autoMarkRead = true,
    this.autoRefreshMinutes,
  });

  final ThemeMode themeMode;
  // null => follow system language.
  final String? localeTag;

  /// Whether to auto-mark articles as read when opened in the reader.
  final bool autoMarkRead;

  /// Auto-refresh interval in minutes. `null` means disabled.
  final int? autoRefreshMinutes;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Object? localeTag = _unset,
    bool? autoMarkRead,
    Object? autoRefreshMinutes = _unset,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeTag: localeTag == _unset ? this.localeTag : localeTag as String?,
      autoMarkRead: autoMarkRead ?? this.autoMarkRead,
      autoRefreshMinutes: autoRefreshMinutes == _unset
          ? this.autoRefreshMinutes
          : autoRefreshMinutes as int?,
    );
  }

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'localeTag': localeTag,
    'autoMarkRead': autoMarkRead,
    'autoRefreshMinutes': autoRefreshMinutes,
  };

  static AppSettings fromJson(Map<String, Object?> json) {
    final rawThemeMode = json['themeMode'];
    final mode = switch (rawThemeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeTag = json['localeTag'];

    final autoMarkRead = json['autoMarkRead'];
    final autoRefreshMinutes = json['autoRefreshMinutes'];

    return AppSettings(
      themeMode: mode,
      localeTag: localeTag is String && localeTag.trim().isNotEmpty
          ? localeTag
          : null,
      autoMarkRead: autoMarkRead is bool ? autoMarkRead : true,
      autoRefreshMinutes: autoRefreshMinutes is num
          ? autoRefreshMinutes.toInt()
          : null,
    );
  }
}

class _Unset {
  const _Unset();
}
