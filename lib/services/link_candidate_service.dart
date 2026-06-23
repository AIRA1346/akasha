import '../core/archiving/entity_anchor.dart';
import '../core/ports/entity_registry_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_fact.dart';
import '../models/entity_link_selection.dart';
import '../models/user_catalog_entity.dart';
import '../utils/discovery_linkable_types.dart';
import 'entity_seed_catalog_promotion.dart';
import 'person_seed_registry.dart';

/// Work 맥락 연결 후보 출처 (R8 P1).
enum LinkCandidateReason {
  creator,
  tag,
  seed,
  catalog,
}

/// Work 기준 연결 제안 후보.
class LinkCandidate {
  const LinkCandidate({
    required this.entityId,
    required this.title,
    required this.entityType,
    required this.score,
    required this.reason,
    this.seedFact,
    this.matchDetail,
  });

  final String entityId;
  final String title;
  final String entityType;
  final double score;
  final LinkCandidateReason reason;
  final EntityFact? seedFact;
  final String? matchDetail;

  EntityAnchorType get anchorType {
    for (final t in EntityAnchorType.values) {
      if (t.name == entityType) return t;
    }
    return EntityAnchorType.person;
  }
}

/// Work 맥락 기반 연결 후보 계산 (R8 P1).
abstract final class LinkCandidateService {
  static const Set<EntityAnchorType> _linkableTypes = DiscoveryLinkableTypes.types;

  static const double _scoreCreatorExact = 10.0;
  static const double _scoreCreatorToken = 7.0;
  static const double _scoreTagExact = 5.0;
  static const double _scoreTagInAlias = 3.0;
  static const double _scoreTitleInTag = 4.0;
  static const double _scoreSeedBrowse = 2.0;
  static const double _scoreCatalogFallback = 1.0;

  static Future<List<LinkCandidate>> candidatesForWork({
    required AkashaItem work,
    required UserCatalogPort userCatalog,
    EntityRegistryPort? personSeed,
    EntityAnchorType? typeFilter,
    Set<String>? excludeEntityIds,
    int limit = 8,
  }) async {
    if (work is EntityItem || work.workId.isEmpty) return const [];

    await userCatalog.load();
    final seed = personSeed ?? PersonSeedRegistry.instance;
    await seed.init();

    final excluded = excludeEntityIds ?? const {};
    final workTags = work.tags
        .map((t) => _normalize(t))
        .where((t) => t.isNotEmpty)
        .toSet();
    final workTitle = _normalize(work.title);
    final creatorTokens = _creatorTokens(work.creator);

    final merged = <String, LinkCandidate>{};

    void put(LinkCandidate candidate) {
      if (candidate.entityId.isNotEmpty && excluded.contains(candidate.entityId)) {
        return;
      }
      if (!_typeAllowed(candidate.anchorType, typeFilter)) return;

      final key = candidate.entityId.isNotEmpty
          ? candidate.entityId
          : 'title:${_normalize(candidate.title)}';
      final existing = merged[key];
      if (existing == null || candidate.score > existing.score) {
        merged[key] = candidate;
      }
    }

    for (final fact in _seedFacts(seed, typeFilter)) {
      if (!_linkableTypes.contains(fact.entityType)) continue;
      if (excluded.contains(fact.entityId)) continue;
      if (userCatalog.getById(fact.entityId) != null) {
        _scoreCatalogEntity(
          entity: EntitySeedCatalogPromotion.entityFromFact(fact),
          workTags: workTags,
          workTitle: workTitle,
          creatorTokens: creatorTokens,
          put: put,
          preferSeedReason: false,
        );
        continue;
      }

      final creatorScore = _creatorScoreForFact(fact, creatorTokens, work.creator);
      if (creatorScore != null) {
        put(
          LinkCandidate(
            entityId: fact.entityId,
            title: fact.title,
            entityType: fact.entityType.name,
            score: creatorScore.score,
            reason: LinkCandidateReason.creator,
            seedFact: fact,
            matchDetail: creatorScore.detail,
          ),
        );
        continue;
      }

      put(
        LinkCandidate(
          entityId: fact.entityId,
          title: fact.title,
          entityType: fact.entityType.name,
          score: _scoreSeedBrowse,
          reason: LinkCandidateReason.seed,
          seedFact: fact,
        ),
      );
    }

    for (final entity in userCatalog.all) {
      if (!_isLinkableCatalogEntity(entity)) continue;
      if (excluded.contains(entity.entityId)) continue;
      _scoreCatalogEntity(
        entity: entity,
        workTags: workTags,
        workTitle: workTitle,
        creatorTokens: creatorTokens,
        put: put,
        preferSeedReason: false,
      );
    }

  if (merged.values.every((c) => c.score < _scoreCatalogFallback)) {
      for (final entity in userCatalog.all) {
        if (!_isLinkableCatalogEntity(entity)) continue;
        if (excluded.contains(entity.entityId)) continue;
        if (!_typeAllowed(entity.anchorType, typeFilter)) continue;
        put(
          LinkCandidate(
            entityId: entity.entityId,
            title: entity.title,
            entityType: entity.entityType,
            score: _scoreCatalogFallback,
            reason: LinkCandidateReason.catalog,
          ),
        );
      }
    }

    final results = merged.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return results.take(limit).toList();
  }

