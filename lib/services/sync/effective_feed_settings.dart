import '../../models/category.dart';
import '../../models/feed.dart';
import '../settings/app_settings.dart';

class EffectiveFeedSettings {
  const EffectiveFeedSettings({
    required this.syncEnabled,
    required this.filterEnabled,
    required this.filterKeywords,
    required this.syncImages,
    required this.syncWebPages,
    required this.rssUserAgent,
  });

  final bool syncEnabled;
  final bool filterEnabled;
  final String filterKeywords;
  final bool syncImages;
  final bool syncWebPages;
  final String rssUserAgent;

  static EffectiveFeedSettings resolve(
    Feed feed,
    Category? category,
    AppSettings appSettings,
  ) {
    bool pickBool(bool? feedV, bool? catV, bool appV) {
      if (feedV != null) return feedV;
      if (catV != null) return catV;
      return appV;
    }

    String pickKeywords(String? feedV, String? catV, String appV) {
      final f = feedV?.trim();
      if (f != null && f.isNotEmpty) return f;
      final c = catV?.trim();
      if (c != null && c.isNotEmpty) return c;
      return appV;
    }

    return EffectiveFeedSettings(
      syncEnabled: pickBool(
        feed.syncEnabled,
        category?.syncEnabled,
        appSettings.syncEnabled,
      ),
      filterEnabled: pickBool(
        feed.filterEnabled,
        category?.filterEnabled,
        appSettings.filterEnabled,
      ),
      filterKeywords: pickKeywords(
        feed.filterKeywords,
        category?.filterKeywords,
        appSettings.filterKeywords,
      ),
      syncImages: pickBool(
        feed.syncImages,
        category?.syncImages,
        appSettings.syncImages,
      ),
      syncWebPages: pickBool(
        feed.syncWebPages,
        category?.syncWebPages,
        appSettings.syncWebPages,
      ),
      rssUserAgent: appSettings.rssUserAgent,
    );
  }
}
