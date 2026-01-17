import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/article.dart';
import '../providers/query_providers.dart';

class ArticleListItem extends ConsumerWidget {
  const ArticleListItem({
    super.key,
    required this.article,
    required this.selected,
  });

  final Article article;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !article.isRead;
    final feedMap = ref.watch(feedMapProvider);
    final feed = feedMap[article.feedId];

    final title = (article.title ?? '').trim();
    final timeStr = timeago.format(article.publishedAt);

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer.withOpacity(0.12)
            : null,
        border: Border(
          left: BorderSide(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Feed Icon (placeholder or favicon if available later)
              // For now, using a small icon or just text
              if (feed?.title != null) ...[
                // Tiny icon for feed source
                Icon(
                  Icons.rss_feed,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    feed!.title!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              // Time
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUnread
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title.isEmpty ? article.link : title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              color: isUnread
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Optional: Summary text or Image could go here in future
          // Metadata Row (e.g. tags) could go here
          if (article.isStarred) ...[
            const SizedBox(height: 6),
            Icon(Icons.star, size: 14, color: theme.colorScheme.tertiary),
          ],
        ],
      ),
    );
  }
}
