import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/archiving/entity_anchor.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../utils/app_log.dart';
import 'markdown_parser.dart';
import 'user_preferences.dart';
import 'vault_work_journal_paths.dart';

class AkashaFileService {
  static const String _prefVaultKey = 'akasha_vault_path';

  static final Set<String> _skipDirNames = {
    'posters',
    'timeline',
    'catalog',
    'journal',
    'entities',
    'node_modules',
    '.git',
    '.obsidian', // 외부 노트 앱 설정 폴더 — 스캔 제외
    '.trash',
    '.cursor',
  };

  // 싱글톤 패턴
  static final AkashaFileService _instance = AkashaFileService._internal();
  factory AkashaFileService() => _instance;
  AkashaFileService._internal();

  String? _vaultPath;
  StreamController<void>? _vaultUpdateController;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  Timer? _watchDebounce;
  Timer? _pollTimer;
  String? _lastVaultFingerprint;
  final Map<String, AkashaItem> _inMemoryCache = {};

  /// 외부 편집 감지 폴링 간격 (Windows·클라우드 드라이브 watch 보조).
  static Duration vaultPollInterval = const Duration(seconds: 2);

  /// 메모리 캐시 반환 (데모 모드 지원용)
  Map<String, AkashaItem> get inMemoryCache => _inMemoryCache;

  /// 현재 설정된 볼트 경로. 설정되지 않은 경우 null을 반환.
  String? get vaultPath => _vaultPath;

  /// 볼트에 `.md` 아카이브가 연동된 작품인지 여부.
  bool isArchivedInVault(AkashaItem item) {
    if (_vaultPath == null || _vaultPath!.isEmpty) return false;
    final path = item.filePath;
    return path != null && path.isNotEmpty;
  }

  /// 볼트 변경 시 알림을 받을 수 있는 스트림.
  Stream<void> get onVaultUpdated {
    _vaultUpdateController ??= StreamController<void>.broadcast();
    return _vaultUpdateController!.stream;
  }

  /// SharedPreferences에서 기존에 저장된 볼트 경로를 불러옵니다.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefVaultKey);
    if (saved == null || saved.isEmpty) {
      _vaultPath = null;
      return;
    }

