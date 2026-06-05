import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Git 기반 글로벌 작품 사전 동기화 서비스 (Phase 4)
class RegistrySyncService {
  static const String _prefLastSyncKey = 'akasha_last_sync_time';
  static const String _prefCustomUrlKey = 'akasha_custom_db_url';
  
  // 기본 작품 사전 데이터 URL (GitHub raw 주소)
  static const String defaultDbUrl =
      'https://raw.githubusercontent.com/AIRA1346/akasha-db/main/works_registry.json';

  // 싱글톤
  static final RegistrySyncService _instance = RegistrySyncService._internal();
  factory RegistrySyncService() => _instance;
  RegistrySyncService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 커스텀 DB 동기화 URL 가져오기
  String get customDbUrl {
    return _prefs?.getString(_prefCustomUrlKey) ?? defaultDbUrl;
  }

  /// 커스텀 DB 동기화 URL 설정하기 (비우면 기본값 복구)
  Future<void> setCustomDbUrl(String url) async {
    await init();
    if (url.trim().isEmpty) {
      await _prefs?.remove(_prefCustomUrlKey);
    } else {
      await _prefs?.setString(_prefCustomUrlKey, url.trim());
    }
  }

  /// 마지막 동기화 일시 가져오기
  DateTime? get lastSyncTime {
    final timeStr = _prefs?.getString(_prefLastSyncKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// 로컬 캐시 파일 경로 얻기
  Future<File> get _localCacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'local_works_registry.json'));
  }

  /// 로컬 캐시 파일의 텍스트 콘텐츠 읽기
  Future<String?> readCachedRegistry() async {
    try {
      final file = await _localCacheFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading local registry cache: $e');
    }
    return null;
  }

  /// 백그라운드 자동 동기화 필요 여부 확인 (마지막 동기화 후 24시간 경과 시)
  Future<bool> shouldAutoSync() async {
    await init();
    final lastSync = lastSyncTime;
    if (lastSync == null) return true;
    
    final difference = DateTime.now().difference(lastSync);
    return difference.inHours >= 24;
  }

  /// 원격 정적 사전을 다운로드하여 로컬 캐시에 저장
  Future<bool> sync() async {
    await init();
    final url = customDbUrl;
    final client = HttpClient();
    
    // 타임아웃 설정 (10초)
    client.connectionTimeout = const Duration(seconds: 10);
    
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        
        // JSON 유효성 검증
        final decoded = json.decode(content);
        if (decoded is Map || decoded is List) {
          // 로컬 캐시 디스크 저장
          final file = await _localCacheFile;
          await file.writeAsString(content);
          
          // 동기화 시간 저장
          await _prefs?.setString(_prefLastSyncKey, DateTime.now().toIso8601String());
          return true;
        }
      }
    } catch (e) {
      print('Error syncing registry database from $url: $e');
    } finally {
      client.close();
    }
    return false;
  }
}
