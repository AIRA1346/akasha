import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/utils/unicode_helper.dart';

void main() {
  group('UnicodeHelper NFC/NFD composed Hangul test', () {
    test('NFC Composed Hangul is preserved untouched', () {
      expect(UnicodeHelper.toNfc('렘'), equals('렘'));
      expect(UnicodeHelper.toNfc('람'), equals('람'));
      expect(UnicodeHelper.toNfc('아카샤'), equals('아카샤'));
      expect(UnicodeHelper.toNfc('Stay Alive (타카하시 리에)'), equals('Stay Alive (타카하시 리에)'));
    });

    test('NFD Decomposed Hangul (macOS) is correctly composed to NFC (Windows)', () {
      // "렘" -> ㄹ(0x1105) + ㅔ(0x1166) + ㅁ(0x11B7)
      final nfdRem = String.fromCharCodes([0x1105, 0x1166, 0x11B7]);
      expect(UnicodeHelper.toNfc(nfdRem), equals('렘'));

      // "람" -> ㄹ(0x1105) + ㅏ(0x1161) + ㅁ(0x11B7)
      final nfdRam = String.fromCharCodes([0x1105, 0x1161, 0x11B7]);
      expect(UnicodeHelper.toNfc(nfdRam), equals('람'));

      // "아카샤" -> ㅇ(0x110B) + ㅏ(0x1161), ㅋ(0x110F) + ㅏ(0x1161), ㅅ(0x1109) + ㅑ(0x1163)
      final nfdAkasha = String.fromCharCodes([
        0x110B, 0x1161, // 아
        0x110F, 0x1161, // 카
        0x1109, 0x1163  // 샤
      ]);
      expect(UnicodeHelper.toNfc(nfdAkasha), equals('아카샤'));
    });

    test('Non-Hangul English, numeric, and symbols stay unmodified', () {
      expect(UnicodeHelper.toNfc(''), equals(''));
      expect(UnicodeHelper.toNfc('Elon Musk 123!'), equals('Elon Musk 123!'));
      expect(UnicodeHelper.toNfc('---'), equals('---'));
    });
  });
}
