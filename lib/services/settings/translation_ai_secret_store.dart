import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TranslationAiSecretStore {
  TranslationAiSecretStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  static const String _prefix = 'fleur:translation_ai';

  String _key(String name) => '$_prefix:$name';

  String _aiServiceKey(String serviceId, String name) =>
      '$_prefix:ai_service:$serviceId:$name';

  Future<void> setBaiduCredentials({
    required String appId,
    required String appKey,
  }) async {
    final id = appId.trim();
    final key = appKey;
    await _storage.write(key: _key('baidu:app_id'), value: id);
    await _storage.write(key: _key('baidu:app_key'), value: key);
  }

  Future<({String appId, String appKey})?> getBaiduCredentials() async {
    final appId = await _storage.read(key: _key('baidu:app_id'));
    final appKey = await _storage.read(key: _key('baidu:app_key'));
    if (appId == null || appId.trim().isEmpty) return null;
    if (appKey == null || appKey.isEmpty) return null;
    return (appId: appId.trim(), appKey: appKey);
  }

  Future<void> deleteBaiduCredentials() async {
    await _storage.delete(key: _key('baidu:app_id'));
    await _storage.delete(key: _key('baidu:app_key'));
  }

  Future<void> setDeepLApiKey(String apiKey) {
    final trimmed = apiKey.trim();
    return _storage.write(key: _key('deepl:api_key'), value: trimmed);
  }

  Future<String?> getDeepLApiKey() async {
    final v = await _storage.read(key: _key('deepl:api_key'));
    final trimmed = (v ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> deleteDeepLApiKey() {
    return _storage.delete(key: _key('deepl:api_key'));
  }

  Future<void> setAiServiceApiKey(String serviceId, String apiKey) {
    final trimmed = apiKey.trim();
    return _storage.write(
      key: _aiServiceKey(serviceId, 'api_key'),
      value: trimmed,
    );
  }

  Future<String?> getAiServiceApiKey(String serviceId) async {
    final v = await _storage.read(key: _aiServiceKey(serviceId, 'api_key'));
    final trimmed = (v ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> deleteAiServiceApiKey(String serviceId) {
    return _storage.delete(key: _aiServiceKey(serviceId, 'api_key'));
  }
}
