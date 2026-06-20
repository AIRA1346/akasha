import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/entity_link_selection.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/dialogs/entity_link_picker_dialog.dart';
import 'package:akasha/services/entity_link_picker_candidates.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/enums.dart';

class _FakeUserCatalog implements UserCatalogPort {
  _FakeUserCatalog(this._entities);

  final List<UserCatalogEntity> _entities;
  final _controller = StreamController<void>.broadcast();

  @override
  List<UserCatalogEntity> get all => List.unmodifiable(_entities);

  @override
  Stream<void> get onChanged => _controller.stream;

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) {
    for (final e in _entities) {
      if (e.entityId == entityId) return e;
    }
    return null;
  }

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _entities.where((e) => e.matchesQuery(q)).toList();
  }

  @override
  Future<void> upsert(UserCatalogEntity entity) async {
    final i = _entities.indexWhere((e) => e.entityId == entity.entityId);
    if (i >= 0) {
      _entities[i] = entity;
    } else {
      _entities.add(entity);
    }
    _controller.add(null);
  }

  @override
  Future<void> remove(String entityId) async {
    _entities.removeWhere((e) => e.entityId == entityId);
    _controller.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EntityLinkPickerCandidates', () {
    late _FakeUserCatalog catalog;

    UserCatalogEntity person({
      required String id,
      required String title,
      List<String> aliases = const [],
      List<String> tags = const [],
    }) {
      return UserCatalogEntity.userLocal(
        entityId: id,
        type: EntityAnchorType.person,
        title: title,
        aliases: aliases,
        tags: tags,
      );
    }

    setUp(() {
      catalog = _FakeUserCatalog([
        person(id: 'pe_u_archived', title: '나츠키 스바루', aliases: ['스바루']),
        person(id: 'pe_u_catalog', title: '나츠키 스바루 B'),
        UserCatalogEntity.userLocal(
          entityId: 'co_u_tiger01',
          type: EntityAnchorType.concept,
          title: 'Tiger',
          aliases: ['호랑이'],
        ),
        UserCatalogEntity.userLocal(
          entityId: 'wk_u_work01',
          type: EntityAnchorType.work,
          title: 'Re:Zero',
          subtype: MediaCategory.book,
        ),
      ]);
    });

    test('title search finds matching entities', () async {
      final results = await EntityLinkPickerCandidates.build(
        userCatalog: catalog,
        query: '나츠키',
        archivedEntityIds: {'pe_u_archived'},
      );

      expect(results.length, 2);
      expect(
        results.map((c) => c.entity.entityId),
        containsAll(['pe_u_archived', 'pe_u_catalog']),
      );
    });

    test('alias search finds entity', () async {
      final results = await EntityLinkPickerCandidates.build(
        userCatalog: catalog,
        query: '호랑이',
        archivedEntityIds: {'co_u_tiger01'},
      );

      expect(results.length, 1);
      expect(results.first.entity.entityId, 'co_u_tiger01');
      expect(results.first.entity.title, 'Tiger');
    });

    test('semantic tag search finds entity', () async {
      final taggedCatalog = _FakeUserCatalog([
        person(
          id: 'pe_u_hero01',
          title: '나츠키 스바루',
          tags: const ['영웅', '구원'],
        ),
      ]);

      final results = await EntityLinkPickerCandidates.build(
        userCatalog: taggedCatalog,
        query: '영웅',
        archivedEntityIds: {'pe_u_hero01'},
      );

      expect(results.length, 1);
      expect(results.first.entity.entityId, 'pe_u_hero01');
    });

    test('archived entities sort before catalog-only', () async {
      final results = await EntityLinkPickerCandidates.build(
        userCatalog: catalog,
        query: '나츠키',
        archivedEntityIds: {'pe_u_archived'},
      );

      expect(results.first.isArchived, isTrue);
      expect(results.first.entity.entityId, 'pe_u_archived');
      expect(results.last.isArchived, isFalse);
    });

    test('excludes work entities from picker', () async {
      final results = await EntityLinkPickerCandidates.build(
        userCatalog: catalog,
        query: 'Re:Zero',
        archivedEntityIds: const {},
      );

      expect(results, isEmpty);
    });

    test('empty query lists linkable entities with archived first', () async {
      final results = await EntityLinkPickerCandidates.build(
        userCatalog: catalog,
        query: '',
        archivedEntityIds: {'pe_u_archived', 'co_u_tiger01'},
      );

      expect(results.length, 3);
      expect(results[0].isArchived, isTrue);
      expect(results[1].isArchived, isTrue);
      expect(results[2].isArchived, isFalse);
    });
  });

  group('EntityLinkSelection', () {
    test('canonical wiki token uses entityId and title', () {
      const selection = EntityLinkSelection(
        entityId: 'pe_u_natsuki1',
        title: '나츠키 스바루',
        entityType: 'person',
      );

      expect(
        selection.canonicalWikiToken,
        '[[pe_u_natsuki1|나츠키 스바루]]',
      );
    });
  });

  group('EntityLinkPickerDialog', () {
    testWidgets('selecting a row returns entityId and title', (tester) async {
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_pick001',
          type: EntityAnchorType.person,
          title: '나츠키 스바루',
        ),
      ]);

      EntityLinkSelection? picked;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  picked = await showEntityLinkPickerDialog(
                    context,
                    userCatalog: catalog,
                    initialQuery: '나츠키',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Entity 연결'), findsOneWidget);
      await tester.tap(find.text('나츠키 스바루'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.entityId, 'pe_u_pick001');
      expect(picked!.title, '나츠키 스바루');
      expect(picked!.entityType, 'person');
    });
  });
}
