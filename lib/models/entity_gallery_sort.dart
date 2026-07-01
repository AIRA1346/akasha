/// Entity gallery sort — independent from Work [SortCriteria].
enum EntityGallerySortCriteria {
  recentlyAdded('Recently Added'),
  titleAsc('By Name'),
  archivedFirst('Archived First'),
  manualOrder('Manual Order');

  final String label;
  const EntityGallerySortCriteria(this.label);

  static const List<EntityGallerySortCriteria> galleryOptions = [
    recentlyAdded,
    titleAsc,
    archivedFirst,
  ];

  static const List<EntityGallerySortCriteria> curatedCollectionOptions = [
    manualOrder,
    recentlyAdded,
    titleAsc,
    archivedFirst,
  ];

  bool get isManualOrder => this == manualOrder;
}
