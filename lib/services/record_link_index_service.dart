import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../core/app_vault.dart';
import '../core/archiving/record_link.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../core/ports/vault_port.dart';
import '../core/archiving/vault_ledger_event.dart';
import '../models/akasha_item.dart';
import 'event_ledger_service.dart';
import 'record_link_navigator.dart';
import 'record_link_parser.dart';

/// `vault/.akasha/link_index.json` — Wave 5.
///
/// Home and Workbench must share one in-memory lifecycle for a vault session.
/// Full [rebuildIndex] is repair/maintenance only — interactive paths use
/// [upsertMarkdownFile] / [removeBySourcePath] or disk load.
class RecordLinkIndexService implements RecordLinkPort {
  RecordLinkIndexService({VaultPort? vault, EventLedgerService? eventLedger})
    : _vault = vault ?? AppVault.port,
      _eventLedger =
          eventLedger ?? EventLedgerService(vault: vault ?? AppVault.port);

  static RecordLinkIndexService? _shared;

  /// Process-wide link index for [AppVault.port] (Home + ArchiveIndexManager).
  static RecordLinkIndexService get shared =>
      _shared ??= RecordLinkIndexService();

  @visibleForTesting
  static void resetSharedForTest() {
    _shared = null;
  }

  /// Clears in-memory state after the Vault root changes.
  void resetSession() {
    _outgoing = {};
    _incoming = {};
    _loaded = false;
    _resolveUserCatalog = null;
    _resolveVaultItems = const [];
  }

  static const int schemaVersion = 1;
  static const String indexDirName = '.akasha';
  static const String indexFileName = 'link_index.json';

  static const Set<String> _scanSkipDirNames = {
    'posters',
    'catalog',
    'node_modules',
    '.git',
    '.obsidian',
    '.trash',
    '.cursor',
    indexDirName,
  };

  final VaultPort _vault;
  final EventLedgerService _eventLedger;

