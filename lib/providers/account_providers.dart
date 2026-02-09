import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/accounts/account.dart';
import '../services/accounts/account_store.dart';
import '../services/accounts/credential_store.dart';

final accountStoreProvider = Provider<AccountStore>((ref) => AccountStore());

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => CredentialStore(),
);

class AccountsController extends AsyncNotifier<AccountsState> {
  @override
  Future<AccountsState> build() async {
    return ref.read(accountStoreProvider).loadOrCreate();
  }

  Future<void> setActive(String accountId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    if (cur.activeAccountId == accountId) return;
    final exists = cur.findById(accountId) != null;
    if (!exists) return;
    final next = AccountsState(
      version: cur.version,
      activeAccountId: accountId,
      accounts: cur.accounts,
    );
    state = AsyncValue.data(next);
    await ref.read(accountStoreProvider).save(next);
  }

  Future<String> addAccount({
    required AccountType type,
    required String name,
    String? baseUrl,
    String? dbName,
  }) async {
    final cur = state.valueOrNull ?? await future;
    final now = DateTime.now();
    final id = AccountStore.newAccountId();
    final account = Account(
      id: id,
      type: type,
      name: name.trim().isEmpty ? type.wire : name.trim(),
      baseUrl: baseUrl?.trim(),
      dbName: dbName,
      createdAt: now,
      updatedAt: now,
    );
    final next = AccountsState(
      version: cur.version,
      activeAccountId: cur.activeAccountId,
      accounts: [...cur.accounts, account],
    );
    state = AsyncValue.data(next);
    await ref.read(accountStoreProvider).save(next);
    return id;
  }
}

final accountsControllerProvider =
    AsyncNotifierProvider<AccountsController, AccountsState>(
      AccountsController.new,
    );

final activeAccountProvider = Provider<Account>((ref) {
  final state = ref.watch(accountsControllerProvider).valueOrNull;
  if (state == null) {
    // This provider should only be used after accounts are loaded.
    return Account(
      id: 'local',
      type: AccountType.local,
      name: 'Local',
      isPrimary: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
  final active = state.findById(state.activeAccountId);
  return active ?? state.accounts.first;
});
