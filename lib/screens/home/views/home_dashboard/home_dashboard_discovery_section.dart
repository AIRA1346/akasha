import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';
import 'home_dashboard_discovery_cards.dart';
import 'home_dashboard_discovery_loader.dart';
import 'home_dashboard_styles.dart';

/// 발견의 여정 — 추천 연결·새 작품·주목 인물. v1: [FeatureFlags.showDiscoveryHome].
class HomeDashboardDiscoverySection extends StatefulWidget {
  const HomeDashboardDiscoverySection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onItemTap,
    this.onItemDoubleTap,
    required this.onOpenEntity,
    this.onOpenEntityDetail,
    required this.onGoExplore,
    required this.onSearch,
    this.onConnectSuggested,
    this.onOpenRecord,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(UserCatalogEntity entity)? onOpenEntityDetail;
  final VoidCallback onGoExplore;
  final VoidCallback onSearch;
  final void Function(LinkCandidate candidate, AkashaItem work)?
  onConnectSuggested;
  final void Function(AkashaItem work)? onOpenRecord;

  @override
  State<HomeDashboardDiscoverySection> createState() =>
      _HomeDashboardDiscoverySectionState();
}

class _HomeDashboardDiscoverySectionState
    extends State<HomeDashboardDiscoverySection> {
  int _activeTab = 0;
  late Future<DiscoverySectionData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardDiscoverySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _future = _load();
    }
  }

  Future<DiscoverySectionData> _load() {
    return loadDiscoverySectionData(
      vaultItems: widget.vaultItems,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HomeDashboardStyles.sectionHeader(
              l10n?.dashboardDiscoveryTitle ?? '발견의 여정',
            ),
            const Spacer(),
            DiscoverySectionTabButton(
              label: l10n?.dashboardDiscoveryTabConnections ?? '추천 연결',
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            DiscoverySectionTabButton(
              label: l10n?.dashboardDiscoveryTabNewWorks ?? '새로운 작품',
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
            DiscoverySectionTabButton(
              label: l10n?.dashboardDiscoveryTabPeople ?? '주목할 인물',
              isActive: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<DiscoverySectionData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final data = snapshot.data ?? const DiscoverySectionData();
            return Column(
              children: [
                Row(children: _buildContent(data, l10n)),
                if (_activeTab == 0 && data.pairs.isEmpty) ...[
                  const SizedBox(height: 12),
                  DiscoverySectionEmptyCta(
                    message:
                        l10n?.dashboardDiscoveryEmptyConnections ??
                        '기록에 [[링크]]를 추가하면 추천 연결이 여기에 표시됩니다.',
                    primaryLabel: l10n?.labelDashboardSearchWorks ?? '작품 검색',
                    onPrimary: widget.onSearch,
                    secondaryLabel: widget.onOpenRecord != null
                        ? (l10n?.actionRecord ?? '기록하기')
                        : null,
                    onSecondary:
                        data.pairs.isEmpty && widget.vaultItems.isNotEmpty
                        ? () =>
                              widget.onOpenRecord?.call(widget.vaultItems.first)
                        : null,
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.onGoExplore,
            child: Text(
              l10n?.dashboardDiscoveryMoreConnections ?? '더 많은 연결 보기',
              style: AkashaTypography.buttonLabel.copyWith(
                color: palette.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent(DiscoverySectionData data, dynamic l10n) {
    if (widget.vaultItems.isEmpty) {
      return [
        Expanded(
          child: DiscoverySectionEmptyCta(
            message:
                l10n?.dashboardDiscoveryEmptyVault ??
                '볼트에 작품을 추가하면 발견의 여정이 시작됩니다.',
            primaryLabel: l10n?.labelDashboardSearchWorks ?? '작품 검색',
            onPrimary: widget.onSearch,
          ),
        ),
      ];
    }

    if (_activeTab == 0) {
      if (data.pairs.isEmpty) {
        return const [Expanded(child: SizedBox(height: 8))];
      }
      return data.pairs.take(3).map((pair) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DiscoverySectionPairCard(
              highlight: pair,
              onItemTap: widget.onItemTap,
              onItemDoubleTap: widget.onItemDoubleTap,
              onOpenEntity: widget.onOpenEntity,
              onConnectSuggested: widget.onConnectSuggested,
            ),
          ),
        );
      }).toList();
    }

    if (_activeTab == 1) {
      final sorted = List<AkashaItem>.from(widget.vaultItems)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      final items = sorted.take(3).toList();
      if (items.isEmpty) {
        return [
          Expanded(
            child: Center(
              child: Text(
                l10n?.dashboardDiscoveryNoRecentWorks ?? '최근 추가한 작품이 없습니다.',
                style: AkashaTypography.body.copyWith(
                  color: AkashaColors.textMuted,
                ),
              ),
            ),
          ),
        ];
      }
      return items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DiscoverySectionSingleCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              onDoubleTap: widget.onItemDoubleTap == null
                  ? null
                  : () => widget.onItemDoubleTap!(item),
            ),
          ),
        );
      }).toList();
    }

    if (data.persons.isEmpty) {
      return [
        Expanded(
          child: DiscoverySectionEmptyCta(
            message:
                l10n?.dashboardDiscoveryNoPeople ??
                '등록된 인물이 없습니다. 인물을 추가하고 작품과 연결해 보세요.',
            primaryLabel: l10n?.labelDashboardExploreEntities ?? '인물 탐색',
            onPrimary: widget.onGoExplore,
          ),
        ),
      ];
    }

    return data.persons.take(3).map((person) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: DiscoverySectionEntityCard(
            entity: person,
            onTap: () => widget.onOpenEntity(person),
            onDoubleTap: widget.onOpenEntityDetail == null
                ? null
                : () => widget.onOpenEntityDetail!(person),
          ),
        ),
      );
    }).toList();
  }
}
