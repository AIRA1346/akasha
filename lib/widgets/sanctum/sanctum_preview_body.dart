import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/sanctum_cast_entry.dart';
import '../../models/sanctum_gallery_entry.dart';
import '../../models/user_catalog_entity.dart';
import 'sanctum_cast_strip.dart';
import 'sanctum_gallery_strip.dart';
import 'sanctum_memo_card.dart';
import 'sanctum_quote_cards.dart';
import 'sanctum_wiki_inline_text.dart';
import '../../theme/akasha_colors.dart';

/// 슬롯 인지 Sanctum 미리보기 — 출연·갤러리 스트립 + wiki 칩 인라인 본문.
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
          style: TextStyle(fontSize: 13, color: AkashaColors.textMuted, height: 1.5),
        ),
      );
    }

    if (!slotAware) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SanctumWikiParagraphs(
          content: data,
          mdFilePath: mdFilePath,
          userCatalog: userCatalog,
          onWikiLinkTap: onWikiLinkTap,
          style: TextStyle(fontSize: 14, height: 1.55, color: AkashaColors.textPrimary),
        ),
      );
    }

    final parsed = _parsePreviewSections(data);
    final bodyStyle =
        TextStyle(fontSize: 14, height: 1.55, color: AkashaColors.textPrimary);

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
        if (parsed.gallery.isNotEmpty)
          SanctumGalleryStrip(
            entries: parsed.gallery,
            mdFilePath: mdFilePath,
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
                ? SanctumQuoteCards(
                    content: section.content,
                    userCatalog: userCatalog,
                    onWikiLinkTap: onWikiLinkTap,
                  )
                : section.kind == _PreviewSectionKind.memo
                    ? SanctumMemoCard(
                        content: section.content,
                        mdFilePath: mdFilePath,
                        userCatalog: userCatalog,
                        onWikiLinkTap: onWikiLinkTap,
                      )
                    : SanctumWikiParagraphs(
                    content: section.content,
                    mdFilePath: mdFilePath,
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

enum _PreviewSectionKind { prose, quotes, cast, gallery, memo }

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
    required this.gallery,
    required this.sections,
  });

  final List<SanctumCastEntry> cast;
  final List<SanctumGalleryEntry> gallery;
  final List<_PreviewSection> sections;
}

_ParsedPreview _parsePreviewSections(String bodyRaw) {
  final lines = bodyRaw.split('\n');
  final sections = <_PreviewSection>[];
  final castEntries = <SanctumCastEntry>[];
  final galleryEntries = <SanctumGalleryEntry>[];

  String? currentHeading;
  _PreviewSectionKind currentKind = _PreviewSectionKind.prose;
  final contentLines = <String>[];

  void flush() {
    final content = contentLines.join('\n').trim();
    switch (currentKind) {
      case _PreviewSectionKind.cast:
        castEntries.addAll(SanctumCastFormat.parseBlock(content));
      case _PreviewSectionKind.gallery:
        galleryEntries.addAll(SanctumGalleryFormat.parseBlock(content));
      case _PreviewSectionKind.prose:
      case _PreviewSectionKind.quotes:
      case _PreviewSectionKind.memo:
        if (currentHeading != null || content.isNotEmpty) {
          sections.add(_PreviewSection(
            heading: currentHeading,
            content: content,
            kind: currentKind,
          ));
        }
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

  return _ParsedPreview(
    cast: castEntries,
    gallery: galleryEntries,
    sections: sections,
  );
}

_PreviewSectionKind _kindForHeading(String headingLine) {
  final lower = headingLine.substring(2).toLowerCase();
  if (lower.contains('출연') || lower.contains('cast')) {
    return _PreviewSectionKind.cast;
  }
  if (lower.contains('갤러리') || lower.contains('gallery')) {
    return _PreviewSectionKind.gallery;
  }
  if (lower.contains('명대사') ||
      lower.contains('명장면') ||
      lower.contains('quote')) {
    return _PreviewSectionKind.quotes;
  }
  if ((lower.contains('📝') ||
          lower.contains('메모') ||
          lower.contains('memo') ||
          lower.contains('감상')) &&
      !lower.contains('ost')) {
    return _PreviewSectionKind.memo;
  }
  return _PreviewSectionKind.prose;
}
