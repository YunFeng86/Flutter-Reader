import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../providers/core_providers.dart';

class DbRecoveryNoticeOverlay extends ConsumerStatefulWidget {
  const DbRecoveryNoticeOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DbRecoveryNoticeOverlay> createState() =>
      _DbRecoveryNoticeOverlayState();
}

class _DbRecoveryNoticeOverlayState
    extends ConsumerState<DbRecoveryNoticeOverlay> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_checkAndShow());
    });
  }

  Future<void> _checkAndShow() async {
    final isar = ref.read(isarProvider);
    final directory = isar.directory?.trim();
    if (directory == null || directory.isEmpty) return;

    final noticeFile = File(p.join(directory, 'backups', 'recovery_last.json'));
    if (!await noticeFile.exists()) return;

    Map<String, Object?>? payload;
    try {
      final raw = await noticeFile.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        payload = decoded.cast<String, Object?>();
      }
    } catch (_) {
      // ignore: best-effort notice parsing
    }

    if (!mounted) return;

    final title = MaterialLocalizations.of(context).alertDialogLabel;
    final createdAt = (payload?['createdAtIso'] as String?)?.trim();
    final accountId = (payload?['accountId'] as String?)?.trim();
    final dbName = (payload?['dbName'] as String?)?.trim();
    final backupPath = (payload?['backupPath'] as String?)?.trim();
    final movedPath = (payload?['movedPath'] as String?)?.trim();
    final fallbackDbName = (payload?['fallbackDbName'] as String?)?.trim();
    final error = (payload?['error'] as String?)?.trim();

    final lines = <String>[
      'Database recovery was triggered.',
      if (createdAt != null && createdAt.isNotEmpty) 'Time: $createdAt',
      if (accountId != null && accountId.isNotEmpty) 'Account: $accountId',
      if (dbName != null && dbName.isNotEmpty) 'DB name: $dbName',
      if (fallbackDbName != null && fallbackDbName.isNotEmpty)
        'Opened as: $fallbackDbName',
      if (backupPath != null && backupPath.isNotEmpty) 'Backup: $backupPath',
      if (movedPath != null && movedPath.isNotEmpty)
        'Moved original: $movedPath',
      if (error != null && error.isNotEmpty) 'Error: $error',
      '',
      'Your data was preserved on disk (backup / moved file).',
    ];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(lines.join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );

    // Clear notice once shown.
    try {
      await noticeFile.delete();
    } catch (_) {
      // ignore: best-effort cleanup
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
