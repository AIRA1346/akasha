import 'package:flutter/material.dart';

import '../models/registry_work.dart';
import '../services/registry_discovery_candidate_service.dart';
import '../theme/akasha_colors.dart';

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
              Icon(Icons.cloud_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                '사전에서 더 보기',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          if (bridgeHint != null && bridgeHint!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bridgeHint!,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                  label: Text(
                    candidate.work.displayTitle(),
                    style: TextStyle(fontSize: compact ? 9 : 10),
                  ),
                  avatar: Icon(
                    _iconFor(candidate.reason),
                    size: 14,
                    color: AkashaColors.accent,
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
