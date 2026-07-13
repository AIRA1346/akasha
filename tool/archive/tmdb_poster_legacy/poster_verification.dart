// Archived akasha-db posterPath verification rules.
library;

import 'dart:convert';
import 'dart:io';

const tmdbImageHost = 'image.tmdb.org';

/// 포스터가 검증됐는지 판단합니다.
/// - posterPath 없음 → 검증 불필요 (true)
/// - TMDB가 아닌 호스트(Steam, Open Library, AniList 등) → 검증됨
/// - TMDB → externalIds.tmdb + 캐시 URL 일치 시에만 검증됨
/// - posterVerified 플래그만으로는 TMDB 검증 통과하지 않음
bool isPosterVerified(
  Map<String, dynamic> work,
  Map<int, String> tmdbPosterCache,
) {
  final poster = work['posterPath']?.toString() ?? '';
  if (poster.isEmpty) return true;

  final host = Uri.tryParse(poster)?.host.toLowerCase() ?? '';
  if (!host.contains(tmdbImageHost)) return true;

  final tmdbId = resolveTmdbId(work);
  if (tmdbId == null) return false;

  final cachedPath = tmdbPosterCache[tmdbId];
  if (cachedPath == null || cachedPath.isEmpty) return false;

  return normalizePosterUrl(poster) ==
      normalizePosterUrl(buildTmdbPosterUrl(cachedPath));
}

int? resolveTmdbId(Map<String, dynamic> work) {
  final externalIds = work['externalIds'];
  if (externalIds is Map) {
    final raw = externalIds['tmdb']?.toString().trim() ?? '';
    final id = int.tryParse(raw);
    if (id != null && id > 0) return id;
  }
  final extensions = work['extensions'];
  if (extensions is Map) {
    for (final key in ['tmdbId', 'tmdb']) {
      final raw = extensions[key]?.toString().trim() ?? '';
      final id = int.tryParse(raw);
      if (id != null && id > 0) return id;
    }
  }
  return null;
}

String buildTmdbPosterUrl(String cachePath) {
  var path = cachePath;
  if (path.startsWith('//')) path = path.substring(1);
  if (!path.startsWith('/')) path = '/$path';
  return 'https://image.tmdb.org/t/p/w500$path';
}

String normalizePosterUrl(String url) {
  return url
      .trim()
      .replaceAll(RegExp(r'https?://'), '')
      .replaceAll('//', '/')
      .toLowerCase();
}

String cleanTmdbPageTitle(String raw) {
  return raw
      .replaceAll(RegExp(r'\s*\(\d{4}\).*$'), '')
      .replaceAll(' — The Movie Database (TMDB)', '')
      .trim();
}

/// workId 슬러그 (sub_manga_rezero_2014 → rezero)
String? slugFromWorkId(String workId) {
  final parts = workId.split('_');
  if (parts.length < 3) return null;
  return parts[parts.length - 2].replaceAll('-', '').toLowerCase();
}

/// TMDB 페이지 제목과 작품 메타를 대조합니다.
bool titlesMatchWork(Map<String, dynamic> work, String tmdbTitle) {
  final tokens = <String>{};
  void add(String? s) {
    if (s == null || s.trim().isEmpty) return;
    final lower = s.toLowerCase();
    tokens.add(lower);
    tokens.add(lower.replaceAll(RegExp(r'[\s:：·\-–—!?.]'), ''));
  }

  add(work['title']?.toString());
  final titles = work['titles'];
  if (titles is Map) {
    for (final v in titles.values) {
      add(v?.toString());
    }
  }
  final aliases = work['aliases'];
  if (aliases is List) {
    for (final a in aliases) {
      add(a?.toString());
    }
  }

  final workId = work['workId']?.toString() ?? '';
  final slug = slugFromWorkId(workId);
  if (slug != null && slug.length >= 4) {
    tokens.add(slug);
  }

  final pageVariants = tmdbTitle.split(' | ').map((s) => s.toLowerCase()).toList();
  for (final page in pageVariants) {
    final pageCompact = page.replaceAll(RegExp(r'[\s:：·\-–—!?.]'), '');
    for (final t in tokens) {
      if (t.length < 3) continue;
      if (page.contains(t) || pageCompact.contains(t)) return true;
      if (t.contains(pageCompact) && pageCompact.length >= 4) return true;
    }
  }

  final ja = work['titles'] is Map
      ? work['titles']['ja']?.toString()
      : null;
  if (ja != null && ja.isNotEmpty) {
    for (final page in pageVariants) {
      if (page.contains(ja)) return true;
    }
  }

  return false;
}

String _decodeHtmlEntities(String raw) {
  return raw
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

Future<String?> fetchTmdbPageTitle(HttpClient client, int id) async {
  for (final type in ['tv', 'movie']) {
    try {
      final request = await client.getUrl(
        Uri.parse('https://www.themoviedb.org/$type/$id'),
      );
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      );
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) continue;
      final html = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      final parts = <String>[];
      final og = RegExp(
        r'property="og:title" content="([^"]+)"',
      ).firstMatch(html);
      if (og != null) {
        parts.add(_decodeHtmlEntities(cleanTmdbPageTitle(og.group(1)!)));
      }
      final h2 = RegExp(r'<h2[^>]*>\s*([^<]+?)\s*</h2>').firstMatch(html);
      if (h2 != null) {
        parts.add(_decodeHtmlEntities(cleanTmdbPageTitle(h2.group(1)!)));
      }
      for (final pattern in [
        RegExp(r'"original_name"\s*:\s*"([^"]+)"'),
        RegExp(r'"original_title"\s*:\s*"([^"]+)"'),
        RegExp(r'Original Name\s*</span>\s*<span[^>]*>([^<]+)'),
      ]) {
        final m = pattern.firstMatch(html);
        if (m != null) {
          parts.add(_decodeHtmlEntities(m.group(1)!.trim()));
        }
      }
      if (parts.isNotEmpty) {
        return parts.toSet().join(' | ');
      }
    } catch (_) {}
  }
  return null;
}

HttpClient createTmdbHttpClient() {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  return client;
}
