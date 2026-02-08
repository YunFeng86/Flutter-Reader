import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class UserAgents {
  UserAgents._();

  /// A lightweight UA for RSS/Atom fetches. Some CDNs block the default Dio UA.
  static const String rss = 'Fleur (Dart/Dio)';

  /// Legacy default: modern desktop browser UA to improve server compatibility
  /// for HTML fetch.
  ///
  /// Note: Fleur is a cross-platform app. Hardcoding a Windows UA everywhere
  /// looks suspicious. Prefer [webForCurrentPlatform] for defaults.
  static const String webWindows =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const String webMacos =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const String webLinux =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const String webAndroid =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // iOS browsers are WebKit-based; Safari UA is the least surprising default.
  static const String webIos =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1';

  // Backward-compat alias: older settings/UI used `UserAgents.web`.
  static const String web = webWindows;

  static String webForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => webAndroid,
      TargetPlatform.iOS => webIos,
      TargetPlatform.macOS => webMacos,
      TargetPlatform.linux => webLinux,
      TargetPlatform.windows => webWindows,
      TargetPlatform.fuchsia => webLinux,
    };
  }

  /// Default UA for full web-page fetches on the current runtime platform.
  ///
  /// On Flutter Web, browsers don't allow setting `User-Agent` header; callers
  /// should avoid sending it (we still return a stable string for settings/UI).
  static String webForCurrentPlatform() {
    if (kIsWeb) return webWindows;
    return webForPlatform(defaultTargetPlatform);
  }
}
