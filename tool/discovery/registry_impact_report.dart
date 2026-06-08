/// Registry Impact Report — Phase B 산출물 (쓰기보다 "왜 선택했는가").
library;

import 'dart:convert';

import 'registry_coverage_utils.dart';
import 'registry_impact_selector.dart';
import 'shadow_write_kpi.dart';
import 'shadow_write_runner.dart';

class RegistryImpactKpi {
  final int registryEntriesBefore;
  final int registryEntriesAfter;
  final int animationEntriesBefore;
  final int animationEntriesAfter;
  final int selectedCount;
  final int gapFillsCount;
  final int totalNovelSearchTokens;
  final int mergeCandidateCount;
  final double coverageDelta;
  final bool searchQualityImproves;
  final bool coverageIncreases;
  final bool recommendPhaseC;

  const RegistryImpactKpi({
    required this.registryEntriesBefore,
    required this.registryEntriesAfter,
    required this.animationEntriesBefore,
    required this.animationEntriesAfter,
    required this.selectedCount,
    required this.gapFillsCount,
    required this.totalNovelSearchTokens,
    required this.mergeCandidateCount,
    required this.coverageDelta,
    required this.searchQualityImproves,
    required this.coverageIncreases,
    required this.recommendPhaseC,
  });

  Map<String, dynamic> toJson() => {
        'registryEntriesBefore': registryEntriesBefore,
        'registryEntriesAfter': registryEntriesAfter,
        'animationEntriesBefore': animationEntriesBefore,
        'animationEntriesAfter': animationEntriesAfter,
        'selectedCount': selectedCount,
        'gapFillsCount': gapFillsCount,
        'totalNovelSearchTokens': totalNovelSearchTokens,
        'mergeCandidateCount': mergeCandidateCount,
        'coverageDelta': coverageDelta,
        'searchQualityImproves': searchQualityImproves,
        'coverageIncreases': coverageIncreases,
        'recommendPhaseC': recommendPhaseC,
      };
}

class RegistryImpactReport {
  final String channelId;
  final List<ImpactSelectionScore> selected;
  final List<ShadowWriteItem> mergeCandidates;
  final RegistryImpactKpi kpi;
  final ShadowWriteKpi shadowKpi;

  const RegistryImpactReport({
    required this.channelId,
    required this.selected,
    required this.mergeCandidates,
    required this.kpi,
    required this.shadowKpi,
  });

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'selected': selected.map((s) => s.toJson()).toList(),
        'mergeCandidates': mergeCandidates
            .map(
              (m) => {
                'anilistId': m.externalId,
                'title': m.title,
                'linkToWorkId': m.matchedWorkId,
                'note': 'externalIds.anilist 연결 후보 — 신규 wk_ 아님',
              },
            )
            .toList(),
        'kpi': kpi.toJson(),
        'shadowKpi': shadowKpi.toJson(),
      };
}

RegistryImpactReport buildRegistryImpactReport({
  required String channelId,
  required ShadowWriteResult shadowResult,
  required RegistryCoverageSnapshot coverageBefore,
  required List<ImpactSelectionScore> selected,
}) {
  var novelTokens = 0;
  var gapFills = 0;
  for (final s in selected) {
    novelTokens += s.gap.totalNewTokens;
    if (s.gap.fillsTitleGap) gapFills++;
  }

  final mergeItems = shadowResult.items
      .where((i) => i.outcome == ShadowWriteOutcome.mergeCandidate)
      .toList();

  final selectedCount = selected.length;
  final entriesAfter = coverageBefore.totalEntries + selectedCount;
  final animAfter = coverageBefore.animationEntries + selectedCount;
  final coverageDelta = selectedCount == 0
      ? 0.0
      : gapFills / selectedCount;

  final searchQualityImproves =
      selectedCount > 0 && novelTokens >= selectedCount;
  final coverageIncreases = gapFills > 0 && selectedCount > 0;

  final recommendPhaseC = coverageIncreases &&
      searchQualityImproves &&
      coverageDelta >= 0.8 &&
      selectedCount >= 5;

  return RegistryImpactReport(
    channelId: channelId,
    selected: selected,
    mergeCandidates: mergeItems,
    shadowKpi: shadowResult.kpi,
    kpi: RegistryImpactKpi(
      registryEntriesBefore: coverageBefore.totalEntries,
      registryEntriesAfter: entriesAfter,
      animationEntriesBefore: coverageBefore.animationEntries,
      animationEntriesAfter: animAfter,
      selectedCount: selectedCount,
      gapFillsCount: gapFills,
      totalNovelSearchTokens: novelTokens,
      mergeCandidateCount: mergeItems.length,
      coverageDelta: coverageDelta,
      searchQualityImproves: searchQualityImproves,
      coverageIncreases: coverageIncreases,
      recommendPhaseC: recommendPhaseC,
    ),
  );
}

