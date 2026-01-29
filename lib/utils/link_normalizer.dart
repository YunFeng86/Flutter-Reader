/// URL normalization utility for RSS article deduplication.
///
/// Removes tracking parameters and normalizes URL format to ensure
/// the same article with slightly different URLs is correctly identified.
class LinkNormalizer {
  LinkNormalizer._();

  /// Tracking parameters to strip from URLs.
  static const _trackingParams = {
    // Google Analytics
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    // Facebook
    'fbclid',
    // Google Ads
    'gclid',
    // Microsoft Ads
    'msclkid',
    // Other common trackers
    'ref',
    'referrer',
    '_ga',
    'mc_cid',
    'mc_eid',
    'source',
  };

  /// Normalize URL for deduplication.
  ///
  /// Steps:
  /// 1. Remove tracking query parameters
  /// 2. Remove fragment (#anchor)
  /// 3. Remove trailing slash (except for root path)
  /// 4. Trim whitespace
  static String normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    // Filter out tracking parameters
    final cleanParams = Map<String, String>.fromEntries(
      uri.queryParameters.entries.where(
        (e) => !_trackingParams.contains(e.key.toLowerCase()),
      ),
    );

    // Rebuild URI without fragment
    final normalized = uri.replace(
      queryParameters: cleanParams.isEmpty ? null : cleanParams,
      fragment: '',
    );

    var result = normalized.toString();

    // Remove trailing slash (except for root path like https://example.com/)
    if (result.endsWith('/') && normalized.pathSegments.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }
}