  /// seed/catalog 후보를 Picker 선택 결과로 변환.
  static Future<EntityLinkSelection> resolveSelection({
    required LinkCandidate candidate,
    required UserCatalogPort userCatalog,
  }) async {
    if (candidate.seedFact != null) {
      final entity = await EntitySeedCatalogPromotion.ensureInCatalog(
        userCatalog: userCatalog,
        fact: candidate.seedFact!,
      );
      return EntityLinkSelection(
        entityId: entity.entityId,
        title: entity.title,
        entityType: entity.entityType,
      );
    }
    return EntityLinkSelection(
      entityId: candidate.entityId,
      title: candidate.title,
      entityType: candidate.entityType,
    );
  }

  static List<EntityFact> _seedFacts(
    EntityRegistryPort seed,
    EntityAnchorType? typeFilter,
  ) {
    if (seed is PersonSeedRegistry) {
      return seed.listFacts(type: typeFilter);
    }
    return const [];
  }

  static void _scoreCatalogEntity({
    required UserCatalogEntity entity,
    required Set<String> workTags,
    required String workTitle,
    required List<String> creatorTokens,
    required void Function(LinkCandidate candidate) put,
    required bool preferSeedReason,
  }) {
    final creatorScore = _creatorScoreForEntity(entity, creatorTokens);
    if (creatorScore != null) {
      put(
        LinkCandidate(
          entityId: entity.entityId,
          title: entity.title,
          entityType: entity.entityType,
          score: creatorScore.score,
          reason: LinkCandidateReason.creator,
          matchDetail: creatorScore.detail,
        ),
      );
      return;
    }

    final tagScore = _tagScoreForEntity(
      entity: entity,
      workTags: workTags,
      workTitle: workTitle,
    );
    if (tagScore != null) {
      put(
        LinkCandidate(
          entityId: entity.entityId,
          title: entity.title,
          entityType: entity.entityType,
          score: tagScore.score,
          reason: LinkCandidateReason.tag,
          matchDetail: tagScore.detail,
        ),
      );
      return;
    }

    if (preferSeedReason) {
      put(
        LinkCandidate(
          entityId: entity.entityId,
          title: entity.title,
          entityType: entity.entityType,
          score: _scoreSeedBrowse,
          reason: LinkCandidateReason.seed,
        ),
      );
    }
  }

