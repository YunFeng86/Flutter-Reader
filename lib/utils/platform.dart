import 'package:flutter/foundation.dart';

bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
