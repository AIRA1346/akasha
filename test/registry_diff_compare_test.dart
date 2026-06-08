import 'package:flutter_test/flutter_test.dart';

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
  RegistryVirtualState stateWith(List<Map<String, dynamic>> drafts) {
    return RegistryVirtualState(
      entries: drafts.map(VirtualWorkEntry.fromDraft).toList(),
    );
  }

  ImpactSelectionScore fakeSelected(Map<String, dynamic> draft) {
    final item = ShadowWriteItem(
      outcome: ShadowWriteOutcome.wouldCreate,
      externalId: '1',
      title: draft['title']?.toString() ?? '',
      shadowWorkId: draft['workId']?.toString(),
      draft: draft,
    );
    return ImpactSelectionScore(
      item: item,
      userValue: const UserValueAssessment(
        tier: UserValueTier.high,
        score: 8,
        highSignals: [],
        lowSignals: [],
        prioritizationNote: '',
      ),
      gap: const GapFillAnalysis(
        fillsTitleGap: true,
        novelSearchTokens: ['uniqueanime'],
        totalNewTokens: 1,
      ),
      coreWork: true,
      franchiseValue: false,
      impactScore: 9,
      axes: const [],
      reasons: const [],
    );
  }

  group('RegistryDiff', () {
    test('zeroToHit when new work becomes searchable', () {
      final before = stateWith(const []);
      final draft = {
        'workId': 'wk_000000411',
        'title': 'Unique Anime Alpha',
        'category': 'animation',
        'domain': 'subculture',
        'releaseYear': 2000,
        'creator': 'Studio',
        'titles': {'en': 'Unique Anime Alpha'},
        'aliases': ['UAA'],
        'externalIds': {'anilist': '1'},
      };
      final after = before.withAddedDrafts([draft]);
      final selected = [fakeSelected(draft)];

      final diff = compareRegistrySnapshots(
        before: before,
        after: after,
        selected: selected,
      );

      expect(diff.zeroToHitCount, greaterThan(0));
      expect(diff.userVisibleWins, isNotEmpty);
      expect(diff.diffStrong, isTrue);
    });

    test('coverage increases with creator and aliases', () {
      final before = stateWith([
        {
          'workId': 'wk_000000001',
          'title': 'Old Anime',
          'category': 'animation',
          'domain': 'subculture',
        },
      ]);
      final draft = {
        'workId': 'wk_000000412',
        'title': 'New Rich Anime',
        'category': 'animation',
        'domain': 'subculture',
        'releaseYear': 2005,
        'creator': 'Madhouse',
        'aliases': ['NRA'],
        'externalIds': {'anilist': '2'},
      };
      final after = before.withAddedDrafts([draft]);
      final diff = compareRegistrySnapshots(
        before: before,
        after: after,
        selected: [fakeSelected(draft)],
      );

      expect(
        diff.coverageAfter.withCreator,
        greaterThan(diff.coverageBefore.withCreator),
      );
      expect(
        diff.coverageAfter.withAliases,
        greaterThan(diff.coverageBefore.withAliases),
      );
    });
  });
}
