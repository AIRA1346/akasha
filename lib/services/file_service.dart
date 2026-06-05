import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import 'markdown_parser.dart';

class AkashaFileService {
  static const String _prefVaultKey = 'akasha_vault_path';
  
  // 싱글톤 패턴
  static final AkashaFileService _instance = AkashaFileService._internal();
  factory AkashaFileService() => _instance;
  AkashaFileService._internal();

  String? _vaultPath;
  StreamController<void>? _vaultUpdateController;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  final Map<String, AkashaItem> _inMemoryCache = {};

  /// 메모리 캐시 반환 (데모 모드 지원용)
  Map<String, AkashaItem> get inMemoryCache => _inMemoryCache;

  /// 현재 설정된 볼트 경로. 설정되지 않은 경우 null을 반환.
  String? get vaultPath => _vaultPath;

  /// 볼트 변경 시 알림을 받을 수 있는 스트림.
  Stream<void> get onVaultUpdated {
    _vaultUpdateController ??= StreamController<void>.broadcast();
    return _vaultUpdateController!.stream;
  }

  /// SharedPreferences에서 기존에 저장된 볼트 경로를 불러옵니다.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _vaultPath = prefs.getString(_prefVaultKey);
    if (_vaultPath != null && _vaultPath!.isNotEmpty) {
      if (await Directory(_vaultPath!).exists()) {
        _startWatching();
      } else {
        _vaultPath = null;
      }
    }
  }

  /// 새로운 볼트 경로를 설정하고 저장합니다.
  Future<void> setVaultPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path.isEmpty) {
      _vaultPath = null;
      await prefs.remove(_prefVaultKey);
      _stopWatching();
    } else {
      _vaultPath = path;
      await prefs.setString(_prefVaultKey, path);
      // 필수 폴더 구조 생성
      await _ensureFolderStructure();
      _startWatching();
    }
    _vaultUpdateController?.add(null);
  }

  /// 볼트에 필요한 기본 폴더 구조(posters, manga, book, animation, game)를 생성합니다.
  Future<void> _ensureFolderStructure() async {
    if (_vaultPath == null) return;
    
    // posters 폴더
    await Directory(p.join(_vaultPath!, 'posters')).create(recursive: true);
    
    // 각 카테고리 폴더
    for (final cat in MediaCategory.values) {
      await Directory(p.join(_vaultPath!, cat.name)).create(recursive: true);
    }
  }

  /// 볼트의 마크다운 파일 변경 감지를 위한 파일 감시를 시작합니다.
  void _startWatching() {
    _stopWatching();
    if (_vaultPath == null) return;

    final dir = Directory(_vaultPath!);
    if (!dir.existsSync()) return;

    // 디렉토리 변경 감시 (재귀적)
    try {
      _watcherSubscription = dir.watch(recursive: true).listen(
        (event) {
          // .md 파일의 변경, 생성, 삭제 이벤트만 감지하여 알림
          if (event.path.endsWith('.md')) {
            _vaultUpdateController?.add(null);
          }
        },
        onError: (error) {
          print('[AkashaFileService] Directory watch error: $error');
        },
      );
    } catch (e) {
      print('[AkashaFileService] Failed to start directory watch: $e');
    }
  }

  /// 파일 감시를 중단합니다.
  void _stopWatching() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
  }

  /// 볼트 내의 모든 마크다운 파일을 로드하여 AkashaItem 리스트를 반환합니다.
  /// 볼트 경로가 지정되지 않은 경우 빈 리스트를 반환합니다.
  Future<List<AkashaItem>> loadAllItems() async {
    if (_vaultPath == null) return [];

    final items = <AkashaItem>[];
    
    try {
      final dir = Directory(_vaultPath!);
      if (await dir.exists()) {
        final entities = dir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.md')) {
            // 숨겨진 폴더/파일 (.obsidian, .git 등) 건너뜀
            final pathParts = p.split(entity.path);
            if (pathParts.any((part) => part.startsWith('.'))) {
              continue;
            }
            // posters 폴더 건너뜀
            if (pathParts.contains('posters')) {
              continue;
            }

            try {
              final content = await entity.readAsString();
              final filename = p.basenameWithoutExtension(entity.path);
              final item = MarkdownParser.deserialize(content, filename);
              item.filePath = entity.path; // 원본 파일 경로 기억
              
              // 중복 방지 (제목과 카테고리가 겹치면 중복 처리)
              final exists = items.any((existing) => 
                existing.title == item.title && existing.category == item.category
              );
              if (!exists) {
                items.add(item);
              }
            } catch (e) {
              print('Error reading file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading items recursively from vault: $e');
    }

    return items;
  }

  /// AkashaItem을 마크다운 파일로 저장합니다.
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) async {
    // 메모리 캐시에 먼저 저장 (데모 모드 및 실시간 상태 동기화 지원)
    final key = item.workId.isNotEmpty ? item.workId : item.title;
    _inMemoryCache[key] = item;

    if (_vaultPath == null) return;

    // 제목이 변경된 경우 이전 파일을 먼저 삭제 처리
    if (oldTitle != null && oldTitle != item.title) {
      if (item.filePath != null && item.filePath!.isNotEmpty) {
        final oldFile = File(item.filePath!);
        final parentDir = p.dirname(item.filePath!);
        if (oldFile.existsSync()) {
          _stopWatching();
          try {
            await oldFile.delete();
          } catch (e) {
            print('Error deleting old file: $e');
          } finally {
            _startWatching();
          }
        }
        // 원래 존재하던 폴더 경로 그대로 새 파일명 조합
        final safeTitle = _makeSafeFilename(item.title);
        item.filePath = p.join(parentDir, '$safeTitle.md');
      } else {
        await deleteItem(oldTitle, item.category);
      }
    }

    String targetPath;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      targetPath = item.filePath!;
    } else {
      final categoryDir = p.join(_vaultPath!, item.category.name);
      await Directory(categoryDir).create(recursive: true);
      final safeTitle = _makeSafeFilename(item.title);
      targetPath = p.join(categoryDir, '$safeTitle.md');
      item.filePath = targetPath;
    }

    final content = MarkdownParser.serialize(item);
    
    // 파일 쓰기 전에 watcher가 일시적으로 중단되도록 하여 불필요한 새로고침 루프 방지
    _stopWatching();
    try {
      final file = File(targetPath);
      await file.writeAsString(content);
    } finally {
      _startWatching();
    }
  }

  /// AkashaItem을 볼트에서 제거(마크다운 파일 삭제)합니다.
  Future<void> deleteItem(String title, MediaCategory category) async {
    _inMemoryCache.removeWhere((key, item) => 
      item.title == title && item.category == category
    );

    if (_vaultPath == null) return;

    final safeTitle = _makeSafeFilename(title);
    final filePath = p.join(_vaultPath!, category.name, '$safeTitle.md');
    final file = File(filePath);

    if (await file.exists()) {
      _stopWatching();
      try {
        await file.delete();
      } finally {
        _startWatching();
      }
    }
  }

  /// 외부 이미지를 볼트의 posters 폴더로 복사하고 상대 경로를 반환합니다.
  Future<String?> importPosterImage(String sourceFilePath) async {
    if (_vaultPath == null) return null;

    final file = File(sourceFilePath);
    if (!await file.exists()) return null;

    final filename = p.basename(sourceFilePath);
    final uniqueFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
    final destinationPath = p.join(_vaultPath!, 'posters', uniqueFilename);

    await file.copy(destinationPath);
    return p.join('posters', uniqueFilename); // relative path stored in DB/YAML
  }

  /// 파일명에 사용할 수 없는 특수 기호를 언더바로 치환합니다.
  String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// 리소스를 해제합니다.
  void dispose() {
    _stopWatching();
    _vaultUpdateController?.close();
  }
}
