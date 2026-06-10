/// Wikidata wbgetentities — 다언어 labels (CC0, backfill·검증용).
library;

import 'dart:convert';
import 'dart:io';

import 'wikidata_client.dart';

const _wikidataApi = 'https://www.wikidata.org/w/api.php';
const _maxIdsPerRequest = 50;

/// Q-id 목록 → `{ Qid: { ko: ..., en: ..., ja: ... } }`
Future<Map<String, Map<String, String>>> fetchWikidataEntityLabels({
  required List<String> qids,
  List<String> languages = const ['ko', 'en', 'ja'],
  HttpClient? client,
  Duration pauseBetweenBatches = const Duration(milliseconds: 300),
}) async {
  final unique = qids
      .map((q) => q.trim())
      .where((q) => q.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  if (unique.isEmpty) return {};

  final http = client ?? HttpClient();
  final ownsClient = client == null;
  final out = <String, Map<String, String>>{};

  try {
    for (var i = 0; i < unique.length; i += _maxIdsPerRequest) {
      final batch = unique.sublist(
        i,
        i + _maxIdsPerRequest > unique.length
            ? unique.length
            : i + _maxIdsPerRequest,
      );
      final chunk = await _fetchLabelBatch(
        client: http,
        qids: batch,
        languages: languages,
      );
      out.addAll(chunk);
      if (i + _maxIdsPerRequest < unique.length && pauseBetweenBatches > Duration.zero) {
        await Future<void>.delayed(pauseBetweenBatches);
      }
    }
    return out;
  } finally {
    if (ownsClient) {
      http.close(force: true);
    }
  }
}

Future<Map<String, Map<String, String>>> _fetchLabelBatch({
  required HttpClient client,
  required List<String> qids,
  required List<String> languages,
}) async {
  final uri = Uri.parse(_wikidataApi).replace(
    queryParameters: {
      'action': 'wbgetentities',
      'ids': qids.join('|'),
      'props': 'labels',
      'languages': languages.join('|'),
      'format': 'json',
    },
  );

  final request = await client.getUrl(uri);
  request.headers.set('User-Agent', akashaDiscoveryUserAgent);
  request.headers.set('Accept', 'application/json');

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode == 429) {
    throw HttpException(
      'Wikidata rate limited (429) — retry later',
      uri: uri,
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Wikidata API HTTP ${response.statusCode}: $body',
      uri: uri,
    );
  }

  final decoded = json.decode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Wikidata API response is not a JSON object');
  }

  final entities = decoded['entities'];
  if (entities is! Map) return {};

  final out = <String, Map<String, String>>{};
  for (final entry in entities.entries) {
    final qid = entry.key.toString();
    if (entry.value is! Map) continue;
    final labelsRaw = (entry.value as Map)['labels'];
    if (labelsRaw is! Map) continue;

    final labels = <String, String>{};
    for (final lang in languages) {
      final block = labelsRaw[lang];
      if (block is Map) {
        final value = block['value']?.toString().trim() ?? '';
        if (value.isNotEmpty) labels[lang] = value;
      }
    }
    if (labels.isNotEmpty) out[qid] = labels;
  }
  return out;
}
