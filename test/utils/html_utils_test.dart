import 'package:flutter_test/flutter_test.dart';
import 'package:fleur/utils/html_utils.dart';

void main() {
  group('extractFirstImageSrc', () {
    test('returns null for null/empty', () {
      expect(extractFirstImageSrc(null), isNull);
      expect(extractFirstImageSrc(''), isNull);
      expect(extractFirstImageSrc('   '), isNull);
    });

    test('extracts first img src', () {
      const html =
          '<p>Hello</p><img src="https://a.example/x.png"><img src="https://b.example/y.png">';
      expect(extractFirstImageSrc(html), 'https://a.example/x.png');
    });

    test('supports single quotes', () {
      const html = "<img src='https://a.example/x.png'>";
      expect(extractFirstImageSrc(html), 'https://a.example/x.png');
    });

    test('falls back to data-src', () {
      const html = "<img data-src='https://a.example/x.png'>";
      expect(extractFirstImageSrc(html), 'https://a.example/x.png');
    });

    test('is case-insensitive', () {
      const html = '<IMG SRC="https://a.example/x.png">';
      expect(extractFirstImageSrc(html), 'https://a.example/x.png');
    });
  });
}