  static ({double score, String detail})? _creatorScoreForFact(
    EntityFact fact,
    List<String> creatorTokens,
    String rawCreator,
  ) {
    final normalizedCreator = _normalize(rawCreator);
    final title = _normalize(fact.title);
    if (normalizedCreator.isNotEmpty && normalizedCreator == title) {
      return (score: _scoreCreatorExact, detail: 'creator 일치');
    }
    for (final alias in fact.aliases) {
      if (normalizedCreator.isNotEmpty && normalizedCreator == _normalize(alias)) {
        return (score: _scoreCreatorExact, detail: 'creator 일치');
      }
    }
  if (_creatorTokens(rawCreator).any((token) => title.contains(token) || token.contains(title))) {
      return (score: _scoreCreatorToken, detail: 'creator 연관');
    }
    for (final alias in fact.aliases) {
      final normalizedAlias = _normalize(alias);
      for (final token in creatorTokens) {
        if (normalizedAlias.contains(token) || token.contains(normalizedAlias)) {
          return (score: _scoreCreatorToken, detail: 'creator 연관');
        }
      }
    }
    return null;
  }

  static ({double score, String detail})? _creatorScoreForEntity(
    UserCatalogEntity entity,
    List<String> creatorTokens,
  ) {
    final title = _normalize(entity.title);
    for (final token in creatorTokens) {
      if (token == title) {
        return (score: _scoreCreatorExact, detail: 'creator 일치');
      }
    }
    for (final alias in entity.aliases) {
      final normalizedAlias = _normalize(alias);
      for (final token in creatorTokens) {
        if (token == normalizedAlias) {
          return (score: _scoreCreatorExact, detail: 'creator 일치');
        }
      }
    }
    for (final token in creatorTokens) {
      if (title.contains(token) || token.contains(title)) {
        return (score: _scoreCreatorToken, detail: 'creator 연관');
      }
      for (final alias in entity.aliases) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.contains(token) || token.contains(normalizedAlias)) {
          return (score: _scoreCreatorToken, detail: 'creator 연관');
        }
      }
    }
    return null;
  }

  static ({double score, String detail})? _tagScoreForEntity({
    required UserCatalogEntity entity,
    required Set<String> workTags,
    required String workTitle,
  }) {
    if (workTags.isEmpty && workTitle.isEmpty) return null;

    var best = 0.0;
    String? detail;

    for (final tag in entity.tags) {
      final normalized = _normalize(tag);
      if (normalized.isEmpty) continue;
      if (workTags.contains(normalized)) {
        if (_scoreTagExact > best) {
          best = _scoreTagExact;
          detail = '태그: $tag';
        }
      }
      if (workTitle.isNotEmpty && normalized.contains(workTitle)) {
        if (_scoreTitleInTag > best) {
          best = _scoreTitleInTag;
          detail = '태그·제목';
        }
      }
    }

    for (final alias in entity.aliases) {
      final normalized = _normalize(alias);
      if (normalized.isEmpty) continue;
      if (workTags.contains(normalized)) {
        if (_scoreTagInAlias > best) {
          best = _scoreTagInAlias;
          detail = '태그·별칭';
        }
      }
    }

    if (best <= 0) return null;
    return (score: best, detail: detail ?? '태그');
  }

  static bool _isLinkableCatalogEntity(UserCatalogEntity entity) {
    return DiscoveryLinkableTypes.isCatalogLinkable(entity);
  }

  static bool _typeAllowed(EntityAnchorType type, EntityAnchorType? filter) {
    if (filter == null) return _linkableTypes.contains(type);
    return type == filter;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _creatorTokens(String creator) {
    final normalized = _normalize(creator);
    if (normalized.isEmpty) return const [];

    final tokens = <String>{normalized};
    for (final part in normalized.split(RegExp(r'[,;/|·]+'))) {
      final trimmed = part.trim();
      if (trimmed.length >= 2) tokens.add(trimmed);
      for (final word in trimmed.split(RegExp(r'\s+'))) {
        if (word.length >= 2) tokens.add(word);
      }
    }
    return tokens.toList();
  }
}
