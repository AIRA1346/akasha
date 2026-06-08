/// AniList Removal Test — AKASHA 독립 Registry 증명.
library;

import 'dart:convert';

import '../registry_v3_utils.dart';
import 'anilist_strip.dart';
import 'discovery_kpi.dart';
import 'registry_diff_compare.dart';
import 'registry_impact_selector.dart';
import 'registry_virtual_state.dart';
import 'user_value_assessment.dart';

enum AniListRemovalVerdict { pass, fail }

class AniListRemovalEntry {
  final ImpactSelectionScore selection;
  final Map<String, dynamic> draftWithoutAnilist;
  final bool shouldExistInAkasha;
  final bool userSearchValue;
  final bool identityMaintained;
  final bool remainsIfAnilistGone;
  final AniListRemovalVerdict verdict;
  final List<String> notes;

  const AniListRemovalEntry({
    required this.selection,
    required this.draftWithoutAnilist,
    required this.shouldExistInAkasha,
    required this.userSearchValue,
    required this.identityMaintained,
    required this.remainsIfAnilistGone,
    required this.verdict,
    required this.notes,
  });

  bool get passed => verdict == AniListRemovalVerdict.pass;

  Map<String, dynamic> toJson() => {
        'title': selection.item.title,
        'shadowWorkId': selection.item.shadowWorkId,
        'verdict': verdict.name,
        'shouldExistInAkasha': shouldExistInAkasha,
        'userSearchValue': userSearchValue,
        'identityMaintained': identityMaintained,
        'remainsIfAnilistGone': remainsIfAnilistGone,
        'draftWithoutAnilist': draftWithoutAnilist,
        'notes': notes,
      };
}

class AniListRemovalReport {
  final List<AniListRemovalEntry> entries;
  final DiscoveryIndependenceKpi kpi;

  const AniListRemovalReport({
    required this.entries,
    required this.kpi,
  });

