import 'dart:convert';
import 'dart:io';

import 'app_settings.dart';
import '../network/user_agents.dart';
import '../../utils/path_manager.dart';

class AppSettingsStore {
  Future<AppSettings> load() async {
    try {
      var f = await _file();
      if (!await f.exists() && !PathManager.isMigrationComplete) {
        final legacy = await PathManager.legacyAppSettingsFile();
        if (legacy != null) f = legacy;
      }
      final exists = await f.exists();
      if (!exists) return AppSettings.defaults();
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AppSettings.defaults();

      final loaded = AppSettings.fromJson(decoded.cast<String, Object?>());
      final migrated = _migrateIfNeeded(loaded);
      // Only persist when we actually loaded an on-disk settings file.
      if (migrated.webUserAgent != loaded.webUserAgent ||
          migrated.rssUserAgent != loaded.rssUserAgent) {
        try {
          await save(migrated);
        } catch (_) {
          // ignore: best-effort migration
        }
      }
      return migrated;
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings settings) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<File> _file() async {
    return PathManager.appSettingsFile();
  }

  AppSettings _migrateIfNeeded(AppSettings cur) {
    // If user never customized UA (still legacy Windows default), use a
    // platform-aware default to avoid "Windows NT" on non-Windows builds.
    final platformDefault = UserAgents.webForCurrentPlatform();
    if (cur.webUserAgent.trim() == UserAgents.web &&
        platformDefault.trim() != UserAgents.web) {
      return cur.copyWith(webUserAgent: platformDefault);
    }
    return cur;
  }
}
