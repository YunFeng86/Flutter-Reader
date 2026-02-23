import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:html/parser.dart' as html_parser;

import '../network/user_agents.dart';

class DiscoveredFeed {
  const DiscoveredFeed({required this.url, this.title, this.type});

  final String url;
  final String? title;
  final String? type;
}

class FeedDiscoveryService {
  FeedDiscoveryService(this._dio);

  final Dio _dio;

  Uri _normalizeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('URL is empty');
    }

    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) {
      throw ArgumentError('Invalid URL: $input');
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw ArgumentError('URL must be http/https: $input');
    }
    return uri;
  }

  bool _looksLikeFeed(String contentType, String body) {
    final ct = contentType.toLowerCase();
    if (ct.contains('application/rss+xml') ||
        ct.contains('application/atom+xml')) {
      return true;
    }
    if (ct.contains('xml')) {
      final head = body.length > 800 ? body.substring(0, 800) : body;
      final lower = head.toLowerCase();
      if (lower.contains('<rss') || lower.contains('<feed')) return true;
    }
    return false;
  }

  bool _isPotentialFeedMime(String type) {
    final t = type.toLowerCase();
    if (t.contains('application/rss+xml')) return true;
    if (t.contains('application/atom+xml')) return true;
    if (t.contains('application/xml')) return true;
    if (t.contains('text/xml')) return true;
    return false;
  }

  String? _trimOrNull(String? v) {
    final s = v?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Discover RSS/Atom feeds from a user-provided URL.
  ///
  /// - If the URL itself looks like a feed, returns it directly.
  /// - Otherwise, fetches HTML and parses `<link rel="alternate" ...>` tags.
  Future<List<DiscoveredFeed>> discover(
    String input, {
    String? userAgent,
  }) async {
    final uri = _normalizeInput(input);
    return discoverFromUri(uri, userAgent: userAgent);
  }

  Future<List<DiscoveredFeed>> discoverFromUri(
    Uri uri, {
    String? userAgent,
  }) async {
    final ua = (userAgent != null && userAgent.trim().isNotEmpty)
        ? userAgent.trim()
        : UserAgents.webForCurrentPlatform();

    final resp = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        headers: <String, String>{
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          if (!kIsWeb) 'User-Agent': ua,
        },
      ),
    );

    final contentType = resp.headers.value('content-type') ?? '';
    final body = (resp.data ?? '').trim();
    final realUri = resp.realUri;

    if (_looksLikeFeed(contentType, body)) {
      return [
        DiscoveredFeed(url: realUri.toString(), type: _trimOrNull(contentType)),
      ];
    }

    if (body.isEmpty) return const [];

    final doc = html_parser.parse(body);
    final baseHref = _trimOrNull(doc.querySelector('base')?.attributes['href']);
    final baseUri = baseHref == null ? realUri : realUri.resolve(baseHref);

    final feeds = <DiscoveredFeed>[];
    final seen = <String>{};

    for (final link in doc.getElementsByTagName('link')) {
      final href = _trimOrNull(link.attributes['href']);
      if (href == null) continue;

      final relRaw = _trimOrNull(link.attributes['rel'])?.toLowerCase() ?? '';
      final relTokens = relRaw
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toSet();
      final isAlternate =
          relTokens.contains('alternate') || relTokens.contains('feed');
      if (!isAlternate) continue;

      final type = _trimOrNull(link.attributes['type']);
      final title = _trimOrNull(link.attributes['title']);

      final looksFeed = type != null && _isPotentialFeedMime(type);
      final hrefLower = href.toLowerCase();
      final hintsFeed =
          hrefLower.contains('rss') ||
          hrefLower.contains('atom') ||
          hrefLower.contains('feed') ||
          hrefLower.contains('xml');
      if (!looksFeed && !hintsFeed) continue;

      final resolved = baseUri.resolve(href);
      if (!(resolved.scheme == 'http' || resolved.scheme == 'https')) continue;

      final url = resolved.toString();
      if (!seen.add(url)) continue;
      feeds.add(DiscoveredFeed(url: url, title: title, type: type));
    }

    return feeds;
  }
}
