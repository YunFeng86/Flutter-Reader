import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'seed_color_presets.dart';
import '../utils/platform.dart';

class AppTheme {
  // Simple design tokens to keep UI consistent across pages.
  static const double radiusCard = 8;
  static const double radiusField = 12;
  static const double desktopTitleBarHeight = 40;

  static ThemeData light({
    ColorScheme? scheme,
    SeedColorPreset? seedColorPreset,
  }) => _build(
    Brightness.light,
    dynamicScheme: scheme,
    seedColor: (seedColorPreset ?? SeedColorPreset.blue).seedColor, // default
  );

  static ThemeData dark({
    ColorScheme? scheme,
    SeedColorPreset? seedColorPreset,
  }) => _build(
    Brightness.dark,
    dynamicScheme: scheme,
    seedColor: (seedColorPreset ?? SeedColorPreset.blue).seedColor, // default
  );

  static List<String> _fontFallback() {
    if (kIsWeb) {
      // Web: rely on browser/system, but keep a sane CJK preference order.
      return const [
        'PingFang SC',
        'PingFang TC',
        'Microsoft YaHei UI',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'Noto Sans SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'Noto Sans',
        'system-ui',
        'Arial',
        'sans-serif',
      ];
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => const [
        'PingFang SC',
        'PingFang TC',
        'Heiti SC',
        'Heiti TC',
        'Songti SC',
        'Hiragino Sans GB',
        '.SF Pro Text',
        '.SF UI Text',
      ],
      TargetPlatform.windows => const [
        'Microsoft YaHei UI',
        'Microsoft YaHei',
        'SimHei',
        'SimSun',
        'Segoe UI',
        'Noto Sans SC',
        'Noto Sans CJK SC',
        'Arial',
      ],
      TargetPlatform.linux => const [
        'Noto Sans CJK SC',
        'Noto Sans SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'Noto Sans',
        'DejaVu Sans',
      ],
      _ => const [
        // Android/Fuchsia: keep Roboto as primary; provide CJK fallbacks.
        'Roboto',
        'Noto Sans CJK SC',
        'Noto Sans SC',
        'Noto Sans',
        'Droid Sans Fallback',
      ],
    };
  }

  static ThemeData _build(
    Brightness brightness, {
    ColorScheme? dynamicScheme,
    required Color seedColor,
  }) {
    final cs =
        dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      // Desktop-first density, but keep minimum touch targets on mobile.
      visualDensity: isDesktop ? VisualDensity.compact : VisualDensity.standard,
      // Prefer sane CJK fallbacks (notably improves Windows Chinese rendering).
      fontFamilyFallback: _fontFallback(),
    );

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        // Only center titles on iOS/macOS to match platform conventions.
        // Other platforms keep left-aligned titles.
        centerTitle: switch (defaultTargetPlatform) {
          TargetPlatform.iOS || TargetPlatform.macOS => true,
          _ => false,
        },
        surfaceTintColor: Colors.transparent,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      listTileTheme: ListTileThemeData(
        dense: isDesktop,
        visualDensity: isDesktop
            ? VisualDensity.compact
            : VisualDensity.standard,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        selectedTileColor: cs.primaryContainer.withAlpha(153),
        selectedColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        width: 320,
        // shape: default M3 shape is rounded on the right. We keep it default for
        // floating drawers. Fixed sidebars will override this if needed.
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(128),
        isDense: isDesktop,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: base.textTheme.labelLarge?.copyWith(color: cs.onSurface),
        side: BorderSide(color: cs.outlineVariant.withAlpha(204)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(cs.onSurfaceVariant),
          overlayColor: WidgetStatePropertyAll(cs.primary.withAlpha(26)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withAlpha(64),
        selectionHandleColor: cs.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
      ),
    );
  }
}
