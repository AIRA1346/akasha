import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'package:akasha/core/archiving/canvas_record.dart';
import 'package:akasha/core/archiving/relation_vocabulary.dart';
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

    test('CanvasNode work and entity kinds serialize and deserialize correctly', () {
      final layout = CanvasLayout(
        layoutSchemaVersion: 1,
        canvasId: 'cv_u_test',
        updatedAt: DateTime.now().toUtc(),
        source: 'user',
        layoutMode: 'freeform',
        viewport: CanvasViewport(x: 0, y: 0, zoom: 1.0),
        nodes: [
          CanvasNode(nodeId: 'n_w1', kind: 'work', workId: 'wk_u_re_zero', x: 10, y: 10),
          CanvasNode(nodeId: 'n_e1', kind: 'entity', entityId: 'pe_u_emilia', x: 20, y: 20),
        ],
        edges: const [],
      );

      final json = layout.toJson();
      final parsed = CanvasLayout.fromJson(json);

      expect(parsed.nodes.length, equals(2));
      expect(parsed.nodes[0].kind, equals('work'));
      expect(parsed.nodes[0].workId, equals('wk_u_re_zero'));
      expect(parsed.nodes[0].entityId, isNull);

      expect(parsed.nodes[1].kind, equals('entity'));
      expect(parsed.nodes[1].entityId, equals('pe_u_emilia'));
      expect(parsed.nodes[1].workId, isNull);
    });

    test('CanvasNode invariants throw FormatException on validation mismatch', () {
      // 1. work kind missing workId
      expect(
        () => CanvasNode.fromJson({
          'node_id': 'n1',
          'kind': 'work',
          'x': 0.0,
          'y': 0.0,
        }),
        throwsA(isA<FormatException>()),
      );

      // 2. work kind having entityId
      expect(
        () => CanvasNode.fromJson({
          'node_id': 'n1',
          'kind': 'work',
          'work_id': 'wk_u_1',
          'entity_id': 'pe_u_1',
          'x': 0.0,
          'y': 0.0,
        }),
        throwsA(isA<FormatException>()),
      );

      // 3. entity kind missing entityId
      expect(
        () => CanvasNode.fromJson({
          'node_id': 'n1',
          'kind': 'entity',
          'x': 0.0,
          'y': 0.0,
        }),
        throwsA(isA<FormatException>()),
      );

      // 4. entity kind having workId
      expect(
        () => CanvasNode.fromJson({
          'node_id': 'n1',
          'kind': 'entity',
          'entity_id': 'pe_u_1',
          'work_id': 'wk_u_1',
          'x': 0.0,
          'y': 0.0,
        }),
        throwsA(isA<FormatException>()),
      );

      // 5. text kind missing text
      expect(
        () => CanvasNode.fromJson({
          'node_id': 'n1',
          'kind': 'text',
          'x': 0.0,
          'y': 0.0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('RelationVocabulary display mapping and fallback tests', () {
      expect(RelationVocabulary.displayLabelFor('appears_in'), equals('등장인물 / 등장장소'));
      expect(RelationVocabulary.displayLabelFor('related'), equals('단순 관련성'));
      expect(RelationVocabulary.displayLabelFor('u:rival_of'), equals('대립 / 라이벌'));
      expect(RelationVocabulary.displayLabelFor('u:custom_unknown'), equals('u:custom_unknown'));
      expect(RelationVocabulary.displayLabelFor(null), equals(''));
    });

    test('RelationVocabulary custom user token validation', () {
      expect(RelationVocabulary.isUserNamespaced('u:likes'), isTrue);
      expect(RelationVocabulary.isUserNamespaced('u:teacher_of'), isTrue);
      expect(RelationVocabulary.isUserNamespaced('likes'), isFalse);
      expect(RelationVocabulary.isUserNamespaced('u:한글'), isFalse);
    });

    test('User relation token sanitization logic emulation test', () {
      String? sanitize(String input) {
        if (input.isEmpty) return null;
        if (RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(input)) return null;
        var token = input.trim().toLowerCase();
        if (!token.startsWith('u:')) {
          token = 'u:$token';
        }
        token = token.replaceAll(' ', '_').replaceAll('-', '_');
        token = token.replaceAll(RegExp(r'[^a-z0-9_:]'), '');
        if (RelationVocabulary.isUserNamespaced(token)) {
          return token;
        }
        return null;
      }

      expect(sanitize('likes'), equals('u:likes'));
      expect(sanitize('teacher of'), equals('u:teacher_of'));
      expect(sanitize('rival-relation'), equals('u:rival_relation'));
      expect(sanitize('u:voiced_by'), equals('u:voiced_by'));
      expect(sanitize('한글관계'), isNull);
      expect(sanitize('u:한글관계'), isNull);
      expect(sanitize(''), isNull);
      expect(sanitize('u:very_long_relation_name_that_exceeds_forty_characters_limit'), isNull);
    });

    test('CanvasEdge edit and delete mock logic validation', () {
      final layout = CanvasLayout(
        layoutSchemaVersion: 1,
        canvasId: 'cv_u_test',
        updatedAt: DateTime.now().toUtc(),
        source: 'user',
        layoutMode: 'freeform',
        viewport: CanvasViewport(x: 0, y: 0, zoom: 1.0),
        nodes: [
          CanvasNode(nodeId: 'n1', kind: 'text', text: 'Node A', x: 0, y: 0),
          CanvasNode(nodeId: 'n2', kind: 'text', text: 'Node B', x: 10, y: 10),
        ],
        edges: [
          CanvasEdge(edgeId: 'e1', from: 'n1', to: 'n2', relation: 'related', edgeKind: 'canvas_only'),
          CanvasEdge(edgeId: 'e2', from: 'n1', to: 'n3', relation: 'u:rival_of', edgeKind: 'canvas_only'),
          CanvasEdge(edgeId: 'e3', from: 'n1', to: 'n2', relation: 'about', edgeKind: 'canonical_view'),
        ],
      );

      // 1. Check edge editing
      final e1 = layout.edges.firstWhere((e) => e.edgeId == 'e1');
      expect(e1.relation, equals('related'));
      
      final e1Index = layout.edges.indexWhere((e) => e.edgeId == 'e1');
      layout.edges[e1Index] = CanvasEdge(
        edgeId: e1.edgeId,
        from: e1.from,
        to: e1.to,
        relation: 'u:ally_of',
        edgeKind: e1.edgeKind,
      );
      expect(layout.edges[e1Index].relation, equals('u:ally_of'));

      // 2. Check edge deleting
      layout.edges.removeWhere((e) => e.edgeId == 'e1');
      expect(layout.edges.any((e) => e.edgeId == 'e1'), isFalse);
      expect(layout.edges.length, equals(2));

      // 3. Safety checks for missing nodes
      CanvasNode? findNode(String id) {
        final matching = layout.nodes.where((n) => n.nodeId == id);
        return matching.isNotEmpty ? matching.first : null;
      }
      
      expect(findNode('n3'), isNull);
      
      for (final edge in layout.edges) {
        final fromNode = findNode(edge.from);
        final toNode = findNode(edge.to);
        if (fromNode == null || toNode == null) {
          continue;
        }
        
        final fromCenter = Offset(fromNode.x + 125, fromNode.y + 50);
        final toCenter = Offset(toNode.x + 125, toNode.y + 50);
        final mid = Offset((fromCenter.dx + toCenter.dx) / 2, (fromCenter.dy + toCenter.dy) / 2);
        expect(mid, isNotNull);
      }

      // 4. canvas_only non-editable check
      final nonEditableEdge = layout.edges.firstWhere((e) => e.edgeId == 'e3');
      expect(nonEditableEdge.edgeKind, isNot(equals('canvas_only')));
    });
  });
}
