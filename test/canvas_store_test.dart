import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'package:akasha/core/archiving/canvas_record.dart';
import 'package:akasha/services/canvas_store.dart';

void main() {
  group('CanvasRecord & CanvasLayout Serialization tests', () {
    test('CanvasRecord parses markdown correctly and serializes back', () {
      const rawMarkdown = '''---
schema_version: 3
document_kind: "canvas"
canvas_id: "cv_u_re_zero"
slug: "re-zero-relations"
title: "Re:Zero Relations Map"
layout_ref: "./layout.json"
created_at: "2026-07-07T08:52:00.000Z"
updated_at: "2026-07-07T08:52:00.000Z"
source: "user"
tags:
  - "re-zero"
  - "anime"
---

# Re:Zero Relations

This is a relations map for Re:Zero.
''';

      final record = CanvasRecord.fromMarkdown(rawMarkdown);
      expect(record, isNotNull);
      expect(record!.canvasId, equals('cv_u_re_zero'));
      expect(record.slug, equals('re-zero-relations'));
      expect(record.title, equals('Re:Zero Relations Map'));
      expect(record.layoutRef, equals('./layout.json'));
      expect(record.tags, containsAll(['re-zero', 'anime']));
      expect(record.body, contains('This is a relations map for Re:Zero.'));

      final serialized = record.toMarkdown();
      expect(serialized, contains('document_kind: "canvas"'));
      expect(serialized, contains('canvas_id: "cv_u_re_zero"'));
    });

    test('CanvasLayout parses JSON correctly and outputs the same JSON', () {
      final jsonMap = {
        'layout_schema_version': 1,
        'canvas_id': 'cv_u_re_zero',
        'updated_at': '2026-07-07T08:55:00.000Z',
        'source': 'user',
        'layout_mode': 'freeform',
        'viewport': {'x': 10.0, 'y': -20.0, 'zoom': 1.5},
        'nodes': [
          {
            'node_id': 'n1',
            'kind': 'entity',
            'entity_id': 'pe_u_subaru',
            'x': 150.0,
            'y': -230.0,
            'pinned': true,
            'collapsed': false
          },
          {
            'node_id': 'note_1',
            'kind': 'text',
            'text': 'A sticker note text',
            'x': 320.0,
            'y': 120.0,
            'width': 280.0,
            'height': 120.0,
            'pinned': false,
            'collapsed': false
          }
        ],
        'edges': [
          {
            'edge_id': 'e1',
            'from': 'n1',
            'to': 'note_1',
            'relation': 'about',
            'edge_kind': 'canvas_only',
            'visible': true
          }
        ]
      };

      final layout = CanvasLayout.fromJson(jsonMap);
      expect(layout.canvasId, equals('cv_u_re_zero'));
      expect(layout.viewport.x, equals(10.0));
      expect(layout.viewport.zoom, equals(1.5));
      expect(layout.nodes.length, equals(2));
      expect(layout.nodes[0].nodeId, equals('n1'));
      expect(layout.nodes[0].entityId, equals('pe_u_subaru'));
      expect(layout.nodes[1].text, equals('A sticker note text'));
      expect(layout.edges.length, equals(1));
      expect(layout.edges[0].edgeKind, equals('canvas_only'));

      final outJson = layout.toJson();
      expect(outJson['canvas_id'], equals('cv_u_re_zero'));
      expect(outJson['layout_schema_version'], equals(1));
    });
  });

  group('CanvasStore Operations tests', () {
    late Directory tempVault;

    setUp(() async {
      tempVault = await Directory.systemTemp.createTemp('akasha_vault_test');
    });

    tearDown(() async {
      if (tempVault.existsSync()) {
        await tempVault.delete(recursive: true);
      }
    });

    test('CanvasStore creates, lists, loads, and writes canvases correctly', () async {
      final store = CanvasStore.instance;

      // 1. Check list on empty vault
      final initialList = await store.listCanvases(tempVault.path);
      expect(initialList, isEmpty);

      // 2. Create canvas
      final canvasData = await store.createCanvas(
        vaultPath: tempVault.path,
        title: 'Re:Zero Custom Map',
        slug: 're-zero',
        tags: ['re-zero', 'custom'],
      );

      expect(canvasData.record.title, equals('Re:Zero Custom Map'));
      expect(canvasData.record.canvasId, startsWith('cv_u_'));
      expect(canvasData.layout.canvasId, equals(canvasData.record.canvasId));

      final canvasId = canvasData.record.canvasId;
      final canvasFolder = Directory(p.join(tempVault.path, 'canvases', canvasId));
      expect(canvasFolder.existsSync(), isTrue);
      expect(File(p.join(canvasFolder.path, 'canvas.md')).existsSync(), isTrue);
      expect(File(p.join(canvasFolder.path, 'layout.json')).existsSync(), isTrue);

      // 3. List canvases
      final list = await store.listCanvases(tempVault.path);
      expect(list.length, equals(1));
      expect(list[0].canvasId, equals(canvasId));
      expect(list[0].title, equals('Re:Zero Custom Map'));

      // 4. Load canvas
      final loaded = await store.loadCanvas(tempVault.path, canvasId);
      expect(loaded, isNotNull);
      expect(loaded!.record.title, equals('Re:Zero Custom Map'));
      expect(loaded.layout.layoutMode, equals('freeform'));

      // 5. Save layout debounced and immediately
      loaded.layout.nodes.add(CanvasNode(
        nodeId: 'n_test',
        kind: 'text',
        text: 'Hello',
        x: 50.0,
        y: 60.0,
      ));
      await store.saveLayoutImmediately(tempVault.path, canvasId, loaded.layout);

      final reloaded = await store.loadCanvas(tempVault.path, canvasId);
      expect(reloaded!.layout.nodes.length, equals(2));
      expect(reloaded.layout.nodes[0].nodeId, equals('n_demo_sticker'));
      expect(reloaded.layout.nodes[1].nodeId, equals('n_test'));
      expect(reloaded.layout.nodes[1].x, equals(50.0));
      expect(reloaded.layout.nodes[1].y, equals(60.0));
    });
  });

  group('Canvas CRUD and Edge cleanups', () {
    test('CanvasNode additions, edits, deletes, and updated_at updates round-trip', () {
      final layout = CanvasLayout(
        layoutSchemaVersion: 1,
        canvasId: 'cv_u_test',
        updatedAt: DateTime.now().toUtc(),
        source: 'user',
        layoutMode: 'freeform',
        viewport: CanvasViewport(x: 0, y: 0, zoom: 1.0),
        nodes: [
          CanvasNode(nodeId: 'n1', kind: 'text', text: 'Text A', x: 10.0, y: 20.0),
          CanvasNode(nodeId: 'n2', kind: 'text', text: 'Text B', x: 30.0, y: 40.0),
        ],
        edges: [
          CanvasEdge(edgeId: 'e1', from: 'n1', to: 'n2', edgeKind: 'canvas_only'),
        ],
      );

      // Verify initial states
      expect(layout.nodes.length, equals(2));
      expect(layout.edges.length, equals(1));

      // 1. Edit node text
      layout.nodes[0].text = 'Modified Text A';
      expect(layout.nodes[0].text, equals('Modified Text A'));

      // 2. Delete node 'n2' and check cascade edge cleanup
      final nodeIdToDelete = 'n2';
      layout.nodes.removeWhere((n) => n.nodeId == nodeIdToDelete);
      layout.edges.removeWhere((e) => e.from == nodeIdToDelete || e.to == nodeIdToDelete);

      expect(layout.nodes.length, equals(1));
      expect(layout.nodes[0].nodeId, equals('n1'));
      expect(layout.edges, isEmpty); // Edge 'e1' referencing 'n2' should be removed!
    });
  });
}
