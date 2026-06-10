/// Wikidata wbgetentities — labels·aliases·kowiki sitelink (CC0, backfill용).
library;

import 'dart:convert';
import 'dart:io';

import 'wikidata_client.dart';

const wikidataApiEndpoint = 'https://www.wikidata.org/w/api.php';
const maxWikidataIdsPerRequest = 50;

/// Q-id별 Wikidata locale facts (labels + ko 보조 소스)
class WikidataEntityLocaleFacts {
  final Map<String, String> labels;
  final List<String> koAliases;
  final String? kowikiTitle;

  const WikidataEntityLocaleFacts({
    this.labels = const {},
    this.koAliases = const [],
    this.kowikiTitle,
  });
}

/// ko 제목 후보 — 우선순위: label → alias → kowiki sitelink
({String? ko, String? source}) pickKoTitle(WikidataEntityLocaleFacts facts) {
  final label = facts.labels['ko']?.trim() ?? '';
  if (label.isNotEmpty && _isPlausibleKoTitle(label)) {
    return (ko: label, source: 'label');
  }

  for (final alias in facts.koAliases) {
    final trimmed = alias.trim();
    if (trimmed.isNotEmpty && _isPlausibleKoTitle(trimmed)) {
      return (ko: trimmed, source: 'alias');
    }
  }

  final sitelink = normalizeKowikiSitelinkTitle(facts.kowikiTitle);
  if (sitelink != null && _isPlausibleKoTitle(sitelink)) {
    return (ko: sitelink, source: 'kowiki');
  }

  return (ko: null, source: null);
}

/// 관련 IP ko 제목 — 영/일 제목에 시즌·편수 힌트가 있으면 ko에 반영
String disambiguateRelatedKoTitle({
  required String relatedKo,
  required Map<String, String> titles,
}) {
  final en = titles['en']?.trim() ?? '';
  final ja = titles['ja']?.trim() ?? '';
  final suffix = _extractSeasonSuffix(en) ?? _extractSeasonSuffix(ja);
  if (suffix == null || suffix.isEmpty) return relatedKo;
  if (relatedKo.contains(suffix)) return relatedKo;
  return '$relatedKo $suffix';
}

String? _extractSeasonSuffix(String title) {
  final ordinal = RegExp(
    r'(\d{1,2})(st|nd|rd|th)\b',
    caseSensitive: false,
  ).firstMatch(title);
  if (ordinal != null) {
    return '${ordinal.group(1)}${ordinal.group(2)!.toLowerCase()}';
  }
  final jp = RegExp(r'(?:第\s*)?(\d+)\s*(?:기|期|部|편)').firstMatch(title);
  if (jp != null) return jp.group(1);
  return null;
}

/// kowiki 문서 제목 — 밑줄을 공백으로 (MediaWiki 표시 관례)
String? normalizeKowikiSitelinkTitle(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  return text.replaceAll('_', ' ').trim();
}

bool _isPlausibleKoTitle(String text) {
  if (text.length < 2) return false;
  // 한국어 위키·라벨은 한글이 포함되는 경우가 대부분
  return RegExp(r'[\uAC00-\uD7A3]').hasMatch(text);
}

/// Q-id 목록 → labels map (하위 호환)
Future<Map<String, Map<String, String>>> fetchWikidataEntityLabels({
  required List<String> qids,
  List<String> languages = const ['ko', 'en', 'ja'],
  HttpClient? client,
  Duration pauseBetweenBatches = const Duration(milliseconds: 300),
}) async {
  final facts = await fetchWikidataEntityLocaleFacts(
    qids: qids,
    languages: languages,
    client: client,
    pauseBetweenBatches: pauseBetweenBatches,
  );
  final out = <String, Map<String, String>>{};
  facts.forEach((qid, f) {
    if (f.labels.isNotEmpty) out[qid] = Map<String, String>.from(f.labels);
  });
  return out;
}

/// Q-id 목록 → [WikidataEntityLocaleFacts]
Future<Map<String, WikidataEntityLocaleFacts>> fetchWikidataEntityLocaleFacts({
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
  final out = <String, WikidataEntityLocaleFacts>{};

  try {
    for (var i = 0; i < unique.length; i += maxWikidataIdsPerRequest) {
      final batch = unique.sublist(
        i,
        i + maxWikidataIdsPerRequest > unique.length
            ? unique.length
            : i + maxWikidataIdsPerRequest,
      );
      final chunk = await _fetchEntityLocaleBatch(
        client: http,
        qids: batch,
        languages: languages,
      );
      out.addAll(chunk);
      if (i + maxWikidataIdsPerRequest < unique.length &&
          pauseBetweenBatches > Duration.zero) {
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

Future<Map<String, WikidataEntityLocaleFacts>> _fetchEntityLocaleBatch({
  required HttpClient client,
  required List<String> qids,
  required List<String> languages,
}) async {
  final uri = Uri.parse(wikidataApiEndpoint).replace(
    queryParameters: {
      'action': 'wbgetentities',
      'ids': qids.join('|'),
      'props': 'labels|aliases|sitelinks',
      'languages': languages.join('|'),
      'sitefilter': 'kowiki',
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

  final out = <String, WikidataEntityLocaleFacts>{};
  for (final entry in entities.entries) {
    final qid = entry.key.toString();
    if (entry.value is! Map) continue;
    final entity = entry.value as Map;

    final labels = <String, String>{};
    final labelsRaw = entity['labels'];
    if (labelsRaw is Map) {
      for (final lang in languages) {
        final block = labelsRaw[lang];
        if (block is Map) {
          final value = block['value']?.toString().trim() ?? '';
          if (value.isNotEmpty) labels[lang] = value;
        }
      }
    }

    final koAliases = <String>[];
    final aliasesRaw = entity['aliases'];
    if (aliasesRaw is Map) {
      final koBlocks = aliasesRaw['ko'];
      if (koBlocks is List) {
        for (final block in koBlocks) {
          if (block is Map) {
            final value = block['value']?.toString().trim() ?? '';
            if (value.isNotEmpty) koAliases.add(value);
          }
        }
      }
    }

    String? kowikiTitle;
    final sitelinksRaw = entity['sitelinks'];
    if (sitelinksRaw is Map) {
      final kowiki = sitelinksRaw['kowiki'];
      if (kowiki is Map) {
        kowikiTitle = kowiki['title']?.toString().trim();
      }
    }

    out[qid] = WikidataEntityLocaleFacts(
      labels: labels,
      koAliases: koAliases,
      kowikiTitle: kowikiTitle,
    );
  }
  return out;
}
