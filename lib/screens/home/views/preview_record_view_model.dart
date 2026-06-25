import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/works_registry.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_typography.dart';

/// Work·Entity 프리뷰 패널 공통 표시 모델.
class PreviewRecordViewModel {
  const PreviewRecordViewModel({
    required this.typeLabel,
    required this.posterItem,
    required this.heroAspectRatio,
    required this.title,
    this.subtitle,
    required this.metaLine,
    required this.coreInfoRows,
  });

  final String typeLabel;
  final AkashaItem posterItem;
  final double heroAspectRatio;
  final String title;
  final String? subtitle;
  final String metaLine;
  final List<PreviewCoreInfoRow> coreInfoRows;

  factory PreviewRecordViewModel.fromWork(AkashaItem item) {
    return PreviewRecordViewModel(
      typeLabel: item.category.label,
      posterItem: item,
      heroAspectRatio: 16 / 9,
      title: item.title,
      subtitle: _workAlternateTitle(item),
      metaLine: [
        if (item.releaseYear != null) '${item.releaseYear}',
        item.category.label,
        if (item.workStatusLabel.isNotEmpty) item.workStatusLabel,
      ].join(' · '),
      coreInfoRows: _workCoreInfo(item),
    );
  }

  factory PreviewRecordViewModel.fromEntity(UserCatalogEntity entity) {
    final posterItem = EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: entity.posterPath,
      tags: entity.tags,
      addedAt: entity.addedAt,
    );

    return PreviewRecordViewModel(
      typeLabel: entityTypeDisplayLabel(entity.anchorType),
      posterItem: posterItem,
      heroAspectRatio: 1,
      title: entity.title,
      subtitle: _entitySubtitle(entity),
      metaLine: [
        if (entity.releaseYear != null) '${entity.releaseYear}',
        entityTypeDisplayLabel(entity.anchorType),
        entity.domain.label,
      ].join(' · '),
      coreInfoRows: _entityCoreInfo(entity),
    );
  }

  static String? _workAlternateTitle(AkashaItem item) {
    final registry = WorksRegistry.getWorkById(item.workId);
    if (registry == null) return null;
    for (final tag in const ['ja', 'native', 'romaji', 'en']) {
      final title = registry.titles[tag];
      if (title != null && title.isNotEmpty && title != item.title) {
        return title;
      }
    }
    return null;
  }

  static List<PreviewCoreInfoRow> _workCoreInfo(AkashaItem item) {
    final genre =
        item.tags.isNotEmpty ? item.tags.first : item.category.label;
    final registry = WorksRegistry.getWorkById(item.workId);
    var studio = '정보 없음';
    final ext = registry?.extensions;
    if (ext != null) {
      for (final key in const [
        'studio',
        'production',
        'studioName',
        'publisher',
      ]) {
        final value = ext[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          studio = value.toString();
          break;
        }
      }
    }

    return [
      PreviewCoreInfoRow(
        icon: Icons.category_outlined,
        label: '장르',
        value: genre,
      ),
      PreviewCoreInfoRow(
        icon: Icons.auto_stories_outlined,
        label: '원작',
        value: item.creator.isNotEmpty ? item.creator : '정보 없음',
      ),
      PreviewCoreInfoRow(
        icon: Icons.business_outlined,
        label: '제작사',
        value: studio,
      ),
      PreviewCoreInfoRow.rating(item.rating),
    ];
  }

  static String? _entitySubtitle(UserCatalogEntity entity) {
    if (entity.aliases.isNotEmpty) {
      return entity.aliases.join(' · ');
    }
    for (final tag in const ['ja', 'native', 'romaji', 'en']) {
      final title = entity.titles[tag];
      if (title != null && title.isNotEmpty && title != entity.title) {
        return title;
      }
    }
    return null;
  }

  static List<PreviewCoreInfoRow> _entityCoreInfo(UserCatalogEntity entity) {
    return [
      PreviewCoreInfoRow(
        icon: Icons.label_outline,
        label: '유형',
        value: entityTypeDisplayLabel(entity.anchorType),
      ),
      PreviewCoreInfoRow(
        icon: Icons.badge_outlined,
        label: '별칭',
        value: entity.aliases.isNotEmpty
            ? entity.aliases.take(3).join(', ')
            : '정보 없음',
      ),
      PreviewCoreInfoRow(
        icon: Icons.public_outlined,
        label: '도메인',
        value: entity.domain.label,
      ),
      PreviewCoreInfoRow(
        icon: Icons.local_offer_outlined,
        label: '태그',
        value: entity.tags.isNotEmpty
            ? entity.tags.take(3).join(', ')
            : '정보 없음',
      ),
    ];
  }
}

class PreviewCoreInfoRow {
  const PreviewCoreInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  factory PreviewCoreInfoRow.rating(double rating) {
    return PreviewCoreInfoRow(
      icon: Icons.star_rounded,
      label: '평점',
      valueWidget: rating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: AkashaColors.statusWarning),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: AkashaTypography.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AkashaColors.textPrimary,
                  ),
                ),
                Text(' / 10', style: AkashaTypography.caption),
              ],
            )
          : Text('평가 없음', style: AkashaTypography.bodySecondary),
    );
  }

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
}

String entityTypeDisplayLabel(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.work => '작품',
    EntityAnchorType.person => '인물',
    EntityAnchorType.concept => '개념',
    EntityAnchorType.event => '사건',
    EntityAnchorType.place => '장소',
    EntityAnchorType.organization => '조직',
    EntityAnchorType.custom => '사용자',
    EntityAnchorType.phenomenon => '레거시',
  };
}
