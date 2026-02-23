// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fleur';

  @override
  String get notFound => 'Not found';

  @override
  String get openFailedGeneral =>
      'Couldn\'t open this location. Check permissions and try again.';

  @override
  String get macosMenuLanguageRestartHint =>
      'Menu bar language may require restarting the app to fully apply.';

  @override
  String pathNotFound(Object path) {
    return 'Path does not exist: $path';
  }

  @override
  String get settings => 'Settings';

  @override
  String get feeds => 'Feeds';

  @override
  String get saved => 'Saved';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get dynamicColor => 'Dynamic colors';

  @override
  String get dynamicColorSubtitle => 'Use Material You colors (Android 12+)';

  @override
  String get seedColorPreset => 'Theme colors';

  @override
  String get seedColorPresetSubtitle =>
      'Used when dynamic colors are off/unavailable';

  @override
  String get seedColorBlue => 'Blue';

  @override
  String get seedColorGreen => 'Green';

  @override
  String get seedColorPurple => 'Purple';

  @override
  String get seedColorOrange => 'Orange';

  @override
  String get seedColorPink => 'Pink';

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
  String get tags => 'Tags';

  @override
  String get all => 'All Articles';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get refreshAll => 'Refresh all';

  @override
  String get refreshSelected => 'Refresh selected';

  @override
  String get importOpml => 'Import OPML';

  @override
  String get opmlParseFailed => 'Invalid OPML file';

  @override
  String get exportOpml => 'Export OPML';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String get creatingCategory => 'Creating category...';

  @override
  String get feverAddSubscriptionNotSupported =>
      'Fever accounts don\'t support adding subscriptions. Please manage subscriptions on the server.';

  @override
  String get newCategory => 'New category';

  @override
  String get articles => 'Articles';

  @override
  String get unread => 'Unread';

  @override
  String get refreshConcurrency => 'Refresh Concurrency';

  @override
  String refreshingProgress(int current, int total) {
    return 'Refreshing $current/$total...';
  }

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get fullText => 'Full text';

  @override
  String get fullTextRetry => 'Full text failed. Retry';

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
  String get feedOrWebsiteUrl => 'Feed / website URL';

  @override
  String get discoveringFeeds => 'Discovering feeds...';

  @override
  String get addingSubscription => 'Adding subscription...';

  @override
  String get selectFeed => 'Select a feed';

  @override
  String get noFeedsFound => 'No feeds found';

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
  String get makeAvailableOffline => 'Make available offline';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get deleteCategoryConfirmTitle => 'Delete category?';

  @override
  String get deleteCategoryConfirmContent =>
      'Feeds in this category will be moved to Uncategorized.';

  @override
  String get deleteTagConfirmTitle => 'Delete tag?';

  @override
  String get deleteTagConfirmContent =>
      'This will remove it from all articles.';

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
  String get starred => 'Starred';

  @override
  String get readLater => 'Read Later';

  @override
  String get markRead => 'Mark read';

  @override
  String get markUnread => 'Mark unread';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get copyLink => 'Copy link';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get share => 'Share';

  @override
  String get autoMarkRead => 'Auto-mark as read when opened';

  @override
  String get search => 'Search';

  @override
  String get searchInContent => 'Search in content';

  @override
  String get groupingAndSorting => 'Grouping & Sorting';

  @override
  String get groupBy => 'Group by';

  @override
  String get groupNone => 'None';

  @override
  String get groupByDay => 'Day';

  @override
  String get sortOrder => 'Sort order';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get enabled => 'Enabled';

  @override
  String get rename => 'Rename';

  @override
  String get edit => 'Edit';

  @override
  String get nameAlreadyExists => 'Name already exists';

  @override
  String get lastChecked => 'Last checked';

  @override
  String get lastSynced => 'Last synced';

  @override
  String get never => 'Never';

  @override
  String get cleanupReadArticles => 'Cleanup read articles';

  @override
  String get cleanupNow => 'Run cleanup';

  @override
  String cachingArticles(int count) {
    return 'Caching $count articles...';
  }

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get newTag => 'New Tag';

  @override
  String get tagColor => 'Tag color';

  @override
  String get autoColor => 'Auto';

  @override
  String get tagsLoadingError => 'Error loading tags';

  @override
  String cleanedArticles(int count) {
    return 'Cleaned $count articles';
  }

  @override
  String days(int days) {
    return '$days days';
  }

  @override
  String get services => 'Services';

  @override
  String get account => 'Account';

  @override
  String get local => 'Local';

  @override
  String get miniflux => 'Miniflux';

  @override
  String get fever => 'Fever';

  @override
  String get addLocal => 'Add Local';

  @override
  String get addLocalAccount => 'Add Local Account';

  @override
  String get addMiniflux => 'Add Miniflux';

  @override
  String get addFever => 'Add Fever';

  @override
  String get minifluxStrategy => 'Miniflux strategy';

  @override
  String get minifluxStrategySubtitle =>
      'Controls how much data is fetched/prefetched during sync.';

  @override
  String get minifluxEntriesLimit => 'Entries per sync';

  @override
  String get minifluxWebFetchMode => 'Web page fetching';

  @override
  String get minifluxWebFetchModeSubtitle =>
      'When \"Download Web Pages during Sync\" is enabled.';

  @override
  String get minifluxWebFetchModeClient => 'Client (Readability)';

  @override
  String get minifluxWebFetchModeServer => 'Server (Miniflux fetch-content)';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get fieldName => 'Name';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get minifluxBaseUrlHint => 'https://miniflux.example.com';

  @override
  String get feverBaseUrlHint => 'https://example.com/fever/';

  @override
  String get apiToken => 'API Token';

  @override
  String get apiKey => 'API Key';

  @override
  String get authenticationMethod => 'Authentication method';

  @override
  String get usernamePassword => 'Username & password';

  @override
  String get minifluxAuthHint =>
      'Use an API token (recommended) or username/password.';

  @override
  String get feverAuthHint =>
      'Use an API key (recommended) or username/password.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get missingRequiredFields => 'Missing required fields';

  @override
  String get invalidBaseUrl => 'Invalid base URL';

  @override
  String get onlySupportedInLocalAccount => 'Only supported in Local account';

  @override
  String get autoRefresh => 'Auto refresh';

  @override
  String get autoRefreshSubtitle => 'Automatically refresh feeds in background';

  @override
  String get off => 'Off';

  @override
  String everyMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get about => 'About';

  @override
  String get dataDirectory => 'Data directory';

  @override
  String get copyPath => 'Copy path';

  @override
  String get openFolder => 'Open folder';

  @override
  String get logDirectory => 'Log directory';

  @override
  String get openLog => 'Open log';

  @override
  String get openLogFolder => 'Open log folder';

  @override
  String get exportLogs => 'Export logs';

  @override
  String get exportedLogs => 'Logs exported';

  @override
  String get noLogsFound => 'No log files found';

  @override
  String get keyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build number';

  @override
  String get openSourceLicense => 'Open source license';

  @override
  String get viewLicense => 'View license';

  @override
  String get thirdPartyLicenses => 'Third-party licenses';

  @override
  String get viewThirdPartyLicenses => 'View all open source licenses';

  @override
  String get filter => 'Filter';

  @override
  String get filterKeywordsHint =>
      'Add reserved keywords (separate with \";\", connect multiple with \"+\")';

  @override
  String get sync => 'Sync';

  @override
  String get enableSync => 'Enable Sync';

  @override
  String get enableFilter => 'Enable Filter';

  @override
  String get syncAlwaysEnabled =>
      'Always enabled (Settings - Sync - Sync Mode is \"All\")';

  @override
  String get syncImages => 'Download Images during Sync';

  @override
  String get syncWebPages => 'Download Web Pages during Sync';

  @override
  String get syncStatusSyncing => 'Syncing';

  @override
  String get syncStatusSyncingFeeds => 'Syncing feeds';

  @override
  String get syncStatusSyncingSubscriptions => 'Syncing subscriptions';

  @override
  String get syncStatusSyncingUnreadArticles => 'Syncing unread articles';

  @override
  String get syncStatusUploadingChanges => 'Uploading changes';

  @override
  String get syncStatusCompleted => 'Sync complete';

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get showAiSummary => 'Show Summary';

  @override
  String get summary => 'Summary';

  @override
  String get showImageTitle => 'Show Image Title';

  @override
  String get showAttachedImage => 'Show Attached Image';

  @override
  String get htmlDecoding => 'HTML Decoding';

  @override
  String get mobilizer => 'Mobilizer';

  @override
  String get inherit => 'Inherit';

  @override
  String get auto => 'Auto';

  @override
  String get autoOn => 'Auto (On)';

  @override
  String get autoOff => 'Off';

  @override
  String get defaultValue => 'Default Value';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get rssUserAgent => 'RSS/Atom User-Agent';

  @override
  String get webUserAgent => 'Web Page User-Agent';

  @override
  String get userAgentRssHint => 'Used when fetching RSS/Atom feeds.';

  @override
  String get userAgentWebHint =>
      'Used when fetching full web pages (Readability).';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get notificationNewArticleTitle => 'New Article';

  @override
  String get notificationNewArticlesTitle => 'New Articles';

  @override
  String notificationNewArticlesBody(int count) {
    return 'Found $count new articles';
  }

  @override
  String get notificationNewArticlesChannelName => 'New Articles';

  @override
  String get notificationNewArticlesChannelDescription =>
      'Notifications for new articles found during sync';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';

  @override
  String get translationAndAiServices => 'Translation & AI';

  @override
  String get translation => 'Translation';

  @override
  String get translationProvider => 'Translation provider';

  @override
  String get aiServices => 'AI services';

  @override
  String get addAiService => 'Add AI service';

  @override
  String get aiService => 'AI service';
}
