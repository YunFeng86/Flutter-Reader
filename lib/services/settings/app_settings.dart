import 'package:flutter/material.dart';

/// Supported app layout modes.
///
/// - auto: decide 1/2/3-column based on screen width (progressive design)
/// - oneColumn/twoColumn/threeColumn: user-enforced layout, with a narrow-width
///   fallback to keep the UI usable on very small windows.
enum AppLayoutMode { auto, oneColumn, twoColumn, threeColumn }

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeTag,
    this.layoutMode = AppLayoutMode.auto,
    this.autoMarkRead = true,
  });

  final ThemeMode themeMode;
  // null => follow system language.
  final String? localeTag;

  /// Layout mode preference for desktop/tablet.
  final AppLayoutMode layoutMode;

  /// Whether to auto-mark articles as read when opened in the reader.
  final bool autoMarkRead;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeTag,
    AppLayoutMode? layoutMode,
    bool? autoMarkRead,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeTag: localeTag,
      layoutMode: layoutMode ?? this.layoutMode,
      autoMarkRead: autoMarkRead ?? this.autoMarkRead,
    );
  }

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'localeTag': localeTag,
    'layoutMode': layoutMode.name,
    'autoMarkRead': autoMarkRead,
  };

  static AppSettings fromJson(Map<String, Object?> json) {
    final rawThemeMode = json['themeMode'];
    final mode = switch (rawThemeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeTag = json['localeTag'];

    final rawLayout = json['layoutMode'];
    final layoutMode = switch (rawLayout) {
      'oneColumn' => AppLayoutMode.oneColumn,
      'twoColumn' => AppLayoutMode.twoColumn,
      'threeColumn' => AppLayoutMode.threeColumn,
      _ => AppLayoutMode.auto,
    };

    final autoMarkRead = json['autoMarkRead'];

    return AppSettings(
      themeMode: mode,
      localeTag: localeTag is String && localeTag.trim().isNotEmpty
          ? localeTag
          : null,
      layoutMode: layoutMode,
      autoMarkRead: autoMarkRead is bool ? autoMarkRead : true,
    );
  }
}
