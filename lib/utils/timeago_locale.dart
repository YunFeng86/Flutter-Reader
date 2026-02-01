import 'package:flutter/widgets.dart';

/// Return a timeago locale code matching the app's locale.
///
/// Note: timeago uses 'zh_CN' for Simplified and 'zh' for Traditional.
String timeagoLocale(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'zh') {
    final script = locale.scriptCode?.toLowerCase();
    if (script == 'hant') return 'zh';
    return 'zh_CN';
  }
  return 'en';
}

