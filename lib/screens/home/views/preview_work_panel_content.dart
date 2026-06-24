import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/works_registry.dart';
import '../../../theme/akasha_colors.dart';
import '../../../widgets/poster_image.dart';

/// mock 우측 패널 — 히어로 · 제목 · 메타 · 핵심 정보.
class PreviewWorkHero extends StatelessWidget {
  const PreviewWorkHero({super.key, required this.item});

  final AkashaItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PosterImage(item: item, fit: BoxFit.cover),
      ),
    );
  }
}

class PreviewWorkTitleBlock extends StatelessWidget {
  const PreviewWorkTitleBlock({super.key, required this.item});

  final AkashaItem item;

  String? get _alternateTitle {
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

  String get _metaLine {
    final parts = <String>[
      if (item.releaseYear != null) '${item.releaseYear}',
      item.category.label,
      if (item.workStatusLabel.isNotEmpty) item.workStatusLabel,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final alt = _alternateTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        if (alt != null) ...[
          const SizedBox(height: 4),
          Text(
            alt,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _metaLine,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class PreviewWorkActionBar extends StatelessWidget {
  const PreviewWorkActionBar({
    super.key,
    required this.onOpenDetail,
    this.canGoBack = false,
    this.onBack,
  });

  final VoidCallback onOpenDetail;
  final bool canGoBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack && onBack != null) ...[
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              foregroundColor: Colors.grey[300],
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onOpenDetail,
            style: FilledButton.styleFrom(
              backgroundColor: AkashaColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '상세 정보',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PreviewCoreInfoSection extends StatelessWidget {
  const PreviewCoreInfoSection({super.key, required this.item});

  final AkashaItem item;

  String get _genre {
    if (item.tags.isNotEmpty) return item.tags.first;
    return item.category.label;
  }

  String get _studio {
    final registry = WorksRegistry.getWorkById(item.workId);
    final ext = registry?.extensions;
    if (ext != null) {
      for (final key in const ['studio', 'production', 'studioName', 'publisher']) {
        final value = ext[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return '정보 없음';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_CoreInfoRow>[
      _CoreInfoRow(
        icon: Icons.category_outlined,
        label: '장르',
        value: _genre,
      ),
      _CoreInfoRow(
        icon: Icons.auto_stories_outlined,
        label: '원작',
        value: item.creator.isNotEmpty ? item.creator : '정보 없음',
      ),
      _CoreInfoRow(
        icon: Icons.business_outlined,
        label: '제작사',
        value: _studio,
      ),
      _CoreInfoRow(
        icon: Icons.star_rounded,
        label: '평점',
        valueWidget: item.rating > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    item.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' / 10',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              )
            : Text(
                '평가 없음',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '핵심 정보',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 12,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CoreInfoRow extends StatelessWidget {
  const _CoreInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
        ),
      ],
    );
  }
}

/// 프리뷰 연결 섹션 공통 헤더.
class PreviewSectionHeader extends StatelessWidget {
  const PreviewSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
