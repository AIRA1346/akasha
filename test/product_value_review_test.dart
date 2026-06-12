import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/product_value_review.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_coverage_utils.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_diff_compare.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_impact_selector.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/user_value_assessment.dart';

void main() {
  ImpactSelectionScore sel(Map<String, dynamic> draft) {
    return ImpactSelectionScore(
      item: ShadowWriteItem(
        outcome: ShadowWriteOutcome.wouldCreate,
        externalId: '42',
        title: draft['title']?.toString() ?? '',
        shadowWorkId: draft['workId']?.toString(),
        draft: draft,
        qualityScore: 60,
      ),
      userValue: const UserValueAssessment(
        tier: UserValueTier.high,
        score: 8,
        highSignals: ['gap'],
        lowSignals: [],
        prioritizationNote: 'high',
      ),
      gap: const GapFillAnalysis(
        fillsTitleGap: true,
        novelSearchTokens: ['monster'],
        totalNewTokens: 3,
      ),
      coreWork: true,
      franchiseValue: false,
      impactScore: 9,
      axes: const [],
      reasons: const ['Registry Gap'],
    );
  }

  group('ProductValueReview', () {
    test('both driver when gap and anilist ref', () {
      final draft = {
        'workId': 'wk_000000411',
        'title': 'Monster',
        'category': 'animation',
        'domain': 'subculture',
        'releaseYear': 2004,
        'creator': 'Madhouse',
        'titles': {'en': 'Monster'},
        'aliases': ['モンスター'],
        'externalIds': {'anilist': '1'},
      };
      final selected = [sel(draft)];
      final diff = RegistryDiffResult(
        entriesBefore: 402,
        entriesAfter: 403,
        searchWins: [
          SearchWin(
            query: 'Monster',
            hitsBefore: 0,
            hitsAfter: 1,
            newTopTitle: 'Monster',
            newTopWorkId: 'wk_000000411',
            rankAfter: 1,
          ),
        ],
        zeroToHitCount: 1,
        coverageBefore: const CoverageMetrics(
          total: 85,
          withCreator: 85,
          withAliases: 0,
          withReleaseYear: 85,
        ),
        coverageAfter: const CoverageMetrics(
          total: 86,
          withCreator: 86,
          withAliases: 1,
          withReleaseYear: 86,
        ),
        franchiseGains: const [],
        userVisibleWins: const ['Monster 0->1'],
        diffStrong: true,
        recommend5bPatch: true,
      );

      final report = buildProductValueReview(selected: selected, diff: diff);
      expect(report.entries.first.additionDriver, AdditionDriver.both);
      expect(report.entries.first.resolvesUserSearchGap, isTrue);
      expect(report.entries.first.survivesWithoutExternalSpine, isTrue);
      expect(report.kpi.userSearchGapResolved, 1.0);
    });

    test('anilistPresence fails product gate', () {
      final draft = {
        'workId': 'wk_000000412',
        'title': 'X',
        'category': 'animation',
        'externalIds': {'anilist': '99'},
      };
      final selected = [
        ImpactSelectionScore(
          item: ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldCreate,
            externalId: '99',
            title: 'X',
            shadowWorkId: 'wk_000000412',
            draft: draft,
          ),
          userValue: const UserValueAssessment(
            tier: UserValueTier.low,
            score: 0,
            highSignals: [],
            lowSignals: ['sparse'],
            prioritizationNote: 'low',
          ),
          gap: const GapFillAnalysis(
            fillsTitleGap: false,
            novelSearchTokens: [],
            totalNewTokens: 0,
          ),
          coreWork: false,
          franchiseValue: false,
          impactScore: 0,
          axes: const [],
          reasons: const [],
        ),
      ];
      final diff = RegistryDiffResult(
        entriesBefore: 1,
        entriesAfter: 2,
        searchWins: const [],
        zeroToHitCount: 0,
        coverageBefore: const CoverageMetrics(
          total: 1,
          withCreator: 0,
          withAliases: 0,
          withReleaseYear: 0,
        ),
        coverageAfter: const CoverageMetrics(
          total: 2,
          withCreator: 0,
          withAliases: 0,
          withReleaseYear: 0,
        ),
        franchiseGains: const [],
        userVisibleWins: const [],
        diffStrong: false,
        recommend5bPatch: false,
      );

      final report = buildProductValueReview(selected: selected, diff: diff);
      expect(report.entries.first.additionDriver, AdditionDriver.externalSpineOnly);
      expect(report.entries.first.productValuePassed, isFalse);
      expect(report.kpi.recommend5bPatch, isFalse);
    });
  });
}
