class UnicodeHelper {
  const UnicodeHelper._();

  /// Converts Unicode NFD (decomposed Hangul jamo) to NFC (composed Hangul syllables).
  ///
  /// This implementation requires zero external package dependencies.
  static String toNfc(String input) {
    if (input.isEmpty) return input;

    final runes = input.runes.toList();
    final buffer = StringBuffer();
    final len = runes.length;
    var i = 0;

    while (i < len) {
      final code = runes[i];

      // Check if current rune is Hangul Choseong (초성: 0x1100 ~ 0x1112)
      if (code >= 0x1100 && code <= 0x1112) {
        final choseongIdx = code - 0x1100;

        // Check if next rune is Jungseong (중성: 0x1161 ~ 0x1175)
        if (i + 1 < len && runes[i + 1] >= 0x1161 && runes[i + 1] <= 0x1175) {
          final jungseongIdx = runes[i + 1] - 0x1161;
          var jongseongIdx = 0;
          var advance = 2;

          // Check if next next rune is Jongseong (종성: 0x11A8 ~ 0x11C2)
          if (i + 2 < len && runes[i + 2] >= 0x11A8 && runes[i + 2] <= 0x11C2) {
            jongseongIdx = runes[i + 2] - 0x11A7; // 1 to 27
            advance = 3;
          }

          // Compose Hangul Syllable
          final composedCode =
              0xAC00 + (choseongIdx * 588) + (jungseongIdx * 28) + jongseongIdx;
          buffer.writeCharCode(composedCode);
          i += advance;
          continue;
        }
      }

      // Write unmodified rune
      buffer.writeCharCode(code);
      i++;
    }

    return buffer.toString();
  }
}
