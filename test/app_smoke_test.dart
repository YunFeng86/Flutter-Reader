import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fleur/app/app.dart';
import 'package:fleur/app/router.dart';
import 'package:fleur/l10n/app_localizations.dart';
import 'package:fleur/models/article.dart';
import 'package:fleur/models/category.dart';
import 'package:fleur/models/feed.dart';
import 'package:fleur/models/tag.dart';
import 'package:fleur/providers/account_providers.dart';
import 'package:fleur/providers/article_list_controller.dart';
import 'package:fleur/providers/app_settings_providers.dart';
import 'package:fleur/providers/background_sync_providers.dart';
import 'package:fleur/providers/outbox_status_providers.dart';
import 'package:fleur/providers/query_providers.dart';
import 'package:fleur/providers/service_providers.dart';
import 'package:fleur/providers/sync_status_providers.dart';
import 'package:fleur/providers/unread_providers.dart';
import 'package:fleur/services/settings/app_settings.dart';
import 'package:fleur/services/sync/sync_status_reporter.dart';
import 'package:fleur/theme/app_theme.dart';
import 'package:fleur/theme/fleur_theme_extensions.dart';
import 'package:fleur/ui/app_shell.dart';
import 'package:fleur/utils/platform.dart';
import 'package:fleur/widgets/article_list.dart';
import 'package:fleur/widgets/article_list_item.dart';
import 'package:fleur/widgets/global_nav_bar.dart';
import 'package:fleur/widgets/global_nav_rail.dart';
import 'package:fleur/widgets/sidebar.dart';
import 'package:fleur/widgets/sync_status_capsule.dart';

import 'test_utils/critical_workflow_test_support.dart';

GoRouter _buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/article/:id',
        builder: (context, state) => Text(state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}

Widget _buildRuntimeHostHarness({
  required Key scopeKey,
  required GoRouter router,
  required FakeNotificationService notificationService,
  required FakeAppSettingsStore appSettingsStore,
  required Future<void> Function(String? localeTag) preferredLanguageApplier,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      routerProvider.overrideWithValue(router),
      appSettingsStoreProvider.overrideWithValue(appSettingsStore),
      notificationServiceProvider.overrideWithValue(notificationService),
      preferredLanguageApplierProvider.overrideWithValue(
        preferredLanguageApplier,
      ),
    ],
    child: AppRuntimeHost(
      child: ProviderScope(
        key: scopeKey,
        overrides: [
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: child,
      ),
    ),
  );
}

Widget _buildShellHarness() {
  return ProviderScope(
    overrides: [activeAccountProvider.overrideWithValue(buildTestAccount())],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(
        currentUri: Uri(path: '/'),
        child: ColoredBox(color: Colors.transparent),
      ),
    ),
  );
}

Feed _buildFeed({
  int id = 10,
  String title = 'Fleur Feed',
  String url = 'https://example.com/feed.xml',
}) {
  return Feed()
    ..id = id
    ..url = url
    ..title = title
    ..siteUrl = 'https://example.com';
}

Article _buildArticle({
  int id = 42,
  int feedId = 10,
  String title = 'Selected Article',
  bool isRead = false,
  bool isStarred = false,
}) {
  return Article()
    ..id = id
    ..feedId = feedId
    ..link = 'https://example.com/article/$id'
    ..title = title
    ..contentHtml = '<p>Hello world</p>'
    ..publishedAt = DateTime.utc(2026, 1, 2)
    ..updatedAt = DateTime.utc(2026, 1, 2)
    ..isRead = isRead
    ..isStarred = isStarred;
}

class _EmptyArticleListController extends ArticleListController {
  @override
  Future<ArticleListState> build() async {
    return const ArticleListState(items: [], hasMore: false, nextOffset: 0);
  }
}

