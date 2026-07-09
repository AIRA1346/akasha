import 'dart:convert';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/collectible_collection.dart';
import 'package:akasha/models/collectible_collection_filter.dart';
import 'package:akasha/models/collectible_kind.dart';
import 'package:akasha/models/collectible_ref.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/dialogs/collectible_collection_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DialogHarness extends StatefulWidget {
  const _DialogHarness({
    required this.catalogEntities,
    required this.vaultItems,
    required this.onClosed,
  });

  final List<UserCatalogEntity> catalogEntities;
  final List<AkashaItem> vaultItems;
  final ValueChanged<CollectibleCollection?> onClosed;

  @override
  State<_DialogHarness> createState() => _DialogHarnessState();
}

class _DialogHarnessState extends State<_DialogHarness> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await showCollectibleCollectionEditDialog(
              context,
              catalogEntities: widget.catalogEntities,
              vaultItems: widget.vaultItems,
            );
            widget.onClosed(result);
          },
          child: const Text('열기'),
        ),
      ),
    );
  }
}

List<UserCatalogEntity> _sampleWorkCatalog() => [
      UserCatalogEntity(
        entityId: 'wk_u_rezero01',
        entityType: UserCatalogEntity.entityTypeWork,
        subtype: MediaCategory.book,
        title: 'Re:Zero',
        addedAt: DateTime(2024),
      ),
    ];

