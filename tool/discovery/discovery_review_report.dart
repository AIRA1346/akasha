/// Discovery 수동 검증 리포트 — wouldCreate 샘플 10건 AKASHA Identity 검토.
library;

import 'dart:convert';

import '../data_policy_utils.dart';
import '../dedupe_utils.dart';
import '../registry_v3_utils.dart';
import 'registry_snapshot.dart';
import 'shadow_write_kpi.dart';
import 'shadow_write_runner.dart';
import 'user_value_assessment.dart';

const minimalCoreFieldKeys = {
  'workId',
  'title',
  'titles',
  'category',
  'domain',
  'releaseYear',
  'creator',
  'aliases',
  'externalIds',
};

class DiscoveryReviewEntry {
  final int index;
  final ShadowWriteItem item;
  final String whyNew;
  final List<String> storedFields;
  final List<String> policyRisks;
  final IdentityWithoutAnilist identityCheck;
  final SearchValueAssessment searchValue;
  final UserValueAssessment userValue;

  const DiscoveryReviewEntry({
    required this.index,
    required this.item,
    required this.whyNew,
    required this.storedFields,
    required this.policyRisks,
    required this.identityCheck,
    required this.searchValue,
    required this.userValue,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'anilistId': item.externalId,
        'title': item.title,
        'shadowWorkId': item.shadowWorkId,
        'whyNew': whyNew,
        'storedFields': storedFields,
        'storedDraft': item.draft,
        'policyRisks': policyRisks,
        'identityWithoutAnilist': identityCheck.toJson(),
        'searchValue': searchValue.toJson(),
        'userValue': userValue.toJson(),
      };
}

class IdentityWithoutAnilist {
  final bool akashaIdentitySufficient;
  final Map<String, dynamic> draftWithoutAnilist;
  final List<String> retainedKeys;
  final List<String> notes;

  const IdentityWithoutAnilist({
    required this.akashaIdentitySufficient,
    required this.draftWithoutAnilist,
    required this.retainedKeys,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'akashaIdentitySufficient': akashaIdentitySufficient,
        'retainedKeys': retainedKeys,
        'draftWithoutAnilist': draftWithoutAnilist,
        'notes': notes,
      };
}

class SearchValueAssessment {
  final List<String> searchTokens;
  final bool titleDistinctInRegistry;
  final List<String> similarRegistryTitles;
  final List<String> notes;

  const SearchValueAssessment({
    required this.searchTokens,
    required this.titleDistinctInRegistry,
    required this.similarRegistryTitles,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'searchTokens': searchTokens,
        'titleDistinctInRegistry': titleDistinctInRegistry,
        'similarRegistryTitles': similarRegistryTitles,
        'notes': notes,
      };
}

class DiscoveryReviewReport {
  final String channelId;
  final int sampleSize;
  final int wouldCreateTotal;
  final int mergeCandidatesTotal;
  final List<DiscoveryReviewEntry> samples;
  final ShadowWriteKpi shadowKpi;

  const DiscoveryReviewReport({
    required this.channelId,
    required this.sampleSize,
    required this.wouldCreateTotal,
    required this.mergeCandidatesTotal,
    required this.samples,
    required this.shadowKpi,
  });

  /// 기술·정책·정체성 게이트 (User Value는 수동 Prioritization)
  bool get readyForTrialWrite =>
      shadowKpi.mirroringIntegrityPassed &&
      samples.every((s) => s.policyRisks.isEmpty) &&
      samples.every((s) => s.identityCheck.akashaIdentitySufficient);

