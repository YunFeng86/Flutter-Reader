import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF1A73E8); // neutral Google-ish blue

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      visualDensity: VisualDensity.compact, // desktop-first information density
    );

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withAlpha(179),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        selectedTileColor: cs.primaryContainer.withAlpha(153),
        selectedColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        width: 320,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(128),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        contentTextStyle:
            base.textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
      ),
    );
  }
}
