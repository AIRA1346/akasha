import 'dart:io';

import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/screens/home/views/knowledge_graph_view.dart';
import 'package:akasha/services/canvas_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class MockUserCatalog extends Fake implements UserCatalogPort {}

class MockRecordLinkIndex extends Fake implements RecordLinkPort {}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 1));
    if (tester.any(finder)) return;
  }
  // ignore: avoid_print
  print(
    'DEBUG widgets after miss:\n${tester.allWidgets.map((w) => w.runtimeType).take(40).join(', ')}',
  );
  fail('Finder not found after $maxPumps pumps: $finder');
}

void main() {
  group('KnowledgeGraphView Incomplete Canvas UI Tests', () {
    late Directory tempVault;

    setUp(() async {
      tempVault = await Directory.systemTemp.createTemp(
        'kg_view_incomplete_test',
      );
    });

    tearDown(() async {
      if (tempVault.existsSync()) {
        await tempVault.delete(recursive: true);
      }
    });

    test(
      'discoverCanvasesSync reports missingMetadata for layout-only canvas',
      () {
        final brokenDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_broken'),
        );
        brokenDir.createSync(recursive: true);
        File(p.join(brokenDir.path, 'layout.json')).writeAsStringSync(
          '{"canvas_id": "cv_u_broken", "nodes": [], "edges": []}',
        );

        final result = CanvasStore.instance.discoverCanvasesSync(
          tempVault.path,
        );
        expect(result.complete, isEmpty);
        expect(result.incomplete, hasLength(1));
        expect(
          result.incomplete.single.status,
          IncompleteCanvasStatus.missingMetadata,
        );
      },
    );

    testWidgets(
      'renders empty state when complete 0 and incomplete 0',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KnowledgeGraphView(
                vaultItems: const <AkashaItem>[],
                userCatalog: MockUserCatalog(),
                linkIndex: MockRecordLinkIndex(),
                onOpenWork: (_) {},
                onOpenEntity: (_) {},
                vaultPath: tempVault.path,
                onOpenCanvas: (_) {},
              ),
            ),
          ),
        );

        await pumpUntilFound(tester, find.text('아직 지식 지도가 없습니다.'));
        expect(find.text('새 지식 지도 만들기'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'renders incomplete alert state when complete 0 and incomplete >= 1',
      (tester) async {
        final brokenDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_broken'),
        );
        brokenDir.createSync(recursive: true);
        File(p.join(brokenDir.path, 'layout.json')).writeAsStringSync(
          '{"canvas_id": "cv_u_broken", "nodes": [], "edges": []}',
        );

        final discovery = CanvasStore.instance.discoverCanvasesSync(
          tempVault.path,
        );
        expect(discovery.incomplete, isNotEmpty);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KnowledgeGraphView(
                vaultItems: const <AkashaItem>[],
                userCatalog: MockUserCatalog(),
                linkIndex: MockRecordLinkIndex(),
                onOpenWork: (_) {},
                onOpenEntity: (_) {},
                vaultPath: tempVault.path,
                onOpenCanvas: (_) {},
              ),
            ),
          ),
        );

        await pumpUntilFound(tester, find.text('불완전한 지식 지도를 발견했습니다'));

        expect(find.textContaining('cv_u_broken'), findsOneWidget);
        expect(find.textContaining('누락 파일: canvas.md'), findsOneWidget);
        expect(find.textContaining('존재 파일: layout.json'), findsOneWidget);
        expect(find.textContaining('missingMetadata'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'renders complete list and non-blocking warning when complete >= 1 and incomplete >= 1',
      (tester) async {
        final validDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_valid'),
        );
        validDir.createSync(recursive: true);
        File(p.join(validDir.path, 'canvas.md')).writeAsStringSync(
          '---\n'
          'document_kind: canvas\n'
          'canvas_id: cv_u_valid\n'
          'title: Valid Canvas\n'
          'layout_ref: ./layout.json\n'
          '---\n',
        );
        File(p.join(validDir.path, 'layout.json')).writeAsStringSync(
          '{"canvas_id": "cv_u_valid", "nodes": [], "edges": []}',
        );

        final brokenDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_broken2'),
        );
        brokenDir.createSync(recursive: true);
        File(p.join(brokenDir.path, 'layout.json')).writeAsStringSync(
          '{"canvas_id": "cv_u_broken2", "nodes": [], "edges": []}',
        );

        var openedTitle = '';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KnowledgeGraphView(
                vaultItems: const <AkashaItem>[],
                userCatalog: MockUserCatalog(),
                linkIndex: MockRecordLinkIndex(),
                onOpenWork: (_) {},
                onOpenEntity: (_) {},
                vaultPath: tempVault.path,
                onOpenCanvas: (canvas) {
                  openedTitle = canvas.title;
                },
              ),
            ),
          ),
        );

        await pumpUntilFound(tester, find.text('Valid Canvas'));

        expect(find.textContaining('불완전한 지식 지도 1개가 감지되었습니다.'), findsOneWidget);
        expect(find.text('Valid Canvas'), findsOneWidget);

        await tester.tap(find.text('Valid Canvas'));
        await tester.pump();
        expect(openedTitle, equals('Valid Canvas'));
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}
