/// Discovery live fetch — source별 분기 (AniList 제거).
library;

import 'dart:io';

import 'discovery_manifest.dart';
import 'discovery_types.dart';
import 'wikidata_client.dart';
import 'wikidata_ko_fetch.dart';

/// 채널 설정에 맞는 외부 소스에서 Fact 노드 fetch.
///
/// AniList는 ToS 리스크로 **지원하지 않음**.
Future<List<Map<String, dynamic>>> fetchDiscoveryBatch({
  required DiscoveryChannelConfig config,
  Directory? projectRoot,
  int? offset,
  HttpClient? client,
}) async {
  switch (config.source) {
    case 'wikidata':
      if (config.category == 'manga') {
        var sparqlOffset = offset ?? 0;
        if (projectRoot != null && offset == null) {
          final cursor = readCursor(projectRoot, config.cursorPath);
          sparqlOffset = int.tryParse(cursor['offset']?.toString() ?? '') ?? 0;
        }
        return fetchWikidataMangaBatch(
          batchSize: config.trialBatchSize,
          offset: sparqlOffset,
          client: client,
        );
      }
      if (config.category == 'animation') {
        throw UnsupportedError(
          'wikidata_anime SPARQL not implemented yet (manifest stub). '
          'See docs/strategy/wikidata-spine-plan.md Phase 3.',
        );
      }
      throw ArgumentError(
        'wikidata source unsupported category: ${config.category}',
      );
    case 'wikidata_ko':
      var sparqlOffset = offset ?? 0;
      if (projectRoot != null && offset == null) {
        final cursor = readCursor(projectRoot, config.cursorPath);
        sparqlOffset = int.tryParse(cursor['offset']?.toString() ?? '') ?? 0;
      }
      return fetchWikidataKoBatch(
        category: config.category,
        batchSize: config.trialBatchSize,
        offset: sparqlOffset,
        client: client,
      );
    case 'anilist':
      throw UnsupportedError(
        'AniList discovery fetch removed (API ToS: no mass collection). '
        'Use wikidata or manual curation.',
      );
    default:
      throw UnsupportedError('unknown discovery source: ${config.source}');
  }
}
