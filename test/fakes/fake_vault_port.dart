import 'dart:async';
import 'package:akasha/core/ports/vault_port.dart';
import 'package:akasha/models/akasha_item.dart';

class FakeVaultPort implements VaultPort {
  String? _vaultPath = '/fake/vault';
  final Map<String, AkashaItem> _cache = {};
  final StreamController<void> _updateController = StreamController<void>.broadcast();

  @override
  Future<void> init() async {}

  @override
  String? get vaultPath => _vaultPath;

  @override
  Future<void> setVaultPath(String path) async {
    _cache.clear();
    _vaultPath = path.isEmpty ? null : path;
    _updateController.add(null);
  }

  @override
  Future<bool> isVaultPathValid() async {
    return _vaultPath != null && _vaultPath!.isNotEmpty;
  }

  @override
  bool isArchivedInVault(AkashaItem item) {
    if (_vaultPath == null) return false;
    final key = item.workId.isNotEmpty ? item.workId : '${item.category.name}::${item.title}';
    return _cache.containsKey(key);
  }

  @override
  Future<List<AkashaItem>> loadAllItems() async {
    if (_vaultPath == null) return [];
    return _cache.values.toList();
  }

  @override
  Future<int> countMarkdownFiles() async {
    if (_vaultPath == null) return 0;
    return _cache.length;
  }

  @override
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) async {
    final key = item.workId.isNotEmpty ? item.workId : '${item.category.name}::${item.title}';

    // 제목이 변경된 경우 이전 항목 삭제 모사
    if (oldTitle != null && oldTitle != item.title) {
      final oldKey = item.workId.isNotEmpty ? item.workId : '${item.category.name}::$oldTitle';
      _cache.remove(oldKey);
    }

    _cache[key] = item;
    _updateController.add(null);
  }

  @override
  Future<void> deleteItem(AkashaItem item) async {
    final key = item.workId.isNotEmpty ? item.workId : '${item.category.name}::${item.title}';
    _cache.remove(key);
    _updateController.add(null);
  }

  @override
  Stream<void> get onVaultUpdated => _updateController.stream;

  @override
  Map<String, AkashaItem> get inMemoryCache => _cache;
}
