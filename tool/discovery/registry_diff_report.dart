// registry_diff_report.md — Registry Improvement 증명.
library;

import 'dart:convert';

import 'registry_diff_compare.dart';

String formatRegistryDiffMarkdown({
  required RegistryDiffResult diff,
  required List<String> selectedTitles,
}) {
  final buf = StringBuffer();
  buf.writeln('# Registry Diff Report');
  buf.writeln();
  buf.writeln('> 질문: **"AKASHA가 실제로 더 좋아졌는가?"**');
  buf.writeln('> "10건을 추가했다"가 아니라 **"사용자가 무엇을 더 찾을 수 있게 되었는가"**');
  buf.writeln();
  buf.writeln('## Snapshot');
  buf.writeln();
  buf.writeln('| | Before | After (virtual) |');
  buf.writeln('|--|--------|-----------------|');
  buf.writeln('| Registry entries | ${diff.entriesBefore} | ${diff.entriesAfter} |');
  buf.writeln(
    '| animation (coverage base) | ${diff.coverageBefore.total} | ${diff.coverageAfter.total} |',
  );
  buf.writeln('| **diffStrong** | | **${diff.diffStrong}** |');
  buf.writeln('| **recommend5bPatch** | | **${diff.recommend5bPatch}** |');
  buf.writeln();
  buf.writeln('선정 작품: ${selectedTitles.map((t) => '"$t"').join(', ')}');
  buf.writeln();

  buf.writeln('## 1. 검색 결과 변화');
  buf.writeln();
  buf.writeln('| 지표 | 값 |');
  buf.writeln('|------|-----|');
  buf.writeln('| 0건 → 발견 (zeroToHit) | **${diff.zeroToHitCount}** |');
  buf.writeln('| 검색 probe 수 | ${diff.searchWins.length} |');
  buf.writeln();
  if (diff.searchWins.isNotEmpty) {
    buf.writeln('| 검색어 | Before | After | 신규 top | rank |');
    buf.writeln('|--------|--------|-------|----------|------|');
    for (final w in diff.searchWins.take(15)) {
      buf.writeln(
        '| ${w.query} | ${w.hitsBefore} | ${w.hitsAfter} | '
        '${w.newTopTitle ?? "-"} | ${w.rankAfter ?? "-"} |',
      );
    }
    buf.writeln();
  }

  buf.writeln('## 2. Coverage 변화 (animation)');
  buf.writeln();
  final cb = diff.coverageBefore;
  final ca = diff.coverageAfter;
  buf.writeln('| 축 | Before | After | Δ |');
  buf.writeln('|----|--------|-------|---|');
  buf.writeln(_covRow('creator', cb.withCreator, ca.withCreator, cb.total, ca.total));
  buf.writeln(_covRow('aliases', cb.withAliases, ca.withAliases, cb.total, ca.total));
  buf.writeln(
    _covRow('releaseYear', cb.withReleaseYear, ca.withReleaseYear, cb.total, ca.total),
  );
  buf.writeln();

  buf.writeln('## 3. Franchise 변화');
  buf.writeln();
  if (diff.franchiseGains.isEmpty) {
    buf.writeln('- 이번 선정 10건에서 franchise 인접 신호 없음 (Gap 감소는 검색·Coverage 축에서 평가)');
  } else {
    for (final f in diff.franchiseGains) {
      buf.writeln('- **${f.franchiseLabel}** ← "${f.addedTitle}" (`${f.addedWorkId}`) 인접');
    }
  }
  buf.writeln();

  buf.writeln('## 4. User-visible 변화');
  buf.writeln();
  buf.writeln('사용자가 체감 가능한 **신규 검색 성공** 사례:');
  buf.writeln();
  if (diff.userVisibleWins.isEmpty) {
    buf.writeln('- (없음 — diff 약함, 5b 보류 검토)');
  } else {
    for (final u in diff.userVisibleWins) {
      buf.writeln('- $u');
    }
  }
  buf.writeln();

  buf.writeln('## 5b 게이트');
  buf.writeln();
  if (diff.recommend5bPatch) {
    buf.writeln(
      '**recommend5bPatch=true** — Registry Improvement 증명 충분. '
      '실제 patch는 **낮은 위험** 작업으로 진행 가능 (수동 승인).',
    );
  } else if (diff.diffStrong) {
    buf.writeln(
      '**diffStrong=true**, recommend5bPatch=false — 개선 신호 있으나 수동 체감 확인 후 patch.',
    );
  } else {
    buf.writeln(
      '**diff 약함** — 5b **보류**, Impact 선정 기준·소스 재검토 권장.',
    );
  }
  buf.writeln();
  buf.writeln('### 수동 체크리스트');
  buf.writeln();
  buf.writeln('- [ ] zeroToHit 검색어가 **실제 앱 검색**과 일치하는가');
  buf.writeln('- [ ] Coverage Δ가 사용자 가치로 이어지는가');
  buf.writeln('- [ ] 5b 성공 = write가 아니라 **Registry Improvement 증명**');
  buf.writeln();

  return buf.toString();
}

String _covRow(String label, int before, int after, int totalB, int totalA) {
  final rateB = totalB == 0 ? 0.0 : before / totalB;
  final rateA = totalA == 0 ? 0.0 : after / totalA;
  final delta = rateA - rateB;
  return '| $label | $before/$totalB (${(rateB * 100).toStringAsFixed(1)}%) | '
      '$after/$totalA (${(rateA * 100).toStringAsFixed(1)}%) | '
      '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(2)}%p |';
}

String formatRegistryDiffJson(RegistryDiffResult diff) {
  return const JsonEncoder.withIndent('  ').convert(diff.toJson());
}
