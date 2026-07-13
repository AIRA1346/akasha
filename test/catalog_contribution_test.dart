import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/catalog_contribution.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/catalog_contribution_export.dart';
import 'package:akasha/config/catalog_contribution_config.dart';

// ignore: avoid_relative_lib_imports
import '../tool/catalog_contribution_validate.dart';

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
        searchQuery: '테스트',
      ),
    );

    final restored = CatalogContribution.fromJson(c.toJson());
    expect(restored.status, CatalogContributionStatus.accepted);
    expect(restored.addWork?.title, '테스트 작품');
    expect(restored.addWork?.releaseYear, 2020);
  });

  test('legacy addWork JSON drops Tier 1 poster and description fields', () {
    final proposal = CatalogAddWorkProposal.fromJson({
      'title': '레거시 작품',
      'category': 'manga',
      'domain': 'subculture',
      'posterPath': 'https://image.tmdb.org/t/p/w500/legacy.jpg',
      'description': '레거시 설명',
    });

    expect(proposal.toJson().containsKey('posterPath'), isFalse);
    expect(proposal.toJson().containsKey('description'), isFalse);

    final fixProposal = CatalogFixWorkProposal.fromJson({
      'targetWorkId': 'wk_000000001',
      'fields': {'title': '정상 제목 수정', 'posterPath': null, 'description': ''},
    });
    expect(fixProposal.fields, {'title': '정상 제목 수정'});
  });

  test('contribution validator rejects Tier 1 presentation fields', () {
    final errors = validateContributionMap({
      'id': 'legacy_add',
      'kind': 'addWork',
      'addWork': {
        'title': '레거시 작품',
        'category': 'manga',
        'domain': 'subculture',
        'posterPath': 'https://image.tmdb.org/t/p/w500/legacy.jpg',
        'description': '레거시 설명',
      },
    });

    expect(errors, contains(contains('posterPath is forbidden')));
    expect(errors, contains(contains('description is forbidden')));

    final fixErrors = validateContributionMap({
      'id': 'legacy_fix',
      'kind': 'fixWork',
      'fixWork': {
        'targetWorkId': 'wk_000000001',
        'issue': '금지 필드 제거 확인',
        'fields': {'posterPath': null, 'description': ''},
      },
    });
    expect(fixErrors, contains(contains('posterPath is forbidden')));
    expect(fixErrors, contains(contains('description is forbidden')));
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
    expect(addPending.repoRelativePath, 'contributions/add/pending/a1.json');

    final fixMerged = CatalogContribution(
      id: 'f1',
      kind: CatalogContributionKind.fixWork,
      status: CatalogContributionStatus.merged,
      createdAt: DateTime.utc(2026, 6, 8),
      fixWork: CatalogFixWorkProposal(targetWorkId: 'wk_000000001'),
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
      '[catalog-add] 원피스 (Manga)',
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
      fixWork: CatalogFixWorkProposal(targetWorkId: 'wk_1'),
    );
    final merged = c.withStatus(CatalogContributionStatus.merged);
    expect(merged.status, CatalogContributionStatus.merged);
    expect(merged.updatedAt, isNotNull);
  });
}
