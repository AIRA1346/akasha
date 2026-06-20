import 'package:akasha/models/entity_browse_card.dart';
import 'package:akasha/models/entity_gallery_sort.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/utils/entity_browse_sort.dart';
import 'package:flutter_test/flutter_test.dart';

EntityBrowseCard _card(
  String title, {
  DateTime? addedAt,
  bool archived = false,
}) {
  return EntityBrowseCard(
    entity: UserCatalogEntity(
      entityId: 'ent_$title',
      entityType: UserCatalogEntity.entityTypePerson,
      subtype: MediaCategory.manga,
      title: title,
      addedAt: addedAt ?? DateTime.utc(2024, 1, 1),
    ),
    isArchived: archived,
  );
}

void main() {
  group('sortEntityBrowseCards', () {
    test('recentlyAdded sorts by addedAt desc then title', () {
      final cards = [
        _card('Bravo', addedAt: DateTime.utc(2024, 1, 1)),
        _card('Alpha', addedAt: DateTime.utc(2024, 6, 1)),
        _card('Charlie', addedAt: DateTime.utc(2024, 1, 1)),
      ];
      final sorted =
          sortEntityBrowseCards(cards, EntityGallerySortCriteria.recentlyAdded);
      expect(sorted.map((c) => c.entity.title).toList(),
          ['Alpha', 'Bravo', 'Charlie']);
    });

    test('titleAsc sorts alphabetically', () {
      final cards = [
        _card('Charlie', addedAt: DateTime.utc(2024, 6, 1)),
        _card('Alpha'),
        _card('Bravo'),
      ];
      final sorted =
          sortEntityBrowseCards(cards, EntityGallerySortCriteria.titleAsc);
      expect(sorted.map((c) => c.entity.title).toList(),
          ['Alpha', 'Bravo', 'Charlie']);
    });

    test('archivedFirst puts archived entries first then title', () {
      final cards = [
        _card('Bravo', archived: false),
        _card('Alpha', archived: true),
        _card('Charlie', archived: true),
      ];
      final sorted =
          sortEntityBrowseCards(cards, EntityGallerySortCriteria.archivedFirst);
      expect(sorted.map((c) => c.entity.title).toList(),
          ['Alpha', 'Charlie', 'Bravo']);
    });
  });
}
