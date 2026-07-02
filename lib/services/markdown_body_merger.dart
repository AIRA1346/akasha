import '../models/sanctum_cast_entry.dart';
import '../models/sanctum_gallery_entry.dart';

class MarkdownSlotHeadings {
  const MarkdownSlotHeadings({
    required this.cast,
    required this.gallery,
    required this.synopsis,
    required this.quotes,
    required this.memo,
  });

  static const fallback = MarkdownSlotHeadings(
    cast: MarkdownBodyMerger.castHeading,
    gallery: MarkdownBodyMerger.galleryHeading,
    synopsis: MarkdownBodyMerger.synopsisHeading,
    quotes: MarkdownBodyMerger.quotesHeading,
    memo: MarkdownBodyMerger.memoHeading,
  );

  factory MarkdownSlotHeadings.fromL10n(dynamic l10n) {
    if (l10n == null) return fallback;
    return MarkdownSlotHeadings(
      cast: '# ${l10n.workbenchCastSectionTitle}',
      gallery: '# ${l10n.workbenchGallerySectionTitle}',
      synopsis: '# ${l10n.workbenchSynopsisSectionTitle}',
      quotes: '# ${l10n.workbenchQuotesSectionTitle}',
      memo: '# ${l10n.workbenchMemoSectionTitle}',
    );
  }

  final String cast;
  final String gallery;
  final String synopsis;
  final String quotes;
  final String memo;
}

/// Sanctum vault 본문 — 슬롯 섹션 merge·round-trip
class MarkdownBodyMerger {
  MarkdownBodyMerger._();

  static const castHeading = '# 👥 출연';
  static const galleryHeading = '# 🖼 갤러리';
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

