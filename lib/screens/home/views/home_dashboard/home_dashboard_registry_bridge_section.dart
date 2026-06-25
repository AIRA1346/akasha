import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/registry_work.dart';
import '../../../../services/registry_discovery_candidate_service.dart';
import '../../../../widgets/poster_image.dart';
import '../../../../widgets/registry_discovery_candidates_section.dart';
import 'home_dashboard_styles.dart';
import '../../../../theme/akasha_colors.dart';

/// Home — Vault 작품에서 Registry 사전 작품으로 이어지는 브리지 (R11 P1).
class HomeDashboardRegistryBridgeSection extends StatefulWidget {
  const HomeDashboardRegistryBridgeSection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onPreviewRegistryWork,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(RegistryWork work) onPreviewRegistryWork;

  @override
  State<HomeDashboardRegistryBridgeSection> createState() =>
      _HomeDashboardRegistryBridgeSectionState();
}

class _HomeDashboardRegistryBridgeSectionState
    extends State<HomeDashboardRegistryBridgeSection> {
  late Future<_BridgeCard?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardRegistryBridgeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _future = _load();
    }
  }

  Future<_BridgeCard?> _load() async {
    if (widget.vaultItems.isEmpty) return null;

    final sorted = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    for (final work in sorted) {
      if (work.creator.trim().isEmpty && work.tags.isEmpty) continue;

      final candidates =
          await RegistryDiscoveryCandidateService.candidatesForVaultWork(
        work: work,
        vaultItems: widget.vaultItems,
        userCatalog: widget.userCatalog,
        linkIndex: widget.linkIndex,
        limit: 3,
      );
      if (candidates.isEmpty) continue;

      final bridgeLabel = work.creator.trim().isNotEmpty
          ? work.creator.trim()
          : work.title;

      return _BridgeCard(
        sourceWork: work,
        bridgeLabel: bridgeLabel,
        candidates: candidates,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BridgeCard?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final card = snapshot.data;
        if (card == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeDashboardStyles.sectionHeader('사전에서 발견'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141A28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 58,
                      child: PosterImage(
                        item: card.sourceWork,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          card.sourceWork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${card.bridgeLabel} → 사전 추천',
                          style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
                        ),
                        RegistryDiscoveryCandidatesSection(
                          candidates: card.candidates,
                          bridgeHint: null,
                          compact: true,
                          onPreviewRegistryWork: widget.onPreviewRegistryWork,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BridgeCard {
  const _BridgeCard({
    required this.sourceWork,
    required this.bridgeLabel,
    required this.candidates,
  });

  final AkashaItem sourceWork;
  final String bridgeLabel;
  final List<RegistryDiscoveryCandidate> candidates;
}
