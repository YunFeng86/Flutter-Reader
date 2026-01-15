import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_reader/models/feed.dart';
import 'package:flutter_reader/services/opml/opml_service.dart';

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
    final urls = OpmlService().parseFeedUrls(xml);
    expect(urls, contains('https://example.com/feed.xml'));
  });

  test('builds OPML', () {
    final feeds = [
      Feed()
        ..url = 'https://example.com/feed.xml'
        ..title = 'Example'
        ..siteUrl = 'https://example.com',
    ];
    final xml = OpmlService().buildOpml(feeds: feeds);
    expect(xml, contains('opml'));
    expect(xml, contains('xmlUrl="https://example.com/feed.xml"'));
  });
}