String formatRegistryImpactMarkdown(RegistryImpactReport report) {
  final k = report.kpi;
  final buf = StringBuffer();

  buf.writeln('# Registry Impact Report (Phase B)');
  buf.writeln();
  buf.writeln('> 목표: **등록 건수**가 아니라 **Registry 품질·Coverage가 실제로 좋아지는지** 검증');
  buf.writeln('> 산출물: Trial Write 자체보다 **"왜 이 작품들을 선택했는가"**');
  buf.writeln();
  buf.writeln('## Executive Summary');
  buf.writeln();
  buf.writeln('| KPI | 값 |');
  buf.writeln('|-----|-----|');
  buf.writeln('| Registry entries | ${k.registryEntriesBefore} → ${k.registryEntriesAfter} |');
  buf.writeln('| animation entries | ${k.animationEntriesBefore} → ${k.animationEntriesAfter} |');
  buf.writeln('| **선정 (Impact Test)** | **${k.selectedCount}** |');
  buf.writeln('| Gap fill | ${k.gapFillsCount} / ${k.selectedCount} |');
  buf.writeln('| 신규 searchTokens | ${k.totalNovelSearchTokens} |');
  buf.writeln('| mergeCandidate (anilist 링크) | ${k.mergeCandidateCount} |');
  buf.writeln('| coverageDelta (gap ratio) | ${k.coverageDelta.toStringAsFixed(2)} |');
  buf.writeln('| searchQualityImproves | **${k.searchQualityImproves}** |');
  buf.writeln('| coverageIncreases | **${k.coverageIncreases}** |');
  buf.writeln('| **recommendPhaseC** | **${k.recommendPhaseC}** |');
  buf.writeln();

  buf.writeln('## 선정 기준 (5~10건)');
  buf.writeln();
  buf.writeln('1. **Registry Gap** — 기존에 없던 제목·검색 토큰');
  buf.writeln('2. **Core Work** — 대표작 신호 (creator·titles·aliases)');
  buf.writeln('3. **Franchise 연결** — franchise_groups 인접 IP');
  buf.writeln('4. **User Value High** 우선');
  buf.writeln();

  buf.writeln('## 선정 작품 — 왜 이 작품인가');
  buf.writeln();
  for (var i = 0; i < report.selected.length; i++) {
    final s = report.selected[i];
    buf.writeln('### ${i + 1}. ${s.item.title}');
    buf.writeln();
    buf.writeln('| | |');
    buf.writeln('|--|--|');
    buf.writeln('| shadow wk_ | `${s.item.shadowWorkId}` |');
    buf.writeln('| anilist (참조) | `${s.item.externalId}` |');
    buf.writeln('| User Value | ${s.userValue.tier.name} |');
    buf.writeln('| impactScore | ${s.impactScore} |');
    buf.writeln('| axes | ${s.axes.map((a) => a.name).join(', ')} |');
    buf.writeln();
    for (final r in s.reasons) {
      buf.writeln('- $r');
    }
    if (s.gap.novelSearchTokens.isNotEmpty) {
      buf.writeln(
        '- 신규 tokens: `${s.gap.novelSearchTokens.take(6).join('`, `')}`',
      );
    }
    buf.writeln();
    buf.writeln('```json');
    buf.writeln(
      const JsonEncoder.withIndent('  ').convert(s.item.draft ?? {}),
    );
    buf.writeln('```');
    buf.writeln();
  }

  if (report.mergeCandidates.isNotEmpty) {
    buf.writeln('## mergeCandidate — externalIds.anilist 연결 후보');
    buf.writeln();
    buf.writeln('신규 `wk_` **아님**. 기존 Registry 작품에 AniList 참조만 연결.');
    buf.writeln();
    for (final m in report.mergeCandidates) {
      buf.writeln(
        '- anilist:${m.externalId} "${m.title}" → `${m.matchedWorkId}`',
      );
    }
    buf.writeln();
  }

  buf.writeln('## 성공 기준 (Phase B)');
  buf.writeln();
  buf.writeln('| | 자동 힌트 | 수동 확인 |');
  buf.writeln('|--|-----------|-----------|');
  buf.writeln('| write·CI | (Impact Test 적용 후) | shard patch + strict CI |');
  buf.writeln('| 검색 품질 | ${k.searchQualityImproves} | "검색했을 때 찾을 수 있는가" |');
  buf.writeln('| Coverage | ${k.coverageIncreases} | Gap이 실제로 줄었는가 |');
  buf.writeln('| 사용자 체감 | — | "들어온 게 맞다" |');
  buf.writeln();
  buf.writeln('## Phase C 게이트');
  buf.writeln();
  if (k.recommendPhaseC) {
    buf.writeln(
      '**recommendPhaseC=true** — ${k.selectedCount}건만으로 Coverage·검색 가치 증가 신호. '
      '100건 Trial Batch 검토 가능.',
    );
  } else {
    buf.writeln(
      '**recommendPhaseC=false** — Impact가 체감되지 않으면 Phase C(100건)로 갈 이유 없음. '
      '선정·소스·Gap 정의 재검토.',
    );
  }
  buf.writeln();
  buf.writeln('## 수동 체크리스트');
  buf.writeln();
  buf.writeln('- [ ] 선정 ${k.selectedCount}건이 AKASHA 사용자에게 **가치 있는** 순증인가');
  buf.writeln('- [ ] Coverage KPI가 등록 건수보다 중요한가 — Gap이 줄었는가');
  buf.writeln('- [ ] mergeCandidate는 **링크 큐**로만 관리 (신규 등록 아님)');
  buf.writeln('- [ ] Impact Test 적용 후 search_index에서 **실제 검색** 확인');
  buf.writeln();

  return buf.toString();
}
