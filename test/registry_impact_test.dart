import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_coverage_utils.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_impact_report.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_impact_selector.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_kpi.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';

void main() {
  final emptyCoverage = RegistryCoverageSnapshot(
    totalEntries: 100,
    animationEntries: 40,
    searchTokens: {'existing'},
    normalizedTitles: {'existingtitle'},
  );

  final franchiseIndex = FranchiseAffinityIndex(
    normToGroupLabel: const {},
  );

  group('Registry Impact', () {
    test('selects gap-filling core works', () {
      final item = ShadowWriteItem(
        outcome: ShadowWriteOutcome.wouldCreate,
        externalId: '100',
        title: 'Unique Impact Anime',
        shadowWorkId: 'wk_000000500',
        qualityScore: 60,
        draft: {
          'workId': 'wk_000000500',
          'title': 'Unique Impact Anime',
          'category': 'animation',
          'domain': 'subculture',
          'releaseYear': 2001,
          'creator': 'Studio X',
          'titles': {'en': 'Unique Impact Anime', 'romaji': 'UIA'},
          'aliases': ['UIA', 'ユニーク'],
          'externalIds': {'anilist': '100'},
        },
      );

      final scored = scoreImpactCandidate(
        item: item,
        draft: item.draft!,
        coverage: emptyCoverage,
        franchiseIndex: franchiseIndex,
      );

      expect(scored.gap.fillsTitleGap, isTrue);
      expect(scored.coreWork, isTrue);
      expect(scored.impactScore, greaterThanOrEqualTo(6));

      final selected = selectImpactCandidates(scored: [scored]);
      expect(selected.length, 1);
    });

    test('impact report recommends phase C when gaps filled', () {
      final selected = List.generate(5, (i) {
        final copy = scoreImpactCandidate(
          item: ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldCreate,
            externalId: '$i',
            title: 'Anime $i',
            shadowWorkId: 'wk_00000050$i',
            draft: {
              'title': 'Anime $i',
              'category': 'animation',
              'domain': 'subculture',
              'releaseYear': 2000 + i,
              'creator': 'Studio',
              'titles': {'en': 'Anime $i', 'romaji': 'A$i'},
              'aliases': ['x', 'y'],
              'externalIds': {'anilist': '$i'},
            },
          ),
          draft: {
            'title': 'Anime $i',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2000 + i,
            'creator': 'Studio',
            'titles': {'en': 'Anime $i', 'romaji': 'A$i'},
            'aliases': ['x', 'y'],
            'externalIds': {'anilist': '$i'},
          },
          coverage: emptyCoverage,
          franchiseIndex: franchiseIndex,
        );
        return copy;
      });

      final shadow = ShadowWriteResult(
        kpi: const ShadowWriteKpi(inputDrafts: 10, wouldCreate: 5),
        items: selected.map((s) => s.item).toList(),
      );

      final report = buildRegistryImpactReport(
        channelId: 'anilist_animation',
        shadowResult: shadow,
        coverageBefore: emptyCoverage,
        selected: selected,
      );

      expect(report.kpi.coverageIncreases, isTrue);
      expect(report.kpi.searchQualityImproves, isTrue);
      expect(report.kpi.recommendPhaseC, isTrue);

      final md = formatRegistryImpactMarkdown(report);
      expect(md, contains('Registry Impact Report'));
      expect(md, contains('Coverage KPI'));
    });
  });
}
