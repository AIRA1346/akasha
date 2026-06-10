/// Wikidata SPARQL binding → Discovery Facts (CC0 structured data only).
library;

import 'discovery_types.dart';

String? qidFromWikidataUri(String? uri) {
  if (uri == null || uri.isEmpty) return null;
  final match = RegExp(r'(Q\d+)$').firstMatch(uri);
  return match?.group(1);
}

int? _yearFromBinding(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  final direct = int.tryParse(text);
  if (direct != null && direct > 0) return direct;
  final match = RegExp(r'(\d{4})').firstMatch(text);
  if (match != null) {
    final y = int.tryParse(match.group(1)!);
    if (y != null && y > 0) return y;
  }
  return null;
}

String _bindingValue(Map<String, dynamic> binding, String key) {
  final block = binding[key];
  if (block is Map) {
    return block['value']?.toString().trim() ?? '';
  }
  return '';
}

/// SPARQL `bindings` row → normalized discovery node.
Map<String, dynamic> wikidataBindingToNode(
  Map<String, dynamic> binding, {
  String category = 'manga',
}) {
  final qid = qidFromWikidataUri(_bindingValue(binding, 'item')) ?? '';
  final enLabel = _bindingValue(binding, 'itemLabel');
  final jaLabel = _bindingValue(binding, 'itemLabelJa');
  final title = enLabel.isNotEmpty ? enLabel : jaLabel;

  final titles = <String, String>{};
  if (enLabel.isNotEmpty) titles['en'] = enLabel;
  if (jaLabel.isNotEmpty) titles['ja'] = jaLabel;

  return {
    'qid': qid,
    'title': title,
    if (titles.isNotEmpty) 'titles': titles,
    'releaseYear': _yearFromBinding(_bindingValue(binding, 'startYear')),
    'creator': _bindingValue(binding, 'authorLabel'),
    'category': category,
    if (enLabel.isNotEmpty) 'entityEnLabel': enLabel,
  };
}

DiscoveryFacts extractWikidataFacts(Map<String, dynamic> node) {
  final titlesRaw = node['titles'];
  final titles = <String, String>{};
  if (titlesRaw is Map) {
    titlesRaw.forEach((key, value) {
      final v = value?.toString().trim() ?? '';
      if (v.isNotEmpty) titles[key.toString()] = v;
    });
  }

  return DiscoveryFacts(
    title: node['title']?.toString().trim() ?? '',
    titles: titles,
    releaseYear: _yearFromBinding(node['releaseYear']),
    creator: node['creator']?.toString().trim() ?? '',
    aliases: const [],
    format: 'MANGA',
  );
}
