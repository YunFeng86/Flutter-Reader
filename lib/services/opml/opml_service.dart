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

  List<OpmlEntry> parseEntries(String opmlXml) {
    final doc = XmlDocument.parse(opmlXml);
    final entries = <OpmlEntry>[];

    XmlElement? body;
    try {
      body = doc.findAllElements('body').first;
    } catch (_) {
      body = null;
    }
    if (body == null) return entries;

    void walk(XmlElement el, String? category) {
      for (final o in el.findElements('outline')) {
        final xmlUrl = o.getAttribute('xmlUrl') ?? o.getAttribute('xmlurl');
        if (xmlUrl != null && xmlUrl.trim().isNotEmpty) {
          entries.add(OpmlEntry(url: xmlUrl.trim(), category: category));
          continue;
        }

        final text = (o.getAttribute('title') ?? o.getAttribute('text'))
            ?.trim();
        final nextCategory = (text == null || text.isEmpty) ? category : text;
        walk(o, nextCategory);
      }
    }

    walk(body, null);
    return entries;
  }

  String buildOpml({
    required List<Feed> feeds,
    Map<int, String> categoryNames = const {},
    String title = 'Fleur Subscriptions',
  }) {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element(
      'opml',
      attributes: {'version': '1.0'},
      nest: () {
        b.element(
          'head',
          nest: () {
            b.element('title', nest: title);
            b.element(
              'dateCreated',
              nest: DateTime.now().toUtc().toIso8601String(),
            );
          },
        );
        b.element(
          'body',
          nest: () {
            final byCat = <int?, List<Feed>>{};
            for (final f in feeds) {
              byCat.putIfAbsent(f.categoryId, () => []).add(f);
            }

            // Categories first.
            final catIds = byCat.keys.whereType<int>().toList()..sort();
            for (final id in catIds) {
              final name = categoryNames[id] ?? 'Category $id';
              b.element(
                'outline',
                attributes: {'text': name, 'title': name},
                nest: () {
                  for (final f in (byCat[id] ?? const <Feed>[])) {
                    _writeFeedOutline(b, f);
                  }
                },
              );
            }

            // Uncategorized.
            for (final f in (byCat[null] ?? const <Feed>[])) {
              _writeFeedOutline(b, f);
            }
          },
        );
      },
    );
    return b.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  void _writeFeedOutline(XmlBuilder b, Feed f) {
    final text = (f.userTitle?.trim().isNotEmpty == true)
        ? f.userTitle!
        : ((f.title?.trim().isNotEmpty == true) ? f.title! : f.url);
    b.element(
      'outline',
      attributes: {
        'type': 'rss',
        'text': text,
        'title': text,
        'xmlUrl': f.url,
        if (f.siteUrl?.trim().isNotEmpty == true) 'htmlUrl': f.siteUrl!,
      },
    );
  }
}

class OpmlEntry {
  const OpmlEntry({required this.url, required this.category});

  final String url;
  final String? category;
}
