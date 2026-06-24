import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/entity_browse_card.dart';
import 'poster_card.dart';

/// Entity gallery collectible card — Phase 1 (Person · Concept · …).
/// Delegates all layout and styles to the unified PosterCard widget for absolute parity.
class EntityCollectibleCard extends StatelessWidget {
  const EntityCollectibleCard({
    super.key,
    required this.card,
    required this.onTap,
    this.highlighted = false,
    this.showPoster = true,
  });

  final EntityBrowseCard card;
  final VoidCallback onTap;
  final bool highlighted;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    final entity = card.entity;
    final journal = card.journal;

    final entityItem = EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: journal?.posterPath ?? entity.posterPath,
      tags: List<String>.from(journal?.tags ?? entity.tags),
      addedAt: journal?.addedAt ?? entity.addedAt,
    );

    return PosterCard(
      item: entityItem,
      showPoster: showPoster,
      highlighted: highlighted,
      incomingRecordCount: card.incomingRecordCount,
      onTap: onTap,
    );
  }
}
