part of 'collectible_collection_edit_dialog.dart';

/// Work picker row — catalog Work entity or vault item fallback.
class CollectibleWorkPickerOption {
  final String workId;
  final String title;

  const CollectibleWorkPickerOption({
    required this.workId,
    required this.title,
  });
}

List<CollectibleWorkPickerOption> buildCollectibleWorkPickerOptions({
  required List<UserCatalogEntity> catalogEntities,
  List<AkashaItem> vaultItems = const [],
}) {
  final byId = <String, CollectibleWorkPickerOption>{};
  for (final entity in catalogEntities) {
    if (!entity.isWorkEntity || entity.entityId.isEmpty) continue;
    byId[entity.entityId] = CollectibleWorkPickerOption(
      workId: entity.entityId,
      title: entity.title,
    );
  }
  for (final item in vaultItems) {
    if (item.workId.isEmpty) continue;
    byId.putIfAbsent(
      item.workId,
      () => CollectibleWorkPickerOption(
        workId: item.workId,
        title: item.title,
      ),
    );
  }
  final options = byId.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  return options;
}
