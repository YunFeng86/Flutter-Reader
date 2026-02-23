import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fleur/services/sync/outbox/outbox_store.dart';
import 'package:fleur/utils/path_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required String documentsPath,
    required String supportPath,
    required String cachePath,
  }) : _documentsPath = documentsPath,
       _supportPath = supportPath,
       _cachePath = cachePath;

  final String _documentsPath;
  final String _supportPath;
  final String _cachePath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => _supportPath;

  @override
  Future<String?> getApplicationCachePath() async => _cachePath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPlatform;
  Directory? tempDir;

  setUpAll(() {
    originalPlatform = PathProviderPlatform.instance;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fleur_test_');
    final docs = await Directory(
      '${tempDir!.path}/documents',
    ).create(recursive: true);
    final support = await Directory(
      '${tempDir!.path}/support',
    ).create(recursive: true);
    final cache = await Directory(
      '${tempDir!.path}/cache',
    ).create(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: docs.path,
      supportPath: support.path,
      cachePath: cache.path,
    );
    PathManager.resetForTests();
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPlatform;
    final dir = tempDir;
    tempDir = null;
    try {
      if (dir != null) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // ignore: best-effort cleanup
    }
  });

  test('OutboxStore save/load roundtrip', () async {
    final store = OutboxStore();
    const accountId = 'acc_roundtrip';

    final ts = DateTime.utc(2026, 2, 9, 12, 0, 0);
    await store.save(accountId, [
      OutboxAction(
        type: OutboxActionType.markRead,
        remoteEntryId: 1,
        value: true,
        createdAt: ts,
      ),
      OutboxAction(
        type: OutboxActionType.bookmark,
        remoteEntryId: 2,
        value: true,
        createdAt: ts,
      ),
    ]);

    final loaded = await store.load(accountId);
    expect(loaded, hasLength(2));
    expect(loaded[0].type, OutboxActionType.markRead);
    expect(loaded[1].type, OutboxActionType.bookmark);
  });

  test('OutboxStore recovers from .bak when primary is corrupted', () async {
    final store = OutboxStore();
    const accountId = 'acc_bak';

    final stateDir = await PathManager.getStateDir();
    final primary = File(
      '${stateDir.path}${Platform.pathSeparator}outbox_$accountId.json',
    );
    final bak = File('${primary.path}.bak');

    final ts = DateTime.utc(2026, 2, 10, 8, 30, 0);
    final expected = [
      OutboxAction(
        type: OutboxActionType.markRead,
        remoteEntryId: 42,
        value: true,
        createdAt: ts,
      ),
    ];

    await bak.writeAsString(
      jsonEncode(expected.map((a) => a.toJson()).toList(growable: false)),
      encoding: utf8,
    );
    await primary.writeAsString('[', encoding: utf8); // corrupted JSON

    final loaded = await store.load(accountId);
    expect(loaded, hasLength(1));
    expect(loaded.first.remoteEntryId, 42);

    final raw = await primary.readAsString(encoding: utf8);
    final decoded = jsonDecode(raw);
    expect(decoded, isA<List>());
  });

  test('OutboxStore recovers from .tmp when primary is corrupted', () async {
    final store = OutboxStore();
    const accountId = 'acc_tmp';

    final stateDir = await PathManager.getStateDir();
    final primary = File(
      '${stateDir.path}${Platform.pathSeparator}outbox_$accountId.json',
    );
    final tmp = File('${primary.path}.tmp');

    final ts = DateTime.utc(2026, 2, 10, 9, 0, 0);
    final expected = [
      OutboxAction(
        type: OutboxActionType.bookmark,
        remoteEntryId: 7,
        value: true,
        createdAt: ts,
      ),
    ];

    await tmp.writeAsString(
      jsonEncode(expected.map((a) => a.toJson()).toList(growable: false)),
      encoding: utf8,
    );
    await primary.writeAsString('[', encoding: utf8); // corrupted JSON

    final loaded = await store.load(accountId);
    expect(loaded, hasLength(1));
    expect(loaded.first.remoteEntryId, 7);
    expect(await tmp.exists(), isFalse);
  });
}
