import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 应用数据目录工具类
///
/// 统一管理应用数据存储路径，并处理旧数据迁移
class PathUtils {
  static const String _appFolderName = 'fleur';

  // Legacy names used by older builds of this app (and the old Flutter Reader branding).
  static const String _legacyAppFolderName = 'flutter_reader';
  static const String _legacyIsarName = 'flutter_reader';
  static const String _isarName = 'fleur';

  /// 获取应用数据目录
  ///
  /// 返回 Documents/fleur/ 目录
  /// 首次调用时会自动创建目录并迁移旧数据
  static Future<Directory> getAppDataDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final appDir = Directory(
      '${documentsDir.path}${Platform.pathSeparator}$_appFolderName',
    );

    // 确保目录存在
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
      // 首次创建时尝试迁移旧数据
      await _migrateOldData(documentsDir, appDir);
    }

    return appDir;
  }

  /// 迁移旧数据到新目录
  ///
  /// 从旧位置迁移以下文件到 Documents/fleur/:
  /// - flutter_reader.isar / flutter_reader.lock (旧数据库文件/锁文件) -> fleur.isar / fleur.lock
  /// - app_settings.json (应用设置)
  /// - reader_settings.json (阅读器设置)
  static Future<void> _migrateOldData(
    Directory documentsDir,
    Directory newDir,
  ) async {
    final legacyDir = Directory(
      '${documentsDir.path}${Platform.pathSeparator}$_legacyAppFolderName',
    );

    final sources = <Directory>[documentsDir, legacyDir];

    final filesToMigrate = <({String from, String to})>[
      // Isar DB renamed from flutter_reader -> fleur.
      (from: '$_legacyIsarName.isar', to: '$_isarName.isar'),
      (from: '$_legacyIsarName.lock', to: '$_isarName.lock'),
      // Settings keep their filenames.
      (from: 'app_settings.json', to: 'app_settings.json'),
      (from: 'reader_settings.json', to: 'reader_settings.json'),
    ];

    for (final srcDir in sources) {
      if (!await srcDir.exists()) continue;
      for (final file in filesToMigrate) {
        final src = File('${srcDir.path}${Platform.pathSeparator}${file.from}');
        if (!await src.exists()) continue;

        final dst = File('${newDir.path}${Platform.pathSeparator}${file.to}');
        if (await dst.exists()) continue;

        try {
          await src.copy(dst.path);
          // 注意：这里不删除旧文件，以防迁移后出现问题
          // 用户可以在确认新版本正常工作后手动删除
        } catch (e) {
          // 迁移失败不影响应用启动，记录错误但继续
          if (kDebugMode) {
            debugPrint('警告：迁移文件 ${file.from} 失败：$e');
          }
        }
      }
    }
  }

  /// 获取应用数据目录路径（仅路径字符串）
  static Future<String> getAppDataPath() async {
    final dir = await getAppDataDirectory();
    return dir.path;
  }
}
