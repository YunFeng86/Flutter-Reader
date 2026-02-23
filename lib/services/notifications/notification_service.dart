import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fleur/l10n/app_localizations.dart';

import '../../models/article.dart';

sealed class NotificationTap {
  const NotificationTap();
}

class NotificationTapHome extends NotificationTap {
  const NotificationTapHome();
}

class NotificationTapArticle extends NotificationTap {
  const NotificationTapArticle(this.articleId);

  final int articleId;
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;
  bool _permissionRequested = false;

  void Function(NotificationTap tap)? _onTap;
  NotificationTap? _pendingTap;

  void setOnNotificationTap(void Function(NotificationTap tap) handler) {
    _onTap = handler;
    final pending = _pendingTap;
    if (pending != null) {
      _pendingTap = null;
      handler(pending);
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initFuture ??= _initOnce();
    return _initFuture!;
  }

  Future<void> _initOnce() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const macOsSettings = DarwinInitializationSettings();
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macOsSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Handle cold-start (app launched by tapping a notification).
      try {
        final launchDetails = await _notificationsPlugin
            .getNotificationAppLaunchDetails();
        final didLaunch = launchDetails?.didNotificationLaunchApp ?? false;
        final response = launchDetails?.notificationResponse;
        if (didLaunch && response != null) {
          _handleNotificationResponse(response);
        }
      } catch (_) {
        // ignore: best-effort
      }

      _initialized = true;
    } on MissingPluginException {
      _initFuture = null;
    } catch (e) {
      if (e is Error && e.runtimeType.toString() == 'LateInitializationError') {
        _initFuture = null;
        return;
      }
      rethrow;
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await init();
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> requestPermissions() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    try {
      await ensureInitialized();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final android = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
      }

      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final macos = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
    } on MissingPluginException {
      _permissionRequested = false;
    } catch (_) {
      // ignore: best-effort; do not break app startup
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = (response.payload ?? '').trim();
    if (payload.isEmpty) return;

    if (payload == 'home') {
      _dispatchTap(const NotificationTapHome());
      return;
    }

    if (payload.startsWith('article:')) {
      final id = int.tryParse(payload.substring('article:'.length).trim());
      if (id == null || id <= 0) return;
      _dispatchTap(NotificationTapArticle(id));
      return;
    }

    final id = int.tryParse(payload);
    if (id == null || id <= 0) return;
    _dispatchTap(NotificationTapArticle(id));
  }

  void _dispatchTap(NotificationTap tap) {
    final handler = _onTap;
    if (handler == null) {
      _pendingTap = tap;
      return;
    }
    handler(tap);
  }

  Locale _normalizeLocale(Locale locale) {
    if (locale.languageCode != 'zh') return locale;

    // Flutter gen-l10n only selects zh_Hant when scriptCode == 'Hant'.
    // Many platforms report zh-TW/HK/MO without scriptCode, so we normalize
    // those regions to Traditional Chinese.
    if (locale.scriptCode == null) {
      final cc = (locale.countryCode ?? '').toUpperCase();
      if (cc == 'TW' || cc == 'HK' || cc == 'MO') {
        return Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: cc,
        );
      }
    }
    return locale;
  }

  Locale _localeFromTag(String tag) {
    // Accept both BCP-47 ("zh-Hant") and underscore ("zh_Hant") formats.
    final parts = tag
        .replaceAll('_', '-')
        .split('-')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return Locale(tag);

    final languageCode = parts[0];
    String? scriptCode;
    String? countryCode;

    String normalizeScript(String s) => s.length != 4
        ? s
        : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

    if (parts.length >= 2) {
      final p1 = parts[1];
      if (p1.length == 4) {
        scriptCode = normalizeScript(p1);
      } else if (p1.length == 2 || p1.length == 3) {
        countryCode = p1.toUpperCase();
      }
    }

    if (parts.length >= 3) {
      final p2 = parts[2];
      if (scriptCode == null && p2.length == 4) {
        scriptCode = normalizeScript(p2);
      } else if (countryCode == null && (p2.length == 2 || p2.length == 3)) {
        countryCode = p2.toUpperCase();
      }
    }

    if (languageCode == 'zh' && scriptCode == null) {
      final cc = (countryCode ?? '').toUpperCase();
      if (cc == 'TW' || cc == 'HK' || cc == 'MO') {
        scriptCode = 'Hant';
      }
    }

    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }

  AppLocalizations _l10nForLocale(Locale locale) {
    locale = _normalizeLocale(locale);
    if (!AppLocalizations.delegate.isSupported(locale)) {
      return lookupAppLocalizations(const Locale('en'));
    }
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      // Fallback to English when locale parsing yields an unsupported combo.
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  Future<void> showNewArticlesSummaryNotification(
    int count, {
    String? localeTag,
  }) async {
    if (count <= 0) return;

    final locale = _normalizeLocale(
      (localeTag == null || localeTag.trim().isEmpty)
          ? PlatformDispatcher.instance.locale
          : _localeFromTag(localeTag),
    );
    final l10n = _l10nForLocale(locale);

    final androidDetails = AndroidNotificationDetails(
      'new_articles_channel',
      l10n.notificationNewArticlesChannelName,
      channelDescription: l10n.notificationNewArticlesChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const macOsDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOsDetails,
      linux: linuxDetails,
    );

    await ensureInitialized();
    await _notificationsPlugin.show(
      0, // Fixed ID for summary
      l10n.notificationNewArticlesTitle,
      l10n.notificationNewArticlesBody(count),
      details,
      payload: 'home',
    );
  }

  Future<void> showNewArticlesNotification(
    List<Article> newArticles, {
    String? localeTag,
  }) async {
    if (newArticles.isEmpty) return;

    final locale = _normalizeLocale(
      (localeTag == null || localeTag.trim().isEmpty)
          ? PlatformDispatcher.instance.locale
          : _localeFromTag(localeTag),
    );
    final l10n = _l10nForLocale(locale);

    final androidDetails = AndroidNotificationDetails(
      'new_articles_channel',
      l10n.notificationNewArticlesChannelName,
      channelDescription: l10n.notificationNewArticlesChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const macOsDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOsDetails,
      linux: linuxDetails,
    );

    await ensureInitialized();

    if (newArticles.length == 1) {
      final article = newArticles.first;
      await _notificationsPlugin.show(
        article.id, // Use article ID as notification ID
        l10n.notificationNewArticleTitle,
        article.title,
        details,
        payload: article.id.toString(),
      );
    } else {
      await _notificationsPlugin.show(
        0, // Fixed ID for summary
        l10n.notificationNewArticlesTitle,
        l10n.notificationNewArticlesBody(newArticles.length),
        details,
        payload: 'home',
      );
    }
  }
}