void main() {
  testWidgets('App builds', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final router = _buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(App), findsOneWidget);
  });

  test('App theme exposes Fleur semantic tokens for desktop and mobile', () {
    debugFleurTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugFleurTargetPlatformOverride = null);

    final desktopTheme = AppTheme.light();
    expect(desktopTheme.fleurSurface.nav, isNotNull);
    expect(desktopTheme.fleurState.selectionTint, isNotNull);
    expect(desktopTheme.fleurReader.maxWidth, greaterThan(0));
    expect(
      desktopTheme.scrollbarTheme.thumbVisibility?.resolve(<WidgetState>{}),
      isTrue,
    );

    debugFleurTargetPlatformOverride = TargetPlatform.android;
    final mobileTheme = AppTheme.light();
    expect(
      mobileTheme.scrollbarTheme.thumbVisibility?.resolve(<WidgetState>{}),
      isFalse,
    );
    expect(
      mobileTheme.navigationBarTheme.height,
      greaterThan(desktopTheme.navigationBarTheme.height ?? 0),
    );
  });

  testWidgets('App shell switches between rail and bottom navigation', (
    tester,
  ) async {
    debugFleurTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugFleurTargetPlatformOverride = null);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_buildShellHarness());
    await tester.pumpAndSettle();

    expect(find.byType(GlobalNavRail), findsOneWidget);
    expect(find.byType(GlobalNavBar), findsNothing);

    tester.view.physicalSize = const Size(640, 900);
    await tester.pumpWidget(_buildShellHarness());
    await tester.pumpAndSettle();

    expect(find.byType(GlobalNavBar), findsOneWidget);
    expect(find.byType(GlobalNavRail), findsNothing);
  });

  testWidgets(
    'App runtime host does not repeat startup side effects on rebuild',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final router = _buildRouter();
      final notificationService = FakeNotificationService();
      final appSettingsStore = FakeAppSettingsStore(
        AppSettings.defaults().copyWith(localeTag: 'en'),
      );
      final localeTags = <String?>[];
      final scheduler = FakeBackgroundSyncScheduler();
      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(router),
          activeAccountProvider.overrideWithValue(buildTestAccount()),
          appSettingsStoreProvider.overrideWithValue(appSettingsStore),
          notificationServiceProvider.overrideWithValue(notificationService),
          outboxPendingCountProvider.overrideWith((ref) async => 0),
          backgroundSyncSchedulerProvider.overrideWithValue(scheduler),
          preferredLanguageApplierProvider.overrideWithValue((localeTag) async {
            localeTags.add(localeTag);
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appSettingsProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AppRuntimeHost(child: App()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(notificationService.actualInitCalls, 1);
      expect(notificationService.actualPermissionCalls, 1);
      expect(notificationService.bindTapHandlerCalls, 1);
      expect(localeTags, ['en']);

      await container
          .read(appSettingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await tester.pump();

      expect(notificationService.actualInitCalls, 1);
      expect(notificationService.actualPermissionCalls, 1);
      expect(notificationService.bindTapHandlerCalls, 1);

      await container
          .read(appSettingsProvider.notifier)
          .setLocaleTag('zh_Hant');
      await tester.pump();

      expect(localeTags, ['en', 'zh_Hant']);
    },
  );

  testWidgets(
    'Global runtime host does not replay app-level side effects across account scope rebuilds',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final router = _buildRouter();
      final notificationService = FakeNotificationService();
      final appSettingsStore = FakeAppSettingsStore(
        AppSettings.defaults().copyWith(localeTag: 'en'),
      );
      final localeTags = <String?>[];

      Future<void> preferredLanguageApplier(String? localeTag) async {
        localeTags.add(localeTag);
      }

      await tester.pumpWidget(
        _buildRuntimeHostHarness(
          scopeKey: const ValueKey<String>('account-a'),
          router: router,
          notificationService: notificationService,
          appSettingsStore: appSettingsStore,
          preferredLanguageApplier: preferredLanguageApplier,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      expect(notificationService.actualInitCalls, 1);
      expect(notificationService.actualPermissionCalls, 1);
      expect(notificationService.bindTapHandlerCalls, 1);
      expect(localeTags, ['en']);

      await tester.pumpWidget(
        _buildRuntimeHostHarness(
          scopeKey: const ValueKey<String>('account-b'),
          router: router,
          notificationService: notificationService,
          appSettingsStore: appSettingsStore,
          preferredLanguageApplier: preferredLanguageApplier,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      expect(notificationService.actualInitCalls, 1);
      expect(notificationService.actualPermissionCalls, 1);
      expect(notificationService.bindTapHandlerCalls, 1);
      expect(localeTags, ['en']);
    },
  );

  testWidgets('Sync status capsule honors reduced-motion preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: SyncStatusCapsuleHost(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SyncStatusCapsuleHost)),
    );
    container
        .read(syncStatusReporterProvider)
        .startTask(label: SyncStatusLabel.syncingFeeds, current: 1, total: 3);
    await tester.pump();

    final capsuleFinder = find.byType(SyncStatusCapsuleHost);
    expect(
      tester
          .widget<AnimatedSlide>(
            find.descendant(
              of: capsuleFinder,
              matching: find.byType(AnimatedSlide),
            ),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: capsuleFinder,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.descendant(
              of: capsuleFinder,
              matching: find.byType(AnimatedSwitcher),
            ),
          )
          .duration,
      Duration.zero,
    );
  });

  testWidgets(
    'Sidebar shows selected feed state and unread badges through shared tokens',
    (tester) async {
      final feed = _buildFeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAccountProvider.overrideWithValue(buildTestAccount()),
            feedsProvider.overrideWith((ref) => Stream.value([feed])),
            categoriesProvider.overrideWith(
              (ref) => Stream.value(<Category>[]),
            ),
            tagsProvider.overrideWith((ref) => Stream.value(<Tag>[])),
            selectedFeedIdProvider.overrideWith((ref) => feed.id),
            allUnreadCountsProvider.overrideWith(
              (ref) => Stream.value(<int?, int>{null: 5, feed.id: 3}),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(
                width: 1200,
                child: Sidebar(onSelectFeed: _noopSelectFeed),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fleur Feed'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      final tileFinder = find.ancestor(
        of: find.text('Fleur Feed'),
        matching: find.byType(ListTile),
      );
      expect(tester.widget<ListTile>(tileFinder).selected, isTrue);
    },
  );

  testWidgets(
    'Article list item reflects selected, unread, and starred states',
    (tester) async {
      final feed = _buildFeed();
      final article = _buildArticle(isRead: false, isStarred: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedsProvider.overrideWith((ref) => Stream.value([feed])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ArticleListItem(article: article, selected: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = AppTheme.light();
      final card = tester.widget<Card>(find.byType(Card));
      final title = tester.widget<Text>(find.text('Selected Article'));

      expect(card.color, theme.fleurSurface.cardSelected);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(find.byIcon(Icons.star), findsOneWidget);
    },
  );

  testWidgets(
    'Article list empty state keeps list surface and unread empty feedback',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStoreProvider.overrideWithValue(
              FakeAppSettingsStore(AppSettings.defaults()),
            ),
            unreadOnlyProvider.overrideWith((ref) => true),
            articleListControllerProvider.overrideWith(
              _EmptyArticleListController.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ArticleList(selectedArticleId: null)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ArticleList));
      final l10n = AppLocalizations.of(element)!;
      final theme = Theme.of(element);
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(l10n.noUnreadArticles),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(find.text(l10n.noUnreadArticles), findsOneWidget);
      expect(container.color, theme.fleurSurface.list);
    },
  );
}

void _noopSelectFeed(int? _) {}
