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

  Future<void> setBasicAuth(
    String accountId,
    AccountType type, {
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    final p = password;
    await _storage.write(
      key: _key(accountId, '${type.wire}_username'),
      value: u,
    );
    await _storage.write(
      key: _key(accountId, '${type.wire}_password'),
      value: p,
    );
  }

  Future<({String username, String password})?> getBasicAuth(
    String accountId,
    AccountType type,
  ) async {
    final u = await _storage.read(
      key: _key(accountId, '${type.wire}_username'),
    );
    final p = await _storage.read(
      key: _key(accountId, '${type.wire}_password'),
    );
    if (u == null || u.trim().isEmpty) return null;
    if (p == null) return null;
    return (username: u.trim(), password: p);
  }

  Future<void> deleteBasicAuth(String accountId, AccountType type) async {
    await _storage.delete(key: _key(accountId, '${type.wire}_username'));
    await _storage.delete(key: _key(accountId, '${type.wire}_password'));
  }
}
