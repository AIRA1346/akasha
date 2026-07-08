import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import '../core/archiving/canvas_record.dart';

class CanvasData {
  CanvasData({required this.record, required this.layout});
  final CanvasRecord record;
  final CanvasLayout layout;
}

class CanvasStore {
  CanvasStore._internal();
  static final CanvasStore instance = CanvasStore._internal();

  final Map<String, Timer> _saveTimers = {};

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

  /// Lists all custom canvas records in the vault's canvases directory.
  Future<List<CanvasRecord>> listCanvases(String vaultPath) async {
    if (vaultPath.isEmpty) return [];
    final canvasesDir = Directory(p.join(vaultPath, 'canvases'));
    if (!canvasesDir.existsSync()) return [];

    final records = <CanvasRecord>[];
    try {
      final entities = await canvasesDir.list(recursive: false).toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final canvasMdFile = File(p.join(entity.path, 'canvas.md'));
          if (canvasMdFile.existsSync()) {
            final content = await canvasMdFile.readAsString();
            final record = CanvasRecord.fromMarkdown(content);
            if (record != null) {
              records.add(record);
            }
          }
        }
      }
    } catch (_) {
      // Ignore directory read/OS permission errors
    }
    return records;
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
      body: '# ${title.trim().isEmpty ? "무제 지식 지도" : title.trim()}\n\n여기에 캔버스에 대한 설명글을 작성하세요.',
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

    // Save synchronously for creation
    final mdFile = File(p.join(canvasDir.path, 'canvas.md'));
    await mdFile.writeAsString(record.toMarkdown(), flush: true);

    final jsonFile = File(p.join(canvasDir.path, 'layout.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await jsonFile.writeAsString(encoder.convert(layout.toJson()), flush: true);

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

      return CanvasData(record: record, layout: layout);
    } catch (_) {
      return null;
    }
  }

  /// Debounces the saving of layout to layout.json.
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

  /// Saves the layout layout.json immediately to the disk.
  Future<void> saveLayoutImmediately(
    String vaultPath,
    String canvasId,
    CanvasLayout layout,
  ) async {
    if (vaultPath.isEmpty || canvasId.isEmpty) return;
    final canvasDir = Directory(p.join(vaultPath, 'canvases', canvasId));
    if (!canvasDir.existsSync()) return;

    final targetPath = p.join(canvasDir.path, 'layout.json');
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
    final content = encoder.convert(updatedLayout.toJson());
    await _writeAtomic(targetPath, content);
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

  Future<void> _writeAtomic(String targetPath, String content) async {
    final file = File(targetPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final tempPath = p.join(
      parent.path,
      '.akasha_canvas_${DateTime.now().microsecondsSinceEpoch}_${p.basename(targetPath)}.tmp',
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
}
