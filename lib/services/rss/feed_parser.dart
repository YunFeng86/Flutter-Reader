import 'package:rss_dart/domain/atom_feed.dart';
import 'package:rss_dart/domain/atom_link.dart';
import 'package:rss_dart/domain/rss_feed.dart';

import '../../utils/date_parse.dart';
import 'parsed_feed.dart';

class FeedParser {
  ParsedFeed parse(String xml) {
    final trimmed = xml.trim();

    // Detect feed format by inspecting root element declaration (first 512 bytes)
    // This prevents false positives from matching format identifiers in content.
    // RSS 2.0: <rss version="2.0">
    // RSS 1.0: <rdf:RDF xmlns:rdf="..." xmlns="http://purl.org/rss/1.0/">
    // Atom: <feed xmlns="http://www.w3.org/2005/Atom">
    final header = trimmed.length > 512 ? trimmed.substring(0, 512) : trimmed;

    // Maintain RSS-first priority to preserve backward compatibility with existing feeds
    // (matches previous try-RSS-first behavior without exception overhead)
    if (_isRssFeed(header)) {
      try {
        return _parseRss(trimmed);
      } catch (e) {
        throw FormatException('Failed to parse RSS feed: $e');
      }
    } else if (_isAtomFeed(header)) {
      try {
        return _parseAtom(trimmed);
      } catch (e) {
        throw FormatException('Failed to parse Atom feed: $e');
      }
    } else {
      throw FormatException(
        'Unknown feed format. Expected RSS 1.0/2.0 or Atom feed.',
      );
    }
  }

  bool _isAtomFeed(String xmlHeader) {
    // Atom must have <feed> root and xmlns="http://www.w3.org/2005/Atom"
    return xmlHeader.contains('<feed') &&
           xmlHeader.contains('http://www.w3.org/2005/Atom');
  }

  bool _isRssFeed(String xmlHeader) {
    // RSS 2.0: <rss version="2.0">
    // RSS 1.0: <rdf:RDF> with RSS 1.0 namespace
    // Also accept <channel> as RSS indicator (some feeds omit version)
    return xmlHeader.contains('<rss') ||
           xmlHeader.contains('<channel>') ||
           (xmlHeader.contains('<rdf:RDF') && xmlHeader.contains('http://purl.org/rss/1.0/'));
  }

  ParsedFeed _parseRss(String xml) {
    final feed = RssFeed.parse(xml);
    return ParsedFeed(
      title: feed.title,
      siteUrl: feed.link,
      description: feed.description,
      items: feed.items
          .map((it) {
            final link = it.link?.trim();
            if (link == null || link.isEmpty) return null;
            return ParsedItem(
              remoteId: it.guid ?? link,
              link: link,
              title: it.title,
              author: it.author ?? it.dc?.creator,
              publishedAt: tryParseFeedDate(it.pubDate),
              contentHtml: it.content?.value ?? it.description,
            );
          })
          .whereType<ParsedItem>()
          .toList(growable: false),
    );
  }

  ParsedFeed _parseAtom(String xml) {
    final feed = AtomFeed.parse(xml);
    final siteUrl = _pickAlternate(feed.links);
    return ParsedFeed(
      title: feed.title,
      siteUrl: siteUrl,
      description: feed.subtitle,
      items: feed.items
          .map((it) {
            final link = _pickAlternate(it.links) ?? '';
            if (link.trim().isEmpty) return null;
            return ParsedItem(
              remoteId: it.id ?? link,
              link: link,
              title: it.title,
              author: it.authors.isNotEmpty ? it.authors.first.name : null,
              publishedAt:
                  tryParseFeedDate(it.published) ?? tryParseFeedDate(it.updated),
              contentHtml: it.content ?? it.summary,
            );
          })
          .whereType<ParsedItem>()
          .toList(growable: false),
    );
  }

  String? _pickAlternate(List<AtomLink> links) {
    for (final l in links) {
      final rel = l.rel;
      final href = l.href;
      if (href == null) continue;
      if (rel == null || rel == 'alternate') return href;
    }
    for (final l in links) {
      final href = l.href;
      if (href != null) return href;
    }
    return null;
  }
}
