import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import 'entity_wiki_chip.dart';

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
          color: Colors.grey[200],
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

/// 문단 단위 wiki 인라인 (빈 줄로 구분).
class SanctumWikiParagraphs extends StatelessWidget {
  const SanctumWikiParagraphs({
    super.key,
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
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final paragraphs = trimmed.split(RegExp(r'\n{2,}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SanctumWikiInlineText(
            text: paragraphs[i].replaceAll('\n', ' '),
            userCatalog: userCatalog,
            onWikiLinkTap: onWikiLinkTap,
            style: style,
          ),
        ],
      ],
    );
  }
}
