import 'package:xml/xml.dart';

import '../../models/feed.dart';

class OpmlService {
  List<String> parseFeedUrls(String opmlXml) {
    final doc = XmlDocument.parse(opmlXml);
    final urls = <String>{};
    for (final el in doc.findAllElements('outline')) {
      final xmlUrl = el.getAttribute('xmlUrl') ?? el.getAttribute('xmlurl');
      if (xmlUrl == null) continue;
      final u = xmlUrl.trim();
      if (u.isNotEmpty) urls.add(u);
    }
    return urls.toList(growable: false);
  }

  String buildOpml({
    required List<Feed> feeds,
    String title = 'Flutter Reader Subscriptions',
  }) {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element(
      'opml',
      attributes: {'version': '1.0'},
      nest: () {
        b.element('head', nest: () {
          b.element('title', nest: title);
          b.element('dateCreated', nest: DateTime.now().toUtc().toIso8601String());
        });
        b.element('body', nest: () {
          for (final f in feeds) {
            b.element(
              'outline',
              attributes: {
                'type': 'rss',
                'text': (f.title?.trim().isNotEmpty == true) ? f.title! : f.url,
                'title': (f.title?.trim().isNotEmpty == true) ? f.title! : f.url,
                'xmlUrl': f.url,
                if (f.siteUrl?.trim().isNotEmpty == true) 'htmlUrl': f.siteUrl!,
              },
            );
          }
        });
      },
    );
    return b.buildDocument().toXmlString(pretty: true, indent: '  ');
  }
}

