import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

class IosShareBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.cloudwind.fleur/ios_share',
  );

  /// 在 iOS 上弹出系统分享/导出面板（包含“存储到文件”等）。
  static Future<void> shareFile({
    required String path,
    String? mimeType,
    String? name,
  }) async {
    if (!isIOS) return;
    await _channel.invokeMethod<void>('shareFile', {
      'path': path,
      'mimeType': mimeType,
      'name': name,
    });
  }
}
