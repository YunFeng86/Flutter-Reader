import 'dart:async';
import 'dart:io';

import '../../db/isar_db.dart';
import '../../utils/path_manager.dart';
import 'account.dart';
import 'credential_store.dart';

class AccountCleanupService {
  AccountCleanupService({required CredentialStore credentials})
    : _credentials = credentials;

  final CredentialStore _credentials;

  Future<void> deleteAccountData(Account account) async {
    // Never delete primary DB automatically; keep a safe fallback.
    if (account.isPrimary) return;

    // Credentials (best-effort).
    try {
      await _credentials.deleteApiToken(account.id, account.type);
    } catch (_) {}
    try {
      await _credentials.deleteBasicAuth(account.id, account.type);
    } catch (_) {}

    // Outbox queue (best-effort).
    try {
      final dir = await PathManager.getStateDir();
      final f = File(
        '${dir.path}${Platform.pathSeparator}outbox_${account.id}.json',
      );
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}

    // Per-account Isar DB (best-effort; may fail on Windows if the DB is still
    // closing after a fast account switch).
    await _deleteIsarWithRetry(account);
  }

  Future<void> _deleteIsarWithRetry(Account account) async {
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      try {
        final isar = await openIsarForAccount(
          accountId: account.id,
          dbName: account.dbName,
          isPrimary: account.isPrimary,
        );
        await isar.close(deleteFromDisk: true);
        return;
      } catch (_) {
        // Backoff: 150ms, 300ms, 600ms...
        final delayMs = 150 * (1 << i);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    // Final fallback: attempt a best-effort manual delete of known files.
    // If Isar still holds a handle, the OS will deny deletion; we ignore.
    try {
      final dir = await PathManager.getDbDir();
      final sanitized = account.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final name = (account.dbName == null || account.dbName!.trim().isEmpty)
          ? 'fleur_$sanitized'
          : account.dbName!.trim();
      final candidates = <String>[
        '${dir.path}${Platform.pathSeparator}$name.isar',
        '${dir.path}${Platform.pathSeparator}$name.isar.lock',
        '${dir.path}${Platform.pathSeparator}$name.isar.txs',
      ];
      for (final p in candidates) {
        final f = File(p);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {}
  }
}
