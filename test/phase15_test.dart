import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  group('Phase 15 — Web Image Search & Clipboard Detection Tests', () {
    test('isValidImageUrl returns true for valid image URLs and known CDN domains', () {
      // Valid URLs with extensions
      expect(isValidImageUrl('https://example.com/poster.jpg'), isTrue);
      expect(isValidImageUrl('http://example.com/poster.JPEG'), isTrue);
      expect(isValidImageUrl('https://example.com/poster.png?width=400'), isTrue);
      expect(isValidImageUrl('https://example.com/poster.webp'), isTrue);
      expect(isValidImageUrl('https://example.com/poster.gif'), isTrue);

      // Valid CDN domains without extension
      expect(isValidImageUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ'), isTrue);
      expect(isValidImageUrl('https://image.yes24.com/goods/2301053/L'), isTrue);
      expect(isValidImageUrl('https://contents.kyobobook.co.kr/sih/fit-in/458x0/pcontents/isbn/979/9791125618867.jpg'), isTrue);
      expect(isValidImageUrl('https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1245620/library_600x900.jpg'), isTrue);
      expect(isValidImageUrl('https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx67707-srHFl9GBmfig.png'), isTrue);
    });

    test('isValidImageUrl returns false for invalid formats or non-image URLs', () {
      // Not starting with http/https
      expect(isValidImageUrl('example.com/poster.jpg'), isFalse);
      expect(isValidImageUrl('ftp://example.com/poster.jpg'), isFalse);
      
      // Not a valid URL pattern / random text
      expect(isValidImageUrl('hello world'), isFalse);
      expect(isValidImageUrl('C:\\Users\\image.jpg'), isFalse);

      // Too long string
      final longStr = 'https://example.com/${'a' * 2050}.jpg';
      expect(isValidImageUrl(longStr), isFalse);
    });
  });
}
