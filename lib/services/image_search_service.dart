import 'dart:convert';
import 'dart:io';
import '../models/enums.dart';

class ImageSearchService {
  static final ImageSearchService _instance = ImageSearchService._internal();
  factory ImageSearchService() => _instance;
  ImageSearchService._internal();

  /// AniList GraphQL API를 이용해 만화, 애니메이션, 라이트노벨 표지 검색
  Future<List<Map<String, String>>> searchAniList(String query) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final uri = Uri.parse('https://graphql.anilist.co');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final graphqlQuery = '''
        query (\$search: String) {
          Page (perPage: 8) {
            media (search: \$search, isAdult: false) {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                extraLarge
              }
              type
              format
            }
          }
        }
      ''';

      final body = json.encode({
        'query': graphqlQuery,
        'variables': {'search': query},
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(jsonStr);
        final List<dynamic> media = data['data']?['Page']?['media'] ?? [];

        return media.map<Map<String, String>>((item) {
          final titleMap = item['title'] ?? {};
          final nativeTitle = titleMap['native']?.toString() ?? '';
          final englishTitle = titleMap['english']?.toString() ?? '';
          final romajiTitle = titleMap['romaji']?.toString() ?? '';
          
          final displayTitle = nativeTitle.isNotEmpty 
              ? nativeTitle 
              : (englishTitle.isNotEmpty ? englishTitle : romajiTitle);
              
          final coverUrl = item['coverImage']?['extraLarge']?.toString() 
              ?? item['coverImage']?['large']?.toString() 
              ?? '';

          final type = item['type']?.toString() ?? '';
          final format = item['format']?.toString() ?? '';
          String categoryLabel = type == 'ANIME' ? '애니메이션' : '만화/도서';
          if (format == 'NOVEL') {
            categoryLabel = '소설/라노벨';
          }

          return {
            'title': displayTitle,
            'coverUrl': coverUrl,
            'source': 'AniList ($categoryLabel)',
          };
        }).toList();
      }
    } catch (e) {
      print('Error searching AniList: $e');
    } finally {
      client.close();
    }
    return [];
  }

  /// Steam Store API를 이용해 게임 표지 이미지(600x900) 검색
  Future<List<Map<String, String>>> searchSteam(String query) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final url = 'https://store.steampowered.com/api/storesearch/?term=${Uri.encodeComponent(query)}&l=korean&cc=kr';
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(jsonStr);
        final List<dynamic> items = data['items'] ?? [];

        return items.map<Map<String, String>>((item) {
          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? '이름 없는 게임';
          
          // Steam 공식 라이브러리 세로형(600x900) 포스터 경로 조합
          final coverUrl = 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$id/library_600x900.jpg';

          return {
            'title': name,
            'coverUrl': coverUrl,
            'source': 'Steam (게임)',
          };
        }).toList();
      }
    } catch (e) {
      print('Error searching Steam: $e');
    } finally {
      client.close();
    }
    return [];
  }

  /// 카테고리에 맞춰 통합 이미지 검색 실행
  Future<List<Map<String, String>>> searchCovers(String query, MediaCategory category) async {
    if (query.trim().isEmpty) return [];

    if (category == MediaCategory.game) {
      // 게임 카테고리는 Steam 우선 검색 후 AniList 보완
      final steamResults = await searchSteam(query);
      if (steamResults.isNotEmpty) return steamResults;
      return await searchAniList(query);
    } else {
      // 만화, 애니메이션, 책 등은 AniList 우선 검색 후 Steam 보완
      final aniResults = await searchAniList(query);
      if (aniResults.isNotEmpty) return aniResults;
      return await searchSteam(query);
    }
  }
}
