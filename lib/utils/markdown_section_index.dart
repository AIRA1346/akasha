import '../services/markdown_body_merger.dart';

/// 본문 `# ` 헤딩 목차 (섹션 점프용).
class MarkdownSectionEntry {
  const MarkdownSectionEntry({
    required this.headingLine,
    required this.label,
    required this.charOffset,
    required this.lineNumber,
    this.slotKind,
  });

  final String headingLine;
  final String label;
  final int charOffset;
  final int lineNumber;
  final MarkdownSlotKind? slotKind;
}

class MarkdownSectionIndex {
  MarkdownSectionIndex._();

  static List<MarkdownSectionEntry> parseHeadings(String text) {
    final entries = <MarkdownSectionEntry>[];
    var offset = 0;
    var lineNumber = 1;
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        final label = trimmed.substring(2).trim();
        entries.add(MarkdownSectionEntry(
          headingLine: trimmed,
          label: label.isEmpty ? '섹션' : label,
          charOffset: offset + line.indexOf(trimmed),
          lineNumber: lineNumber,
          slotKind: MarkdownBodyMerger.slotKindForHeadingLine(trimmed),
        ));
      }
      offset += line.length + 1;
      lineNumber++;
    }
    return entries;
  }

  static int lineNumberAtOffset(String text, int offset) {
    if (text.isEmpty || offset <= 0) return 1;
    final clamped = offset.clamp(0, text.length);
    return '\n'.allMatches(text.substring(0, clamped)).length + 1;
  }

  static MarkdownSectionEntry? sectionAtOffset(
    String text,
    int offset,
  ) {
    final headings = parseHeadings(text);
    if (headings.isEmpty) return null;
    MarkdownSectionEntry? current;
    for (final h in headings) {
      if (h.charOffset <= offset) {
        current = h;
      } else {
        break;
      }
    }
    return current;
  }

  static String sectionLabelAtOffset(String text, int offset) {
    return sectionAtOffset(text, offset)?.label ?? '본문';
  }
}
