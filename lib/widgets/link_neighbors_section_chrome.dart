import 'package:flutter/material.dart';

import '../models/user_catalog_entity.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_typography.dart';

/// Work·Entity 링크 이웃 섹션 공통 chrome (제목 행 · 빈 상태 · 칩).
class LinkNeighborsSection extends StatelessWidget {
  const LinkNeighborsSection({
    super.key,
    required this.title,
    required this.isEmpty,
    required this.titleStyle,
    required this.showEmptySections,
    this.child,
    this.onAdd,
    this.addLabel = '추가',
    this.emptyChild,
  });

  final String title;
  final bool isEmpty;
  final TextStyle titleStyle;
  final bool showEmptySections;
  final Widget? child;
  final VoidCallback? onAdd;
  final String addLabel;
  final Widget? emptyChild;

  @override
  Widget build(BuildContext context) {
    if (!showEmptySections && isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: titleStyle)),
              if (onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    addLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AkashaColors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEmpty) emptyChild ?? const SizedBox.shrink() else child!,
        ],
      ),
    );
  }
}

class LinkNeighborsEmptyLinkCta extends StatelessWidget {
  const LinkNeighborsEmptyLinkCta({
    super.key,
    required this.message,
    this.onPressed,
    this.actionLabel = '본문에서 링크 추가하기',
  });

  final String message;
  final VoidCallback? onPressed;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: AkashaTypography.caption),
          if (onPressed != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LinkNeighborsEmptyHint extends StatelessWidget {
  const LinkNeighborsEmptyHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      child: Text(message, style: AkashaTypography.caption),
    );
  }
}

class LinkNeighborsEntityChipList extends StatelessWidget {
  const LinkNeighborsEntityChipList({
    super.key,
    required this.entities,
    this.onOpenEntity,
  });

  final List<UserCatalogEntity> entities;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entities.map((entity) {
        return ActionChip(
          label: Text(
            entity.title,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: AkashaColors.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          visualDensity: VisualDensity.compact,
          onPressed:
              onOpenEntity == null ? null : () => onOpenEntity!(entity),
        );
      }).toList(),
    );
  }
}

class LinkNeighborsConceptTagChip extends StatelessWidget {
  const LinkNeighborsConceptTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: AkashaTypography.caption.copyWith(color: AkashaColors.textSecondary),
      ),
    );
  }
}
