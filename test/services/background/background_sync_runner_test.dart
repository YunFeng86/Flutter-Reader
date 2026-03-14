import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fleur/models/feed.dart';
import 'package:fleur/services/accounts/account.dart';
import 'package:fleur/services/accounts/account_store.dart';
import 'package:fleur/services/background/background_sync_service.dart';
import 'package:fleur/services/settings/app_settings.dart';
import 'package:fleur/services/settings/app_settings_store.dart';
import 'package:fleur/services/sync/outbox/outbox_store.dart';
import 'package:fleur/utils/platform.dart';

import '../../test_utils/critical_workflow_test_support.dart';

Future<T> _runWithoutMutex<T>(String key, Future<T> Function() op) => op();

class _FakeIsar extends Fake implements Isar {
  var closeCalls = 0;

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    closeCalls++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AccountsState buildAccountsState() {
    final account = buildTestAccount(
      id: 'remote-account',
      type: AccountType.miniflux,
      baseUrl: 'https://example.com',
      isPrimary: true,
    );
    return AccountsState(
      version: AccountStore.currentVersion,
      activeAccountId: account.id,
      accounts: [account],
    );
  }

  AppSettingsStore buildAppSettingsStore(AppSettings settings) {
    return FakeAppSettingsStore(settings);
  }

  testWidgets('returns early without opening DB when there is no work', (
    tester,
  ) async {
    debugFleurTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugFleurTargetPlatformOverride = null);

    var openCalls = 0;
    final runner = BackgroundSyncRunner(
      accounts: buildAccountsState(),
      appSettingsStore: buildAppSettingsStore(
        AppSettings.defaults().copyWith(
          autoRefreshMinutes: null,
          syncEnabled: false,
        ),
      ),
      outboxStore: FakeOutboxStore(),
      runWithMutex: _runWithoutMutex,
      openIsarForAccountFn:
          ({required accountId, required dbName, required isPrimary}) async {
            openCalls++;
            throw UnimplementedError('DB should not be opened');
          },
      syncServiceBuilder:
          ({
            required account,
            required feeds,
            required categories,
            required articles,
            required outbox,
            required appSettingsStore,
          }) {
            throw UnimplementedError('syncServiceBuilder should not be called');
          },
    );

    await runner.run(
      taskName: kBackgroundSyncTaskName,
      inputData: const <String, dynamic>{},
    );

    expect(openCalls, 0);
  });

  testWidgets('flushes outbox only when refresh is disabled', (tester) async {
    debugFleurTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugFleurTargetPlatformOverride = null);

    final outbox = FakeOutboxStore();
    final accountId = buildAccountsState().activeAccountId;
    await outbox.save(accountId, [
      OutboxAction(
        type: OutboxActionType.markRead,
        remoteEntryId: 1,
        value: true,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
    final syncService = FakeSyncService();
    final isar = _FakeIsar();
    final runner = BackgroundSyncRunner(
      accounts: buildAccountsState(),
      appSettingsStore: buildAppSettingsStore(
        AppSettings.defaults().copyWith(
          autoRefreshMinutes: null,
          syncEnabled: false,
        ),
      ),
      outboxStore: outbox,
      runWithMutex: _runWithoutMutex,
      openIsarForAccountFn:
          ({required accountId, required dbName, required isPrimary}) async =>
              isar,
      syncServiceBuilder:
          ({
            required account,
            required feeds,
            required categories,
            required articles,
            required outbox,
            required appSettingsStore,
          }) {
            return syncService;
          },
    );

    await runner.run(
      taskName: kBackgroundSyncTaskName,
      inputData: const <String, dynamic>{},
    );

    expect(syncService.flushCalls, 1);
    expect(syncService.refreshCalls, isEmpty);
    expect(isar.closeCalls, 1);
  });

  testWidgets('flushes outbox and refreshes feeds when both are needed', (
    tester,
  ) async {
    debugFleurTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugFleurTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final outbox = FakeOutboxStore();
    final accountId = buildAccountsState().activeAccountId;
    await outbox.save(accountId, [
      OutboxAction(
        type: OutboxActionType.markRead,
        remoteEntryId: 1,
        value: true,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
    final syncService = FakeSyncService();
    final isar = _FakeIsar();
    final feed = Feed()
      ..id = 1
      ..url = 'https://example.com/feed.xml'
      ..title = 'Feed 1';
    final runner = BackgroundSyncRunner(
      accounts: buildAccountsState(),
      appSettingsStore: buildAppSettingsStore(
        AppSettings.defaults().copyWith(
          autoRefreshMinutes: 30,
          syncEnabled: true,
        ),
      ),
      outboxStore: outbox,
      runWithMutex: _runWithoutMutex,
      openIsarForAccountFn:
          ({required accountId, required dbName, required isPrimary}) async =>
              isar,
      loadAllFeeds: (feeds, account) async => [feed],
      syncServiceBuilder:
          ({
            required account,
            required feeds,
            required categories,
            required articles,
            required outbox,
            required appSettingsStore,
          }) {
            return syncService;
          },
    );

    await runner.run(
      taskName: kBackgroundSyncTaskName,
      inputData: const <String, dynamic>{},
    );

    expect(syncService.flushCalls, 1);
    expect(syncService.refreshCalls, [
      [1],
    ]);
    expect(isar.closeCalls, 1);
  });

  testWidgets('skips refresh when iOS gating says interval has not elapsed', (
    tester,
  ) async {
    debugFleurTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugFleurTargetPlatformOverride = null);

    SharedPreferences.setMockInitialValues({
      'background_sync:last_refresh:remote-account': DateTime.utc(
        2026,
        1,
        1,
        0,
        10,
      ).millisecondsSinceEpoch,
    });

    final outbox = FakeOutboxStore();
    final accountId = buildAccountsState().activeAccountId;
    await outbox.save(accountId, [
      OutboxAction(
        type: OutboxActionType.markRead,
        remoteEntryId: 1,
        value: true,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
    final syncService = FakeSyncService();
    final isar = _FakeIsar();
    final runner = BackgroundSyncRunner(
      accounts: buildAccountsState(),
      appSettingsStore: buildAppSettingsStore(
        AppSettings.defaults().copyWith(
          autoRefreshMinutes: 30,
          syncEnabled: true,
        ),
      ),
      outboxStore: outbox,
      runWithMutex: _runWithoutMutex,
      nowProvider: () => DateTime.utc(2026, 1, 1, 0, 20),
      openIsarForAccountFn:
          ({required accountId, required dbName, required isPrimary}) async =>
              isar,
      syncServiceBuilder:
          ({
            required account,
            required feeds,
            required categories,
            required articles,
            required outbox,
            required appSettingsStore,
          }) {
            return syncService;
          },
    );

    await runner.run(
      taskName: kBackgroundSyncTaskName,
      inputData: const <String, dynamic>{},
    );

    expect(syncService.flushCalls, 1);
    expect(syncService.refreshCalls, isEmpty);
    expect(isar.closeCalls, 1);
  });
}