  Map<String, int> get userValueSummary =>
      summarizeUserValueTiers(samples.map((s) => s.userValue));

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'sampleSize': sampleSize,
        'wouldCreateTotal': wouldCreateTotal,
        'mergeCandidatesTotal': mergeCandidatesTotal,
        'readyForTrialWrite': readyForTrialWrite,
        'userValueSummary': userValueSummary,
        'shadowKpi': shadowKpi.toJson(),
        'samples': samples.map((s) => s.toJson()).toList(),
      };
}

/// wouldCreate 항목에서 [sampleSize]건 균등 샘플
List<ShadowWriteItem> sampleWouldCreateItems(
  List<ShadowWriteItem> items, {
  int sampleSize = 10,
}) {
  final creates =
      items.where((i) => i.outcome == ShadowWriteOutcome.wouldCreate).toList();
  if (creates.length <= sampleSize) return creates;
  final step = creates.length / sampleSize;
  return List.generate(
    sampleSize,
    (i) => creates[(i * step).floor().clamp(0, creates.length - 1)],
  );
}

DiscoveryReviewReport buildDiscoveryReviewReport({
  required String channelId,
  required ShadowWriteResult shadowResult,
  required RegistrySnapshot registry,
  int sampleSize = 10,
}) {
  final samples = sampleWouldCreateItems(
    shadowResult.items,
    sampleSize: sampleSize,
  );

  final entries = <DiscoveryReviewEntry>[];
  for (var i = 0; i < samples.length; i++) {
    entries.add(
      _reviewEntry(
        index: i + 1,
        item: samples[i],
        registry: registry,
      ),
    );
  }

  return DiscoveryReviewReport(
    channelId: channelId,
    sampleSize: sampleSize,
    wouldCreateTotal: shadowResult.kpi.wouldCreate,
    mergeCandidatesTotal: shadowResult.kpi.mergeCandidates,
    samples: entries,
    shadowKpi: shadowResult.kpi,
  );
}

DiscoveryReviewEntry _reviewEntry({
  required int index,
  required ShadowWriteItem item,
  required RegistrySnapshot registry,
}) {
  final draft = Map<String, dynamic>.from(item.draft ?? {});
  final shardPath = item.targetShard ?? 'shards/unknown/00.json';
  final workId = item.shadowWorkId ?? 'wk_PENDING';

  final policyIssues = lintWorkEntry(
    workId: workId,
    work: draft,
    relativePath: shardPath,
  );
  final policyRisks =
      policyIssues.map((v) => '${v.rule}: ${v.detail}').toList();

  final storedFields = draft.keys
      .where((k) => draft[k] != null && draft[k] != '' && draft[k] != [])
      .map((k) => k.toString())
      .toList()
    ..sort();

  final identity = _assessIdentityWithoutAnilist(draft, workId);
  final search = _assessSearchValue(draft, registry);
  final userValue = assessUserValue(
    draft: draft,
    item: item,
    titleDistinctInRegistry: search.titleDistinctInRegistry,
    searchTokenCount: search.searchTokens.length,
  );

  return DiscoveryReviewEntry(
    index: index,
    item: item,
    whyNew: _whyNew(draft, registry),
    storedFields: storedFields,
    policyRisks: policyRisks,
    identityCheck: identity,
    searchValue: search,
    userValue: userValue,
  );
}

String _whyNew(Map<String, dynamic> draft, RegistrySnapshot registry) {
  final parts = <String>[];

  final ext = draft['externalIds'];
  if (ext is Map) {
    var anyInRegistry = false;
    ext.forEach((source, id) {
      final key = '${source.toString().toLowerCase()}:${id.toString().trim()}';
      if (registry.byExternalKey.containsKey(key)) anyInRegistry = true;
    });
    if (!anyInRegistry) {
      parts.add('Registry에 해당 externalIds 없음');
    }
  } else {
    parts.add('externalIds 없음 (Minimal Core 위반 가능)');
  }

  final category = draft['category']?.toString() ?? '';
  final year = draft['releaseYear'] is int
      ? draft['releaseYear'] as int
      : int.tryParse(draft['releaseYear']?.toString() ?? '');
  final norms = _normsFromDraft(draft);
  var fuzzyHit = false;
  for (final norm in norms) {
    if (norm.length < 2) continue;
    final hits = registry.byTitleKey['$category::$norm'] ?? const [];
    for (final hit in hits) {
      if (!releaseYearsCompatible(year, hit.releaseYear)) continue;
      fuzzyHit = true;
      break;
    }
    if (fuzzyHit) break;
  }
  if (!fuzzyHit) {
    parts.add('fuzzy title+category+year 중복 없음');
  }

  parts.add('AKASHA 신규 wk_ 할당 대상 (존재 신호 → Identity 생성)');
  return parts.join('; ');
}

IdentityWithoutAnilist _assessIdentityWithoutAnilist(
  Map<String, dynamic> draft,
  String workId,
) {
  final without = Map<String, dynamic>.from(draft);
  without.remove('externalIds');

  final notes = <String>[];
  final title = without['title']?.toString().trim() ?? '';
  final category = without['category']?.toString() ?? '';
  final year = without['releaseYear'];

  without['workId'] = workId;

  var sufficient = workId.startsWith('wk_') && title.isNotEmpty && category.isNotEmpty;

  if (year == null) {
    notes.add('releaseYear 없음 — externalIds 제거 시 연도 식별 불가');
    sufficient = sufficient && title.length >= 4;
  } else {
    notes.add('releaseYear=$year — AniList 없이도 title+category+year로 식별 가능');
  }

  notes.add('canonical identity = $workId (AniList는 참조값만)');

  final nonMinimal = without.keys.where((k) => !minimalCoreFieldKeys.contains(k)).toList();
  if (nonMinimal.isNotEmpty) {
    notes.add('Minimal Core 외 필드 없음 확인 필요: ${nonMinimal.join(', ')}');
  } else {
    notes.add('저장 필드 = Minimal Core 수준 (description/poster/tags 없음)');
  }

  return IdentityWithoutAnilist(
    akashaIdentitySufficient: sufficient,
    draftWithoutAnilist: without,
    retainedKeys: without.keys.map((k) => k.toString()).toList()..sort(),
    notes: notes,
  );
}

SearchValueAssessment _assessSearchValue(
  Map<String, dynamic> draft,
  RegistrySnapshot registry,
) {
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

  final norms = _normsFromDraft(draft);
  final similar = <String>[];
  for (final norm in norms) {
    if (norm.length < 2) continue;
    final category = draft['category']?.toString() ?? '';
    final hits = registry.byTitleKey['$category::$norm'] ?? const [];
    for (final hit in hits.take(3)) {
      similar.add('${hit.workId} "${hit.title}"');
    }
  }

  final notes = <String>[];
  if (tokens.length < 2) {
    notes.add('searchTokens 빈약 — 유저 검색 가치 낮을 수 있음');
  } else {
    notes.add('searchTokens ${tokens.length}개 — 기본 검색 가능');
  }
  if (title.length < 3) {
    notes.add('title 짧음 — 검색·식별 어려움');
  }
  if (similar.isNotEmpty) {
    notes.add('유사 Registry 항목 존재 — 수동 검토 권장');
  } else {
    notes.add('Registry 내 동일 정규화 제목 없음 — 신규 검색 가치 후보');
  }

  return SearchValueAssessment(
    searchTokens: tokens.take(12).toList(),
    titleDistinctInRegistry: similar.isEmpty,
    similarRegistryTitles: similar,
    notes: notes,
  );
}

Set<String> _normsFromDraft(Map<String, dynamic> draft) {
  final norms = <String>{};
  void add(String? t) {
    if (t == null || t.isEmpty) return;
    final n = normalizeTitle(t);
    if (n.isNotEmpty) norms.add(n);
  }

  add(draft['title']?.toString());
  final titles = draft['titles'];
  if (titles is Map) {
    titles.forEach((_, v) => add(v?.toString()));
  }
  final aliases = draft['aliases'];
  if (aliases is List) {
    for (final a in aliases) {
      add(a?.toString());
    }
  }
  return norms;
}

String formatReviewReportMarkdown(DiscoveryReviewReport report) {
  final buf = StringBuffer();
  buf.writeln('# Discovery Manual Review Report');
  buf.writeln();
  buf.writeln('- channel: `${report.channelId}`');
  buf.writeln('- wouldCreate total: **${report.wouldCreateTotal}**');
  buf.writeln('- mergeCandidates (fuzzy dedupe): **${report.mergeCandidatesTotal}**');
  buf.writeln('- sample size: **${report.samples.length}**');
  buf.writeln(
    '- mirroringIntegrityPassed: **${report.shadowKpi.mirroringIntegrityPassed}**',
  );
  buf.writeln('- readyForTrialWrite (auto): **${report.readyForTrialWrite}**');
  final uv = report.userValueSummary;
  buf.writeln(
    '- User Value (sample): **high=${uv['high']} medium=${uv['medium']} low=${uv['low']}**',
  );
  buf.writeln();
  buf.writeln('> Discovery 목표: 외부 DB 미러링이 아니라 **가치 있는 작품을 우선 발견**');
  buf.writeln('> Prioritization ≠ 필터링 — Low도 등록 가능, Trial Write는 High·Medium 우선');
  buf.writeln();

  for (final s in report.samples) {
    buf.writeln('## Sample ${s.index}: ${s.item.title}');
    buf.writeln();
    buf.writeln('| | |');
    buf.writeln('|--|--|');
    buf.writeln('| anilist (참조) | `${s.item.externalId}` |');
    buf.writeln('| shadow wk_ | `${s.item.shadowWorkId}` |');
    buf.writeln('| shard | `${s.item.targetShard}` |');
    buf.writeln('| qualityScore | ${s.item.qualityScore} (tier ${s.item.qualityTier}) |');
    buf.writeln();
    buf.writeln('### 1. 왜 신규로 판단되었는가');
    buf.writeln(s.whyNew);
    buf.writeln();
    buf.writeln('### 2. 저장될 필드 (Minimal Core)');
    buf.writeln('```json');
    buf.writeln(const JsonEncoder.withIndent('  ').convert(s.item.draft ?? {}));
    buf.writeln('```');
    buf.writeln('필드 목록: `${s.storedFields.join('`, `')}`');
    buf.writeln();
    buf.writeln('### 3. Data Policy 위반 가능성');
    if (s.policyRisks.isEmpty) {
      buf.writeln('- **없음** (strict lint 통과)');
    } else {
      for (final r in s.policyRisks) {
        buf.writeln('- $r');
      }
    }
    buf.writeln();
    buf.writeln('### 4. AniList 제거 후 Registry 정체성');
    buf.writeln(
      '- akashaIdentitySufficient: **${s.identityCheck.akashaIdentitySufficient}**',
    );
    for (final n in s.identityCheck.notes) {
      buf.writeln('- $n');
    }
    buf.writeln('```json');
    buf.writeln(
      const JsonEncoder.withIndent('  ')
          .convert(s.identityCheck.draftWithoutAnilist),
    );
    buf.writeln('```');
    buf.writeln();
    buf.writeln('### 5. 검색 가치 (유저 관점)');
    for (final n in s.searchValue.notes) {
      buf.writeln('- $n');
    }
    if (s.searchValue.similarRegistryTitles.isNotEmpty) {
      buf.writeln('- 유사 항목: ${s.searchValue.similarRegistryTitles.join('; ')}');
    }
    buf.writeln('- searchTokens: `${s.searchValue.searchTokens.join('`, `')}`');
    buf.writeln();
    buf.writeln('### 6. User Value (Discovery Prioritization)');
    buf.writeln('**질문:** ${UserValueAssessment.reviewQuestion}');
    buf.writeln();
    buf.writeln('- tier: **${s.userValue.tier.name.toUpperCase()}** (score ${s.userValue.score})');
    buf.writeln('- ${s.userValue.prioritizationNote}');
    if (s.userValue.highSignals.isNotEmpty) {
      buf.writeln('- High 신호:');
      for (final h in s.userValue.highSignals) {
        buf.writeln('  - $h');
      }
    }
    if (s.userValue.lowSignals.isNotEmpty) {
      buf.writeln('- Low 신호:');
      for (final l in s.userValue.lowSignals) {
        buf.writeln('  - $l');
      }
    }
    buf.writeln();
    buf.writeln('---');
    buf.writeln();
  }

  buf.writeln('## 검증 체크리스트 (수동)');
  buf.writeln();
  buf.writeln('1. [ ] 96건이 AKASHA에 **필요한** 신규 작품인가?');
  buf.writeln('2. [ ] AniList 없이 `wk_`+title+category+year로 정체성 유지되는가?');
  buf.writeln('3. [ ] Minimal Core만으로 Registry 품질 기준을 만족하는가?');
  buf.writeln('4. [ ] 유저 검색 시 **가치 있는** 작품인가?');
  buf.writeln('5. [ ] 외부 DB 미러링이 아닌 **존재 신호 → Identity** 흐름인가?');
  buf.writeln(
    '6. [ ] **User Value** — 지금 Registry에 넣을 사용자 가치가 있는가? (Prioritization)',
  );
  buf.writeln();
  buf.writeln('## Phase B — Registry Impact Test');
  buf.writeln();
  buf.writeln('- Manual Review + User Value **수동 확인** 후 진행');
  buf.writeln('- `dart run tool/discovery/registry_impact_test.dart --live`');
  buf.writeln('- 선정: Gap·Core·Franchise 축 5~10건 — **Coverage KPI 우선**');
  buf.writeln('- `mergeCandidate` = 기존 `wk_`에 anilist **링크 후보** (신규 등록 아님)');
  buf.writeln();
  return buf.toString();
}
