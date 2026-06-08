import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/discovery_review_report.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/registry_snapshot.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/user_value_assessment.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_kpi.dart';
// ignore: avoid_relative_lib_imports
import '../tool/discovery/shadow_write_runner.dart';

void main() {
  group('DiscoveryReviewReport', () {
    test('samples 10 from wouldCreate evenly', () {
      final items = List.generate(
        96,
        (i) => ShadowWriteItem(
          outcome: ShadowWriteOutcome.wouldCreate,
          externalId: '$i',
          title: 'Anime $i',
          shadowWorkId: 'wk_${(411 + i).toString().padLeft(9, '0')}',
          draft: {
            'workId': 'wk_${(411 + i).toString().padLeft(9, '0')}',
            'title': 'Anime $i',
            'category': 'animation',
            'domain': 'subculture',
            'releaseYear': 2010,
            'externalIds': {'anilist': '$i'},
          },
        ),
      );

      final sampled = sampleWouldCreateItems(items, sampleSize: 10);
      expect(sampled.length, 10);
      expect(sampled.first.title, 'Anime 0');
    });

    test('report includes identity without anilist', () {
      final shadow = ShadowWriteResult(
        kpi: const ShadowWriteKpi(
          inputDrafts: 1,
          wouldCreate: 1,
        ),
        items: [
          ShadowWriteItem(
            outcome: ShadowWriteOutcome.wouldCreate,
            externalId: '42',
            title: 'Test Anime',
            shadowWorkId: 'wk_000000411',
            targetShard: 'shards/animation/fc.json',
            qualityScore: 60,
            qualityTier: 3,
            draft: {
              'workId': 'wk_000000411',
              'title': 'Test Anime',
              'category': 'animation',
              'domain': 'subculture',
              'releaseYear': 2020,
              'creator': 'Test Studio',
              'titles': {'en': 'Test Anime', 'romaji': 'Test'},
              'aliases': ['テスト', 'Test Alias'],
              'externalIds': {'anilist': '42'},
            },
          ),
        ],
      );

      final report = buildDiscoveryReviewReport(
        channelId: 'anilist_animation',
        shadowResult: shadow,
        registry: RegistrySnapshot.fromWorks(const []),
        sampleSize: 1,
      );

      expect(report.samples.length, 1);
      expect(report.samples.first.identityCheck.akashaIdentitySufficient, isTrue);
      expect(
        report.samples.first.identityCheck.draftWithoutAnilist.containsKey(
          'externalIds',
        ),
        isFalse,
      );
      expect(report.samples.first.policyRisks, isEmpty);
      expect(report.readyForTrialWrite, isTrue);
      expect(report.samples.first.userValue.tier, UserValueTier.high);

      final md = formatReviewReportMarkdown(report);
      expect(md, contains('가치 있는 작품을 우선 발견'));
      expect(md, contains('Minimal Core'));
      expect(md, contains('User Value'));
      expect(md, contains('Phase B'));
    });
  });
}
