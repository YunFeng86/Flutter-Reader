// Lightweight HTML helpers used in list views/previews.
//
// Prefer regex/substring extraction for tiny tasks; full HTML parsing is
// expensive in scrolling lists.

final RegExp _imgSrcRegex = RegExp(
  // Whitespace before `src` avoids matching `data-src`.
  r"""<img[^>]*\ssrc\s*=\s*['"]([^'"]+)['"]""",
  caseSensitive: false,
);

final RegExp _imgDataSrcRegex = RegExp(
  r"""<img[^>]*\sdata-src\s*=\s*['"]([^'"]+)['"]""",
  caseSensitive: false,
);

String? extractFirstImageSrc(String? html) {
  if (html == null || html.isEmpty) return null;
  // Prefer real src, but fall back to data-src for lazy-loaded markup.
  final src = _imgSrcRegex.firstMatch(html)?.group(1);
  if (src != null) return src;
  return _imgDataSrcRegex.firstMatch(html)?.group(1);
}
