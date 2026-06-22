import '../core/archiving/entity_anchor.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';

/// 작품과 태그·제목이 겹치는 인물 엔티티를 우선순위로 반환합니다.
List<UserCatalogEntity> relatedCharactersForWork({
  required AkashaItem work,
  required UserCatalogPort catalog,
  int limit = 4,
}) {
  if (work is EntityItem) return const [];

  final workTags = work.tags.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toSet();
  final workTitle = work.title.trim().toLowerCase();

  final scored = <({UserCatalogEntity entity, int score})>[];

  for (final person in catalog.all) {
    if (person.anchorType != EntityAnchorType.person) continue;

    var score = 0;
    for (final tag in person.tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (workTags.contains(normalized)) score += 2;
      if (workTitle.isNotEmpty && normalized.contains(workTitle)) score += 3;
    }

    for (final alias in person.aliases) {
      final normalized = alias.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (workTags.contains(normalized)) score += 1;
    }

    if (workTitle.isNotEmpty && person.title.trim().toLowerCase() == workTitle) {
      score += 1;
    }

    if (score > 0) {
      scored.add((entity: person, score: score));
    }
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return b.entity.addedAt.compareTo(a.entity.addedAt);
  });

  return scored.take(limit).map((e) => e.entity).toList();
}
