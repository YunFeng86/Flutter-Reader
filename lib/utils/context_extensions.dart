import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void showSnack(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? foregroundColor,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) {
      // In debug builds, help spot "silent" SnackBar failures caused by an
      // unexpected BuildContext scope (e.g. missing ScaffoldMessenger).
      assert(() {
        debugPrint(
          'SnackBar blocked: no ScaffoldMessenger in context for: $message',
        );
        return true;
      }());
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: foregroundColor == null
                ? null
                : TextStyle(color: foregroundColor),
          ),
          duration: duration,
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }

  void showSuccess(String message) {
    final theme = Theme.of(this);
    showSnack(
      message,
      backgroundColor: theme.colorScheme.tertiaryContainer,
      foregroundColor: theme.colorScheme.onTertiaryContainer,
    );
  }

  void showErrorMessage(String message) {
    final theme = Theme.of(this);
    showSnack(
      message,
      backgroundColor: theme.colorScheme.errorContainer,
      foregroundColor: theme.colorScheme.onErrorContainer,
    );
  }

  void showError(Object error) => showErrorMessage(error.toString());
}
