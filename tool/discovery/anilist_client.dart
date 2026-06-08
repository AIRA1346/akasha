/// AniList GraphQL client — 허용 Fact 필드만 요청, 응답은 메모리 전용.
library;

import 'dart:convert';
import 'dart:io';

import 'anilist_facts.dart';

const anilistGraphqlEndpoint = 'https://graphql.anilist.co';

/// 금지 필드(description·coverImage 등)는 쿼리에 포함하지 않음.
const _animationMediaQuery = r'''
query ($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
    }
    media(type: ANIME, sort: ID, isAdult: false) {
      id
      format
      title {
        romaji
        english
        native
      }
      synonyms
      startDate {
        year
      }
      seasonYear
      studios(isMain: true) {
        nodes {
          name
        }
      }
    }
  }
}
''';

/// [batchSize]건까지 [requiredCategory]에 맞는 ANIME Media fetch.
/// 카테고리 불일치(MOVIE 등)는 건너뛰고 다음 페이지를 이어감. raw 응답은 폐기.
Future<List<Map<String, dynamic>>> fetchAnilistAnimationBatch({
  required int batchSize,
  String requiredCategory = 'animation',
  HttpClient? client,
  Future<Map<String, dynamic>> Function({
    required int page,
    required int perPage,
    required HttpClient client,
  })? fetchPage,
}) async {
  if (batchSize <= 0) return const [];

  final http = client ?? HttpClient();
  final ownsClient = client == null;
  final pageFetcher = fetchPage ?? _fetchAnilistPage;
  final out = <Map<String, dynamic>>[];

  try {
    var page = 1;
    const perPage = 50;
    const maxPages = 20;
    while (out.length < batchSize && page <= maxPages) {
      final payload = await pageFetcher(
        page: page,
        perPage: perPage,
        client: http,
      );
      final pageBlock = payload['Page'];
      if (pageBlock is! Map) break;

      final media = pageBlock['media'];
      if (media is List) {
        for (final item in media) {
          if (item is! Map) continue;
          final node = Map<String, dynamic>.from(item);
          final category =
              anilistFormatToCategory(node['format']?.toString());
          if (category != requiredCategory) continue;
          out.add(node);
          if (out.length >= batchSize) break;
        }
      }

      final pageInfo = pageBlock['pageInfo'];
      final hasNext = pageInfo is Map && pageInfo['hasNextPage'] == true;
      if (!hasNext || out.length >= batchSize) break;
      page++;
    }
  } finally {
    if (ownsClient) {
      http.close(force: true);
    }
  }

  if (out.length < batchSize) {
    throw StateError(
      'Only ${out.length}/$batchSize $requiredCategory nodes found',
    );
  }

  return out;
}

Future<Map<String, dynamic>> _fetchAnilistPage({
  required int page,
  required int perPage,
  required HttpClient client,
}) async {
  final uri = Uri.parse(anilistGraphqlEndpoint);
  final request = await client.postUrl(uri);
  request.headers.set('Content-Type', 'application/json');
  request.headers.set('Accept', 'application/json');
  request.write(
    json.encode({
      'query': _animationMediaQuery,
      'variables': {'page': page, 'perPage': perPage},
    }),
  );

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'AniList HTTP ${response.statusCode}: $body',
      uri: uri,
    );
  }

  final decoded = json.decode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('AniList response is not a JSON object');
  }

  final errors = decoded['errors'];
  if (errors is List && errors.isNotEmpty) {
    throw StateError('AniList GraphQL errors: ${json.encode(errors)}');
  }

  final data = decoded['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('AniList response missing data');
  }
  return data;
}
