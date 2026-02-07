import 'dart:io';

import 'path_manager.dart';

/// 应用数据目录工具类
///
/// 统一管理应用数据存储路径，并处理旧数据迁移。
///
/// 说明：历史上本项目将数据放在 Documents 下；从迁移 v2 开始，改为遵循平台规范：
/// - Application Support：DB / settings / user state
/// - Application Cache：缓存数据
///
/// 新代码优先直接使用 [PathManager]，本类仅保留用于兼容旧调用点。
class PathUtils {
  /// 获取应用数据目录（Application Support）。
  static Future<Directory> getAppDataDirectory() async {
    return PathManager.getSupportDir();
  }

  /// 获取应用数据目录路径（仅路径字符串）
  static Future<String> getAppDataPath() async {
    return PathManager.getSupportPath();
  }
}
