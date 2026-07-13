import 'enums.dart';
import 'work_titles.dart';

/// 유저가 글로벌 사전(akasha-db)에 보내는 제안 종류
enum CatalogContributionKind { addWork, fixWork }

/// GitHub akasha-db 에서 관리하는 제안 상태 (서버비 0원)
enum CatalogContributionStatus {
  submitted,
  aiVerified,
  accepted,
  rejected,
  merged;

  String get jsonName => switch (this) {
    CatalogContributionStatus.submitted => 'submitted',
    CatalogContributionStatus.aiVerified => 'ai_verified',
    CatalogContributionStatus.accepted => 'accepted',
    CatalogContributionStatus.rejected => 'rejected',
    CatalogContributionStatus.merged => 'merged',
  };

  static CatalogContributionStatus fromJsonName(String? raw) {
    switch (raw) {
      case 'ai_verified':
        return CatalogContributionStatus.aiVerified;
      case 'accepted':
        return CatalogContributionStatus.accepted;
      case 'rejected':
        return CatalogContributionStatus.rejected;
      case 'merged':
        return CatalogContributionStatus.merged;
      case 'submitted':
      default:
        return CatalogContributionStatus.submitted;
    }
  }

  /// akasha-db/contributions/{add|fix}/{folder}/ 경로 세그먼트
  String get repoFolderName => switch (this) {
    CatalogContributionStatus.submitted => 'pending',
    CatalogContributionStatus.aiVerified => 'pending',
    CatalogContributionStatus.accepted => 'accepted',
    CatalogContributionStatus.rejected => 'rejected',
    CatalogContributionStatus.merged => 'merged',
  };

  bool get isTerminal =>
      this == CatalogContributionStatus.rejected ||
      this == CatalogContributionStatus.merged;
}

/// 신규 작품 추가 제안 (Tier 1 메타 — 직접 작성)
class CatalogAddWorkProposal {
  final String title;
  final WorkTitles titles;
  final String creator;
  final int? releaseYear;
  final MediaCategory category;
  final AppDomain domain;
  final List<String> tags;
  final Map<String, String> externalIds;
  final String? searchQuery;

  const CatalogAddWorkProposal({
    required this.title,
    this.titles = const WorkTitles(),
    this.creator = '',
    this.releaseYear,
    required this.category,
    required this.domain,
    this.tags = const [],
    this.externalIds = const {},
    this.searchQuery,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (!titles.isEmpty) 'titles': titles.toJson(),
    'creator': creator,
    if (releaseYear != null) 'releaseYear': releaseYear,
    'category': category.name,
    'domain': domain.name,
    if (tags.isNotEmpty) 'tags': tags,
    if (externalIds.isNotEmpty) 'externalIds': externalIds,
    if (searchQuery != null && searchQuery!.isNotEmpty)
      'searchQuery': searchQuery,
  };

  factory CatalogAddWorkProposal.fromJson(Map<String, dynamic> json) {
    return CatalogAddWorkProposal(
      title: json['title']?.toString() ?? '',
      titles: WorkTitles.fromJson(json['titles']),
      creator: json['creator']?.toString() ?? '',
      releaseYear: int.tryParse(json['releaseYear']?.toString() ?? ''),
      category: MediaCategory.values.firstWhere(
        (e) => e.name == json['category']?.toString(),
        orElse: () => MediaCategory.manga,
      ),
      domain: AppDomain.values.firstWhere(
        (e) => e.name == json['domain']?.toString(),
        orElse: () => AppDomain.subculture,
      ),
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      externalIds: _parseStringMap(json['externalIds']),
      searchQuery: json['searchQuery']?.toString(),
    );
  }
}

/// 기존 사전 작품 수정 제안
class CatalogFixWorkProposal {
  final String targetWorkId;
  final Map<String, dynamic> fields;
  final String issue;

  CatalogFixWorkProposal({
    required this.targetWorkId,
    Map<String, dynamic> fields = const {},
    this.issue = '',
  }) : fields = Map.unmodifiable(
         Map<String, dynamic>.from(fields)
           ..remove('posterPath')
           ..remove('description'),
       );

  Map<String, dynamic> toJson() => {
    'targetWorkId': targetWorkId,
    if (fields.isNotEmpty) 'fields': fields,
    if (issue.isNotEmpty) 'issue': issue,
  };

