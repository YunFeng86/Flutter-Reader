import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account.dart';

class CredentialStore {
  CredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  String _key(String accountId, String name) => 'fleur:$accountId:$name';

  Future<void> setApiToken(String accountId, AccountType type, String token) {
    final trimmed = token.trim();
    return _storage.write(
      key: _key(accountId, '${type.wire}_api_token'),
      value: trimmed,
    );
  }

  Future<String?> getApiToken(String accountId, AccountType type) {
    return _storage.read(key: _key(accountId, '${type.wire}_api_token'));
  }

  Future<void> deleteApiToken(String accountId, AccountType type) {
    return _storage.delete(key: _key(accountId, '${type.wire}_api_token'));
  }
}
