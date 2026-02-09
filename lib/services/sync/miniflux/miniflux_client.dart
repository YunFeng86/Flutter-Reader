import 'package:dio/dio.dart';

class MinifluxClient {
  MinifluxClient({
    required Dio dio,
    required String baseUrl,
    required String apiToken,
  }) : _dio = dio,
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _apiToken = apiToken.trim();

  final Dio _dio;
  final String _baseUrl;
  final String _apiToken;

  Options get _options => Options(
    headers: <String, Object?>{'X-Auth-Token': _apiToken},
    responseType: ResponseType.json,
  );

  Future<List<Map<String, Object?>>> getCategories() async {
    final resp = await _dio.get('$_baseUrl/v1/categories', options: _options);
    final data = resp.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList(growable: false);
    }
    return const [];
  }

  Future<List<Map<String, Object?>>> getFeeds() async {
    final resp = await _dio.get('$_baseUrl/v1/feeds', options: _options);
    final data = resp.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList(growable: false);
    }
    return const [];
  }

  Future<Map<String, Object?>> getEntries({
    required int limit,
    int offset = 0,
    // Miniflux expects one or more "status" query params.
    // Docs: status = read | unread | removed (can be repeated).
    // We default to the common "all visible" set (unread + read).
    List<String> statuses = const ['unread', 'read'],
    String order = 'published_at',
    String direction = 'desc',
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/v1/entries',
      options: _options,
      queryParameters: <String, Object?>{
        'limit': limit,
        if (offset > 0) 'offset': offset,
        if (statuses.isNotEmpty) 'status': statuses,
        'order': order,
        'direction': direction,
      },
    );
    final data = resp.data;
    if (data is Map) return data.cast<String, Object?>();
    return const <String, Object?>{};
  }

  Future<void> setEntriesStatus(
    List<int> entryIds, {
    required String status,
  }) async {
    if (entryIds.isEmpty) return;
    await _dio.put(
      '$_baseUrl/v1/entries',
      options: _options,
      data: <String, Object?>{'entry_ids': entryIds, 'status': status},
    );
  }

  Future<void> bookmarkEntry(int entryId) async {
    await _dio.put('$_baseUrl/v1/entries/$entryId/bookmark', options: _options);
  }

  Future<void> unbookmarkEntry(int entryId) async {
    await _dio.put(
      '$_baseUrl/v1/entries/$entryId/unbookmark',
      options: _options,
    );
  }

  Future<void> markFeedAllAsRead(int feedId) async {
    await _dio.put(
      '$_baseUrl/v1/feeds/$feedId/mark-all-as-read',
      options: _options,
    );
  }

  Future<void> markCategoryAllAsRead(int categoryId) async {
    await _dio.put(
      '$_baseUrl/v1/categories/$categoryId/mark-all-as-read',
      options: _options,
    );
  }

  Future<String> fetchEntryContent(
    int entryId, {
    bool updateContent = false,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/v1/entries/$entryId/fetch-content',
      options: _options,
      queryParameters: <String, Object?>{'update_content': updateContent},
    );
    final data = resp.data;
    if (data is Map) {
      final content = data['content'];
      if (content is String) return content;
    }
    return '';
  }
}
