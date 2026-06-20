/// Entity gallery sort — independent from Work [SortCriteria].
enum EntityGallerySortCriteria {
  recentlyAdded('최근 추가순'),
  titleAsc('이름순'),
  archivedFirst('아카이브 우선'),
  manualOrder('수동 순서');

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
