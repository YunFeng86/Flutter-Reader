import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/providers/translation_ai_settings_providers.dart';
import 'package:fleur/services/settings/translation_ai_secret_store.dart';
import 'package:fleur/services/settings/translation_ai_settings.dart';
import 'package:fleur/services/settings/translation_ai_settings_store.dart';

class FakeTranslationAiSettingsStore implements TranslationAiSettingsStore {
  FakeTranslationAiSettingsStore(this._settings);

  TranslationAiSettings _settings;
  int saveCount = 0;

  @override
  Future<TranslationAiSettings> load() async => _settings;

  @override
  Future<void> save(TranslationAiSettings settings) async {
    saveCount++;
    _settings = settings;
  }
}

class FakeTranslationAiSecretStore implements TranslationAiSecretStore {
  FakeTranslationAiSecretStore({
    this.throwOnSet = false,
    this.throwOnDelete = false,
  });

  bool throwOnSet;
  bool throwOnDelete;

  int setCalls = 0;
  int deleteCalls = 0;

  final Map<String, String> _aiServiceApiKeys = <String, String>{};

  @override
  Future<void> setBaiduCredentials({
    required String appId,
    required String appKey,
  }) async {}

  @override
  Future<({String appId, String appKey})?> getBaiduCredentials() async => null;

  @override
  Future<void> deleteBaiduCredentials() async {}

  @override
  Future<void> setDeepLApiKey(String apiKey) async {}

  @override
  Future<String?> getDeepLApiKey() async => null;

  @override
  Future<void> deleteDeepLApiKey() async {}

  @override
  Future<void> setAiServiceApiKey(String serviceId, String apiKey) async {
    setCalls++;
    if (throwOnSet) throw Exception('secure storage write failed');
    _aiServiceApiKeys[serviceId] = apiKey.trim();
  }

  @override
  Future<String?> getAiServiceApiKey(String serviceId) async {
    final v = _aiServiceApiKeys[serviceId];
    final trimmed = (v ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<void> deleteAiServiceApiKey(String serviceId) async {
    deleteCalls++;
    if (throwOnDelete) throw Exception('secure storage delete failed');
    _aiServiceApiKeys.remove(serviceId);
  }
}

void main() {
  test('addAiService rolls back when api-key save fails', () async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults(),
    );
    final secrets = FakeTranslationAiSecretStore(throwOnSet: true);

    final container = ProviderContainer(
      overrides: [
        translationAiSettingsStoreProvider.overrideWithValue(store),
        translationAiSecretStoreProvider.overrideWithValue(secrets),
      ],
    );
    addTearDown(container.dispose);

    await container.read(translationAiSettingsProvider.future);
    final controller = container.read(translationAiSettingsProvider.notifier);

    await expectLater(
      controller.addAiService(
        name: 'Test',
        apiType: AiServiceApiType.openAiChatCompletions,
        baseUrl: 'https://example.com',
        defaultModel: 'gpt-4o-mini',
        enabled: true,
        apiKey: 'k',
      ),
      throwsA(isA<Exception>()),
    );

    expect(store.saveCount, 0);
    final settings = await container.read(translationAiSettingsProvider.future);
    expect(settings.aiServices, isEmpty);
  });

  test('updateAiService is atomic when api-key update fails', () async {
    const service = AiServiceConfig(
      id: 'svc1',
      name: 'Before',
      apiType: AiServiceApiType.openAiChatCompletions,
      baseUrl: 'https://example.com',
      defaultModel: 'gpt-4o-mini',
      enabled: true,
    );

    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults().copyWith(aiServices: [service]),
    );
    final secrets = FakeTranslationAiSecretStore(throwOnSet: true);

    final container = ProviderContainer(
      overrides: [
        translationAiSettingsStoreProvider.overrideWithValue(store),
        translationAiSecretStoreProvider.overrideWithValue(secrets),
      ],
    );
    addTearDown(container.dispose);

    await container.read(translationAiSettingsProvider.future);
    final controller = container.read(translationAiSettingsProvider.notifier);

    final updated = service.copyWith(name: 'After');
    await expectLater(
      controller.updateAiService(
        updated,
        apiKey: 'new-key',
        previousApiKey: 'old-key',
      ),
      throwsA(isA<Exception>()),
    );

    expect(store.saveCount, 0);
    final settings = await container.read(translationAiSettingsProvider.future);
    expect(settings.aiServices.single.name, 'Before');
  });

  test('updateAiService skips secret write when api-key unchanged', () async {
    const service = AiServiceConfig(
      id: 'svc1',
      name: 'Before',
      apiType: AiServiceApiType.openAiChatCompletions,
      baseUrl: 'https://example.com',
      defaultModel: 'gpt-4o-mini',
      enabled: true,
    );

    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults().copyWith(aiServices: [service]),
    );
    final secrets = FakeTranslationAiSecretStore(
      throwOnSet: true,
      throwOnDelete: true,
    );

    final container = ProviderContainer(
      overrides: [
        translationAiSettingsStoreProvider.overrideWithValue(store),
        translationAiSecretStoreProvider.overrideWithValue(secrets),
      ],
    );
    addTearDown(container.dispose);

    await container.read(translationAiSettingsProvider.future);
    final controller = container.read(translationAiSettingsProvider.notifier);

    final updated = service.copyWith(name: 'After');
    await controller.updateAiService(
      updated,
      apiKey: 'same-key',
      previousApiKey: 'same-key',
    );

    expect(secrets.setCalls, 0);
    expect(secrets.deleteCalls, 0);
    expect(store.saveCount, 1);

    final settings = await container.read(translationAiSettingsProvider.future);
    expect(settings.aiServices.single.name, 'After');
  });
}
