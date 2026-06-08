import 'dart:convert';

import '../config/catalog_contribution_config.dart';
import '../models/catalog_contribution.dart';

/// 제안 export·GitHub Issue 본문 생성
class CatalogContributionExport {
  static String bundleToJson(CatalogContributionBundle bundle) {
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  static CatalogContributionBundle bundleFromJson(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Contribution bundle must be a JSON object');
    }
    return CatalogContributionBundle.fromJson(decoded);
  }

  static String issueTitle(CatalogContribution contribution) {
    switch (contribution.kind) {
      case CatalogContributionKind.addWork:
        final title = contribution.addWork?.title ?? '작품';
        final cat = contribution.addWork?.category.label ?? '';
        return '[catalog-add] $title ($cat)';
      case CatalogContributionKind.fixWork:
        final id = contribution.fixWork?.targetWorkId ?? '';
        return '[catalog-fix] $id';
    }
  }

  static String issueBody(CatalogContribution contribution) {
    final buffer = StringBuffer()
      ..writeln('## AKASHA 카탈로그 제안')
      ..writeln()
      ..writeln('- kind: `${contribution.kind.name}`')
      ..writeln('- id: `${contribution.id}`')
      ..writeln(
        '- createdAt: `${contribution.createdAt.toUtc().toIso8601String()}`',
      );
    if (contribution.note != null && contribution.note!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### 메모')
        ..writeln(contribution.note);
    }
    buffer
      ..writeln()
      ..writeln('### JSON')
      ..writeln('```json')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert(contribution.toJson()),
      )
      ..writeln('```')
      ..writeln()
      ..writeln('---')
      ..writeln(
        '검수 후 `dart run tool/apply_catalog_contributions.dart` 로 inbox import.',
      );
    return buffer.toString();
  }

  static Uri githubIssueUri(CatalogContribution contribution) {
    final title = Uri.encodeComponent(issueTitle(contribution));
    final body = Uri.encodeComponent(issueBody(contribution));
    return Uri.parse(
      '${CatalogContributionConfig.newIssueUrl}?title=$title&body=$body',
    );
  }
}
