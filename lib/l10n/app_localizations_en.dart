// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Reader';

  @override
  String get notFound => 'Not found';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get english => 'English';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁體中文';

  @override
  String get reader => 'Reader';

  @override
  String get fontSize => 'Font size';

  @override
  String get lineHeight => 'Line height';

  @override
  String get horizontalPadding => 'Horizontal padding';

  @override
  String get storage => 'Storage';

  @override
  String get clearImageCache => 'Clear image cache';

  @override
  String get clearImageCacheSubtitle =>
      'Remove cached images used for offline reading';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get all => 'All';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get refreshAll => 'Refresh all';

  @override
  String get refreshSelected => 'Refresh selected';

  @override
  String get importOpml => 'Import OPML';

  @override
  String get exportOpml => 'Export OPML';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get newCategory => 'New category';

  @override
  String get articles => 'Articles';

  @override
  String get unread => 'Unread';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get fullText => 'Full text';

  @override
  String get readerSettings => 'Reader settings';

  @override
  String get done => 'Done';

  @override
  String get more => 'More';

  @override
  String get showAll => 'Show all';

  @override
  String get unreadOnly => 'Unread only';

  @override
  String get selectAnArticle => 'Select an article';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String unreadCountError(String error) {
    return 'Unread count error: $error';
  }

  @override
  String get refreshed => 'Refreshed';

  @override
  String get refreshedAll => 'Refreshed all';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get rssAtomUrl => 'RSS/Atom URL';

  @override
  String get name => 'Name';

  @override
  String get addedAndSynced => 'Added & synced';

  @override
  String get deleteSubscription => 'Delete subscription';

  @override
  String get deleteSubscriptionConfirmTitle => 'Delete subscription?';

  @override
  String get deleteSubscriptionConfirmContent =>
      'This will delete its cached articles too.';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get refresh => 'Refresh';

  @override
  String get moveToCategory => 'Move to category';

  @override
  String get noFeedsFoundInOpml => 'No feeds found in OPML';

  @override
  String importedFeeds(int count) {
    return 'Imported $count feeds';
  }

  @override
  String get exportedOpml => 'Exported OPML';

  @override
  String fullTextFailed(String error) {
    return 'Full text failed: $error';
  }

  @override
  String get scrollToLoadMore => 'Scroll to load more';

  @override
  String get noArticles => 'No articles';

  @override
  String get noUnreadArticles => 'No unread articles';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Unstar';

  @override
  String get markRead => 'Mark read';

  @override
  String get markUnread => 'Mark unread';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get search => 'Search';

  @override
  String get groupingAndSorting => 'Grouping & Sorting';

  @override
  String get rules => 'Rules';

  @override
  String get services => 'Services';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get about => 'About';
}
