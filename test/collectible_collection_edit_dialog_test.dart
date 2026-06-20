import 'dart:convert';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/collectible_collection_filter.dart';
import 'package:akasha/models/collectible_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/dialogs/collectible_collection_edit_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
