/// Discovery Signal → Registry 게이트 (Facts만, 금지 필드 차단).
library;

import 'anilist_facts.dart';
import 'discovery_types.dart';
import 'wikidata_facts.dart';

/// Signal이 Registry Minimal Core 등록 조건을 만족하는지
List<String> validateDiscoverySignal(DiscoverySignal signal) {
  final errors = <String>[];

  if (signal.externalId.isEmpty) {
    errors.add('externalId required');
  }
  if (signal.category.isEmpty) {
    errors.add('category required');
  }
  if (signal.facts.title.isEmpty) {
    errors.add('title required');
  }

  final hasYear = signal.facts.releaseYear != null;
  final hasExternal = signal.externalId.isNotEmpty;
  if (!hasYear && !hasExternal) {
    errors.add('releaseYear or externalId required');
  }

  final factsJson = signal.facts.toJson();
  final forbidden = findForbiddenKeysInMap(factsJson);
  if (forbidden.isNotEmpty) {
    errors.add('forbidden facts: ${forbidden.join(', ')}');
  }

  return errors;
}

/// Signal → Registry shard insert 초안 (Minimal Core, wk_ 할당 전)
Map<String, dynamic> signalToMinimalCoreDraft({
  required DiscoverySignal signal,
  required String workId,
}) {
  final errors = validateDiscoverySignal(signal);
  if (errors.isNotEmpty) {
    throw StateError('signal gate failed: ${errors.join('; ')}');
  }

  final draft = <String, dynamic>{
    'workId': workId,
    'title': signal.facts.title,
    'category': signal.category,
    'domain': signal.domain,
    'externalIds': {signal.source: signal.externalId},
  };

  if (signal.facts.titles.isNotEmpty) {
    draft['titles'] = signal.facts.titles;
  }
  if (signal.facts.releaseYear != null) {
    draft['releaseYear'] = signal.facts.releaseYear;
  }
  if (signal.facts.creator.isNotEmpty) {
    draft['creator'] = signal.facts.creator;
  }
  if (signal.facts.aliases.isNotEmpty) {
    draft['aliases'] = signal.facts.aliases;
  }

  // description, posterPath, tags 의도적 생략 — Minimal Core

  final forbidden = findForbiddenKeysInMap(draft);
  if (forbidden.isNotEmpty) {
    throw StateError('draft contains forbidden keys: ${forbidden.join(', ')}');
  }

  return draft;
}

/// Facts → DiscoverySignal (소스 무관).
DiscoverySignal factsToSignal({
  required String channelId,
  required String source,
  required String externalId,
  required String category,
  required DiscoveryFacts facts,
  String domain = 'subculture',
}) {
  final signal = DiscoverySignal(
    channelId: channelId,
    source: source,
    externalId: externalId,
    category: category,
    domain: domain,
    facts: facts,
    discoveredAt: DateTime.now().toUtc(),
  );

  final errors = validateDiscoverySignal(signal);
  if (errors.isNotEmpty) {
    throw StateError('discovery signal invalid: ${errors.join('; ')}');
  }

  return signal;
}

/// AniList raw 노드 → DiscoverySignal (레거시 테스트·기존 shard 해석용).
DiscoverySignal anilistNodeToSignal({
  required String channelId,
  required Map<String, dynamic> media,
  String domain = 'subculture',
}) {
  final id = media['id']?.toString() ?? '';
  final format = media['format']?.toString();
  final category = anilistFormatToCategory(format) ?? 'animation';
  final facts = extractAnilistFacts(media);

  return factsToSignal(
    channelId: channelId,
    source: 'anilist',
    externalId: id,
    category: category,
    domain: domain,
    facts: facts,
  );
}

/// Wikidata normalized node → DiscoverySignal.
DiscoverySignal wikidataNodeToSignal({
  required String channelId,
  required Map<String, dynamic> node,
  String domain = 'subculture',
}) {
  final qid = node['qid']?.toString().trim() ?? '';
  final category = node['category']?.toString() ?? 'manga';
  final facts = extractWikidataFacts(node);

  return factsToSignal(
    channelId: channelId,
    source: 'wikidata',
    externalId: qid,
    category: category,
    domain: domain,
    facts: facts,
  );
}
