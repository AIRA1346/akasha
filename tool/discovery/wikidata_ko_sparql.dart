// Wikidata SPARQL — 관련 항목(시리즈·상위)의 kowiki 제목.
library;

import 'dart:convert';
import 'dart:io';

import 'wikidata_client.dart';
import 'wikidata_entity_labels.dart';

/// Q-id → kowiki 제목 (1-hop P179/P361/P527 관련 항목)
Future<Map<String, String>> fetchRelatedKowikiTitles({
  required List<String> qids,
  HttpClient? client,
}) async {
  final unique = qids
      .map((q) => q.trim())
      .where((q) => q.startsWith('Q'))
      .toSet()
      .toList()
    ..sort();
  if (unique.isEmpty) return {};

  final http = client ?? HttpClient();
  final ownsClient = client == null;
  final out = <String, String>{};

  try {
    for (var i = 0; i < unique.length; i += 40) {
      final batch = unique.sublist(
        i,
        i + 40 > unique.length ? unique.length : i + 40,
      );
      final chunk = await _runRelatedKowikiQuery(client: http, qids: batch);
      out.addAll(chunk);
      if (i + 40 < unique.length) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    return out;
  } finally {
    if (ownsClient) {
      http.close(force: true);
    }
  }
}

Future<Map<String, String>> _runRelatedKowikiQuery({
  required HttpClient client,
  required List<String> qids,
}) async {
  final values = qids.map((q) => 'wd:$q').join(' ');
  final query = '''
SELECT ?item ?koTitle WHERE {
  VALUES ?item { $values }
  {
    ?item (wdt:P179|wdt:P361) ?rel .
    ?rel ^schema:about ?article .
    ?article schema:inLanguage "ko" .
    ?article schema:name ?koTitle .
  }
  UNION
  {
    ?rel (wdt:P179|wdt:P361) ?item .
    ?rel ^schema:about ?article .
    ?article schema:inLanguage "ko" .
    ?article schema:name ?koTitle .
  }
  UNION
  {
    ?rel wdt:P527 ?item .
    ?rel ^schema:about ?article .
    ?article schema:inLanguage "ko" .
    ?article schema:name ?koTitle .
  }
}
''';

  final uri = Uri.parse(wikidataSparqlEndpoint).replace(
    queryParameters: {'format': 'json', 'query': query},
  );
  final request = await client.getUrl(uri);
  request.headers.set('User-Agent', akashaDiscoveryUserAgent);
  request.headers.set('Accept', 'application/sparql-results+json');

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('SPARQL HTTP ${response.statusCode}', uri: uri);
  }

  final decoded = json.decode(body);
  if (decoded is! Map) return {};
  final bindings = (decoded['results'] as Map?)?['bindings'];
  if (bindings is! List) return {};

  final out = <String, String>{};
  for (final row in bindings) {
    if (row is! Map) continue;
    final itemUri = row['item'];
    final koRaw = row['koTitle'];
    if (itemUri is! Map || koRaw is! Map) continue;
    final qid = RegExp(r'(Q\d+)$').firstMatch(itemUri['value']?.toString() ?? '')?.group(1);
    final koTitle = normalizeKowikiSitelinkTitle(koRaw['value']?.toString());
    if (qid == null || koTitle == null) continue;
    if (!_isPlausibleKoTitle(koTitle)) continue;
    out.putIfAbsent(qid, () => koTitle);
  }
  return out;
}

bool _isPlausibleKoTitle(String text) =>
    text.length >= 2 && RegExp(r'[\uAC00-\uD7A3]').hasMatch(text);
