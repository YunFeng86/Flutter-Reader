import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Content hash utility for detecting article updates.
///
/// Computes a SHA-256 hash of article content to determine if the content
/// has actually changed during sync, avoiding unnecessary database writes.
class ContentHash {
  ContentHash._();

  /// Compute SHA-256 hash of HTML content.
  ///
  /// Returns the first 32 characters (128 bits) of the hex digest.
  /// Returns empty string for null or empty content.
  static String compute(String? html) {
    if (html == null || html.trim().isEmpty) return '';

    final bytes = utf8.encode(html.trim());
    final digest = sha256.convert(bytes);

    // Use first 128 bits (32 hex chars) to save space
    return digest.toString().substring(0, 32);
  }
}
