class TranslationAiSettings {
  const TranslationAiSettings({
    required this.version,
    required this.translationProvider,
    required this.aiServices,
    required this.defaultAiServiceId,
    required this.deepL,
    required this.deepLX,
  });

  static const int currentVersion = 1;

  static TranslationAiSettings defaults() {
    return const TranslationAiSettings(
      version: currentVersion,
      translationProvider: TranslationProviderSelection.googleWeb(),
      aiServices: <AiServiceConfig>[],
      defaultAiServiceId: null,
      deepL: DeepLSettings(),
      deepLX: DeepLXSettings(),
    );
  }

  final int version;
  final TranslationProviderSelection translationProvider;
  final List<AiServiceConfig> aiServices;
  final String? defaultAiServiceId;
  final DeepLSettings deepL;
  final DeepLXSettings deepLX;

  TranslationAiSettings copyWith({
    int? version,
    TranslationProviderSelection? translationProvider,
    List<AiServiceConfig>? aiServices,
    Object? defaultAiServiceId = _unset,
    DeepLSettings? deepL,
    DeepLXSettings? deepLX,
  }) {
    return TranslationAiSettings(
      version: version ?? this.version,
      translationProvider: translationProvider ?? this.translationProvider,
      aiServices: aiServices ?? this.aiServices,
      defaultAiServiceId: defaultAiServiceId == _unset
          ? this.defaultAiServiceId
          : defaultAiServiceId as String?,
      deepL: deepL ?? this.deepL,
      deepLX: deepLX ?? this.deepLX,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'translationProvider': translationProvider.toJson(),
    'aiServices': aiServices.map((s) => s.toJson()).toList(growable: false),
    'defaultAiServiceId': defaultAiServiceId,
    'deepL': deepL.toJson(),
    'deepLX': deepLX.toJson(),
  };

  static TranslationAiSettings fromJson(Map<String, Object?> json) {
    final rawVersion = json['version'];
    final version = rawVersion is num ? rawVersion.toInt() : currentVersion;

    final translationProvider = TranslationProviderSelection.fromJson(
      json['translationProvider'],
    );

    final rawServices = json['aiServices'];
    final services = <AiServiceConfig>[];
    if (rawServices is List) {
      for (final raw in rawServices) {
        final service = AiServiceConfig.fromJson(raw);
        if (service == null) continue;
        services.add(service);
      }
    }

    final rawDefaultId = json['defaultAiServiceId'];
    final defaultId = rawDefaultId is String && rawDefaultId.trim().isNotEmpty
        ? rawDefaultId.trim()
        : null;

    final deepL = DeepLSettings.fromJson(json['deepL']);
    final deepLX = DeepLXSettings.fromJson(json['deepLX']);

    final loaded = TranslationAiSettings(
      version: version,
      translationProvider: translationProvider,
      aiServices: services,
      defaultAiServiceId: defaultId,
      deepL: deepL,
      deepLX: deepLX,
    );
    return loaded.normalized();
  }

  TranslationAiSettings normalized() {
    // Remove duplicates and empty ids; preserve order (first wins).
    final seenIds = <String>{};
    final normalizedServices = <AiServiceConfig>[];
    for (final s in aiServices) {
      final id = s.id.trim();
      if (id.isEmpty) continue;
      if (seenIds.contains(id)) continue;
      seenIds.add(id);
      normalizedServices.add(s.copyWith(id: id));
    }

    final enabledIds = <String>{
      for (final s in normalizedServices)
        if (s.enabled) s.id,
    };

    String? normalizedDefaultId = defaultAiServiceId;
    if (normalizedDefaultId != null &&
        !enabledIds.contains(normalizedDefaultId)) {
      normalizedDefaultId = null;
    }

    TranslationProviderSelection normalizedProvider = translationProvider;
    if (normalizedProvider.kind == TranslationProviderKind.aiService) {
      final id = normalizedProvider.aiServiceId;
      if (id == null || id.trim().isEmpty || !enabledIds.contains(id.trim())) {
        normalizedProvider = const TranslationProviderSelection.googleWeb();
      } else {
        normalizedProvider = TranslationProviderSelection.aiService(id.trim());
      }
    }

    return TranslationAiSettings(
      version: version,
      translationProvider: normalizedProvider,
      aiServices: normalizedServices,
      defaultAiServiceId: normalizedDefaultId,
      deepL: deepL,
      deepLX: deepLX,
    );
  }
}

enum TranslationProviderKind {
  googleWeb,
  bingWeb,
  baiduApi,
  deepLApi,
  deepLX,
  aiService,
}

class TranslationProviderSelection {
  const TranslationProviderSelection({required this.kind, this.aiServiceId});

  const TranslationProviderSelection.googleWeb()
    : kind = TranslationProviderKind.googleWeb,
      aiServiceId = null;

  const TranslationProviderSelection.bingWeb()
    : kind = TranslationProviderKind.bingWeb,
      aiServiceId = null;

  const TranslationProviderSelection.baiduApi()
    : kind = TranslationProviderKind.baiduApi,
      aiServiceId = null;

  const TranslationProviderSelection.deepLApi()
    : kind = TranslationProviderKind.deepLApi,
      aiServiceId = null;

  const TranslationProviderSelection.deepLX()
    : kind = TranslationProviderKind.deepLX,
      aiServiceId = null;

