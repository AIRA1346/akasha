// 오프라인 Contract / Shadow fixture — 채널 source별.
library;

import 'discovery_types.dart';

List<Map<String, dynamic>> contractFixturesForChannel(
  DiscoveryChannelConfig config,
  int count,
) {
  switch (config.source) {
    case 'wikidata':
      return _wikidataMangaFixtures(count);
    default:
      throw UnsupportedError(
        'offline fixtures unsupported for source ${config.source}',
      );
  }
}

List<Map<String, dynamic>> _wikidataMangaFixtures(int count) {
  return List.generate(count, (i) {
    final n = i + 1;
    return {
      'qid': 'Q${900000 + n}',
      'title': 'Wikidata Manga Fixture $n',
      'titles': {
        'en': 'Wikidata Manga Fixture $n',
        'ja': 'ウィキデータ漫画$n',
      },
      'releaseYear': 1995 + (i % 30),
      'creator': 'Fixture Mangaka $n',
      'category': 'manga',
    };
  });
}

List<Map<String, dynamic>> sampleNodesForChannel(DiscoveryChannelConfig config) {
  if (config.source != 'wikidata') {
    throw UnsupportedError('sample nodes unsupported for ${config.source}');
  }
  return [
    {
      'qid': 'Q1048',
      'title': 'One Piece',
      'titles': {'en': 'One Piece', 'ja': 'ワンピース'},
      'releaseYear': 1997,
      'creator': 'Eiichiro Oda',
      'category': 'manga',
    },
    {
      'qid': 'Q186324',
      'title': 'Naruto',
      'titles': {'en': 'Naruto', 'ja': 'ナルト'},
      'releaseYear': 1999,
      'creator': 'Masashi Kishimoto',
      'category': 'manga',
    },
  ];
}
