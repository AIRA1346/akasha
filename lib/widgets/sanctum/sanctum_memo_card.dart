import 'package:flutter/material.dart';

import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../theme/akasha_colors.dart';
import '../../theme/akasha_radius.dart';
import 'sanctum_wiki_inline_text.dart';

/// Sanctum 미리보기 — `# 📝 메모` 감상 카드.
class SanctumMemoCard extends StatelessWidget {
  const SanctumMemoCard({
    super.key,
    required this.content,
    this.mdFilePath,
    this.userCatalog,
    this.onWikiLinkTap,
  });

  final String content;
  final String? mdFilePath;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '메모가 비어 있습니다.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AkashaColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.55,
      color: AkashaColors.textPrimary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface.withValues(alpha: 0.5),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: SanctumWikiParagraphs(
          content: trimmed,
          mdFilePath: mdFilePath,
          userCatalog: userCatalog,
          onWikiLinkTap: onWikiLinkTap,
          style: bodyStyle,
        ),
      ),
    );
  }
}
