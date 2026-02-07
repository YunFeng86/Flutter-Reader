import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fleur/utils/path_manager.dart';
import 'package:fleur/utils/path_utils.dart';
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
  late Directory tempDir;

  setUpAll(() {
    originalPlatform = PathProviderPlatform.instance;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fleur_test_');
    final docs = await Directory(
      '${tempDir.path}/documents',
    ).create(recursive: true);
    final support = await Directory(
      '${tempDir.path}/support',
    ).create(recursive: true);
    final cache = await Directory(
      '${tempDir.path}/cache',
    ).create(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: docs.path,
      supportPath: support.path,
      cachePath: cache.path,
    );
    PathManager.resetForTests();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  tearDownAll(() {
    PathProviderPlatform.instance = originalPlatform;
  });

  group('PathUtils', () {
    test('getAppDataDirectory 应返回包含 fleur 的目录', () async {
      final dir = await PathUtils.getAppDataDirectory();

      expect(dir.path.contains('fleur'), isTrue, reason: '应用数据目录应包含 fleur 文件夹');
    });

    test('getAppDataPath 应返回字符串路径', () async {
      final path = await PathUtils.getAppDataPath();

      expect(path, isA<String>(), reason: '应返回字符串类型的路径');
      expect(path.contains('fleur'), isTrue, reason: '路径应包含 fleur 文件夹');
    });

    test('getAppDataDirectory 应创建目录如果不存在', () async {
      final dir = await PathUtils.getAppDataDirectory();
      final exists = await dir.exists();

      expect(exists, isTrue, reason: '应用数据目录应该存在');
    });
  });
}
