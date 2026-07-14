import 'package:flutter/material.dart';

import '../models/registry_work.dart';
import '../services/registry_discovery_candidate_service.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_typography.dart';
import '../utils/app_l10n.dart';

/// Registry Discovery Bridge — 사전 작품 추천 섹션 (R11).
class RegistryDiscoveryCandidatesSection extends StatelessWidget {
  const RegistryDiscoveryCandidatesSection({
    super.key,
    required this.candidates,
    this.loading = false,
    this.bridgeHint,
    this.onPreviewRegistryWork,
    this.compact = false,
  });

  final List<RegistryDiscoveryCandidate> candidates;
  final bool loading;
  final String? bridgeHint;
  final void Function(RegistryWork work)? onPreviewRegistryWork;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final l10n = lookupAppL10n(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 14, color: palette.textMuted),
              const SizedBox(width: 6),
              Text(
                l10n?.registryDiscoveryMoreFromCatalog ?? '사전에서 더 보기',
                style: AkashaTypography.micro.copyWith(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          if (bridgeHint != null && bridgeHint!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bridgeHint!,
              style: AkashaTypography.micro.copyWith(color: palette.textMuted),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final candidate in candidates)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: palette.hoverSurface,
                  side: BorderSide(color: palette.borderSubtle(0.28)),
                  label: Text(
                    candidate.work.displayTitle(),
                    style: AkashaTypography.micro.copyWith(
                      fontSize: compact ? 9 : 10,
                      color: palette.textPrimary,
                    ),
                  ),
                  avatar: Icon(
                    _iconFor(candidate.reason),
                    size: 14,
                    color: palette.accent,
                  ),
                  onPressed: onPreviewRegistryWork == null
                      ? null
                      : () => onPreviewRegistryWork!(candidate.work),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(RegistryDiscoveryReason reason) {
    return switch (reason) {
      RegistryDiscoveryReason.creator => Icons.person_outline,
      RegistryDiscoveryReason.tag => Icons.local_offer_outlined,
      RegistryDiscoveryReason.linkedEntity => Icons.link,
    };
  }
}
