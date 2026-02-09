import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../db/isar_db.dart';
import '../providers/account_providers.dart';
import '../providers/core_providers.dart';
import '../services/accounts/account.dart';
import 'app.dart';

class AccountGate extends ConsumerStatefulWidget {
  const AccountGate({super.key});

  @override
  ConsumerState<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends ConsumerState<AccountGate> {
  Isar? _isar;
  String? _openedForAccountId;
  Future<void>? _opening;

  @override
  void dispose() {
    unawaited(_isar?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsControllerProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    if (accountsAsync.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (accountsAsync.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text(accountsAsync.error.toString())),
        ),
      );
    }

    // Ensure the correct Isar instance is opened for the active account.
    final shouldOpen = _openedForAccountId != activeAccount.id;
    if (shouldOpen && _opening == null) {
      _opening = _openFor(activeAccount).whenComplete(() {
        if (mounted) setState(() => _opening = null);
      });
    }

    final opening = _opening;
    if (opening != null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final isar = _isar;
    if (isar == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ProviderScope(
      key: ValueKey('account:${activeAccount.id}'),
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const App(),
    );
  }

  Future<void> _openFor(Account account) async {
    final next = await openIsarForAccount(
      accountId: account.id,
      dbName: account.dbName,
      isPrimary: account.isPrimary,
    );
    final prev = _isar;
    _isar = next;
    _openedForAccountId = account.id;
    if (prev != null) {
      // Close in background; Isar close can be slow on some platforms.
      unawaited(prev.close());
    }
  }
}
