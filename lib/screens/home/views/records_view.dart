import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../theme/akasha_palette.dart';
import '../../../utils/app_l10n.dart';
import 'candidate_review_view.dart';
import 'entity_journal_view.dart';
import 'journal_view.dart';
import 'timeline_view.dart';

/// Wave 3 — 「기록」축: 타임라인 + 메모 탭.
class RecordsView extends StatelessWidget {
  const RecordsView({
    super.key,
    required this.vaultPath,
    required this.vaultItems,
    required this.onOpenWork,
    required this.onOpenEntity,
    required this.onNewTimelineEntry,
    required this.onNewJournalEntry,
    required this.userCatalog,
    required this.linkIndex,
    this.reloadToken = 0,
  });

  final String? vaultPath;
  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onOpenWork;
  final Future<void> Function(UserCatalogEntity entity) onOpenEntity;
  final VoidCallback onNewTimelineEntry;
  final VoidCallback onNewJournalEntry;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final int reloadToken;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: palette.surface.withValues(alpha: 0.42),
            child: TabBar(
              indicatorColor: palette.accent,
              labelColor: palette.accent,
              unselectedLabelColor: palette.textMuted,
              dividerColor: palette.borderSubtle(0.2),
              tabs: [
                Tab(
                  key: const ValueKey('records-tab-timeline'),
                  text: l10n?.tabTimeline ?? '타임라인',
                  icon: const Icon(Icons.timeline, size: 18),
                ),
                Tab(
                  key: const ValueKey('records-tab-memo'),
                  text: l10n?.tabMemo ?? '메모',
                  icon: const Icon(Icons.note_alt_outlined, size: 18),
                ),
                Tab(
                  key: const ValueKey('records-tab-entity'),
                  text: l10n?.tabEntity ?? 'Entity',
                  icon: const Icon(Icons.category_outlined, size: 18),
                ),
                Tab(
                  key: const ValueKey('records-tab-candidates'),
                  text: l10n?.tabCandidates ?? '후보',
                  icon: const Icon(Icons.inbox_outlined, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                TimelineView(
                  vaultPath: vaultPath,
                  vaultItems: vaultItems,
                  onOpenWork: onOpenWork,
                  onNewEntry: onNewTimelineEntry,
                  reloadToken: reloadToken,
                ),
                JournalView(
                  vaultPath: vaultPath,
                  onNewEntry: onNewJournalEntry,
                  reloadToken: reloadToken,
                ),
                EntityJournalView(
                  vaultPath: vaultPath,
                  userCatalog: userCatalog,
                  linkIndex: linkIndex,
                  vaultItems: vaultItems,
                  onOpenWork: onOpenWork,
                  onOpenEntity: onOpenEntity,
                  reloadToken: reloadToken,
                ),
                CandidateReviewView(
                  vaultPath: vaultPath,
                  userCatalog: userCatalog,
                  onOpenEntity: onOpenEntity,
                  reloadToken: reloadToken,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
