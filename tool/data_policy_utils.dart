// [data-policy.md](../docs/history/policy/data-policy.md) — Registry CI 강제 규칙
library;

/// Tier 1 WorkEntry — description·posterPath 금지 (v1 Fact only)
const dataPolicyMaxDescriptionChars = 500;

const dataPolicyMaxTitleChars = 200;
const dataPolicyMaxCreatorChars = 200;
const dataPolicyMaxTagChars = 60;
const dataPolicyMaxTagCount = 25;
const dataPolicyMaxAliasChars = 120;
const dataPolicyMaxAliasCount = 30;

/// WorkEntry 최상위 허용 키 (이 외 최상위 키 = 금지)
const allowedWorkTopLevelKeys = {
  'workId',
  'legacyIds',
  'title',
  'titles',
  'aliases',
  'category',
  'domain',
  'creator',
  'releaseYear',
  'tags',
  'posterPath',
  'externalIds',
  'wikidataRelations',
  'extensions',
  'qualitySignals',
};

/// Wikidata Q-id (`Q123`) · P-id (`P31`)
final wikidataQidPattern = RegExp(r'^Q\d+$');
final wikidataPropertyPattern = RegExp(r'^P\d+$');

const allowedSeasonEntryKeys = {
  'label',
  'releaseYear',
  'year',
  'wikidata',
  'seriesQid',
  'episodes',
};

const allowedWikidataRelationKeys = {'p', 'target'};

/// extensions 내 허용 키 (레거시·provenance)
const allowedExtensionsKeys = {
  'registeredVia',
  'ingestSource',
  'ingestChannel',
  'anilistId',
  'anilist',
  'tmdb',
  'tmdbId',
  'steam',
  'steamAppId',
  'mal',
  'malId',
  'wikidata',
  'wikidataId',
  'isbn',
  'igdb',
  'igdbId',
  'seasons',
  'latestSeason',
  'edition',
  'platform',
  'platforms',
  'episodes',
  'label',
  'year',
  // Sprint / Scale 감사 흔적 (Phase 2 · A5)
  'coverageSprint03',
  'coverageSprint04ExternalId',
  'coverageSprint04R2Fix',
  'coverageScaleEnrich',
};

const allowedRegisteredViaValues = {
  'manual_pr',
  'official_db',
  'contribution',
  'pipeline',
  'curation',
};

const allowedQualitySignalKeys = {'externalIdVerified', 'franchiseVerified'};

/// 금지 필드명 (어디에 있든 금지 — Copyright Risk / UGC 미러)
const forbiddenFieldKeys = {
  'synopsis',
  'overview',
  'plot',
  'plotSummary',
  'tagline',
  'taglines',
  'review',
  'reviews',
  'criticReviews',
  'userReviews',
  'officialSummary',
  'short_description',
  'detailed_description',
  'descriptionHtml',
  'summary',
  'body',
  'content',
  'coverImage',
  'bannerImage',
  'backdropPath',
  'header_image',
  'capsule_image',
  'apiResponse',
  'rawResponse',
  'sourcePayload',
  'rawPayload',
  '_raw',
  'anilistData',
  'tmdbData',
  'steamData',
  'openLibraryData',
  'wikidataEntity',
  'searchTokens',
  'edges',
  'nodes',
  'pageInfo',
};

/// API 응답 blob 시그니처 (동시 존재 시 금지)
const apiBlobSignatureKeys = {
  'averageScore',
  'favourites',
  'popularity',
  'meanScore',
  'siteUrl',
  'coverImage',
  'bannerImage',
  'streamingEpisodes',
};

class DataPolicyViolation {
  final String workId;
  final String relativePath;
  final String rule;
  final String detail;

  /// true면 CI 실패에 포함하지 않음 (기존 카탈로그 정리 전 경고)
  final bool warnOnly;

  const DataPolicyViolation({
    required this.workId,
    required this.relativePath,
    required this.rule,
    required this.detail,
    this.warnOnly = false,
  });

  @override
  String toString() => '$relativePath/$workId [$rule] $detail';
}

