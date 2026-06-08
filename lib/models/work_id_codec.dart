import 'enums.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 글로벌 work_id 마스터 규칙 (수백만 체급)
//
//  형식: {domain}_{category}_{identifier}_{releaseYear}
//  - domain: sub (subculture) | gen (generalCulture)
//  - category: manga | webtoon | animation | game | book | movie | drama
//  - identifier:
//      · ISBN: 9788925251111
//      · Steam: appid1245620
//      · 슬러그: kimetsu-no-yaiba
//      · 유저 커스텀: custom_a1b2c3d4
// ════════════════════════════════════════════════════════════════

enum WorkIdIdentifierType {
  isbn,
  steamAppId,
  slug,
  custom,
  legacy,
}

class ParsedWorkId {
  final String raw;
  final AppDomain domain;
  final MediaCategory category;
  final WorkIdIdentifierType identifierType;
  final String identifier;
  final int? releaseYear;

  const ParsedWorkId({
    required this.raw,
    required this.domain,
    required this.category,
    required this.identifierType,
    required this.identifier,
    this.releaseYear,
  });

  /// 샤드 키 (예: manga_K, game_A, manga_numeric)
  String get shardKey {
    final cat = category.name;
    if (identifierType == WorkIdIdentifierType.steamAppId) {
      final digits = identifier.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 3) {
        return '${cat}_steam_${digits.substring(0, 3)}';
      }
      return '${cat}_steam';
    }
    final first = identifier.isEmpty ? '#' : identifier[0].toUpperCase();
    if (RegExp(r'[0-9]').hasMatch(first)) return '${cat}_numeric';
    if (!RegExp(r'[A-Z]').hasMatch(first)) return '${cat}_misc';
    return '${cat}_$first';
  }
}

class WorkIdCodec {
  /// v4 영구 ID — `wk_000012345` (9자리 순번, 최대 ~10억 작)
  static final RegExp wkIdPattern = RegExp(r'^wk_\d{9}$');

  static final RegExp _masterPatternWithYear = RegExp(
    r'^(sub|gen)_(manga|webtoon|animation|game|book|movie|drama)_(.+)_(\d{4})$',
  );

  static final RegExp _masterPatternNoYear = RegExp(
    r'^(sub|gen)_(manga|webtoon|animation|game|book|movie|drama)_(.+)$',
  );

  static bool isWkFormat(String workId) => wkIdPattern.hasMatch(workId);

  static String domainPrefix(AppDomain domain) =>
      domain == AppDomain.subculture ? 'sub' : 'gen';

  static AppDomain parseDomainPrefix(String prefix) =>
      prefix == 'gen' ? AppDomain.generalCulture : AppDomain.subculture;

  static WorkIdIdentifierType classifyIdentifier(String identifier) {
    if (identifier.startsWith('custom_')) return WorkIdIdentifierType.custom;
    if (identifier.startsWith('appid')) return WorkIdIdentifierType.steamAppId;
    if (RegExp(r'^\d{10,13}$').hasMatch(identifier)) {
      return WorkIdIdentifierType.isbn;
    }
    return WorkIdIdentifierType.slug;
  }

  static ParsedWorkId? parse(String workId) {
    if (workId.isEmpty) return null;

    if (isWkFormat(workId)) {
      return ParsedWorkId(
        raw: workId,
        domain: AppDomain.subculture,
        category: MediaCategory.manga,
        identifierType: WorkIdIdentifierType.legacy,
        identifier: workId,
      );
    }

    RegExpMatch? match = _masterPatternWithYear.firstMatch(workId);
    int? releaseYear;
    if (match != null) {
      releaseYear = int.tryParse(match.group(4)!);
    } else {
      match = _masterPatternNoYear.firstMatch(workId);
    }

    if (match == null) {
      return ParsedWorkId(
        raw: workId,
        domain: AppDomain.subculture,
        category: MediaCategory.manga,
        identifierType: WorkIdIdentifierType.legacy,
        identifier: workId,
      );
    }

    final resolved = match;
    final identifier = resolved.group(3)!;
    return ParsedWorkId(
      raw: workId,
      domain: parseDomainPrefix(resolved.group(1)!),
      category: MediaCategory.values.firstWhere(
        (e) => e.name == resolved.group(2),
        orElse: () => MediaCategory.manga,
      ),
      identifierType: classifyIdentifier(identifier),
      identifier: identifier,
      releaseYear: releaseYear,
    );
  }

  static bool isMasterFormat(String workId) =>
      isWkFormat(workId) ||
      _masterPatternWithYear.hasMatch(workId) ||
      _masterPatternNoYear.hasMatch(workId);

  static String build({
    required AppDomain domain,
    required MediaCategory category,
    required String identifier,
    int? releaseYear,
  }) {
    final id = identifier.trim();
    final yearSuffix = releaseYear != null ? '_$releaseYear' : '';
    return '${domainPrefix(domain)}_${category.name}_${id}$yearSuffix';
  }

  static String buildIsbn({
    required AppDomain domain,
    required MediaCategory category,
    required String isbn,
    int? releaseYear,
  }) =>
      build(
        domain: domain,
        category: category,
        identifier: isbn.replaceAll(RegExp(r'[^0-9Xx]'), ''),
        releaseYear: releaseYear,
      );

  static String buildSteamAppId({
    required AppDomain domain,
    required int appId,
    int? releaseYear,
  }) =>
      build(
        domain: domain,
        category: MediaCategory.game,
        identifier: 'appid$appId',
        releaseYear: releaseYear,
      );

  static String buildSlug({
    required AppDomain domain,
    required MediaCategory category,
    required String slug,
    int? releaseYear,
  }) =>
      build(
        domain: domain,
        category: category,
        identifier: _normalizeSlug(slug),
        releaseYear: releaseYear,
      );

  static String buildCustom({
    required AppDomain domain,
    required MediaCategory category,
    int? releaseYear,
    String? suffix,
  }) {
    final token = suffix ?? DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return build(
      domain: domain,
      category: category,
      identifier: 'custom_$token',
      releaseYear: releaseYear,
    );
  }

  static String _normalizeSlug(String slug) {
    return slug
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
