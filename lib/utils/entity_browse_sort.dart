import '../models/entity_browse_card.dart';
import '../models/entity_gallery_sort.dart';

/// Sort [EntityBrowseCard] list for gallery display.
List<EntityBrowseCard> sortEntityBrowseCards(
  List<EntityBrowseCard> cards,
  EntityGallerySortCriteria criteria,
) {
  final sorted = List<EntityBrowseCard>.from(cards);
  int compare(EntityBrowseCard a, EntityBrowseCard b) {
    switch (criteria) {
      case EntityGallerySortCriteria.manualOrder:
        return 0;
      case EntityGallerySortCriteria.recentlyAdded:
        final byDate = b.entity.addedAt.compareTo(a.entity.addedAt);
        if (byDate != 0) return byDate;
        return _titleCompare(a, b);
      case EntityGallerySortCriteria.titleAsc:
        final byTitle = _titleCompare(a, b);
        if (byTitle != 0) return byTitle;
        return b.entity.addedAt.compareTo(a.entity.addedAt);
      case EntityGallerySortCriteria.archivedFirst:
        final byArchived = (b.isArchived ? 1 : 0).compareTo(a.isArchived ? 1 : 0);
        if (byArchived != 0) return byArchived;
        return _titleCompare(a, b);
    }
  }

  sorted.sort(compare);
  return sorted;
}

int _titleCompare(EntityBrowseCard a, EntityBrowseCard b) {
  return a.entity.title.toLowerCase().compareTo(b.entity.title.toLowerCase());
}