  Map<String, dynamic> toJson() => {
        'kpi': kpi.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

AniListRemovalReport buildAniListRemovalReport({
  required List<ImpactSelectionScore> selected,
  required RegistryVirtualState registryBefore,
  required RegistryDiffResult diff,
}) {
  final entries = <AniListRemovalEntry>[];
  var pass = 0;
  var fail = 0;

  for (final s in selected) {
    final raw = s.item.draft ?? {};
    final stripped = stripAnilistFromDraft(Map<String, dynamic>.from(raw));
    final entry = _evaluateEntry(
      selection: s,
      stripped: stripped,
      registryBefore: registryBefore,
      diff: diff,
    );
    entries.add(entry);
    if (entry.passed) {
      pass++;
    } else {
      fail++;
    }
  }

  return AniListRemovalReport(
    entries: entries,
    kpi: DiscoveryIndependenceKpi(
      selectedCount: selected.length,
      passCount: pass,
      failCount: fail,
    ),
  );
}

AniListRemovalEntry _evaluateEntry({
  required ImpactSelectionScore selection,
  required Map<String, dynamic> stripped,
  required RegistryVirtualState registryBefore,
  required RegistryDiffResult diff,
}) {
  final workId = selection.item.shadowWorkId ?? 'wk_PENDING';
  stripped['workId'] = workId;

  final title = stripped['title']?.toString().trim() ?? '';
  final category = stripped['category']?.toString() ?? '';
  final year = stripped['releaseYear'] is int
      ? stripped['releaseYear'] as int
      : int.tryParse(stripped['releaseYear']?.toString() ?? '');
  final creator = stripped['creator']?.toString().trim() ?? '';
  final titles = parseTitlesJson(stripped['titles']);
  final aliases = (stripped['aliases'] as List?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];

  final notes = <String>[];
  if (!draftHasAnilistReference(stripped)) {
    notes.add('externalIds.anilist·AniList ingest 제거 확인');
  } else {
    notes.add('WARN: AniList 참조 잔존');
  }

  final identityMaintained = title.isNotEmpty &&
      category.isNotEmpty &&
      workId.startsWith('wk_') &&
      (year != null && year > 0 ||
          creator.isNotEmpty ||
          aliases.isNotEmpty ||
          titles.isNotEmpty);

  if (identityMaintained) {
    notes.add(
      '정체성: title+category+${year != null ? 'releaseYear' : 'creator/aliases/titles'}',
    );
  }

  final tokens = buildWorkSearchTokens(
    legacyTitle: title,
    titles: titles,
    aliases: aliases,
    creator: creator,
  );
  final userSearchValue = tokens.length >= 2;

  // 제목 검색으로 가상 Registry에서 발견 가능 (AniList 없이)
  final virtualAfter = registryBefore.withAddedDrafts([stripped]);
  final searchHits = searchRegistry(title, virtualAfter);
  final foundByTitle = searchHits.any((e) => e.workId == workId);
  final userSearchValueProbe = userSearchValue && foundByTitle;

  if (userSearchValueProbe) {
    notes.add('검색: "$title" — AniList 없이 searchTokens·probe 성공');
  }

  final primaryGap = diff.searchWins.any(
    (w) =>
        w.query == title &&
        w.wasZeroBefore &&
        w.newTopWorkId == workId,
  );

  final shouldExistInAkasha = identityMaintained &&
      userSearchValueProbe &&
      (primaryGap || selection.gap.fillsTitleGap) &&
      selection.userValue.tier != UserValueTier.low;

  final remainsIfAnilistGone =
      shouldExistInAkasha && identityMaintained && !draftHasAnilistReference(stripped);

  if (shouldExistInAkasha) {
    notes.add('AKASHA 존재 정당화 — 사용자 Gap·독립 메타데이터');
  } else {
    notes.add('FAIL 후보 — AniList 존재에 의존 가능성');
  }

  final allYes = shouldExistInAkasha &&
      userSearchValueProbe &&
      identityMaintained &&
      remainsIfAnilistGone;

  return AniListRemovalEntry(
    selection: selection,
    draftWithoutAnilist: stripped,
    shouldExistInAkasha: shouldExistInAkasha,
    userSearchValue: userSearchValueProbe,
    identityMaintained: identityMaintained,
    remainsIfAnilistGone: remainsIfAnilistGone,
    verdict: allYes ? AniListRemovalVerdict.pass : AniListRemovalVerdict.fail,
    notes: notes,
  );
}

String formatAniListRemovalMarkdown({
  required AniListRemovalReport report,
  required DiscoveryTechnicalKpi technical,
  required DiscoveryProductKpiV2 product,
  required DiscoveryPatchGate patchGate,
}) {
  final k = report.kpi;
  final buf = StringBuffer();

  buf.writeln('# AniList Removal Test');
  buf.writeln();
  buf.writeln('> AKASHA ≠ AniList 미러 — **독립 Registry** 증명');
  buf.writeln('> 선정 작품에서 `externalIds.anilist`·AniList 출처 **제거** 후 평가');
  buf.writeln();
  buf.writeln('## Independence KPI');
  buf.writeln();
  buf.writeln('| KPI | 값 |');
  buf.writeln('|-----|-----|');
  buf.writeln(
    '| independentRegistryValue | ${(k.independentRegistryValue * 100).toStringAsFixed(1)}% |',
  );
  buf.writeln(
    '| percentWorksJustifiedWithoutAniList | '
    '${(k.percentWorksJustifiedWithoutAniList * 100).toStringAsFixed(1)}% |',
  );
  buf.writeln('| PASS | ${k.passCount} |');
  buf.writeln('| FAIL | ${k.failCount} |');
  buf.writeln(
    '| anilistRemovalTestPassed | **${k.anilistRemovalTestPassed}** |',
  );
  buf.writeln();

  buf.writeln('## KPI 계층');
  buf.writeln();
  buf.writeln('### Discovery (기술)');
  buf.writeln('- wouldCreate: ${technical.wouldCreate}');
  buf.writeln('- mergeCandidates: ${technical.mergeCandidates}');
  buf.writeln('- coverageDelta: ${technical.coverageDelta.toStringAsFixed(2)}');
  buf.writeln('- zeroToHit: ${technical.zeroToHit}');
  buf.writeln();
  buf.writeln('### Product');
  buf.writeln(
    '- userSearchGapResolved: '
    '${(product.userSearchGapResolved * 100).toStringAsFixed(1)}%',
  );
  buf.writeln(
    '- aliasCoverageIncrease: '
    '${(product.aliasCoverageIncrease * 100).toStringAsFixed(2)}%p',
  );
  buf.writeln(
    '- searchRecallIncrease: '
    '${(product.searchRecallIncrease * 100).toStringAsFixed(1)}%',
  );
  buf.writeln(
    '- franchiseCoverageIncrease: '
    '${(product.franchiseCoverageIncrease * 100).toStringAsFixed(1)}%',
  );
  buf.writeln(
    '- productReviewApproved: **${product.productReviewApproved}**',
  );
  buf.writeln();

  buf.writeln('## 5b Patch Gate (모두 true 필요)');
  buf.writeln();
  buf.writeln('| Gate | |');
  buf.writeln('|------|--|');
  buf.writeln('| recommend5bPatch | ${patchGate.recommend5bPatch} |');
  buf.writeln('| productReviewApproved | ${patchGate.productReviewApproved} |');
  buf.writeln(
    '| anilistRemovalTestPassed | ${patchGate.anilistRemovalTestPassed} |',
  );
  buf.writeln('| **allow5bReview** | **${patchGate.allow5bReview}** |');
  buf.writeln();
  buf.writeln('**5b: ON HOLD** — allow5bReview + 수동 승인');
  buf.writeln();

  buf.writeln('## 작품별 (4질문)');
  buf.writeln();
  for (var i = 0; i < report.entries.length; i++) {
    final e = report.entries[i];
    buf.writeln('### ${i + 1}. ${e.selection.item.title} — **${e.verdict.name.toUpperCase()}**');
    buf.writeln();
    buf.writeln('| 질문 | YES |');
    buf.writeln('|------|-----|');
    buf.writeln('| 1. 여전히 AKASHA에 존재해야 하는가? | ${e.shouldExistInAkasha} |');
    buf.writeln('| 2. 사용자 검색 가치가 있는가? | ${e.userSearchValue} |');
    buf.writeln('| 3. title/aliases/creator/year로 정체성 유지? | ${e.identityMaintained} |');
    buf.writeln('| 4. AniList 사라져도 Registry에 남아야 하는가? | ${e.remainsIfAnilistGone} |');
    buf.writeln();
    for (final n in e.notes) {
      buf.writeln('- $n');
    }
    buf.writeln();
    buf.writeln('```json');
    buf.writeln(
      const JsonEncoder.withIndent('  ').convert(e.draftWithoutAnilist),
    );
    buf.writeln('```');
    buf.writeln();
  }

  buf.writeln('## 수동 체크리스트');
  buf.writeln();
  buf.writeln('- [ ] PASS 작품은 **외부 DB 없이** 존재 이유를 설명할 수 있는가');
  buf.writeln('- [ ] FAIL 작품은 등록 대상에서 **제외**하는가');
  buf.writeln('- [ ] "왜 AKASHA에 있는가"를 AniList ID 없이 말할 수 있는가');
  buf.writeln();

  return buf.toString();
}

String formatAniListRemovalJson(AniListRemovalReport report) {
  return const JsonEncoder.withIndent('  ').convert(report.toJson());
}
