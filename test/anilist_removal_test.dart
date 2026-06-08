import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/anilist_removal_test.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/anilist_strip.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_coverage_utils.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_diff_compare.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_impact_selector.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_virtual_state.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/user_value_assessment.dart';

void main() {
  group('stripAnilistFromDraft', () {
    test('removes anilist reference', () {
      final stripped = stripAnilistFromDraft({
        'workId': 'wk_000000411',
        'title': 'Monster',
        'category': 'animation',
        'externalIds': {'anilist': '1'},
        'extensions': {'ingestChannel': 'anilist_animation'},
      });
      expect(draftHasAnilistReference(stripped), isFalse);
      expect(stripped.containsKey('externalIds'), isFalse);
    });
  });

  group('AniList Removal', () {
    test('PASS when identity and search survive strip', () {
      final draft = {
        'workId': 'wk_000000418',
        'title': 'Monster',
        'category': 'animation',
        'domain': 'subculture',
        'releaseYear': 2004,
        'creator': 'MADHOUSE',
        'titles': {
          'en': 'Monster',
          'romaji': 'MONSTER',
          'ja': 'MONSTER',
        },
        'aliases': ['モンスター'],
        'externalIds': {'anilist': '99'},
      };
      final sel = ImpactSelectionScore(
        item: ShadowWriteItem(
          outcome: ShadowWriteOutcome.wouldCreate,
          externalId: '99',
          title: 'Monster',
          shadowWorkId: 'wk_000000418',
          draft: draft,
          qualityScore: 60,
        ),
        userValue: const UserValueAssessment(
          tier: UserValueTier.high,
          score: 8,
          highSignals: [],
          lowSignals: [],
          prioritizationNote: '',
        ),
        gap: const GapFillAnalysis(
          fillsTitleGap: true,
          novelSearchTokens: ['monster'],
          totalNewTokens: 2,
        ),
        coreWork: true,
        franchiseValue: false,
        impactScore: 9,
        axes: const [],
        reasons: const [],
      );

      final diff = RegistryDiffResult(
        entriesBefore: 1,
        entriesAfter: 2,
        searchWins: [
          SearchWin(
            query: 'Monster',
            hitsBefore: 0,
            hitsAfter: 1,
            newTopTitle: 'Monster',
            newTopWorkId: 'wk_000000418',
            rankAfter: 1,
          ),
        ],
        zeroToHitCount: 1,
        coverageBefore: const CoverageMetrics(
          total: 1,
          withCreator: 1,
          withAliases: 0,
          withReleaseYear: 1,
        ),
        coverageAfter: const CoverageMetrics(
          total: 2,
          withCreator: 2,
          withAliases: 1,
          withReleaseYear: 2,
        ),
        franchiseGains: const [],
        userVisibleWins: const [],
        diffStrong: true,
        recommend5bPatch: true,
      );

      final report = buildAniListRemovalReport(
        selected: [sel],
        registryBefore: RegistryVirtualState(entries: const []),
        diff: diff,
      );

      expect(report.entries.first.passed, isTrue);
      expect(report.kpi.passCount, 1);
      expect(report.kpi.anilistRemovalTestPassed, isFalse); // ≥5건 필요
      expect(
        draftHasAnilistReference(report.entries.first.draftWithoutAnilist),
        isFalse,
      );
    });
  });
}
