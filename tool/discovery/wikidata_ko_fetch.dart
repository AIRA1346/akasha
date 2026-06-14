/// Wikidata SPARQL — 한국어 라벨(ko) 필수 작품 fetch.
library;

import 'dart:convert';
import 'dart:io';

import 'wikidata_client.dart';
import 'wikidata_facts.dart';
import 'wikidata_q_validation.dart';

/// AKASHA category → 허용 P31 (wikidata_q_validation SSOT)
const wikidataKoSupportedCategories = [
  'manga',
  'webtoon',
  'animation',
  'game',
  'book',
  'movie',
  'drama',
];

List<String> p31QidsForCategory(String category) {
  final set = expectedP31ByAkashaCategory[category];
  if (set == null || set.isEmpty) {
    throw ArgumentError('unsupported category for wikidata_ko: $category');
  }
  return set.toList()..sort();
}

/// SPARQL fetch용 P31 — webtoon은 manga series(Q21198342) 제외해 dedupe-only 구간 방지.
const sparqlP31ByAkashaCategory = {
  'webtoon': {'Q60496358', 'Q7978994', 'Q74262765'},
};

List<String> p31QidsForSparql(String category) {
  final narrow = sparqlP31ByAkashaCategory[category];
  if (narrow != null && narrow.isNotEmpty) {
    return narrow.toList()..sort();
  }
  return p31QidsForCategory(category);
}

/// 한국어 라벨이 있는 항목만 — category별 P31 필터.
String wikidataKoLabelSparql({
  required String category,
  required int limit,
  required int offset,
}) {
  final p31Values = p31QidsForSparql(category)
      .map((q) => 'wd:$q')
      .join(' ');

  return '''
SELECT ?item ?itemLabel ?itemLabelKo ?itemLabelJa ?authorLabel ?startYear ?instanceOf WHERE {
  VALUES ?instanceOf { $p31Values }
  ?item wdt:P31 ?instanceOf .
  ?item rdfs:label ?itemLabelKo .
  FILTER(LANG(?itemLabelKo) = "ko")
  OPTIONAL {
    ?item wdt:P50 ?author .
    ?author rdfs:label ?authorLabel .
    FILTER(LANG(?authorLabel) IN ("en", "ja", "ko"))
  }
  OPTIONAL {
    ?item wdt:P577 ?startTime .
    BIND(YEAR(?startTime) AS ?startYear)
  }
  OPTIONAL {
    ?item rdfs:label ?itemLabelJa .
    FILTER(LANG(?itemLabelJa) = "ja")
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
ORDER BY ?item
LIMIT $limit
OFFSET $offset
''';
}

Future<List<Map<String, dynamic>>> fetchWikidataKoBatch({
  required String category,
  required int batchSize,
  int offset = 0,
  HttpClient? client,
  Future<String> Function({
    required String query,
    required HttpClient client,
  })? runQuery,
}) async {
  if (batchSize <= 0) return const [];
  if (!wikidataKoSupportedCategories.contains(category)) {
    throw ArgumentError('unsupported category: $category');
  }

  final http = client ?? HttpClient();
  final ownsClient = client == null;
  final queryRunner = runQuery ?? _runSparqlQuery;

  try {
    final query = wikidataKoLabelSparql(
      category: category,
      limit: batchSize,
      offset: offset,
    );
    final body = await queryRunner(query: query, client: http);
    final decoded = json.decode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Wikidata response is not a JSON object');
    }

    final results = decoded['results'];
    if (results is! Map) {
      throw const FormatException('Wikidata response missing results');
    }
    final bindings = results['bindings'];
    if (bindings is! List) {
      throw const FormatException('Wikidata response missing bindings');
    }

    final out = <Map<String, dynamic>>[];
    for (final row in bindings) {
      if (row is! Map) continue;
      final binding = Map<String, dynamic>.from(row);
      final node = wikidataBindingToNode(binding, category: category);
      final ko = (node['titles'] as Map?)?['ko']?.toString().trim() ?? '';
      if (ko.isEmpty) continue;

      final instanceUri = binding['instanceOf'];
      final p31Uri = instanceUri is Map
          ? instanceUri['value']?.toString()
          : instanceUri?.toString();
      final p31 = qidFromWikidataUri(p31Uri);
      if (p31 != null && p31.isNotEmpty) {
        node['entityP31'] = [p31];
      }

      if ((node['qid']?.toString() ?? '').isEmpty) continue;
      if ((node['title']?.toString() ?? '').isEmpty) continue;
      out.add(node);
    }
    return out;
  } finally {
    if (ownsClient) {
      http.close(force: true);
    }
  }
}

Future<String> _runSparqlQuery({
  required String query,
  required HttpClient client,
}) async {
  final uri = Uri.parse(wikidataSparqlEndpoint).replace(
    queryParameters: {'format': 'json', 'query': query},
  );
  final request = await client.getUrl(uri);
  request.headers.set('User-Agent', akashaDiscoveryUserAgent);
  request.headers.set('Accept', 'application/sparql-results+json');

  var response = await request.close();
  var body = await response.transform(utf8.decoder).join();

  if (response.statusCode == 429) {
    final retryAfterSec = _retryAfterSeconds(response);
    if (retryAfterSec > 0) {
      await Future<void>.delayed(Duration(seconds: retryAfterSec));
      final retryRequest = await client.getUrl(uri);
      retryRequest.headers.set('User-Agent', akashaDiscoveryUserAgent);
      retryRequest.headers.set('Accept', 'application/sparql-results+json');
      response = await retryRequest.close();
      body = await response.transform(utf8.decoder).join();
    }
  }

  if (response.statusCode == 429) {
    throw HttpException(
      'Wikidata rate limited (429) — respect Retry-After before retrying',
      uri: uri,
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Wikidata HTTP ${response.statusCode}: $body',
      uri: uri,
    );
  }
  return body;
}

int _retryAfterSeconds(HttpClientResponse response) {
  final raw = response.headers.value('retry-after')?.trim() ?? '';
  final sec = int.tryParse(raw);
  if (sec != null && sec > 0) return sec.clamp(1, 300);
  return 60;
}
