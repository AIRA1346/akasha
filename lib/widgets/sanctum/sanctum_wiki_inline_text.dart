import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/sanctum_gallery_entry.dart';
import 'entity_wiki_chip.dart';
import 'sanctum_vault_image.dart';
import '../../theme/akasha_colors.dart';

/// 본문 텍스트의 `[[entityId|Title]]` 토큰을 인라인 칩으로 렌더.
class SanctumWikiInlineText extends StatelessWidget {
  const SanctumWikiInlineText({
    super.key,
    required this.text,
    this.userCatalog,
    this.onWikiLinkTap,
    this.style,
  });

  final String text;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final TextStyle? style;

  static final _wikiPattern = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        TextStyle(
          fontSize: 14,
          height: 1.55,
          color: AkashaColors.textPrimary,
        );

    if (!_wikiPattern.hasMatch(text)) {
      return Text(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in _wikiPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final entityId = match.group(1)!.trim();
      final label = match.group(2)?.trim();
      final title = label != null && label.isNotEmpty ? label : entityId;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: EntityWikiChip(
            entityId: entityId,
            title: title,
            userCatalog: userCatalog,
            onTap: onWikiLinkTap,
          ),
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

/// 문단 단위 wiki·이미지 인라인 (빈 줄로 구분).
class SanctumWikiParagraphs extends StatelessWidget {
  const SanctumWikiParagraphs({
    super.key,
    required this.content,
    this.mdFilePath,
    this.userCatalog,
    this.onWikiLinkTap,
    this.style,
  });

  final String content;
  final String? mdFilePath;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final paragraphs = trimmed.split(RegExp(r'\n{2,}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SanctumProseBlock(
            content: paragraphs[i],
            mdFilePath: mdFilePath,
            userCatalog: userCatalog,
            onWikiLinkTap: onWikiLinkTap,
            style: style,
          ),
        ],
      ],
    );
  }
}

/// 단일 문단 — 이미지 줄·wiki 텍스트 혼합.
class SanctumProseBlock extends StatelessWidget {
  const SanctumProseBlock({
    super.key,
    required this.content,
    this.mdFilePath,
    this.userCatalog,
    this.onWikiLinkTap,
    this.style,
  });

  final String content;
  final String? mdFilePath;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final image = SanctumGalleryFormat.parseInlineImageLine(line);
      if (image != null) {
        children.add(SanctumVaultImage(
          src: image.imagePath,
          mdFilePath: mdFilePath,
          caption: image.caption,
        ));
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 6));
        }
        continue;
      }

      children.add(SanctumWikiInlineText(
        text: line,
        userCatalog: userCatalog,
        onWikiLinkTap: onWikiLinkTap,
        style: style,
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
