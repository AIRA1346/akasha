import 'dart:io';

import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/screens/home/views/knowledge_graph_view.dart';
import 'package:akasha/services/canvas_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('KnowledgeGraphView Incomplete Canvas UI Tests', () {
    late Directory tempVault;

    setUp(() async {
      tempVault = await Directory.systemTemp.createTemp('kg_incomplete_test');
    });

    tearDown(() async {
      if (tempVault.existsSync()) {
        await tempVault.delete(recursive: true);
      }
    });

    Widget buildView() {
      return MaterialApp(
        home: Scaffold(
          body: KnowledgeGraphView(
            vaultPath: tempVault.path,
            vaultItems: const [],
            userCatalog: const _MockUserCatalogPort(),
            linkIndex: const _MockRecordLinkPort(),
            onOpenCanvas: (_) {},
            onOpenEntity: (_) {},
            onOpenWork: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders empty state when complete 0 and incomplete 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildView());
      await tester.pumpAndSettle();

      expect(find.text('아직 지식 지도가 없습니다.'), findsOneWidget);
    });

    testWidgets(
      'renders incomplete alert state when complete 0 and incomplete >= 1',
      (tester) async {
        // Create incomplete canvas (missing canvas.md)
        final incDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_broken'),
        );
        await incDir.create(recursive: true);
        await File(
          p.join(incDir.path, 'layout.json'),
        ).writeAsString('{"canvas_id": "cv_u_broken"}');

        await tester.pumpWidget(buildView());
        await tester.pumpAndSettle();

        expect(find.textContaining('불완전한 지식 지도를 발견했습니다'), findsOneWidget);
        expect(find.textContaining('cv_u_broken'), findsOneWidget);
      },
    );

    testWidgets(
      'renders complete list and non-blocking warning when complete >= 1 and incomplete >= 1',
      (tester) async {
        // Create complete canvas
        await CanvasStore.instance.createCanvas(
          vaultPath: tempVault.path,
          title: 'Valid Canvas Title',
          slug: 'valid-canvas',
        );

        // Create incomplete canvas
        final incDir = Directory(
          p.join(tempVault.path, 'canvases', 'cv_u_broken2'),
        );
        await incDir.create(recursive: true);
        await File(
          p.join(incDir.path, 'layout.json'),
        ).writeAsString('{"canvas_id": "cv_u_broken2"}');

        await tester.pumpWidget(buildView());
        await tester.pumpAndSettle();

        expect(find.text('Valid Canvas Title'), findsOneWidget);
        expect(find.textContaining('불완전한 지식 지도 1개가 감지되었습니다'), findsOneWidget);
      },
    );
  });
}

class _MockUserCatalogPort implements UserCatalogPort {
  const _MockUserCatalogPort();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRecordLinkPort implements RecordLinkPort {
  const _MockRecordLinkPort();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
