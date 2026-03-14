import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/providers/translation_ai_settings_providers.dart';
import 'package:fleur/services/settings/translation_ai_settings.dart';
import 'package:fleur/ui/settings/tabs/translation_ai_services_tab.dart';

import '../../test_utils/critical_workflow_test_support.dart';

void main() {
  Future<void> pumpTab(
    WidgetTester tester, {
    required FakeTranslationAiSettingsStore store,
    FakeTranslationAiSecretStore? secrets,
  }) async {
    await pumpLocalizedTestApp(
      tester,
      home: const Scaffold(body: TranslationAiServicesTab()),
      overrides: [
        translationAiSettingsStoreProvider.overrideWithValue(store),
        translationAiSecretStoreProvider.overrideWithValue(
          secrets ?? FakeTranslationAiSecretStore(),
        ),
      ],
      size: const Size(900, 1200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('updates translation provider and target language selections', (
    tester,
  ) async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults(),
    );

    await pumpTab(tester, store: store);

    await tester.tap(find.text('Translation provider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bing 翻译（网页）').last);
    await tester.pumpAndSettle();

    expect(
      store.settings.translationProvider.kind,
      TranslationProviderKind.bingWeb,
    );

    await tester.tap(find.text('Target language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese').last);
    await tester.pumpAndSettle();

    expect(store.settings.targetLanguageTag, 'ja');
  });

  testWidgets('resets custom AI translation prompt to default', (tester) async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults().copyWith(
        aiTranslationPrompt: 'Translate this in a custom way.',
      ),
    );

    await pumpTab(tester, store: store);

    await tester.tap(find.text('AI translation prompt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();

    expect(store.settings.aiTranslationPrompt, isNull);
  });

  testWidgets('shows error for invalid DeepLX base URL and keeps settings', (
    tester,
  ) async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults().copyWith(
        deepLX: const DeepLXSettings(baseUrl: 'https://deeplx.initial'),
      ),
    );

    await pumpTab(tester, store: store);

    await tester.tap(find.text('DeepLX'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'notaurl');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid base URL'), findsOneWidget);
    expect(store.settings.deepLX.baseUrl, 'https://deeplx.initial');
  });

  testWidgets('saves DeepL endpoint and API key from dialog', (tester) async {
    final store = FakeTranslationAiSettingsStore(
      TranslationAiSettings.defaults(),
    );
    final secrets = FakeTranslationAiSecretStore();

    await pumpTab(tester, store: store, secrets: secrets);

    await tester.tap(find.text('DeepL（API）'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'deep-key');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(store.settings.deepL.endpoint, DeepLEndpoint.pro);
    expect(await secrets.getDeepLApiKey(), 'deep-key');
  });
}
