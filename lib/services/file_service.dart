import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/enums.dart';
import '../utils/app_log.dart';
import 'entity_path_index_service.dart';
import 'markdown_parser.dart';
import 'record_summary_index_service.dart';
import 'user_preferences.dart';
import 'vault_readme_writer.dart';
import 'vault_trash_service.dart';
import 'vault_watch_poll_policy.dart';
import 'vault_work_journal_paths.dart';

part 'file_service_paths.dart';
part 'file_service_watch.dart';
part 'file_service_scan.dart';
part 'file_service_save.dart';
part 'file_service_bootstrap.dart';

abstract class _AkashaFileServiceBase {
  String? _vaultPath;
  StreamController<void>? _vaultUpdateController;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  Timer? _watchDebounce;
  Timer? _pollTimer;
  String? _lastVaultFingerprint;
  bool _directoryWatchActive = false;
  final Map<String, AkashaItem> _inMemoryCache = {};
}

class AkashaFileService extends _AkashaFileServiceBase
    with
        _AkashaFileServicePaths,
        _AkashaFileServiceWatch,
        _AkashaFileServiceScan,
        _AkashaFileServiceSave,
        _AkashaFileServiceBootstrap {
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
    VaultTrashService.trashDirName,
    '.cursor',
  };

  // 싱글톤 패턴
  static final AkashaFileService _instance = AkashaFileService._internal();
  factory AkashaFileService() => _instance;
  AkashaFileService._internal();

  /// 외부 편집 감지 폴링 간격 — directory watch 실패 시 fallback.
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
}