  const TranslationProviderSelection.aiService(String this.aiServiceId)
    : kind = TranslationProviderKind.aiService;

  final TranslationProviderKind kind;
  final String? aiServiceId;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'aiServiceId': aiServiceId,
  };

  static TranslationProviderSelection fromJson(Object? json) {
    if (json is String) {
      final kind = _parseKind(json);
      return TranslationProviderSelection._fromKind(kind, aiServiceId: null);
    }
    if (json is! Map) return const TranslationProviderSelection.googleWeb();
    final map = json.cast<String, Object?>();
    final kind = _parseKind(map['kind']);
    final rawAiId = map['aiServiceId'];
    final aiServiceId = rawAiId is String && rawAiId.trim().isNotEmpty
        ? rawAiId.trim()
        : null;
    return TranslationProviderSelection._fromKind(
      kind,
      aiServiceId: aiServiceId,
    );
  }

  static TranslationProviderKind _parseKind(Object? raw) {
    final s = raw is String ? raw.trim() : '';
    for (final v in TranslationProviderKind.values) {
      if (v.name == s) return v;
    }
    return TranslationProviderKind.googleWeb;
  }

  static TranslationProviderSelection _fromKind(
    TranslationProviderKind kind, {
    required String? aiServiceId,
  }) {
    return switch (kind) {
      TranslationProviderKind.googleWeb =>
        const TranslationProviderSelection.googleWeb(),
      TranslationProviderKind.bingWeb =>
        const TranslationProviderSelection.bingWeb(),
      TranslationProviderKind.baiduApi =>
        const TranslationProviderSelection.baiduApi(),
      TranslationProviderKind.deepLApi =>
        const TranslationProviderSelection.deepLApi(),
      TranslationProviderKind.deepLX =>
        const TranslationProviderSelection.deepLX(),
      TranslationProviderKind.aiService =>
        TranslationProviderSelection.aiService(aiServiceId ?? ''),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranslationProviderSelection &&
            other.kind == kind &&
            other.aiServiceId == aiServiceId;
  }

  @override
  int get hashCode => Object.hash(kind, aiServiceId);
}

enum AiServiceApiType {
  openAiChatCompletions,
  openAiResponses,
  gemini,
  anthropic,
}

class AiServiceConfig {
  const AiServiceConfig({
    required this.id,
    required this.name,
    required this.apiType,
    required this.baseUrl,
    required this.defaultModel,
    required this.enabled,
  });

  final String id;
  final String name;
  final AiServiceApiType apiType;
  final String baseUrl;
  final String defaultModel;
  final bool enabled;

  AiServiceConfig copyWith({
    String? id,
    String? name,
    AiServiceApiType? apiType,
    String? baseUrl,
    String? defaultModel,
    bool? enabled,
  }) {
    return AiServiceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      apiType: apiType ?? this.apiType,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'apiType': apiType.name,
    'baseUrl': baseUrl,
    'defaultModel': defaultModel,
    'enabled': enabled,
  };

  static AiServiceConfig? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final rawId = map['id'];
    final rawName = map['name'];
    final rawApiType = map['apiType'];
    final rawBaseUrl = map['baseUrl'];
    final rawDefaultModel = map['defaultModel'];
    final rawEnabled = map['enabled'];

    final id = rawId is String ? rawId.trim() : '';
    if (id.isEmpty) return null;
    final name = rawName is String ? rawName.trim() : '';
    final baseUrl = rawBaseUrl is String ? rawBaseUrl.trim() : '';
    final defaultModel = rawDefaultModel is String
        ? rawDefaultModel.trim()
        : '';

    AiServiceApiType parseApiType(Object? raw) {
      final s = raw is String ? raw.trim() : '';
      for (final t in AiServiceApiType.values) {
        if (t.name == s) return t;
      }
      return AiServiceApiType.openAiChatCompletions;
    }

    final apiType = parseApiType(rawApiType);
    final enabled = rawEnabled is! bool || rawEnabled;

    return AiServiceConfig(
      id: id,
      name: name.isEmpty ? id : name,
      apiType: apiType,
      baseUrl: baseUrl,
      defaultModel: defaultModel,
      enabled: enabled,
    );
  }
}

enum DeepLEndpoint { free, pro }

class DeepLSettings {
  const DeepLSettings({this.endpoint = DeepLEndpoint.free});

  final DeepLEndpoint endpoint;

  Map<String, Object?> toJson() => <String, Object?>{'endpoint': endpoint.name};

  static DeepLSettings fromJson(Object? json) {
    if (json is! Map) return const DeepLSettings();
    final map = json.cast<String, Object?>();
    final raw = map['endpoint'];
    final s = raw is String ? raw.trim() : '';
    for (final e in DeepLEndpoint.values) {
      if (e.name == s) return DeepLSettings(endpoint: e);
    }
    return const DeepLSettings();
  }
}

class DeepLXSettings {
  const DeepLXSettings({this.baseUrl = ''});

  final String baseUrl;

  Map<String, Object?> toJson() => <String, Object?>{'baseUrl': baseUrl};

  static DeepLXSettings fromJson(Object? json) {
    if (json is! Map) return const DeepLXSettings();
    final map = json.cast<String, Object?>();
    final raw = map['baseUrl'];
    final baseUrl = raw is String ? raw.trim() : '';
    return DeepLXSettings(baseUrl: baseUrl);
  }
}

const Object _unset = Object();
