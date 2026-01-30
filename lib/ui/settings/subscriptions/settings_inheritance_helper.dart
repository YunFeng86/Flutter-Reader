import '../../../models/feed.dart';
import '../../../models/category.dart';
import '../../../services/settings/app_settings.dart';

class SettingsInheritanceHelper {
  static bool resolveFilterEnabled(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.filterEnabled != null) return feed!.filterEnabled!;
    if (category?.filterEnabled != null) return category!.filterEnabled!;
    return appSettings.filterEnabled;
  }

  static String resolveFilterKeywords(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.filterKeywords != null && feed!.filterKeywords!.isNotEmpty) {
      return feed!.filterKeywords!;
    }
    if (category?.filterKeywords != null &&
        category!.filterKeywords!.isNotEmpty) {
      return category!.filterKeywords!;
    }
    return appSettings.filterKeywords;
  }

  static bool resolveSyncEnabled(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.syncEnabled != null) return feed!.syncEnabled!;
    if (category?.syncEnabled != null) return category!.syncEnabled!;
    return appSettings.syncEnabled;
  }

  static bool resolveSyncImages(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.syncImages != null) return feed!.syncImages!;
    if (category?.syncImages != null) return category!.syncImages!;
    return appSettings.syncImages;
  }

  static bool resolveSyncWebPages(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.syncWebPages != null) return feed!.syncWebPages!;
    if (category?.syncWebPages != null) return category!.syncWebPages!;
    return appSettings.syncWebPages;
  }

  static bool resolveShowAiSummary(
    Feed? feed,
    Category? category,
    AppSettings appSettings,
  ) {
    if (feed?.showAiSummary != null) return feed!.showAiSummary!;
    if (category?.showAiSummary != null) return category!.showAiSummary!;
    return appSettings.showAiSummary;
  }
}
