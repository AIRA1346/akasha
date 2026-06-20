import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/entity_browse_card.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';

/// Entity gallery collectible card — Phase 1 (Person · Concept · …).
class EntityCollectibleCard extends StatefulWidget {
  const EntityCollectibleCard({
    super.key,
    required this.card,
    required this.onTap,
    this.highlighted = false,
  });

  final EntityBrowseCard card;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<EntityCollectibleCard> createState() => _EntityCollectibleCardState();
}

class _EntityCollectibleCardState extends State<EntityCollectibleCard> {
  var _isHovered = false;

  static const double _borderWidthIdle = 1.0;
  static const double _borderWidthHighlight = 1.5;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final entity = card.entity;
    final alias = entity.aliases.isNotEmpty ? entity.aliases.first : null;

    final cardBody = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.highlighted
                ? Colors.tealAccent
                : Colors.white.withValues(alpha: 0.12),
            width: widget.highlighted ? _borderWidthHighlight : _borderWidthIdle,
          ),
          boxShadow: _cardShadows(hovered: _isHovered),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(entity.anchorType, card.isArchived),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (alias != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        alias,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (card.bodyPreview.isNotEmpty)
                      Expanded(
                        child: Text(
                          card.bodyPreview,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          '(메모 없음)',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    if (card.incomingRecordCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🔗 연결 ${card.incomingRecordCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: cardBody,
    );
  }

  List<BoxShadow> _cardShadows({required bool hovered}) {
    final depth = BoxShadow(
      color: Colors.black.withValues(alpha: hovered ? 0.32 : 0.28),
      blurRadius: 8,
      offset: Offset(0, hovered ? 4 : 3),
    );
    if (hovered) {
      return [
        depth,
        BoxShadow(
          color: Colors.tealAccent.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      depth,
      BoxShadow(
        color: Colors.tealAccent.withValues(alpha: 0.08),
        blurRadius: 10,
      ),
    ];
  }

  Widget _buildHeader(EntityAnchorType type, bool archived) {
    return SizedBox(
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.tealAccent.withValues(alpha: 0.38),
                  const Color(0xFF252536),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    iconForEntityAnchorType(type),
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entityTypeBadgeLabel(type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (archived) _buildArchivedBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedBadge() {
    return Tooltip(
      message: 'entity journal 아카이브됨',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Icon(
          Icons.description_outlined,
          size: 13,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}

/// Shared icon map for entity gallery cards.
IconData iconForEntityAnchorType(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => Icons.person_outline,
    EntityAnchorType.concept => Icons.lightbulb_outline,
    EntityAnchorType.event => Icons.event_outlined,
    EntityAnchorType.place => Icons.place_outlined,
    EntityAnchorType.organization => Icons.groups_outlined,
    _ => Icons.category_outlined,
  };
}
