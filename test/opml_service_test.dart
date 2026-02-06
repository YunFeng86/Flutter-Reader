import 'package:flutter_test/flutter_test.dart';

import 'package:fleur/models/feed.dart';
import 'package:fleur/services/opml/opml_service.dart';

void main() {
  test('parses OPML urls', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0">
  <body>
    <outline text="Tech">
      <outline text="Example" type="rss" xmlUrl="https://example.com/feed.xml" />
    </outline>
  </body>
</opml>
''';
    final entries = OpmlService().parseEntries(xml);
    expect(entries.map((e) => e.url), contains('https://example.com/feed.xml'));
    expect(entries.first.category, 'Tech');
  });

  test('builds OPML', () {
    final feeds = [
      Feed()
        ..url = 'https://example.com/feed.xml'
        ..title = 'Example'
        ..categoryId = 1
        ..siteUrl = 'https://example.com',
    ];
    final xml = OpmlService().buildOpml(
      feeds: feeds,
      categoryNames: const {1: 'Tech'},
    );
    expect(xml, contains('opml'));
    expect(xml, contains('xmlUrl="https://example.com/feed.xml"'));
    expect(xml, contains('Tech'));
  });
}