  Map<String, List<RecordLink>> _outgoing = {};
  Map<String, List<String>> _incoming = {};
  bool _loaded = false;
  UserCatalogPort? _resolveUserCatalog;
  List<AkashaItem> _resolveVaultItems = const [];

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
    Future<void> Function(Map<String, dynamic> stats)? onRebuilt,
  }) async {
    final vaultPath = _vault.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      _outgoing = {};
      _incoming = {};
      _loaded = true;
      return;
    }

    if (userCatalog != null) {
      _resolveUserCatalog = userCatalog;
      await userCatalog.load();
    }
    if (vaultItems.isNotEmpty) {
      _resolveVaultItems = vaultItems;
    }

    final catalog = _resolveUserCatalog;
    final items = _resolveVaultItems;

    final outgoing = <String, List<RecordLink>>{};
    final incoming = <String, List<String>>{};

    await for (final file in _scanRecordFiles(vaultPath)) {
      try {
        final content = await file.readAsString();
        final parsed = RecordLinkParser.parseFromRecordContent(content);
        if (parsed.isEmpty) continue;

        final sourcePath = p.normalize(file.path);
        final links = parsed
            .map(
              (link) => RecordLink.fromParsed(
                sourceRecordId: sourcePath,
                parsed: link,
              ),
            )
            .toList();

        outgoing[sourcePath] = _dedupeLinks(links);

        for (final link in outgoing[sourcePath]!) {
          final targetId = _incomingTargetId(link, catalog, items);
          if (targetId == null) continue;
          incoming.putIfAbsent(targetId, () => []).add(sourcePath);
        }
      } catch (_) {
        // skip unreadable files
      }
    }

    for (final entry in incoming.entries) {
      entry.value.sort();
    }

    _outgoing = outgoing;
    _incoming = incoming;
    _loaded = true;

    await _persist(vaultPath);

    final stats = {
      'outgoingSources': outgoing.length,
      'incomingEntities': incoming.length,
      if (changedPath != null && changedPath.isNotEmpty)
        'changedPath': p.normalize(changedPath),
    };
    if (onRebuilt != null) {
      await onRebuilt(stats);
    } else {
      await _eventLedger.append(
        VaultLedgerEvent(
          type: VaultLedgerEventType.linkIndexRebuilt,
          at: DateTime.now().toUtc(),
          meta: stats,
        ),
      );
    }
  }

  Future<List<RecordLink>> upsertMarkdownFile({
    required String vaultPath,
    required String absolutePath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) {
      return const [];
    }
    if (!_isWithinVault(vaultPath, absolutePath)) return const [];

    if (userCatalog != null) {
      _resolveUserCatalog = userCatalog;
      await userCatalog.load();
    }
    if (vaultItems.isNotEmpty) {
      _resolveVaultItems = vaultItems;
    }

    final file = File(absolutePath);
    if (!await file.exists() || _shouldSkipPath(file.path)) {
      await removeBySourcePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return const [];
    }

    await _ensureLoadedForVault(vaultPath);

    final sourcePath = p.normalize(file.path);
    final parsed = RecordLinkParser.parseFromRecordContent(
      await file.readAsString(),
    );
    final links = _dedupeLinks(
      parsed
          .map(
            (link) =>
                RecordLink.fromParsed(sourceRecordId: sourcePath, parsed: link),
          )
          .toList(),
    );

    _removeSourceFromIndexes(sourcePath);
    if (links.isNotEmpty) {
      _outgoing[sourcePath] = links;
      for (final link in links) {
        final targetId = _incomingTargetId(
          link,
          _resolveUserCatalog,
          _resolveVaultItems,
        );
        if (targetId == null) continue;
        _incoming.putIfAbsent(targetId, () => []).add(sourcePath);
      }
      for (final entry in _incoming.entries) {
        entry.value.sort();
      }
    }

    await _persist(vaultPath);
    return links;
  }

  Future<void> removeBySourcePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return;
    if (!_isWithinVault(vaultPath, absolutePath)) return;

    await _ensureLoadedForVault(vaultPath);
    final changed = _removeSourceFromIndexes(p.normalize(absolutePath));
    if (changed) {
      await _persist(vaultPath);
    }
  }

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async {
    await _ensureLoaded();
    final key = p.normalize(sourcePath);
    return List.unmodifiable(_outgoing[key] ?? const []);
  }

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async {
    await _ensureLoaded();
    return List.unmodifiable(_incoming[entityId] ?? const []);
  }

  @override
  Future<Iterable<String>> incomingEntityIds() async {
    await _ensureLoaded();
    return _incoming.keys;
  }

  @override
  Future<RecordLinkSummary> loadSummary() async {
    await _ensureLoaded();
    return RecordLinkSummary(
      totalLinkCount: _outgoing.values.fold<int>(
        0,
        (total, links) => total + links.length,
      ),
      linkedRecordCount: _outgoing.length,
      connectedEntityCount: _incoming.length,
    );
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final vaultPath = _vault.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      _loaded = true;
      return;
    }

    if (!await _loadFromDisk(vaultPath)) {
      // Interactive paths must not full-scan. Repair calls [rebuildIndex].
      _outgoing = {};
      _incoming = {};
      _loaded = true;
    }
  }

  Future<void> _ensureLoadedForVault(String vaultPath) async {
    if (_loaded) return;
    if (!await _loadFromDisk(vaultPath)) {
      _outgoing = {};
      _incoming = {};
      _loaded = true;
    }
  }

  Future<bool> _loadFromDisk(String vaultPath) async {
    final file = _indexFile(vaultPath);
    if (!await file.exists()) {
      return false;
    }

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if ((json['version'] as num?)?.toInt() != schemaVersion) {
        return false;
      }

      final outgoingRaw = json['outgoing'] as Map<String, dynamic>? ?? {};
      _outgoing = {};
      for (final entry in outgoingRaw.entries) {
        final linksJson = entry.value as List<dynamic>? ?? const [];
        _outgoing[p.normalize(entry.key)] = linksJson
            .map(
              (e) => RecordLink.fromJson(
                p.normalize(entry.key),
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }

      final incomingRaw = json['incoming'] as Map<String, dynamic>? ?? {};
      _incoming = incomingRaw.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? const [])
              .map((e) => p.normalize(e.toString()))
              .toList(),
        ),
      );
      _loaded = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _removeSourceFromIndexes(String sourcePath) {
    var changed = _outgoing.remove(sourcePath) != null;
    final emptyTargets = <String>[];
    for (final entry in _incoming.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((path) => p.normalize(path) == sourcePath);
      if (entry.value.length != before) changed = true;
      if (entry.value.isEmpty) emptyTargets.add(entry.key);
    }
    for (final target in emptyTargets) {
      _incoming.remove(target);
    }
    return changed;
  }

  Future<void> _persist(String vaultPath) async {
    final dir = Directory(p.join(vaultPath, indexDirName));
    await dir.create(recursive: true);
    final file = _indexFile(vaultPath);

    final payload = jsonEncode({
      'version': schemaVersion,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'outgoing': _outgoing.map(
        (path, links) => MapEntry(path, links.map((l) => l.toJson()).toList()),
      ),
      'incoming': _incoming,
    });

    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload);
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  File _indexFile(String vaultPath) =>
      File(p.join(vaultPath, indexDirName, indexFileName));

  Stream<File> _scanRecordFiles(String vaultPath) async* {
    final root = Directory(vaultPath);
    if (!await root.exists()) return;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      if (_shouldSkipPath(entity.path)) continue;
      yield entity;
    }
  }

  bool _shouldSkipPath(String filePath) {
    final parts = p.split(p.normalize(filePath));
    return parts.any(
      (part) =>
          _scanSkipDirNames.contains(part) ||
          (part.startsWith('.') && part != indexDirName),
    );
  }

  String? _incomingTargetId(
    RecordLink link,
    UserCatalogPort? catalog,
    List<AkashaItem> vaultItems,
  ) {
    if (link.kind == RecordLinkKind.explicitId) {
      return link.targetEntityId;
    }
    if (link.kind == RecordLinkKind.titleOnly && catalog != null) {
      final title = link.targetTitle ?? link.raw;
      return RecordLinkNavigator.resolveTitleToEntityId(
        title,
        userCatalog: catalog,
        vaultItems: vaultItems,
      );
    }
    return null;
  }

  List<RecordLink> _dedupeLinks(List<RecordLink> links) {
    final seen = <String>{};
    final result = <RecordLink>[];
    for (final link in links) {
      final key = '${link.kind.name}|${link.indexKey}|${link.displayLabel}';
      if (seen.add(key)) result.add(link);
    }
    return result;
  }

  static bool _isWithinVault(String vaultPath, String absolutePath) {
    final vaultRoot = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    final relative = p.relative(target, from: vaultRoot);
    if (relative == '.') return true;
    if (p.isAbsolute(relative)) return false;
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }
}
