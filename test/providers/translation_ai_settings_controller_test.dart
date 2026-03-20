import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/providers/translation_ai_settings_providers.dart';
import 'package:fleur/services/settings/translation_ai_settings.dart';
import 'package:fleur/utils/language_utils.dart';
import '../test_utils/critical_workflow_test_support.dart';

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

  test('setTargetLanguageTag canonicalizes equivalent language tags', () async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults(),
    );

    final container = ProviderContainer(
      overrides: [
        translationAiSettingsStoreProvider.overrideWithValue(store),
        translationAiSecretStoreProvider.overrideWithValue(
          FakeTranslationAiSecretStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(translationAiSettingsProvider.future);
    final controller = container.read(translationAiSettingsProvider.notifier);
    await controller.setTargetLanguageTag('zh-Hans-CN');

    expect(store.settings.targetLanguageTag, 'zh-Hans');
  });

  test(
    'disable reminder deduplicates equivalent language identities',
    () async {
      final store = FakeTranslationAiSettingsStore(
        TranslationAiSettings.defaults(),
      );

      final container = ProviderContainer(
        overrides: [
          translationAiSettingsStoreProvider.overrideWithValue(store),
          translationAiSecretStoreProvider.overrideWithValue(
            FakeTranslationAiSecretStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(translationAiSettingsProvider.future);
      final controller = container.read(translationAiSettingsProvider.notifier);
      await controller.disableTranslationReminderForLanguage('en-GB');
      await controller.disableTranslationReminderForLanguage('en');

      expect(store.settings.disabledTranslationReminderLanguages, <String>[
        canonicalLanguageIdentityTag('en'),
      ]);
    },
  );
}
