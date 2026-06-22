import 'package:flutter/material.dart';

import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardDiscoverySection extends StatefulWidget {
  const HomeDashboardDiscoverySection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.onItemTap,
    required this.onOpenEntity,
    required this.onGoExplore,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final void Function(AkashaItem item) onItemTap;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final VoidCallback onGoExplore;

  @override
  State<HomeDashboardDiscoverySection> createState() =>
      _HomeDashboardDiscoverySectionState();
}

class _HomeDashboardDiscoverySectionState
    extends State<HomeDashboardDiscoverySection> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HomeDashboardStyles.sectionHeader('발견의 여정'),
            const Spacer(),
            _TabButton(
              label: '추천 연결',
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            _TabButton(
              label: '새로운 작품',
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
            _TabButton(
              label: '주목할 인물',
              isActive: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: _buildContent()),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.onGoExplore,
            child: const Text(
              '더 많은 연결 보기',
              style: TextStyle(
                fontSize: 12,
                color: AkashaColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent() {
    if (widget.vaultItems.length < 2) {
      return const [
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                '더 많은 작품을 추가하여 발견의 여정을 시작하세요.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ),
      ];
    }

    if (_activeTab == 0) {
      final sorted = List<AkashaItem>.from(widget.vaultItems)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      final a = sorted[0];
      final b = sorted[1];
      final c = sorted.length > 2 ? sorted[2] : sorted[0];

      return [
        Expanded(
          child: _PairCard(
            title: '최근 추가됨',
            rateText: _commonalityText(a, b),
            leftItem: a,
            rightItem: b,
            onItemTap: widget.onItemTap,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PairCard(
            title: '연관 탐색',
            rateText: _commonalityText(b, c),
            leftItem: b,
            rightItem: c,
            onItemTap: widget.onItemTap,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PairCard(
            title: '발견의 고리',
            rateText: _commonalityText(c, a),
            leftItem: c,
            rightItem: a,
            onItemTap: widget.onItemTap,
          ),
        ),
      ];
    }

    if (_activeTab == 1) {
      final sorted = List<AkashaItem>.from(widget.vaultItems)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return sorted.take(3).map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _SingleCard(
              title: '새로운 작품',
              item: item,
              onTap: () => widget.onItemTap(item),
            ),
          ),
        );
      }).toList();
    }

    final persons = widget.userCatalog.all
        .where((e) => e.anchorType == EntityAnchorType.person)
        .toList();
    if (persons.isEmpty) {
      return const [
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                '등록된 인물이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ),
      ];
    }

    return persons.take(3).map((person) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _EntityCard(
            title: '주목할 인물',
            entity: person,
            onTap: () => widget.onOpenEntity(person),
          ),
        ),
      );
    }).toList();
  }

  String _commonalityText(AkashaItem a, AkashaItem b) {
    if (a.workId == b.workId) return '동일 작품';

    final commonTags =
        a.tags.where((tag) => b.tags.contains(tag)).toList();
    if (commonTags.isNotEmpty) {
      return '공통 태그: ${commonTags.first}';
    }
    if (a.creator.isNotEmpty && a.creator == b.creator) {
      return '같은 창작자';
    }
    if (a.category == b.category) {
      return '동일 카테고리';
    }
    return '연결 탐색 중';
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.grey[600],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({
    required this.title,
    required this.rateText,
    required this.leftItem,
    required this.rightItem,
    required this.onItemTap,
  });

  final String title;
  final String rateText;
  final AkashaItem leftItem;
  final AkashaItem rightItem;
  final void Function(AkashaItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  rateText,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AkashaColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WorkThumb(item: leftItem, onTap: () => onItemTap(leftItem)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AkashaColors.accent,
                  ),
                ),
                _WorkThumb(item: rightItem, onTap: () => onItemTap(rightItem)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleCard extends StatelessWidget {
  const _SingleCard({
    required this.title,
    required this.item,
    required this.onTap,
  });

  final String title;
  final AkashaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: _WorkThumb(item: item, onTap: onTap)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.title,
    required this.entity,
    required this.onTap,
  });

  final String title;
  final UserCatalogEntity entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: _EntityThumb(label: entity.title)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkThumb extends StatelessWidget {
  const _WorkThumb({required this.item, required this.onTap});

  final AkashaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: PosterImage(item: item, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _EntityThumb extends StatelessWidget {
  const _EntityThumb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Container(
              color: AkashaColors.thumbPlaceholder,
              child: Center(
                child: Text(
                  label.isNotEmpty ? label.substring(0, 1) : '?',
                  style: const TextStyle(
                    color: AkashaColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }
}
