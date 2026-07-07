import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/archiving/canvas_record.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/safe_local_image.dart';

class CanvasNodeCard extends StatelessWidget {
  const CanvasNodeCard({
    super.key,
    required this.node,
    required this.localItems,
    required this.entities,
    required this.vaultPath,
    required this.palette,
    required this.onEdit,
    required this.onDelete,
  });

  final CanvasNode node;
  final List<AkashaItem> localItems;
  final List<EntityJournalEntry> entities;
  final String vaultPath;
  final AkashaPalette palette;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Determine card dimensions (preferring layout.json width/height, falling back to defaults)
    final double width = node.width ?? (node.kind == 'text' ? 250.0 : 260.0);
    final double height = node.height ?? (node.kind == 'text' ? 100.0 : 90.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AkashaRadius.md),
        border: Border.all(color: _getAccentColor(palette).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AkashaRadius.md),
        child: node.kind == 'text'
            ? _buildTextCard(context)
            : _buildArchiveCard(context, width, height),
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AkashaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt_outlined, size: 14, color: palette.accent),
                  const SizedBox(width: AkashaSpacing.xs),
                  Text(
                    '메모',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined, size: 14, color: AkashaColors.textSecondary),
                  ),
                  const SizedBox(width: AkashaSpacing.sm),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AkashaSpacing.xs),
          Expanded(
            child: Text(
              node.text ?? '',
              style: AkashaTypography.body.copyWith(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, double cardWidth, double cardHeight) {
    final String label;
    final String title;
    final String subtitle;
    final IconData fallbackIcon;
    final Color accentColor = _getAccentColor(palette);
    final String? posterPath;
    final AkashaItem? matchedWork;

    if (node.kind == 'work') {
      label = '작품';
      final matching = localItems.where((w) => w.workId == node.workId);
      final work = matching.isNotEmpty ? matching.first : null;
      matchedWork = work;
      title = work != null ? work.title : '[Missing work: ${node.workId}]';
      subtitle = work != null ? work.creator : 'Unknown';
      fallbackIcon = Icons.movie_filter_outlined;
      posterPath = work?.posterPath;
    } else if (node.kind == 'entity') {
      matchedWork = null;
      final matching = entities.where((e) => e.entityId == node.entityId);
      final entity = matching.isNotEmpty ? matching.first : null;
      label = entity != null ? _labelForEntityType(entity.entityType) : '엔티티';
      title = entity != null ? entity.title : '[Missing entity: ${node.entityId}]';
      subtitle = entity != null ? entity.tags.join(', ') : 'Unknown';
      fallbackIcon = entity != null ? _iconForEntityType(entity.entityType) : Icons.person_outline;
      posterPath = entity?.posterPath;
    } else {
      matchedWork = null;
      label = '레코드';
      title = '[Missing node: ${node.nodeId}]';
      subtitle = '';
      fallbackIcon = Icons.warning_amber_outlined;
      posterPath = null;
    }

    final isMissing = (node.kind == 'work' && matchedWork == null) ||
        (node.kind == 'entity' && entities.where((e) => e.entityId == node.entityId).isEmpty);

    // Left Column Visual Box Widget
    final Widget leftVisualBox = SizedBox(
      width: 60,
      height: double.infinity,
      child: isMissing
          ? _buildPlaceholderBox(Icons.warning_amber_outlined, const [Color(0xFF374151), Color(0xFF4B5563)])
          : _buildLeftImage(posterPath, matchedWork, fallbackIcon, accentColor),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        leftVisualBox,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AkashaSpacing.sm,
              vertical: AkashaSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isMissing ? Colors.redAccent : accentColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AkashaTypography.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: AkashaColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftImage(
    String? path,
    AkashaItem? matchedWork,
    IconData fallbackIcon,
    Color accentColor,
  ) {
    // Fallback placeholder container
    final placeholder = _buildPlaceholderBox(
      fallbackIcon,
      node.kind == 'work'
          ? const [Color(0xFF1E1E2F), Color(0xFF2E2E42)]
          : const [Color(0xFF132A13), Color(0xFF3F5E3D)],
    );

    if (node.kind == 'work' && matchedWork != null) {
      // Reuse PosterImage which handles caching and loading states
      return PosterImage(
        item: matchedWork,
        fit: BoxFit.cover,
      );
    }

    // Entity avatar loading using SafeLocalImage asynchronously
    if (path == null || path.isEmpty) {
      return placeholder;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Direct network image call using standard user-agent header
      return Image.network(
        path,
        fit: BoxFit.cover,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    // Resolve local path relative to vault path without synchronous blocking
    final String resolvedPath = (path.startsWith('/') || path.contains(':\\') || path.contains(':/'))
        ? path
        : '$vaultPath/$path';

    return SafeLocalImage(
      file: File(resolvedPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildPlaceholderBox(IconData icon, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Color _getAccentColor(AkashaPalette palette) {
    if (node.kind == 'work') return palette.accent;
    if (node.kind == 'entity') return Colors.tealAccent;
    return palette.accent;
  }

  String _labelForEntityType(EntityAnchorType type) => switch (type) {
        EntityAnchorType.person => '인물',
        EntityAnchorType.concept => '개념',
        EntityAnchorType.event => '사건',
        EntityAnchorType.place => '장소',
        EntityAnchorType.organization => '조직',
        _ => '엔티티',
      };

  IconData _iconForEntityType(EntityAnchorType type) => switch (type) {
        EntityAnchorType.person => Icons.person_outline,
        EntityAnchorType.concept => Icons.lightbulb_outline,
        EntityAnchorType.event => Icons.event_outlined,
        EntityAnchorType.place => Icons.place_outlined,
        EntityAnchorType.organization => Icons.groups_outlined,
        _ => Icons.category_outlined,
      };
}
