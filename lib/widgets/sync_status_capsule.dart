import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleur/l10n/app_localizations.dart';

import '../providers/sync_status_providers.dart';
import '../services/sync/sync_status_reporter.dart';

class SyncStatusCapsuleHost extends ConsumerWidget {
  const SyncStatusCapsuleHost({
    super.key,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  final Widget child;
  final bool enabled;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    final state = ref.watch(syncStatusControllerProvider);
    final visible = state.visible;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: padding,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: _SyncStatusCapsule(state: state),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncStatusCapsule extends StatelessWidget {
  const _SyncStatusCapsule({required this.state});

  final SyncStatusState state;

  String _labelText(AppLocalizations l10n, SyncStatusLabel label) {
    // Keep this in one place so UI can stay consistent across panes.
    switch (label) {
      case SyncStatusLabel.syncing:
        return l10n.syncStatusSyncing;
      case SyncStatusLabel.syncingFeeds:
        return l10n.syncStatusSyncingFeeds;
      case SyncStatusLabel.syncingSubscriptions:
        return l10n.syncStatusSyncingSubscriptions;
      case SyncStatusLabel.syncingUnreadArticles:
        return l10n.syncStatusSyncingUnreadArticles;
      case SyncStatusLabel.uploadingChanges:
        return l10n.syncStatusUploadingChanges;
      case SyncStatusLabel.completed:
        return l10n.syncStatusCompleted;
      case SyncStatusLabel.failed:
        return l10n.syncStatusFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final label = _labelText(l10n, state.label);
    final detail = (state.detail ?? '').trim();
    final title = detail.isEmpty ? label : '$label · $detail';

    final current = state.current;
    final total = state.total;
    final hasProgress = current != null && (total != null && total > 0);
    final text = hasProgress ? '$title（$current/$total）' : title;

    final key = ValueKey<int>(state.revision);

    final indicator = state.running
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.onSurface,
            ),
          )
        : Icon(
            state.label == SyncStatusLabel.failed
                ? Icons.error_outline
                : Icons.check,
            size: 16,
            color: scheme.onSurface,
          );

    return Material(
      elevation: 6,
      color: scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            indicator,
            const SizedBox(width: 10),
            Expanded(
              child: DefaultTextStyle(
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ) ??
                    TextStyle(color: scheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    // Stage switches: new label scrolls in from top, old exits down.
                    final isIncoming = child.key == key;
                    final begin = isIncoming
                        ? const Offset(0, -0.6)
                        : const Offset(0, 0.6);
                    return ClipRect(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: begin,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(text, key: key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
