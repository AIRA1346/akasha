import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../theme/akasha_colors.dart';
import '../../theme/akasha_radius.dart';
import 'sanctum_wiki_inline_text.dart';

/// Sanctum 미리보기 — 명장면·명대사 인용 카드.
class SanctumQuoteCards extends StatelessWidget {
  const SanctumQuoteCards({
    super.key,
    required this.content,
    this.userCatalog,
    this.onWikiLinkTap,
  });

  final String content;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;

  static List<String> parseQuotes(String content) {
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
    return quotes;
  }

  @override
  Widget build(BuildContext context) {
    final quotes = parseQuotes(content);
    if (quotes.isEmpty) return const SizedBox.shrink();

    final quoteStyle = TextStyle(
      fontSize: 14,
      height: 1.55,
      fontStyle: FontStyle.italic,
      color: Colors.tealAccent.withValues(alpha: 0.9),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < quotes.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AkashaColors.surface.withValues(alpha: 0.45),
              borderRadius: AkashaRadius.mdBorder,
              border: Border.all(color: AkashaColors.borderSubtle(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: Colors.tealAccent.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '명대사',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AkashaColors.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SanctumWikiInlineText(
                    text: quotes[i],
                    userCatalog: userCatalog,
                    onWikiLinkTap: onWikiLinkTap,
                    style: quoteStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
