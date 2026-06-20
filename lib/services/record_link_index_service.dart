import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/record_link.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../core/archiving/vault_ledger_event.dart';
import '../models/akasha_item.dart';
import 'event_ledger_service.dart';
import 'file_service.dart';
import 'record_link_navigator.dart';
import 'record_link_parser.dart';

/// `vault/.akasha/link_index.json` — Wave 5.
class RecordLinkIndexService implements RecordLinkPort {
  RecordLinkIndexService({
    AkashaFileService? fileService,
    EventLedgerService? eventLedger,
  })  : _fileService = fileService ?? AkashaFileService(),
        _eventLedger = eventLedger ?? EventLedgerService();

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

  final AkashaFileService _fileService;
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
    final vaultPath = _fileService.vaultPath;
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

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final vaultPath = _fileService.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      _loaded = true;
      return;
    }

    final file = _indexFile(vaultPath);
    if (!await file.exists()) {
      await rebuildIndex();
      return;
    }

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if ((json['version'] as num?)?.toInt() != schemaVersion) {
        await rebuildIndex();
        return;
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
    } catch (_) {
      await rebuildIndex();
    }
  }

  Future<void> _persist(String vaultPath) async {
    final dir = Directory(p.join(vaultPath, indexDirName));
    await dir.create(recursive: true);
    final file = _indexFile(vaultPath);

    final payload = jsonEncode({
      'version': schemaVersion,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'outgoing': _outgoing.map(
        (path, links) => MapEntry(
          path,
          links.map((l) => l.toJson()).toList(),
        ),
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
}
