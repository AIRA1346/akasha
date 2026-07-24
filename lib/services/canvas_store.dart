import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import '../core/archiving/canvas_record.dart';
import 'vault_recovery_write_service.dart';
import 'vault_trash_service.dart';

class CanvasData {
  CanvasData({required this.record, required this.layout});
  final CanvasRecord record;
  final CanvasLayout layout;
}

enum IncompleteCanvasStatus {
  missingMetadata,
  missingLayout,
  invalidMetadata,
  invalidLayout,
  idMismatch,
  layoutRefMismatch,
}

class IncompleteCanvasRecord {
  const IncompleteCanvasRecord({
    required this.canvasDirectory,
    required this.inferredCanvasId,
    required this.status,
    required this.existingFiles,
    required this.missingFiles,
    required this.diagnosticMessage,
  });

  final String canvasDirectory;
  final String inferredCanvasId;
  final IncompleteCanvasStatus status;
  final List<String> existingFiles;
  final List<String> missingFiles;
  final String diagnosticMessage;
}

class CanvasDiscoveryResult {
  const CanvasDiscoveryResult({
    required this.complete,
    required this.incomplete,
  });

  final List<CanvasRecord> complete;
  final List<IncompleteCanvasRecord> incomplete;
}

class CanvasStore {
  CanvasStore._internal();
  static final CanvasStore instance = CanvasStore._internal();

  final Map<String, Timer> _saveTimers = {};

  /// In-memory layout sessions keyed by canvasId — survives widget dispose.
  final Map<String, _CanvasLayoutSession> _layoutSessions = {};
  final Map<String, _CanvasRevisionSnapshot> _openedRevisions = {};