/// WorkEntry 1건 검사
List<DataPolicyViolation> lintWorkEntry({
  required String workId,
  required Map<String, dynamic> work,
  required String relativePath,
}) {
  final issues = <DataPolicyViolation>[];

  void add(String rule, String detail) {
    issues.add(
      DataPolicyViolation(
        workId: workId,
        relativePath: relativePath,
        rule: rule,
        detail: detail,
      ),
    );
  }

  for (final key in work.keys) {
    if (!allowedWorkTopLevelKeys.contains(key)) {
      add('forbidden_top_level', 'disallowed field "$key"');
    }
  }

  _walkForbiddenKeys(
    work,
    pathPrefix: '',
    onForbidden: (path, key) {
      add('forbidden_field', 'disallowed field "$path$key"');
    },
    maxDepth: 6,
  );

  _detectApiBlobMaps(
    work,
    onBlob: (path) {
      add('api_blob', 'possible raw API payload at "$path"');
    },
  );

  if (work.containsKey('description')) {
    add(
      'tier1_description',
      'Tier 1 description forbidden — user Sanctum vault only (v1)',
    );
  }

  final title = work['title']?.toString() ?? '';
  if (title.length > dataPolicyMaxTitleChars) {
    add(
      'text_length',
      'title length ${title.length} > $dataPolicyMaxTitleChars',
    );
  }

  final creator = work['creator']?.toString() ?? '';
  if (creator.length > dataPolicyMaxCreatorChars) {
    add(
      'text_length',
      'creator length ${creator.length} > $dataPolicyMaxCreatorChars',
    );
  }

  final tags = work['tags'];
  if (tags is List) {
    if (tags.length > dataPolicyMaxTagCount) {
      add('text_length', 'tags count ${tags.length} > $dataPolicyMaxTagCount');
    }
    for (final tag in tags) {
      final s = tag?.toString() ?? '';
      if (s.length > dataPolicyMaxTagChars) {
        add('text_length', 'tag too long (${s.length} chars)');
      }
    }
  }

  final aliases = work['aliases'];
  if (aliases is List) {
    if (aliases.length > dataPolicyMaxAliasCount) {
      add(
        'text_length',
        'aliases count ${aliases.length} > $dataPolicyMaxAliasCount',
      );
    }
    for (final alias in aliases) {
      final s = alias?.toString() ?? '';
      if (s.length > dataPolicyMaxAliasChars) {
        add('text_length', 'alias too long (${s.length} chars)');
      }
    }
  }

  final titles = work['titles'];
  if (titles is Map) {
    for (final entry in titles.entries) {
      final s = entry.value?.toString() ?? '';
      if (s.length > dataPolicyMaxTitleChars) {
        add('text_length', 'titles.${entry.key} too long (${s.length} chars)');
      }
    }
  }

  if (work.containsKey('posterPath')) {
    add(
      'tier1_poster',
      'Tier 1 posterPath forbidden — user Sanctum vault only (v1)',
    );
  }

  final extensions = work['extensions'];
  if (extensions is Map) {
    for (final key in extensions.keys) {
      final k = key.toString();
      if (!allowedExtensionsKeys.contains(k)) {
        add('provenance', 'extensions.$k not in allowed extensions keys');
      }
    }

    final registeredVia = extensions['registeredVia']?.toString().trim() ?? '';
    if (registeredVia.isNotEmpty &&
        !allowedRegisteredViaValues.contains(registeredVia)) {
      add('provenance', 'extensions.registeredVia invalid: "$registeredVia"');
    }

    final ingestSource = extensions['ingestSource']?.toString().trim() ?? '';
    if (ingestSource.isNotEmpty && forbiddenFieldKeys.contains(ingestSource)) {
      add('provenance', 'extensions.ingestSource suspicious: "$ingestSource"');
    }
  }

  final qualitySignals = work['qualitySignals'];
  if (qualitySignals is Map) {
    for (final key in qualitySignals.keys) {
      if (!allowedQualitySignalKeys.contains(key.toString())) {
        add('provenance', 'qualitySignals.$key not allowed');
      }
    }
  }

  if (work.containsKey('searchTokens')) {
    add(
      'build_artifact',
      'searchTokens must not be stored in shard (build output only)',
    );
  }

  _lintWikidataSpineFields(work, add);

  return issues;
}