  factory CatalogFixWorkProposal.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = <String, dynamic>{};
    if (rawFields is Map) {
      rawFields.forEach((k, v) {
        if (k != null) fields[k.toString()] = v;
      });
    }
    return CatalogFixWorkProposal(
      targetWorkId: json['targetWorkId']?.toString() ?? '',
      fields: fields,
      issue: json['issue']?.toString() ?? '',
    );
  }
}

/// 로컬 제안 1건
class CatalogContribution {
  final String id;
  final CatalogContributionKind kind;
  final CatalogContributionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? note;
  final String? statusNote;
  final CatalogAddWorkProposal? addWork;
  final CatalogFixWorkProposal? fixWork;

  const CatalogContribution({
    required this.id,
    required this.kind,
    this.status = CatalogContributionStatus.submitted,
    required this.createdAt,
    this.updatedAt,
    this.note,
    this.statusNote,
    this.addWork,
    this.fixWork,
  });

  /// akasha-db repo 상대 경로 (import 시)
  String get repoKindSegment => switch (kind) {
    CatalogContributionKind.addWork => 'add',
    CatalogContributionKind.fixWork => 'fix',
  };

  String get repoRelativePath =>
      'contributions/$repoKindSegment/${status.repoFolderName}/$id.json';

  CatalogContribution withStatus(
    CatalogContributionStatus newStatus, {
    String? statusNote,
  }) {
    return CatalogContribution(
      id: id,
      kind: kind,
      status: newStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      note: note,
      statusNote: statusNote ?? this.statusNote,
      addWork: addWork,
      fixWork: fixWork,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'status': status.jsonName,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
    if (statusNote != null && statusNote!.isNotEmpty) 'statusNote': statusNote,
    if (addWork != null) 'addWork': addWork!.toJson(),
    if (fixWork != null) 'fixWork': fixWork!.toJson(),
  };

  factory CatalogContribution.fromJson(Map<String, dynamic> json) {
    final kind = CatalogContributionKind.values.firstWhere(
      (e) => e.name == json['kind']?.toString(),
      orElse: () => CatalogContributionKind.addWork,
    );
    return CatalogContribution(
      id: json['id']?.toString() ?? '',
      kind: kind,
      status: CatalogContributionStatus.fromJsonName(
        json['status']?.toString(),
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      note: json['note']?.toString(),
      statusNote: json['statusNote']?.toString(),
      addWork: json['addWork'] is Map
          ? CatalogAddWorkProposal.fromJson(
              Map<String, dynamic>.from(json['addWork'] as Map),
            )
          : null,
      fixWork: json['fixWork'] is Map
          ? CatalogFixWorkProposal.fromJson(
              Map<String, dynamic>.from(json['fixWork'] as Map),
            )
          : null,
    );
  }

  String get summaryLabel {
    final statusTag = status.jsonName;
    switch (kind) {
      case CatalogContributionKind.addWork:
        return '[$statusTag] 추가: ${addWork?.title ?? '(제목 없음)'}';
      case CatalogContributionKind.fixWork:
        return '[$statusTag] 수정: ${fixWork?.targetWorkId ?? ''}';
    }
  }
}

/// export / maintainer inbox용 번들
class CatalogContributionBundle {
  final int version;
  final DateTime exportedAt;
  final String appVersion;
  final List<CatalogContribution> contributions;

  const CatalogContributionBundle({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.contributions,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'contributions': contributions.map((c) => c.toJson()).toList(),
  };

  factory CatalogContributionBundle.fromJson(Map<String, dynamic> json) {
    final list = json['contributions'];
    return CatalogContributionBundle(
      version: json['version'] as int? ?? 1,
      exportedAt:
          DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      appVersion: json['appVersion']?.toString() ?? '',
      contributions: list is List
          ? list
                .whereType<Map>()
                .map(
                  (e) => CatalogContribution.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

Map<String, String> _parseStringMap(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, String>{};
  raw.forEach((k, v) {
    if (k == null || v == null) return;
    final key = k.toString().trim();
    final val = v.toString().trim();
    if (key.isNotEmpty && val.isNotEmpty) out[key] = val;
  });
  return out;
}