  /// Generates a canvas stable ID matching "cv_u_{8-char}" format.
  static String generateCanvasId() {
    final rand = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer('cv_u_');
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Discovers complete and incomplete canvas records in the vault's canvases directory.
  Future<CanvasDiscoveryResult> discoverCanvases(String vaultPath) async {
    if (vaultPath.isEmpty) {
      return const CanvasDiscoveryResult(complete: [], incomplete: []);
    }
    final canvasesDir = Directory(p.join(vaultPath, 'canvases'));
    if (!canvasesDir.existsSync()) {
      return const CanvasDiscoveryResult(complete: [], incomplete: []);
    }

    final complete = <CanvasRecord>[];
    final incomplete = <IncompleteCanvasRecord>[];

    try {
      final entities = await canvasesDir.list(recursive: false).toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final inferredId = p.basename(entity.path);
          final mdFile = File(p.join(entity.path, 'canvas.md'));
          final jsonFile = File(p.join(entity.path, 'layout.json'));

          final hasMd = mdFile.existsSync();
          final hasJson = jsonFile.existsSync();

          final existingFiles = <String>[];
          final missingFiles = <String>[];
          if (hasMd) {
            existingFiles.add('canvas.md');
          } else {
            missingFiles.add('canvas.md');
          }
          if (hasJson) {
            existingFiles.add('layout.json');
          } else {
            missingFiles.add('layout.json');
          }

          if (!hasMd) {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.missingMetadata,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage: 'canvas.md metadata file is missing.',
              ),
            );
            continue;
          }

          if (!hasJson) {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.missingLayout,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage: 'layout.json layout file is missing.',
              ),
            );
            continue;
          }

          String? mdContent;
          CanvasRecord? record;
          try {
            mdContent = await mdFile.readAsString();
            record = CanvasRecord.fromMarkdown(mdContent);
          } catch (_) {}

          if (record == null) {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.invalidMetadata,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage:
                    'canvas.md content is invalid or missing required frontmatter.',
              ),
            );
            continue;
          }

          Map<String, dynamic>? layoutJson;
          try {
            final jsonContent = await jsonFile.readAsString();
            layoutJson = jsonDecode(jsonContent) as Map<String, dynamic>?;
          } catch (_) {}

          if (layoutJson == null) {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.invalidLayout,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage: 'layout.json is not valid JSON.',
              ),
            );
            continue;
          }

          final jsonCanvasId = layoutJson['canvas_id']?.toString() ?? '';
          if (record.canvasId != inferredId || jsonCanvasId != inferredId) {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.idMismatch,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage:
                    'Canvas ID mismatch between folder, canvas.md ($record.canvasId), or layout.json ($jsonCanvasId).',
              ),
            );
            continue;
          }

          if (record.layoutRef != './layout.json') {
            incomplete.add(
              IncompleteCanvasRecord(
                canvasDirectory: entity.path,
                inferredCanvasId: inferredId,
                status: IncompleteCanvasStatus.layoutRefMismatch,
                existingFiles: existingFiles,
                missingFiles: missingFiles,
                diagnosticMessage:
                    'layout_ref in canvas.md is ${record.layoutRef}, expected ./layout.json.',
              ),
            );
            continue;
          }

          complete.add(record);
        }
      }
    } catch (_) {
      // Ignore directory read/OS permission errors
    }

    return CanvasDiscoveryResult(complete: complete, incomplete: incomplete);
  }

  /// Backward compatible wrapper for discoverCanvases.
  Future<List<CanvasRecord>> listCanvases(String vaultPath) async {
    final result = await discoverCanvases(vaultPath);
    return result.complete;
  }

  /// Trashes an entire canvas directory (canvas.md + layout.json) as one unit.
  Future<CanvasTrashResult> deleteCanvas(
    String vaultPath,
    String canvasId, {
    String? reason,
  }) async {
    cancelPendingSave(canvasId);
    unregisterLayoutSession(canvasId);
    return const VaultTrashService().moveCanvasToTrash(
      vaultPath: vaultPath,
      canvasId: canvasId,
      reason: reason,
    );
  }

  /// Creates a new Canvas in the vault.
  Future<CanvasData> createCanvas({
    required String vaultPath,
    required String title,
    required String slug,
    List<String>? tags,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }

    final canvasId = generateCanvasId();
    final canvasDir = Directory(p.join(vaultPath, 'canvases', canvasId));
    await canvasDir.create(recursive: true);

    final now = DateTime.now().toUtc();
    final record = CanvasRecord(
      canvasId: canvasId,
      slug: slug.trim().isEmpty ? 'untitled' : slug.trim(),
      title: title.trim().isEmpty ? '무제 지식 지도' : title.trim(),
      layoutRef: './layout.json',
      createdAt: now,
      updatedAt: now,
      source: 'user',
      tags: tags ?? [],
      body:
          '# ${title.trim().isEmpty ? "무제 지식 지도" : title.trim()}\n\n여기에 캔버스에 대한 설명글을 작성하세요.',
    );

    final layout = CanvasLayout(
      layoutSchemaVersion: 1,
      canvasId: canvasId,
      updatedAt: now,
      source: 'user',
      layoutMode: 'freeform',
      viewport: CanvasViewport(x: 0.0, y: 0.0, zoom: 1.0),
      nodes: [
        CanvasNode(
          nodeId: 'n_demo_sticker',
          kind: 'text',
          text: '드래그하여 이 스티커 메모를 움직이고 화면을 재진입해보세요.',
          x: 150.0,
          y: 150.0,
          width: 250.0,
          height: 100.0,
        ),
      ],
      edges: [],
    );

    // Canvas discovery is only possible after this recoverable two-file
    // transaction has a complete, verified set.
    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    final jsonFile = File(p.join(canvasDir.path, 'layout.json'));
    const encoder = JsonEncoder.withIndent('  ');
    final writer = VaultRecoveryWriteService();
    final batch = await writer.writeTextBatch(
      vaultPath: vaultPath,
      reason: 'canvas_create',
      writes: [
        VaultTextWriteRequest(
          targetPath: mdFile.path,
          content: record.toMarkdown(),
          expectedRevision: const VaultFileRevision.missing(),
        ),
        VaultTextWriteRequest(
          targetPath: jsonFile.path,
          content: encoder.convert(layout.toJson()),
          expectedRevision: const VaultFileRevision.missing(),
        ),
      ],
    );
    _openedRevisions[_revisionKey(
      vaultPath,
      canvasId,
    )] = _CanvasRevisionSnapshot(
      record: batch.writes[0].newRevision,
      layout: batch.writes[1].newRevision,
    );

    return CanvasData(record: record, layout: layout);
  }

  /// Loads a CanvasData session.
  Future<CanvasData?> loadCanvas(String vaultPath, String canvasId) async {
    if (vaultPath.isEmpty || canvasId.isEmpty) return null;
    final canvasDir = Directory(p.join(vaultPath, 'canvases', canvasId));
    if (!canvasDir.existsSync()) return null;

    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    final jsonFile = File(p.join(canvasDir.path, 'layout.json'));
    if (!mdFile.existsSync() || !jsonFile.existsSync()) return null;

    try {
      final mdContent = await mdFile.readAsString();
      final record = CanvasRecord.fromMarkdown(mdContent);
      if (record == null) return null;

      final jsonContent = await jsonFile.readAsString();
      final layoutJson = jsonDecode(jsonContent) as Map<String, dynamic>;
      final layout = CanvasLayout.fromJson(layoutJson);
      _openedRevisions[_revisionKey(
        vaultPath,
        canvasId,
      )] = _CanvasRevisionSnapshot(
        record: VaultFileRevision.fromText(
          mdContent,
          modifiedAtUtc: (await mdFile.lastModified()).toUtc(),
        ),
        layout: VaultFileRevision.fromText(
          jsonContent,
          modifiedAtUtc: (await jsonFile.lastModified()).toUtc(),
        ),
      );

      return CanvasData(record: record, layout: layout);
    } catch (_) {
      return null;
    }
  }

  /// Registers the latest in-memory layout for [canvasId] (editor or dispose path).
  void registerLayoutSession(
    String vaultPath,
    String canvasId,
    CanvasLayout layout,
  ) {
    if (vaultPath.isEmpty || canvasId.isEmpty) return;
    _layoutSessions[canvasId] = _CanvasLayoutSession(
      vaultPath: vaultPath,
      layout: layout,
    );
  }

  void unregisterLayoutSession(String canvasId) {
    _layoutSessions.remove(canvasId);
  }

  void unregisterLayoutSessions(Iterable<String> canvasIds) {
    for (final id in canvasIds) {
      unregisterLayoutSession(id);
    }
  }

  /// Persists a registered layout to disk (works even when the editor widget is disposed).
  Future<void> persistRegisteredLayout(String canvasId) async {
    final session = _layoutSessions[canvasId];
    if (session == null) return;
    await flushPendingSave(
      session.vaultPath,
      canvasId,
      session.layout,
      force: true,
    );
  }

  Future<void> persistRegisteredLayouts(Iterable<String> canvasIds) async {
    for (final id in canvasIds) {
      await persistRegisteredLayout(id);
    }
  }

  /// Debounces a recoverable Canvas record + layout save.
  void saveLayoutDebounced(
    String vaultPath,
    String canvasId,
    CanvasLayout layout, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    if (vaultPath.isEmpty || canvasId.isEmpty) return;

    _saveTimers[canvasId]?.cancel();
    _saveTimers[canvasId] = Timer(duration, () async {
      _saveTimers.remove(canvasId);
      await saveLayoutImmediately(vaultPath, canvasId, layout);
    });
  }

  /// Saves Canvas metadata and layout as one recoverable two-file revision.
  Future<void> saveLayoutImmediately(
    String vaultPath,
    String canvasId,
    CanvasLayout layout,
  ) async {
    if (vaultPath.isEmpty || canvasId.isEmpty) return;
    final canvasDir = Directory(p.join(vaultPath, 'canvases', canvasId));
    if (!canvasDir.existsSync()) return;

    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    final layoutFile = File(p.join(canvasDir.path, 'layout.json'));
    if (!await mdFile.exists() || !await layoutFile.exists()) return;
    final mdContent = await mdFile.readAsString();
    final existingLayoutContent = await layoutFile.readAsString();
    final key = _revisionKey(vaultPath, canvasId);
    final expected =
        _openedRevisions[key] ??
        _CanvasRevisionSnapshot(
          record: VaultFileRevision.fromText(
            mdContent,
            modifiedAtUtc: (await mdFile.lastModified()).toUtc(),
          ),
          layout: VaultFileRevision.fromText(
            existingLayoutContent,
            modifiedAtUtc: (await layoutFile.lastModified()).toUtc(),
          ),
        );
    final updatedLayout = CanvasLayout(
      layoutSchemaVersion: layout.layoutSchemaVersion,
      canvasId: layout.canvasId,
      updatedAt: DateTime.now().toUtc(),
      source: layout.source,
      layoutMode: layout.layoutMode,
      viewport: layout.viewport,
      nodes: layout.nodes,
      edges: layout.edges,
    );

    const encoder = JsonEncoder.withIndent('  ');
    final layoutContent = encoder.convert(updatedLayout.toJson());
    final batch = await VaultRecoveryWriteService().writeTextBatch(
      vaultPath: vaultPath,
      reason: 'canvas_layout_save',
      writes: [
        // Carry the source form exactly as opened. This makes unknown Canvas
        // frontmatter byte-preserving while layout changes are committed.
        VaultTextWriteRequest(
          targetPath: mdFile.path,
          content: mdContent,
          expectedRevision: expected.record,
        ),
        VaultTextWriteRequest(
          targetPath: layoutFile.path,
          content: layoutContent,
          expectedRevision: expected.layout,
        ),
      ],
    );
    _openedRevisions[key] = _CanvasRevisionSnapshot(
      record: batch.writes[0].newRevision,
      layout: batch.writes[1].newRevision,
    );
  }

  /// Discards any pending debounce timers for a canvas.
  void cancelPendingSave(String canvasId) {
    _saveTimers[canvasId]?.cancel();
    _saveTimers.remove(canvasId);
  }

  /// Flushes pending debounce timers and optionally persists [layout] immediately.
  ///
  /// When [force] is true, always writes [layout] to disk after cancelling any
  /// pending debounce — used before Canvas tab teardown so viewport is durable.
  Future<void> flushPendingSave(
    String vaultPath,
    String canvasId,
    CanvasLayout layout, {
    bool force = false,
  }) async {
    final hadPending = _saveTimers.containsKey(canvasId);
    _saveTimers[canvasId]?.cancel();
    _saveTimers.remove(canvasId);
    if (force || hadPending) {
      await saveLayoutImmediately(vaultPath, canvasId, layout);
    }
  }

  static String _revisionKey(String vaultPath, String canvasId) =>
      '${p.normalize(p.absolute(vaultPath))}::$canvasId';
}

class _CanvasLayoutSession {
  const _CanvasLayoutSession({required this.vaultPath, required this.layout});

  final String vaultPath;
  final CanvasLayout layout;
}

class _CanvasRevisionSnapshot {
  const _CanvasRevisionSnapshot({required this.record, required this.layout});

  final VaultFileRevision record;
  final VaultFileRevision layout;
}