void _lintWikidataSpineFields(
  Map<String, dynamic> work,
  void Function(String rule, String detail) add,
) {
  final extIds = work['externalIds'];
  if (extIds is Map) {
    final wd = extIds['wikidata']?.toString().trim() ?? '';
    if (wd.isNotEmpty && !wikidataQidPattern.hasMatch(wd)) {
      add('wikidata_format', 'externalIds.wikidata invalid: "$wd"');
    }
  }

  final relations = work['wikidataRelations'];
  if (relations is List) {
    for (var i = 0; i < relations.length; i++) {
      final row = relations[i];
      if (row is! Map) {
        add('wikidata_relations', 'wikidataRelations[$i] must be object');
        continue;
      }
      for (final key in row.keys) {
        if (!allowedWikidataRelationKeys.contains(key.toString())) {
          add('wikidata_relations', 'wikidataRelations[$i].$key not allowed');
        }
      }
      final p = row['p']?.toString().trim() ?? '';
      final target = row['target']?.toString().trim() ?? '';
      if (p.isNotEmpty && !wikidataPropertyPattern.hasMatch(p)) {
        add('wikidata_relations', 'wikidataRelations[$i].p invalid: "$p"');
      }
      if (target.isNotEmpty && !wikidataQidPattern.hasMatch(target)) {
        add(
          'wikidata_relations',
          'wikidataRelations[$i].target invalid: "$target"',
        );
      }
    }
  }

  final extensions = work['extensions'];
  if (extensions is Map) {
    final seasons = extensions['seasons'];
    if (seasons is List) {
      for (var i = 0; i < seasons.length; i++) {
        final row = seasons[i];
        if (row is! Map) {
          add('wikidata_seasons', 'extensions.seasons[$i] must be object');
          continue;
        }
        for (final key in row.keys) {
          if (!allowedSeasonEntryKeys.contains(key.toString())) {
            add('wikidata_seasons', 'extensions.seasons[$i].$key not allowed');
          }
        }
        final q = row['wikidata']?.toString().trim() ?? '';
        if (q.isNotEmpty && !wikidataQidPattern.hasMatch(q)) {
          add(
            'wikidata_seasons',
            'extensions.seasons[$i].wikidata invalid: "$q"',
          );
        }
        final seriesQ = row['seriesQid']?.toString().trim() ?? '';
        if (seriesQ.isNotEmpty && !wikidataQidPattern.hasMatch(seriesQ)) {
          add(
            'wikidata_seasons',
            'extensions.seasons[$i].seriesQid invalid: "$seriesQ"',
          );
        }
      }
    }
  }
}

void _walkForbiddenKeys(
  Object? node, {
  required String pathPrefix,
  required void Function(String path, String key) onForbidden,
  required int maxDepth,
  int depth = 0,
}) {
  if (depth > maxDepth || node is! Map) return;

  for (final entry in node.entries) {
    final key = entry.key.toString();
    final lower = key.toLowerCase();

    if (forbiddenFieldKeys.contains(key) ||
        forbiddenFieldKeys.contains(lower)) {
      onForbidden(pathPrefix, key);
    }

    final child = entry.value;
    if (child is Map) {
      _walkForbiddenKeys(
        child,
        pathPrefix: '$pathPrefix$key.',
        onForbidden: onForbidden,
        maxDepth: maxDepth,
        depth: depth + 1,
      );
    } else if (child is List) {
      for (var i = 0; i < child.length && i < 5; i++) {
        if (child[i] is Map) {
          _walkForbiddenKeys(
            child[i],
            pathPrefix: '$pathPrefix$key[$i].',
            onForbidden: onForbidden,
            maxDepth: maxDepth,
            depth: depth + 1,
          );
        }
      }
    }
  }
}

void _detectApiBlobMaps(
  Object? node, {
  required void Function(String path) onBlob,
  String path = '',
  int depth = 0,
}) {
  if (depth > 5 || node == null) return;

  if (node is Map) {
    final keys = node.keys.map((k) => k.toString()).toSet();
    final hits = keys.where(apiBlobSignatureKeys.contains).length;
    if (hits >= 2) {
      onBlob(path.isEmpty ? '(root)' : path);
    }
    for (final entry in node.entries) {
      _detectApiBlobMaps(
        entry.value,
        onBlob: onBlob,
        path: path.isEmpty ? entry.key.toString() : '$path.${entry.key}',
        depth: depth + 1,
      );
    }
  } else if (node is List) {
    for (var i = 0; i < node.length && i < 3; i++) {
      _detectApiBlobMaps(
        node[i],
        onBlob: onBlob,
        path: '$path[$i]',
        depth: depth + 1,
      );
    }
  }
}
