/// Wikidata Query Service — manga series Facts (CC0).
///
/// Policy: scoped SPARQL, User-Agent, rate limit respect (429 backoff).
/// No description/image fields requested.
library;

import 'dart:convert';
import 'dart:io';

import 'wikidata_facts.dart';

const wikidataSparqlEndpoint = 'https://query.wikidata.org/sparql';

/// Wikimedia [User-Agent policy](https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy)
const akashaDiscoveryUserAgent =
    'AKASHA-Discovery/1.0 (https://github.com/AIRA1346/akasha; +https://github.com/AIRA1346/akasha/issues) bot';

/// `instance of` manga (Q21198342)
String mangaSeriesSparql({required int limit, required int offset}) => '''
SELECT ?item ?itemLabel ?authorLabel ?startYear ?itemLabelJa WHERE {
  ?item wdt:P31 wd:Q21198342 .
  OPTIONAL {
    ?item wdt:P50 ?author .
    ?author rdfs:label ?authorLabel .
    FILTER(LANG(?authorLabel) IN ("en", "ja"))
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

Future<List<Map<String, dynamic>>> fetchWikidataMangaBatch({
  required int batchSize,
  int offset = 0,
  HttpClient? client,
  Future<String> Function({
    required String query,
    required HttpClient client,
  })? runQuery,
}) async {
  if (batchSize <= 0) return const [];

  final http = client ?? HttpClient();
  final ownsClient = client == null;
  final queryRunner = runQuery ?? _runSparqlQuery;

  try {
    final query = mangaSeriesSparql(limit: batchSize, offset: offset);
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
      final node = wikidataBindingToNode(Map<String, dynamic>.from(row));
      if ((node['qid']?.toString() ?? '').isEmpty) continue;
      if ((node['title']?.toString() ?? '').isEmpty) continue;
      out.add(node);
    }

    if (out.length < batchSize) {
      throw StateError(
        'Only ${out.length}/$batchSize wikidata manga nodes at offset $offset',
      );
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
