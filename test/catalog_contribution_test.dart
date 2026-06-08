import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/catalog_contribution.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/catalog_contribution_export.dart';
import 'package:akasha/config/catalog_contribution_config.dart';

void main() {
  test('CatalogContribution status defaults to submitted', () {
    final c = CatalogContribution(
      id: 'contrib_test',
      kind: CatalogContributionKind.addWork,
      createdAt: DateTime.utc(2026, 6, 8),
      addWork: const CatalogAddWorkProposal(
        title: '테스트',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      ),
    );
    expect(c.status, CatalogContributionStatus.submitted);
    expect(c.toJson()['status'], 'submitted');
  });

  test('CatalogContribution addWork round-trip JSON with status', () {
    final c = CatalogContribution(
      id: 'contrib_test',
      kind: CatalogContributionKind.addWork,
      status: CatalogContributionStatus.accepted,
      createdAt: DateTime.utc(2026, 6, 8),
      addWork: const CatalogAddWorkProposal(
        title: '테스트 작품',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        releaseYear: 2020,
        posterPath: 'https://example.com/poster.jpg',
        searchQuery: '테스트',
      ),
    );

    final restored = CatalogContribution.fromJson(c.toJson());
    expect(restored.status, CatalogContributionStatus.accepted);
    expect(restored.addWork?.title, '테스트 작품');
  });

  test('repoRelativePath maps status to GitHub folders', () {
    final addPending = CatalogContribution(
      id: 'a1',
      kind: CatalogContributionKind.addWork,
      createdAt: DateTime.utc(2026, 6, 8),
      addWork: const CatalogAddWorkProposal(
        title: 't',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      ),
    );
    expect(
      addPending.repoRelativePath,
      'contributions/add/pending/a1.json',
    );

    final fixMerged = CatalogContribution(
      id: 'f1',
      kind: CatalogContributionKind.fixWork,
      status: CatalogContributionStatus.merged,
      createdAt: DateTime.utc(2026, 6, 8),
      fixWork: const CatalogFixWorkProposal(targetWorkId: 'wk_000000001'),
    );
    expect(fixMerged.repoRelativePath, 'contributions/fix/merged/f1.json');
  });

  test('CatalogContributionExport bundle v2', () {
    final contribution = CatalogContribution(
      id: 'a1',
      kind: CatalogContributionKind.addWork,
      createdAt: DateTime.utc(2026, 6, 8),
      addWork: const CatalogAddWorkProposal(
        title: '원피스',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      ),
    );

    expect(
      CatalogContributionExport.issueTitle(contribution),
      '[catalog-add] 원피스 (만화)',
    );

    final bundle = CatalogContributionBundle(
      version: CatalogContributionConfig.bundleVersion,
      exportedAt: DateTime.utc(2026, 6, 8),
      appVersion: '1.0.0',
      contributions: [contribution],
    );
    final parsed = CatalogContributionExport.bundleFromJson(
      CatalogContributionExport.bundleToJson(bundle),
    );
    expect(parsed.version, 2);
    expect(parsed.contributions.first.status.jsonName, 'submitted');
  });

  test('withStatus updates terminal state', () {
    final c = CatalogContribution(
      id: 'x',
      kind: CatalogContributionKind.fixWork,
      createdAt: DateTime.utc(2026, 6, 8),
      fixWork: const CatalogFixWorkProposal(targetWorkId: 'wk_1'),
    );
    final merged = c.withStatus(CatalogContributionStatus.merged);
    expect(merged.status, CatalogContributionStatus.merged);
    expect(merged.updatedAt, isNotNull);
  });
}
