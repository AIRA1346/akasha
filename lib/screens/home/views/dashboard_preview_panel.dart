import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/work_related_characters.dart';
import '../../../widgets/poster_image.dart';

class DashboardPreviewPanel extends StatelessWidget {
  const DashboardPreviewPanel({
    super.key,
    required this.item,
    required this.userCatalog,
    required this.onClose,
    required this.onOpenDetail,
    this.onOpenEntity,
  });

  final AkashaItem item;
  final UserCatalogPort userCatalog;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final characters = item is EntityItem
        ? const <UserCatalogEntity>[]
        : relatedCharactersForWork(work: item, catalog: userCatalog);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                Text(
                  item.category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.grey[500],
                  onPressed: onClose,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 180,
                        height: 260,
                        child: PosterImage(
                          item: item,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.creator.isNotEmpty ? item.creator : '작자 미상',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.releaseYear ?? '연도 미상'} · ${item.category.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onOpenDetail,
                          style: FilledButton.styleFrom(
                            backgroundColor: AkashaColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '상세 정보 >',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildInfoRow('장르', item.category.name),
                  _buildInfoRow('원작', item.creator.isNotEmpty ? item.creator : '정보 없음'),
                  _buildInfoRow('평점', item.rating > 0 ? '${item.rating} / 10.0' : '평가 없음'),
                  const SizedBox(height: 24),
                  if (characters.isNotEmpty) ...[
                    const Text(
                      '주요 인물',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCharacterRow(characters),
                    const SizedBox(height: 24),
                  ],
                  if (item.tags.isNotEmpty) ...[
                    const Text(
                      '관련 개념',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterRow(List<UserCatalogEntity> characters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: characters.map((person) {
          final avatarItem = EntityItem(
            entityType: EntityAnchorType.person,
            entityId: person.entityId,
            title: person.title,
            category: person.subtype,
            domain: person.domain,
            creator: person.creator,
            releaseYear: person.releaseYear,
            posterPath: person.posterPath,
            tags: person.tags,
            addedAt: person.addedAt,
          );

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: onOpenEntity == null ? null : () => onOpenEntity!(person),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                child: Column(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
