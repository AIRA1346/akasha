import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 포스터 이미지 로컬 다운로드 및 해시 기반 캐싱 관리 서비스 (Phase 5)
class ImageCacheService {
  // 싱글톤
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// 캐시 디렉토리(ApplicationDocumentsDirectory/posters) 얻기
  Future<Directory> get _cacheDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final cachePath = p.join(docDir.path, 'posters');
    final dir = Directory(cachePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 기기 독립적인 간단한 URL 문자열 해시 생성 (Cache Invalidation용)
  String _getUrlHash(String url) {
    int hash = 0;
    for (int i = 0; i < url.length; i++) {
      hash = 31 * hash + url.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.abs().toString();
  }

  /// URL에서 확장자 추출 (기본값은 .jpg)
  String _getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final ext = p.extension(path).toLowerCase();
      if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp' || ext == '.gif') {
        return ext;
      }
    } catch (_) {}
    return '.jpg';
  }

  /// 지정한 workId와 URL에 해당하는 로컬 캐시 파일 반환
  Future<File?> getLocalPosterFile(String workId, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return null;
    }
    final hash = _getUrlHash(imageUrl);
    final ext = _getExtension(imageUrl);
    final dir = await _cacheDir;
    return File(p.join(dir.path, '${workId}_$hash$ext'));
  }

  /// 로컬 캐시 포스터 존재 여부 반환
  Future<bool> hasLocalPoster(String workId, String? imageUrl) async {
    final file = await getLocalPosterFile(workId, imageUrl);
    if (file == null) return false;
    return await file.exists();
  }

  /// 원격 이미지를 백그라운드에서 로컬 디스크로 캐싱하고 이전 캐시는 정리
  Future<File?> cachePosterImage(String workId, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return null;
    }

    final targetFile = await getLocalPosterFile(workId, imageUrl);
    if (targetFile == null) return null;

    // 이미 최신 해시의 캐시가 존재하는 경우 즉시 반환
    if (await targetFile.exists()) {
      return targetFile;
    }

    final client = HttpClient();
    // 10초 타임아웃
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse(imageUrl);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          [],
          (previous, element) => previous..addAll(element),
        );
        
        if (bytes.isNotEmpty) {
          // 파일 쓰기
          await targetFile.writeAsBytes(bytes);

          // 구버전 캐시 정리 (workId가 같으나 해시가 다른 파일 삭제)
          await _cleanOldCaches(workId, targetFile.path);

          return targetFile;
        }
      }
    } catch (e) {
      print('Error caching poster image for $workId from $imageUrl: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// 옛날 버전 캐시 파일 삭제 (동일 workId로 생성되었으나 현재 해시 파일이 아닌 것)
  Future<void> _cleanOldCaches(String workId, String currentFilePath) async {
    try {
      final dir = await _cacheDir;
      if (!await dir.exists()) return;
      
      final files = dir.listSync();
      final currentName = p.basename(currentFilePath);
      final prefix = '${workId}_';

      for (final entity in files) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.startsWith(prefix) && name != currentName) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning old poster caches for $workId: $e');
    }
  }
}