    if (heading.contains('출연') || heading.contains('cast')) {
      return MarkdownSlotKind.cast;
    }
    if (heading.contains('갤러리') || heading.contains('gallery')) {
      return MarkdownSlotKind.gallery;
    }
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
    List<SanctumCastEntry> cast = const [],
    List<SanctumGalleryEntry> gallery = const [],
    required String synopsis,
    required List<String> quotes,
    required String memo,
    MarkdownSlotHeadings? headings,
  }) {
    final activeHeadings = headings ?? MarkdownSlotHeadings.fallback;
    final sections = _parseSections(bodyRaw);
    final foundSlots = <MarkdownSlotKind>{};

    for (final section in sections) {
      if (section.slotKind == null) continue;
      foundSlots.add(section.slotKind!);
      final formatted = _formatSlotContent(
        section.slotKind!,
        cast: cast,
        gallery: gallery,
        synopsis: synopsis,
        quotes: quotes,
        memo: memo,
      );
      if (_normalizeSlotContent(section.content) ==
              _normalizeSlotContent(formatted) &&
          section.content.isNotEmpty) {
        continue;
      }
      section.content = formatted;
    }

    final buffer = StringBuffer();
    for (final section in sections) {
      if (section.headingLine != null) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln(section.headingLine);
      }
      if (section.content.isNotEmpty) {
        buffer.write(section.content);
        if (!section.content.endsWith('\n')) {
          buffer.writeln();
        }
      }
    }

    final trailing = <_BodySection>[];
    if (!foundSlots.contains(MarkdownSlotKind.cast) && cast.isNotEmpty) {
      trailing.add(
        _BodySection(
          headingLine: activeHeadings.cast,
          content: SanctumCastFormat.formatBlock(cast),
          slotKind: MarkdownSlotKind.cast,
        ),
      );
    }
    if (!foundSlots.contains(MarkdownSlotKind.gallery) && gallery.isNotEmpty) {
      trailing.add(
        _BodySection(
          headingLine: activeHeadings.gallery,
          content: SanctumGalleryFormat.formatBlock(gallery),
          slotKind: MarkdownSlotKind.gallery,
        ),
      );
    }
    if (!foundSlots.contains(MarkdownSlotKind.synopsis) &&
        synopsis.trim().isNotEmpty) {
      trailing.add(
        _BodySection(
          headingLine: activeHeadings.synopsis,
          content: synopsis.trim(),
          slotKind: MarkdownSlotKind.synopsis,
        ),
      );
    }
    if (!foundSlots.contains(MarkdownSlotKind.quotes) && quotes.isNotEmpty) {
      trailing.add(
        _BodySection(
          headingLine: activeHeadings.quotes,
          content: _formatQuotes(quotes),
          slotKind: MarkdownSlotKind.quotes,
        ),
      );
    }
    if (!foundSlots.contains(MarkdownSlotKind.memo) && memo.trim().isNotEmpty) {
      trailing.add(
        _BodySection(
          headingLine: activeHeadings.memo,
          content: memo.trim(),
          slotKind: MarkdownSlotKind.memo,
        ),
      );
    }

    if (trailing.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      for (var i = 0; i < trailing.length; i++) {
        if (i > 0) buffer.writeln();
        final section = trailing[i];
        buffer.writeln(section.headingLine);
        buffer.write(section.content);
        if (!section.content.endsWith('\n')) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  /// 슬롯만으로 기본 본문 생성 (신규 아카이브)
  static String buildDefaultBody({
    List<SanctumCastEntry> cast = const [],
    List<SanctumGalleryEntry> gallery = const [],
    required String synopsis,
    required List<String> quotes,
    required String memo,
    MarkdownSlotHeadings? headings,
  }) => mergeBody(
    bodyRaw: '',
    cast: cast,
    gallery: gallery,
    synopsis: synopsis,
    quotes: quotes,
    memo: memo,
    headings: headings,
  );

  static String _normalizeSlotContent(String content) {
    if (content.isEmpty) return content;
    final lines = content.split('\n');
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n');
  }

  static String _formatSlotContent(
    MarkdownSlotKind kind, {
    required List<SanctumCastEntry> cast,
    required List<SanctumGalleryEntry> gallery,
    required String synopsis,
    required List<String> quotes,
    required String memo,
  }) {
    switch (kind) {
      case MarkdownSlotKind.cast:
        return SanctumCastFormat.formatBlock(cast);
      case MarkdownSlotKind.gallery:
        return SanctumGalleryFormat.formatBlock(gallery);
      case MarkdownSlotKind.synopsis:
        return synopsis;
      case MarkdownSlotKind.quotes:
        return _formatQuotes(quotes);
      case MarkdownSlotKind.memo:
        return memo;
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
    final contentLines = <String>[];

    void flush() {
      sections.add(
        _BodySection(
          headingLine: currentHeading,
          content: contentLines.join('\n'),
          slotKind: currentSlot,
        ),
      );
      contentLines.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        if (currentHeading != null || contentLines.isNotEmpty) {
          flush();
        }
        currentHeading = trimmed;
        currentSlot = slotKindForHeadingLine(trimmed);
        continue;
      }
      contentLines.add(line);
    }

    if (currentHeading != null || contentLines.isNotEmpty) {
      flush();
    }

    if (sections.isEmpty && bodyRaw.trim().isEmpty) {
      return [];
    }

    return sections;
  }

  /// 본문에서 슬롯 필드 추출 (deserialize용)
  static ({
    List<SanctumCastEntry> cast,
    List<SanctumGalleryEntry> gallery,
    String synopsis,
    List<String> quotes,
    String memo,
  })
  parseSlots(String bodyRaw) {
    final sections = _parseSections(bodyRaw);
    final cast = <SanctumCastEntry>[];
    final gallery = <SanctumGalleryEntry>[];
    var synopsis = '';
    final quotes = <String>[];
    var memo = '';

    for (final section in sections) {
      switch (section.slotKind) {
        case MarkdownSlotKind.cast:
          cast.addAll(SanctumCastFormat.parseBlock(section.content));
        case MarkdownSlotKind.gallery:
          gallery.addAll(SanctumGalleryFormat.parseBlock(section.content));
        case MarkdownSlotKind.synopsis:
          synopsis = _normalizeSlotContent(section.content);
        case MarkdownSlotKind.memo:
          memo = _normalizeSlotContent(section.content);
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

    return (
      cast: cast,
      gallery: gallery,
      synopsis: synopsis,
      quotes: quotes,
      memo: memo,
    );
  }
}

enum MarkdownSlotKind { cast, gallery, synopsis, quotes, memo }

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
