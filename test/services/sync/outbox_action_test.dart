import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/services/sync/outbox/outbox_store.dart';

void main() {
  test('OutboxAction serializes markAllRead with feedUrl', () {
    final ts = DateTime.utc(2026, 2, 9, 12, 0, 0);
    final a = OutboxAction(
      type: OutboxActionType.markAllRead,
      feedUrl: 'https://example.com/rss.xml',
      value: true,
      createdAt: ts,
    );
    final json = a.toJson();
    final decoded = OutboxAction.fromJson(json);

    expect(decoded.type, OutboxActionType.markAllRead);
    expect(decoded.feedUrl, 'https://example.com/rss.xml');
    expect(decoded.categoryTitle, isNull);
    expect(decoded.remoteEntryId, isNull);
    expect(decoded.value, true);
    expect(decoded.createdAt.toIso8601String(), ts.toIso8601String());
  });

  test('OutboxAction.fromJson supports legacy entry-level fields', () {
    final legacy = <String, Object?>{
      'type': 'markRead',
      'remoteEntryId': 42,
      'value': true,
      'createdAt': '2026-02-09T12:00:00.000Z',
    };
    final a = OutboxAction.fromJson(legacy);
    expect(a.type, OutboxActionType.markRead);
    expect(a.remoteEntryId, 42);
    expect(a.value, true);
    expect(a.feedUrl, isNull);
    expect(a.categoryTitle, isNull);
  });
}
