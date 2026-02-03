class ReaderSettings {
  const ReaderSettings({
    this.fontSize = 16,
    this.lineHeight = 1.5,
    this.horizontalPadding = 16,
  });

  final double fontSize;
  final double lineHeight;
  final double horizontalPadding;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? horizontalPadding,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    );
  }

  Map<String, Object?> toJson() => {
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'horizontalPadding': horizontalPadding,
  };

  static ReaderSettings fromJson(Map<String, Object?> json) {
    double toDoubleOr(Object? v, double fallback) {
      if (v is num) return v.toDouble();
      return fallback;
    }

    return ReaderSettings(
      fontSize: toDoubleOr(json['fontSize'], 16),
      lineHeight: toDoubleOr(json['lineHeight'], 1.5),
      horizontalPadding: toDoubleOr(json['horizontalPadding'], 16),
    );
  }
}