    if (await Directory(saved).exists()) {
      _vaultPath = saved;
      _startWatching();
    } else {
      _vaultPath = null;
      await prefs.remove(_prefVaultKey);
    }
  }

  /// 새로운 볼트 경로를 설정하고 저장합니다.
  Future<void> setVaultPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _inMemoryCache.clear();

    if (path.isEmpty) {
      _vaultPath = null;
      await prefs.remove(_prefVaultKey);
      _stopWatching();
    } else {
      _vaultPath = path;
      await prefs.setString(_prefVaultKey, path);
      await _ensureFolderStructure();
      _startWatching();
    }
    await _refreshVaultFingerprint();
    _notifyVaultUpdated();
  }

  /// 볼트에 필요한 기본 폴더 구조(posters, 카테고리별)를 생성합니다.
  Future<void> _ensureFolderStructure() async {
    if (_vaultPath == null) return;

    await Directory(p.join(_vaultPath!, 'posters')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'timeline')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'catalog')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'works')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'journal')).create(recursive: true);
    await Directory(p.join(_vaultPath!, 'entities')).create(recursive: true);
    for (final type in EntityAnchorType.values) {
      if (type == EntityAnchorType.work || type == EntityAnchorType.phenomenon) {
        continue;
      }
      await Directory(
        p.join(_vaultPath!, 'entities', type.name),
      ).create(recursive: true);
    }

    for (final cat in MediaCategory.values) {
      await Directory(p.join(_vaultPath!, 'works', cat.name)).create(recursive: true);
    }

    for (final cat in MediaCategory.values) {
      await Directory(p.join(_vaultPath!, cat.name)).create(recursive: true);
    }
  }

  void _notifyVaultUpdated() {
    _vaultUpdateController?.add(null);
  }

  /// timeline 등 VaultPort 외 경로로 vault 파일이 바뀐 뒤 UI 갱신용.
  Future<void> signalVaultChanged() async {
    await _refreshVaultFingerprint();
    _notifyVaultUpdated();
  }

  void _scheduleVaultUpdateNotification() {
    _watchDebounce?.cancel();
    _watchDebounce = Timer(const Duration(milliseconds: 400), () async {
      await _refreshVaultFingerprint();
      _notifyVaultUpdated();
    });
  }

  Future<void> _refreshVaultFingerprint() async {
    _lastVaultFingerprint = await _computeVaultFingerprint();
  }

  Future<String> _computeVaultFingerprint() async {
    if (_vaultPath == null) return '';

    final parts = <String>[];
    try {
      final dir = Directory(_vaultPath!);
      if (!await dir.exists()) return '';

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        if (_shouldSkipPath(entity.path)) continue;
        final stat = await entity.stat();
        parts.add(
          '${entity.path}|${stat.modified.millisecondsSinceEpoch}|${stat.size}',
        );
      }
    } catch (e) {
      appLog('[AkashaFileService] fingerprint error: $e');
    }
    parts.sort();
    return parts.join('\n');
  }

  Future<void> _pollVaultChanges() async {
    if (_vaultPath == null) return;
    final fp = await _computeVaultFingerprint();
    if (_lastVaultFingerprint == null) {
      _lastVaultFingerprint = fp;
      return;
    }
    if (fp != _lastVaultFingerprint) {
      _lastVaultFingerprint = fp;
      _notifyVaultUpdated();
    }
  }

  /// 볼트의 마크다운 파일 변경 감지를 위한 파일 감시를 시작합니다.
  void _startWatching() {
    _stopWatching();
    if (_vaultPath == null) return;

    final dir = Directory(_vaultPath!);
    if (!dir.existsSync()) return;

    try {
      _watcherSubscription = dir.watch(recursive: true).listen(
        (event) {
          if (_shouldNotifyForWatchEvent(event.path)) {
            _scheduleVaultUpdateNotification();
          }
        },
        onError: (error) {
          appLog('[AkashaFileService] Directory watch error: $error');
        },
      );
    } catch (e) {
      appLog('[AkashaFileService] Failed to start directory watch: $e');
    }

    _startPolling();
  }

  bool _shouldNotifyForWatchEvent(String path) {
    if (_shouldSkipPath(path)) return false;
    final lower = path.toLowerCase();
    if (lower.endsWith('.md')) return true;
    // 에디터 atomic save 임시 파일
    if (lower.contains('.akasha_') || lower.endsWith('.tmp')) return true;
    return false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (_vaultPath == null) return;
    _lastVaultFingerprint = null;
    _pollTimer = Timer.periodic(vaultPollInterval, (_) {
      _pollVaultChanges();
    });
    _pollVaultChanges();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastVaultFingerprint = null;
  }

  void _stopWatching() {
    _watchDebounce?.cancel();
    _watchDebounce = null;
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _stopPolling();
  }

  bool _shouldSkipPath(String filePath) {
    final parts = p.split(filePath);
    return parts.any((part) => part.startsWith('.') || _skipDirNames.contains(part));
  }

  static String cacheKeyFor(AkashaItem item) {
    if (item.workId.isNotEmpty) return item.workId;
    return '${item.category.name}::${item.title}';
  }

  /// workId 우선으로 중복 항목을 병합합니다. 동일 키면 addedAt이 최신인 항목을 유지합니다.
  static List<AkashaItem> dedupeItems(List<AkashaItem> items) {
    final map = <String, AkashaItem>{};
    for (final item in items) {
      final key = cacheKeyFor(item);
      final existing = map[key];
      if (existing == null || item.addedAt.isAfter(existing.addedAt)) {
        map[key] = item;
      }
    }
    return map.values.toList();
  }

  void _syncCacheFromItems(List<AkashaItem> items) {
    _inMemoryCache.clear();
    for (final item in items) {
      _inMemoryCache[cacheKeyFor(item)] = item;
    }
  }

  /// 볼트 내의 모든 마크다운 파일을 로드하여 AkashaItem 리스트를 반환합니다.
  Future<List<AkashaItem>> loadAllItems() async {
    if (_vaultPath == null) return [];

    final parsed = <AkashaItem>[];

    try {
      final dir = Directory(_vaultPath!);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.md')) continue;
          if (_shouldSkipPath(entity.path)) continue;

          try {
            final content = await entity.readAsString();
            final filename = p.basenameWithoutExtension(entity.path);
            final item = MarkdownParser.deserialize(content, filename);
            item.filePath = entity.path;
            parsed.add(item);
          } catch (e) {
            appLog('Error reading file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      appLog('Error loading items recursively from vault: $e');
    }

    final items = dedupeItems(parsed);
    _syncCacheFromItems(items);
    return items;
  }

  /// 볼트 내 .md 파일 개수 (파싱 없이 스캔)
  Future<int> countMarkdownFiles() async {
    if (_vaultPath == null) return 0;
    var count = 0;
    try {
      final dir = Directory(_vaultPath!);
      if (!await dir.exists()) return 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File &&
            entity.path.endsWith('.md') &&
            !_shouldSkipPath(entity.path)) {
          count++;
        }
      }
    } catch (e) {
      appLog('[AkashaFileService] countMarkdownFiles error: $e');
    }
    return count;
  }

  /// 볼트 경로가 유효한지 확인합니다.
  Future<bool> isVaultPathValid() async {
    if (_vaultPath == null || _vaultPath!.isEmpty) return false;
    return Directory(_vaultPath!).exists();
  }

  /// AkashaItem을 마크다운 파일로 저장합니다.
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) async {
    item.workId = MarkdownParser.ensureWorkId(item);
    _inMemoryCache[cacheKeyFor(item)] = item;

    if (_vaultPath == null) return;

    if (oldTitle != null && oldTitle != item.title) {
      if (item.filePath != null && item.filePath!.isNotEmpty) {
        final oldFile = File(item.filePath!);
        final parentDir = p.dirname(item.filePath!);
        if (oldFile.existsSync()) {
          _stopWatching();
          try {
            await oldFile.delete();
          } catch (e) {
            appLog('Error deleting old file: $e');
          } finally {
            _startWatching();
          }
        }
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
      final useWorksLayout = await UserPreferences.isVaultWorksLayoutEnabled();
      targetPath = VaultWorkJournalPaths.resolveNewPath(
        vaultRoot: _vaultPath!,
        item: item,
        useWorksLayout: useWorksLayout,
      );
      await Directory(p.dirname(targetPath)).create(recursive: true);
      item.filePath = targetPath;
    }

    final content = MarkdownParser.serialize(item);

    _stopWatching();
    try {
      await _writeAtomic(targetPath, content);
      await _refreshVaultFingerprint();
      _notifyVaultUpdated();
    } finally {
      _startWatching();
    }
  }

  Future<void> _writeAtomic(String targetPath, String content) async {
    final file = File(targetPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final tempPath = p.join(
      parent.path,
      '.akasha_${DateTime.now().microsecondsSinceEpoch}_${p.basename(targetPath)}.tmp',
    );
    final temp = File(tempPath);
    try {
      await temp.writeAsString(content, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(targetPath);
    } catch (e) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// AkashaItem을 볼트에서 제거(마크다운 파일 삭제)합니다.
  Future<bool> deleteAkashaItem(AkashaItem item) async {
    _inMemoryCache.remove(cacheKeyFor(item));

    if (_vaultPath == null) return true;

    final candidates = VaultWorkJournalPaths.resolveDeleteCandidates(
      vaultRoot: _vaultPath!,
      title: item.title,
      category: item.category,
      filePath: item.filePath,
    );
    return _deleteAtCandidatePaths(candidates);
  }

  /// 제목·카테고리 기반 삭제 (파일명 변경 시 saveItem 내부용)
  Future<void> deleteItem(String title, MediaCategory category) async {
    _inMemoryCache.removeWhere(
      (key, cached) => cached.title == title && cached.category == category,
    );

    if (_vaultPath == null) return;

    final candidates = VaultWorkJournalPaths.resolveDeleteCandidates(
      vaultRoot: _vaultPath!,
      title: title,
      category: category,
    );
    await _deleteAtCandidatePaths(candidates);
  }

  Future<bool> _deleteAtCandidatePaths(List<String> candidatePaths) async {
    final existing = <File>[];
    for (final path in candidatePaths) {
      final file = File(path);
      if (await file.exists()) {
        existing.add(file);
      }
    }
    if (existing.isEmpty) return false;

    _stopWatching();
    try {
      for (final file in existing) {
        await file.delete();
      }
      _notifyVaultUpdated();
      return true;
    } finally {
      _startWatching();
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
    return p.join('posters', uniqueFilename);
  }

  String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  void dispose() {
    _stopWatching();
    _vaultUpdateController?.close();
    _vaultUpdateController = null;
  }
}
