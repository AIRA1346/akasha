// 가상 Registry 상태 — 선정 draft를 메모리에만 적용.
library;

import '../quality_score_utils.dart';
import '../registry_v3_utils.dart';
import 'registry_snapshot.dart';

class VirtualWorkEntry {
  final String workId;
  final String title;
  final String category;
  final int? releaseYear;
  final String creator;
  final List<String> aliases;
  final Map<String, String> titles;
  final List<String> searchTokens;
  final int qualityScore;
  final Map<String, dynamic> draft;

  const VirtualWorkEntry({
    required this.workId,
    required this.title,
    required this.category,
    required this.releaseYear,
    required this.creator,
    required this.aliases,
    required this.titles,
    required this.searchTokens,
    required this.qualityScore,
    required this.draft,
  });

  factory VirtualWorkEntry.fromDraft(Map<String, dynamic> draft) {
    final workId = draft['workId']?.toString() ?? 'wk_PENDING';
    final title = draft['title']?.toString() ?? '';
    final titles = parseTitlesJson(draft['titles']);
    final aliases = (draft['aliases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final tokens = buildWorkSearchTokens(
      legacyTitle: title,
      titles: titles,
      aliases: aliases,
      creator: draft['creator']?.toString() ?? '',
    );
    final signals = resolveQualitySignals(draft, franchiseMember: false);
    final score = computeQualityScore(draft, signals);

    return VirtualWorkEntry(
      workId: workId,
      title: title,
      category: draft['category']?.toString() ?? 'animation',
      releaseYear: draft['releaseYear'] is int
          ? draft['releaseYear'] as int
          : int.tryParse(draft['releaseYear']?.toString() ?? ''),
      creator: draft['creator']?.toString().trim() ?? '',
      aliases: aliases,
      titles: titles,
      searchTokens: tokens,
      qualityScore: score,
      draft: Map<String, dynamic>.from(draft),
    );
  }
}

class RegistryVirtualState {
  final List<VirtualWorkEntry> entries;

  const RegistryVirtualState({required this.entries});

  factory RegistryVirtualState.fromSnapshot(RegistrySnapshot snapshot) {
    return RegistryVirtualState(
      entries: snapshot.works.map(_virtualFromRegistryWork).toList(),
    );
  }

  RegistryVirtualState withAddedDrafts(Iterable<Map<String, dynamic>> drafts) {
    final added = drafts.map(VirtualWorkEntry.fromDraft).toList();
    return RegistryVirtualState(entries: [...entries, ...added]);
  }

  static VirtualWorkEntry _virtualFromRegistryWork(RegistryWorkEntry w) {
    final work = w.work;
    final titles = parseTitlesJson(work['titles']);
    final aliases = (work['aliases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final tokens = buildWorkSearchTokens(
      legacyTitle: w.title,
      titles: titles,
      aliases: aliases,
      creator: work['creator']?.toString() ?? '',
      tags: (work['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
    final signals = resolveQualitySignals(work, franchiseMember: false);
    final score = computeQualityScore(work, signals);

    return VirtualWorkEntry(
      workId: w.workId,
      title: w.title,
      category: w.category,
      releaseYear: w.releaseYear,
      creator: work['creator']?.toString().trim() ?? '',
      aliases: aliases,
      titles: titles,
      searchTokens: tokens,
      qualityScore: score,
      draft: Map<String, dynamic>.from(work),
    );
  }
}