Future<void> _openNewDialog(
  WidgetTester tester, {
  List<UserCatalogEntity> catalogEntities = const [],
  List<AkashaItem> vaultItems = const [],
  required void Function(CollectibleCollection?) onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _DialogHarness(
        catalogEntities: catalogEntities,
        vaultItems: vaultItems,
        onClosed: onClosed,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  expect(find.text('컬렉션 추가'), findsOneWidget);
}

Future<void> _enterTitle(WidgetTester tester, String title) async {
  final titleField = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.labelText == '컬렉션 이름',
  );
  await tester.enterText(titleField, title);
  await tester.pump();
}

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.text('추가'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _absorbRenderOverflow(WidgetTester tester) {
  while (true) {
    final error = tester.takeException();
    if (error == null) return;
    expect(error.toString(), contains('overflowed'));
  }
}

Future<void> _selectRelatedWork(WidgetTester tester, String workTitle) async {
  final dropdown = find.byWidgetPredicate(
    (w) => w is DropdownButtonFormField<String?>,
  );
  await tester.scrollUntilVisible(
    dropdown,
    48,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(workTitle).last);
  await tester.pumpAndSettle();
  _absorbRenderOverflow(tester);
}

Future<void> _selectCuratedMode(WidgetTester tester) async {
  final dropdown = find.byWidgetPredicate(
    (w) => w is DropdownButtonFormField<CollectibleCollectionMode>,
  );
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('큐레이션 (직접 선택)').last);
  await tester.pumpAndSettle();
}

Future<void> _toggleCuratedWork(
  WidgetTester tester,
  String workTitle,
) async {
  final tile = find.byWidgetPredicate(
    (w) =>
        w is CheckboxListTile &&
        w.title is Text &&
        (w.title as Text).data == workTitle,
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1280, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });
  group('CollectibleCollectionFilter', () {
    test('relatedWorkId json round-trip', () {
      const filter = CollectibleCollectionFilter(
        kinds: [CollectibleKind.person],
        tagsAll: ['영웅'],
        relatedWorkId: 'wk_u_rezero01',
      );

      final decoded = CollectibleCollectionFilter.fromJson(filter.toJson());

      expect(decoded.kinds?.map((k) => k.name), ['person']);
      expect(decoded.tagsAll, ['영웅']);
      expect(decoded.relatedWorkId, 'wk_u_rezero01');
    });

    test('legacy json without relatedWorkId keeps null', () {
      final decoded = CollectibleCollectionFilter.fromJson(
        jsonDecode('{"tagsAll":["영웅"],"kinds":["person"]}') as Map<String, dynamic>,
      );

      expect(decoded.tagsAll, ['영웅']);
      expect(decoded.relatedWorkId, isNull);
    });

    test('relatedWorkOnly json round-trip', () {
      const filter = CollectibleCollectionFilter(
        kinds: [CollectibleKind.person],
        relatedWorkId: 'wk_u_rezero01',
      );

      final json = filter.toJson();
      expect(json.containsKey('tagsAll'), isFalse);
      expect(json['relatedWorkId'], 'wk_u_rezero01');

      final decoded = CollectibleCollectionFilter.fromJson(json);
      expect(decoded.tagsAll, isNull);
      expect(decoded.relatedWorkId, 'wk_u_rezero01');
    });

    group('hasFilterPredicate', () {
      test('tagsOnly validation passes', () {
        expect(
          CollectibleCollectionFilter.hasFilterPredicate(
            tagsAll: ['영웅'],
          ),
          isTrue,
        );
      });

      test('relatedWorkOnly validation passes', () {
        expect(
          CollectibleCollectionFilter.hasFilterPredicate(
            relatedWorkId: 'wk_u_rezero01',
          ),
          isTrue,
        );
      });

      test('tags and relatedWork validation passes', () {
        expect(
          CollectibleCollectionFilter.hasFilterPredicate(
            tagsAll: ['영웅'],
            relatedWorkId: 'wk_u_rezero01',
          ),
          isTrue,
        );
      });

      test('empty filter validation fails', () {
        expect(
          CollectibleCollectionFilter.hasFilterPredicate(
            tagsAll: const [],
            relatedWorkId: null,
          ),
          isFalse,
        );
        expect(
          CollectibleCollectionFilter.hasFilterPredicate(
            tagsAll: const [],
            relatedWorkId: '   ',
          ),
          isFalse,
        );
      });
    });
  });

  group('buildCollectibleWorkPickerOptions', () {
    test('merges catalog works and vault items deduped by workId', () {
      final catalog = [
        UserCatalogEntity(
          entityId: 'wk_u_rezero01',
          entityType: UserCatalogEntity.entityTypeWork,
          subtype: MediaCategory.book,
          title: 'Re:Zero',
          addedAt: DateTime(2024),
        ),
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_subaru01',
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      ];
      final vaultItems = [
        ContentItem(
          workId: 'wk_u_fate0001',
          title: 'Fate/stay night',
          category: MediaCategory.book,
          domain: AppDomain.subculture,
        ),
        ContentItem(
          workId: 'wk_u_rezero01',
          title: 'Re:Zero (vault title ignored)',
          category: MediaCategory.book,
          domain: AppDomain.subculture,
        ),
      ];

      final options = buildCollectibleWorkPickerOptions(
        catalogEntities: catalog,
        vaultItems: vaultItems,
      );

      expect(options.map((o) => o.workId), [
        'wk_u_fate0001',
        'wk_u_rezero01',
      ]);
      expect(options.firstWhere((o) => o.workId == 'wk_u_rezero01').title, 'Re:Zero');
    });
  });

  group('showCollectibleCollectionEditDialog save flow', () {
    testWidgets('creates filter collection with title and relatedWorkId', (
      tester,
    ) async {
      CollectibleCollection? saved;

      await _openNewDialog(
        tester,
        catalogEntities: _sampleWorkCatalog(),
        onClosed: (result) => saved = result,
      );
      await _enterTitle(tester, 'Re:Zero Cast');
      await _selectRelatedWork(tester, 'Re:Zero');
      await _tapAdd(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(saved, isNotNull);
      expect(saved!.mode, CollectibleCollectionMode.filter);
      expect(saved!.title, 'Re:Zero Cast');
      expect(saved!.filter?.relatedWorkId, 'wk_u_rezero01');
    });

    testWidgets('empty title shows validation snackbar and keeps dialog open', (
      tester,
    ) async {
      var closed = false;

      await _openNewDialog(
        tester,
        catalogEntities: _sampleWorkCatalog(),
        onClosed: (_) => closed = true,
      );
      await _tapAdd(tester);

      expect(find.text('이름을 입력해 주세요.'), findsOneWidget);
      expect(find.text('컬렉션 추가'), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets(
      'filter mode without tags or work shows validation snackbar and keeps dialog open',
      (tester) async {
        var closed = false;

        await _openNewDialog(
          tester,
          catalogEntities: _sampleWorkCatalog(),
          onClosed: (_) => closed = true,
        );
        await _enterTitle(tester, '태그 없음');
        await _tapAdd(tester);

        expect(
          find.text('태그 또는 작품을 하나 이상 지정해 주세요.'),
          findsOneWidget,
        );
        expect(find.text('컬렉션 추가'), findsOneWidget);
        expect(closed, isFalse);
      },
    );

    testWidgets('curated mode saves selected work in memberOrder', (
      tester,
    ) async {
      CollectibleCollection? saved;

      await _openNewDialog(
        tester,
        catalogEntities: _sampleWorkCatalog(),
        onClosed: (result) => saved = result,
      );
      await _enterTitle(tester, '내 큐레이션');
      await _selectCuratedMode(tester);
      await _toggleCuratedWork(tester, 'Re:Zero');
      await _tapAdd(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(saved, isNotNull);
      expect(saved!.mode, CollectibleCollectionMode.curated);
      expect(
        saved!.memberOrder,
        contains(
          const CollectibleRef(kind: CollectibleKind.work, id: 'wk_u_rezero01'),
        ),
      );
    });
  });
}
