/// Sanctum vault 본문 — 슬롯 섹션 merge·round-trip
class MarkdownBodyMerger {
  MarkdownBodyMerger._();

  static const synopsisHeading = '# 📋 시놉시스';
  static const quotesHeading = '# 🎬 명장면 & 명대사';
  static const memoHeading = '# 📝 메모';

  /// `# …` 헤딩이 앱 슬롯인지 판별
  ///
  /// 부분 문자열 `메모`만으로는 판별하지 않습니다 (`# 🎵 OST 메모` 등 커스텀 보호).
  static MarkdownSlotKind? slotKindForHeadingLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('# ')) return null;
    final heading = trimmed.substring(2).toLowerCase();

    if (heading.contains('명대사') ||
        heading.contains('명장면') ||
        heading.contains('quote')) {
      return MarkdownSlotKind.quotes;
    }
    if (heading.contains('시놉') || heading.contains('synopsis')) {
      return MarkdownSlotKind.synopsis;
    }
    if (heading.contains('📝') ||
        heading == '메모' ||
        heading == 'memo' ||
        heading.contains('감상문') ||
        heading.contains('review')) {
      return MarkdownSlotKind.memo;
    }
    return null;
  }

  /// 슬롯 필드를 [bodyRaw]에 merge. 커스텀 섹션·순서 유지.
  static String mergeBody({
    required String bodyRaw,
    required String synopsis,
    required List<String> quotes,
    required String memo,
  }) {
    final sections = _parseSections(bodyRaw);
    final foundSlots = <MarkdownSlotKind>{};

    for (final section in sections) {
      if (section.slotKind == null) continue;
      foundSlots.add(section.slotKind!);
      section.content = _formatSlotContent(
        section.slotKind!,
        synopsis: synopsis,
        quotes: quotes,
        memo: memo,
      );
    }

    final buffer = StringBuffer();
    for (final section in sections) {
      if (section.headingLine != null) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln(section.headingLine);
      }
      final content = section.content.trimRight();
      if (content.isNotEmpty) {
        buffer.writeln(content);
      }
    }

    final trailing = <_BodySection>[];
    if (!foundSlots.contains(MarkdownSlotKind.synopsis) &&
        synopsis.trim().isNotEmpty) {
      trailing.add(_BodySection(
        headingLine: synopsisHeading,
        content: synopsis.trim(),
        slotKind: MarkdownSlotKind.synopsis,
      ));
    }
    if (!foundSlots.contains(MarkdownSlotKind.quotes) && quotes.isNotEmpty) {
      trailing.add(_BodySection(
        headingLine: quotesHeading,
        content: _formatQuotes(quotes),
        slotKind: MarkdownSlotKind.quotes,
      ));
    }
    if (!foundSlots.contains(MarkdownSlotKind.memo) && memo.trim().isNotEmpty) {
      trailing.add(_BodySection(
        headingLine: memoHeading,
        content: memo.trim(),
        slotKind: MarkdownSlotKind.memo,
      ));
    }

    if (trailing.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      for (var i = 0; i < trailing.length; i++) {
        if (i > 0) buffer.writeln();
        final section = trailing[i];
        buffer.writeln(section.headingLine);
        buffer.writeln(section.content.trimRight());
      }
    }

    return buffer.toString().trimRight();
  }

  /// 슬롯만으로 기본 본문 생성 (신규 아카이브)
  static String buildDefaultBody({
    required String synopsis,
    required List<String> quotes,
    required String memo,
  }) =>
      mergeBody(
        bodyRaw: '',
        synopsis: synopsis,
        quotes: quotes,
        memo: memo,
      );

  static String _formatSlotContent(
    MarkdownSlotKind kind, {
    required String synopsis,
    required List<String> quotes,
    required String memo,
  }) {
    switch (kind) {
      case MarkdownSlotKind.synopsis:
        return synopsis.trim();
      case MarkdownSlotKind.quotes:
        return _formatQuotes(quotes);
      case MarkdownSlotKind.memo:
        return memo.trim();
    }
  }

  static String _formatQuotes(List<String> quotes) {
    final buffer = StringBuffer();
    for (final quote in quotes) {
      final trimmed = quote.trim();
      if (trimmed.isEmpty) continue;
      final line = trimmed.startsWith('>') ? trimmed : '> $trimmed';
      buffer.writeln(line);
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  static List<_BodySection> _parseSections(String bodyRaw) {
    final lines = bodyRaw.split('\n');
    final sections = <_BodySection>[];
    String? currentHeading;
    MarkdownSlotKind? currentSlot;
    final contentBuffer = StringBuffer();

    void flush() {
      sections.add(_BodySection(
        headingLine: currentHeading,
        content: contentBuffer.toString(),
        slotKind: currentSlot,
      ));
      contentBuffer.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        if (currentHeading != null || contentBuffer.isNotEmpty) {
          flush();
        }
        currentHeading = trimmed;
        currentSlot = slotKindForHeadingLine(trimmed);
        continue;
      }
      contentBuffer.writeln(line);
    }

    if (currentHeading != null || contentBuffer.toString().trim().isNotEmpty) {
      flush();
    }

    if (sections.isEmpty && bodyRaw.trim().isEmpty) {
      return [];
    }

    return sections;
  }

  /// 본문에서 슬롯 필드 추출 (deserialize용)
  static ({String synopsis, List<String> quotes, String memo}) parseSlots(
    String bodyRaw,
  ) {
    final sections = _parseSections(bodyRaw);
    var synopsis = '';
    final quotes = <String>[];
    var memo = '';

    for (final section in sections) {
      switch (section.slotKind) {
        case MarkdownSlotKind.synopsis:
          synopsis = section.content.trim();
        case MarkdownSlotKind.memo:
          memo = section.content.trim();
        case MarkdownSlotKind.quotes:
          for (final line in section.content.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            if (trimmed.startsWith('>')) {
              final quote = trimmed.substring(1).trim();
              if (quote.isNotEmpty) quotes.add(quote);
            } else if (!trimmed.startsWith('#') && !trimmed.startsWith('---')) {
              quotes.add(trimmed);
            }
          }
        case null:
          break;
      }
    }

    return (synopsis: synopsis, quotes: quotes, memo: memo);
  }
}

enum MarkdownSlotKind { synopsis, quotes, memo }

class _BodySection {
  final String? headingLine;
  String content;
  final MarkdownSlotKind? slotKind;

  _BodySection({
    required this.headingLine,
    required this.content,
    required this.slotKind,
  });
}
