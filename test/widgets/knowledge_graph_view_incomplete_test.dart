import 'dart:io';

import 'package:akasha/core/archiving/canvas_record.dart';
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
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 1));
    if (tester.any(finder)) return;
  }
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
                canvasDiscoverer: (_) async =>
                    const CanvasDiscoveryResult(complete: [], incomplete: []),
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
        final incomplete = IncompleteCanvasRecord(
          inferredCanvasId: 'cv_u_broken',
          canvasDirectory: p.join(tempVault.path, 'canvases', 'cv_u_broken'),
          status: IncompleteCanvasStatus.missingMetadata,
          existingFiles: const ['layout.json'],
          missingFiles: const ['canvas.md'],
          diagnosticMessage: 'missing canvas.md',
        );

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
                canvasDiscoverer: (_) async => CanvasDiscoveryResult(
                  complete: const [],
                  incomplete: [incomplete],
                ),
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
        final valid = CanvasRecord(
          canvasId: 'cv_u_valid01',
          title: 'Valid Canvas',
          slug: 'valid',
          layoutRef: './layout.json',
          createdAt: DateTime.utc(2026, 7, 1),
          updatedAt: DateTime.utc(2026, 7, 1),
          source: 'user',
          tags: const [],
        );
        final incomplete = IncompleteCanvasRecord(
          inferredCanvasId: 'cv_u_broken2',
          canvasDirectory: p.join(tempVault.path, 'canvases', 'cv_u_broken2'),
          status: IncompleteCanvasStatus.missingMetadata,
          existingFiles: const ['layout.json'],
          missingFiles: const ['canvas.md'],
          diagnosticMessage: 'missing canvas.md',
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
                canvasDiscoverer: (_) async => CanvasDiscoveryResult(
                  complete: [valid],
                  incomplete: [incomplete],
                ),
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

    testWidgets(
      'directory listing failure shows error state, not empty, and retry recovers',
      (tester) async {
        var calls = 0;
        final valid = CanvasRecord(
          canvasId: 'cv_u_retry001',
          title: 'Recovered Canvas',
          slug: 'recovered',
          layoutRef: './layout.json',
          createdAt: DateTime.utc(2026, 7, 1),
          updatedAt: DateTime.utc(2026, 7, 1),
          source: 'user',
          tags: const [],
        );

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
                canvasDiscoverer: (_) async {
                  calls++;
                  if (calls == 1) {
                    throw const FileSystemException(
                      'Failed to list canvases directory',
                    );
                  }
                  return CanvasDiscoveryResult(
                    complete: [valid],
                    incomplete: const [],
                  );
                },
              ),
            ),
          ),
        );

        await pumpUntilFound(tester, find.text('지식 지도 목록을 읽지 못했습니다'));
        expect(find.text('아직 지식 지도가 없습니다.'), findsNothing);
        expect(
          find.byKey(const ValueKey('graph-canvas-discovery-retry')),
          findsOneWidget,
        );
        expect(find.textContaining('FileSystemException'), findsOneWidget);
        expect(find.textContaining(tempVault.path), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey('graph-canvas-discovery-retry')),
        );
        await pumpUntilFound(tester, find.text('Recovered Canvas'));
        expect(find.text('지식 지도 목록을 읽지 못했습니다'), findsNothing);
        expect(calls, 2);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}
