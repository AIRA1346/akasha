import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
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
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: '타임라인', icon: Icon(Icons.timeline, size: 18)),
              Tab(text: '메모', icon: Icon(Icons.note_alt_outlined, size: 18)),
              Tab(text: 'Entity', icon: Icon(Icons.category_outlined, size: 18)),
              Tab(text: '후보', icon: Icon(Icons.inbox_outlined, size: 18)),
            ],
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
