import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/record_link.dart';
import '../core/ports/record_link_port.dart';
import 'file_service.dart';
import 'record_link_parser.dart';

/// `vault/.akasha/link_index.json` — Wave 5.
class RecordLinkIndexService implements RecordLinkPort {
  RecordLinkIndexService({AkashaFileService? fileService})
      : _fileService = fileService ?? AkashaFileService();

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

  Map<String, List<RecordLink>> _outgoing = {};
  Map<String, List<String>> _incoming = {};
  bool _loaded = false;

  @override
  Future<void> rebuildIndex({String? changedPath}) async {
    final vaultPath = _fileService.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      _outgoing = {};
      _incoming = {};
      _loaded = true;
      return;
    }

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
          if (link.kind != RecordLinkKind.explicitId ||
              link.targetEntityId == null) {
            continue;
          }
          incoming
              .putIfAbsent(link.targetEntityId!, () => [])
              .add(sourcePath);
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
