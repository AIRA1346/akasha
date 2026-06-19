import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import 'journal_view.dart';
import 'timeline_view.dart';

/// Wave 3 — 「기록」축: 타임라인 + 메모 탭.
class RecordsView extends StatelessWidget {
  const RecordsView({
    super.key,
    required this.vaultItems,
    required this.onOpenWork,
    required this.onNewTimelineEntry,
    required this.onNewJournalEntry,
    this.reloadToken = 0,
  });

  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onOpenWork;
  final VoidCallback onNewTimelineEntry;
  final VoidCallback onNewJournalEntry;
  final int reloadToken;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: '타임라인', icon: Icon(Icons.timeline, size: 18)),
              Tab(text: '메모', icon: Icon(Icons.note_alt_outlined, size: 18)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TimelineView(
                  vaultItems: vaultItems,
                  onOpenWork: onOpenWork,
                  onNewEntry: onNewTimelineEntry,
                  reloadToken: reloadToken,
                ),
                JournalView(
                  onNewEntry: onNewJournalEntry,
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
