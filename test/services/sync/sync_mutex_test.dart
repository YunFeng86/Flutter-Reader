import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fleur/services/sync/sync_mutex.dart';
import 'package:fleur/utils/path_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FailingPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => null;

  @override
  Future<String?> getApplicationSupportPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async => null;
}

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

  tearDownAll(() {
    PathProviderPlatform.instance = originalPlatform;
  });

  tearDown(() async {
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

  test('SyncMutex falls back and retries lock file after failure', () async {
    const key = 'sync_mutex_test';

    PathProviderPlatform.instance = _FailingPathProviderPlatform();
    PathManager.resetForTests();

    final v1 = await SyncMutex.instance.run(key, () async => 123);
    expect(v1, 123);

    tempDir = await Directory.systemTemp.createTemp('fleur_test_');
    final docs = await Directory(
      '${tempDir!.path}/documents',
    ).create(recursive: true);
    final support = await Directory(
      '${tempDir!.path}/support',
    ).create(recursive: true);
    final cache = await Directory('${tempDir!.path}/cache').create(
      recursive: true,
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: docs.path,
      supportPath: support.path,
      cachePath: cache.path,
    );
    PathManager.resetForTests();

    final v2 = await SyncMutex.instance.run(key, () async => 456);
    expect(v2, 456);

    final stateDir = await PathManager.getStateDir();
    final lockFile = File(
      '${stateDir.path}${Platform.pathSeparator}mutex_$key.lock',
    );
    expect(await lockFile.exists(), isTrue);
  });
}
