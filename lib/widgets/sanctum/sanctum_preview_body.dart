import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/sanctum_cast_entry.dart';
import '../../models/user_catalog_entity.dart';
import 'sanctum_cast_strip.dart';
import 'sanctum_wiki_inline_text.dart';

/// 슬롯 인지 Sanctum 미리보기 — 출연 스트립 + wiki 칩 인라인 본문.
class SanctumPreviewBody extends StatelessWidget {
  const SanctumPreviewBody({
    super.key,
    required this.data,
    this.mdFilePath,
    this.userCatalog,
    this.onWikiLinkTap,
    this.onOpenEntity,
    this.slotAware = true,
  });

  final String data;
  final String? mdFilePath;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final bool slotAware;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'Sanctum 페이지가 비어 있습니다.\n'
          '「본문」 또는 「.md」 탭에서 감상·메모를 작성해 보세요.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
        ),
      );
    }

    if (!slotAware) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SanctumWikiParagraphs(
          content: data,
          userCatalog: userCatalog,
          onWikiLinkTap: onWikiLinkTap,
          style: TextStyle(fontSize: 14, height: 1.55, color: Colors.grey[200]),
        ),
      );
    }

    final parsed = _parsePreviewSections(data);
    final bodyStyle =
        TextStyle(fontSize: 14, height: 1.55, color: Colors.grey[200]);
    final quoteStyle = TextStyle(
      fontSize: 14,
      height: 1.5,
      fontStyle: FontStyle.italic,
      color: Colors.tealAccent.withValues(alpha: 0.85),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parsed.cast.isNotEmpty)
          SanctumCastStrip(
            cast: parsed.cast,
            userCatalog: userCatalog,
            onWikiLinkTap: onWikiLinkTap,
            onOpenEntity: onOpenEntity,
          ),
        for (final section in parsed.sections) ...[
          if (section.heading != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Text(
                _displayHeading(section.heading!),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: section.kind == _PreviewSectionKind.quotes
                ? _QuoteBlocks(
                    content: section.content,
                    userCatalog: userCatalog,
                    onWikiLinkTap: onWikiLinkTap,
                    style: quoteStyle,
                  )
                : SanctumWikiParagraphs(
                    content: section.content,
                    userCatalog: userCatalog,
                    onWikiLinkTap: onWikiLinkTap,
                    style: bodyStyle,
                  ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _displayHeading(String raw) {
    var text = raw.trim();
    if (text.startsWith('# ')) text = text.substring(2);
    return text;
  }
}

enum _PreviewSectionKind { prose, quotes, cast }

class _PreviewSection {
  const _PreviewSection({
    this.heading,
    required this.content,
    this.kind = _PreviewSectionKind.prose,
  });

  final String? heading;
  final String content;
  final _PreviewSectionKind kind;
}

class _ParsedPreview {
  const _ParsedPreview({
    required this.cast,
    required this.sections,
  });

  final List<SanctumCastEntry> cast;
  final List<_PreviewSection> sections;
}

_ParsedPreview _parsePreviewSections(String bodyRaw) {
  final lines = bodyRaw.split('\n');
  final sections = <_PreviewSection>[];
  final castEntries = <SanctumCastEntry>[];

  String? currentHeading;
  _PreviewSectionKind currentKind = _PreviewSectionKind.prose;
  final contentLines = <String>[];

  void flush() {
    final content = contentLines.join('\n').trim();
    if (currentKind == _PreviewSectionKind.cast) {
      castEntries.addAll(SanctumCastFormat.parseBlock(content));
    } else if (currentHeading != null || content.isNotEmpty) {
      sections.add(_PreviewSection(
        heading: currentHeading,
        content: content,
        kind: currentKind,
      ));
    }
    contentLines.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('# ')) {
      flush();
      currentHeading = trimmed;
      currentKind = _kindForHeading(trimmed);
      continue;
    }
    contentLines.add(line);
  }
  flush();

  return _ParsedPreview(cast: castEntries, sections: sections);
}

_PreviewSectionKind _kindForHeading(String headingLine) {
  final lower = headingLine.substring(2).toLowerCase();
  if (lower.contains('출연') || lower.contains('cast')) {
    return _PreviewSectionKind.cast;
  }
  if (lower.contains('명대사') ||
      lower.contains('명장면') ||
      lower.contains('quote')) {
    return _PreviewSectionKind.quotes;
  }
  return _PreviewSectionKind.prose;
}

class _QuoteBlocks extends StatelessWidget {
  const _QuoteBlocks({
    required this.content,
    this.userCatalog,
    this.onWikiLinkTap,
    this.style,
  });

  final String content;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final quotes = <String>[];
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('>')) {
        final quote = trimmed.substring(1).trim();
        if (quote.isNotEmpty) quotes.add(quote);
      } else if (!trimmed.startsWith('#')) {
        quotes.add(trimmed);
      }
    }

    if (quotes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < quotes.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.tealAccent.withValues(alpha: 0.4),
                  width: 3,
                ),
              ),
            ),
            child: SanctumWikiInlineText(
              text: quotes[i],
              userCatalog: userCatalog,
              onWikiLinkTap: onWikiLinkTap,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}
