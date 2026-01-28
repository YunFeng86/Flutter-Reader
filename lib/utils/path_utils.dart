import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 应用数据目录工具类
///
/// 统一管理应用数据存储路径，并处理旧数据迁移
class PathUtils {
  static const String _appFolderName = 'flutter_reader';

  /// 获取应用数据目录
  ///
  /// 返回 Documents/flutter_reader/ 目录
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
  /// 从 Documents 根目录迁移以下文件到 Documents/flutter_reader/:
  /// - flutter_reader.isar (数据库文件)
  /// - flutter_reader.lock (数据库锁文件)
  /// - app_settings.json (应用设置)
  /// - reader_settings.json (阅读器设置)
  static Future<void> _migrateOldData(
    Directory oldDir,
    Directory newDir,
  ) async {
    final filesToMigrate = [
      'flutter_reader.isar',
      'flutter_reader.lock',
      'app_settings.json',
      'reader_settings.json',
    ];

    for (final fileName in filesToMigrate) {
      final oldFile = File('${oldDir.path}${Platform.pathSeparator}$fileName');
      if (await oldFile.exists()) {
        try {
          final newFile = File(
            '${newDir.path}${Platform.pathSeparator}$fileName',
          );
          await oldFile.copy(newFile.path);
          // 注意：这里不删除旧文件，以防迁移后出现问题
          // 用户可以在确认新版本正常工作后手动删除
        } catch (e) {
          // 迁移失败不影响应用启动，记录错误但继续
          if (kDebugMode) {
            debugPrint('警告：迁移文件 $fileName 失败：$e');
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
