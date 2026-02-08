import 'package:flutter/material.dart';

/// Preset seed colors used when dynamic colors are unavailable/disabled.
///
/// Keep this list small and high-quality; too many options becomes "settings
/// soup" quickly.
enum SeedColorPreset { blue, green, purple, orange, pink }

extension SeedColorPresetX on SeedColorPreset {
  Color get seedColor => switch (this) {
    // Neutral Google-ish blue (existing default).
    SeedColorPreset.blue => const Color(0xFF1A73E8),
    // Material-ish green.
    SeedColorPreset.green => const Color(0xFF34A853),
    // A vivid but not-too-loud purple.
    SeedColorPreset.purple => const Color(0xFF7E57C2),
    // Warm orange.
    SeedColorPreset.orange => const Color(0xFFFF8F00),
    // Pink accent.
    SeedColorPreset.pink => const Color(0xFFE91E63),
  };
}
