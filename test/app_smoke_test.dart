import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fleur/app/app.dart';
import 'package:fleur/app/router.dart';
import 'package:fleur/providers/account_providers.dart';
import 'package:fleur/providers/app_settings_providers.dart';
import 'package:fleur/providers/background_sync_providers.dart';
import 'package:fleur/providers/outbox_status_providers.dart';
import 'package:fleur/providers/service_providers.dart';
import 'package:fleur/services/settings/app_settings.dart';

import 'test_utils/critical_workflow_test_support.dart';

GoRouter _buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
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
      preferredLanguageApplierProvider.overrideWithValue(preferredLanguageApplier),
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

  testWidgets('App runtime host does not repeat startup side effects on rebuild', (
    tester,
  ) async {
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

    await container.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pump();

    expect(notificationService.actualInitCalls, 1);
    expect(notificationService.actualPermissionCalls, 1);
    expect(notificationService.bindTapHandlerCalls, 1);

    await container.read(appSettingsProvider.notifier).setLocaleTag('zh_Hant');
    await tester.pump();

    expect(localeTags, ['en', 'zh_Hant']);
  });

  testWidgets('Global runtime host does not replay app-level side effects across account scope rebuilds', (
    tester,
  ) async {
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
  });
}
