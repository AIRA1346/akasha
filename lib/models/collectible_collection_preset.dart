import 'collectible_collection.dart';
import 'collectible_collection_filter.dart';
import 'collectible_collection_id_codec.dart';
import 'collectible_kind.dart';

/// Cast-style filter collection — kind + relatedWorkId only (Phase 4 Step 4).
class CollectibleCollectionPreset {
  final String title;
  final String relatedWorkId;

  const CollectibleCollectionPreset({
    required this.title,
    required this.relatedWorkId,
  });

  CollectibleCollection build() => buildRelatedWorkCollection(
        title: title,
        workId: relatedWorkId,
      );

  bool isAvailableIn(Iterable<String> knownWorkIds) {
    final ids = knownWorkIds.toSet();
    return ids.contains(relatedWorkId);
  }
}

abstract final class CollectibleCollectionPresets {
  static const rezeroCast = CollectibleCollectionPreset(
    title: 'Re:Zero Cast',
    relatedWorkId: 'wk_u_rezero01',
  );

  static const fateCast = CollectibleCollectionPreset(
    title: 'Fate Cast',
    relatedWorkId: 'wk_u_fate_stay_night',
  );

  static const List<CollectibleCollectionPreset> all = [
    rezeroCast,
    fateCast,
  ];
}

CollectibleCollection buildRelatedWorkCollection({
  required String title,
  required String workId,
  List<CollectibleKind> kinds = const [CollectibleKind.person],
}) {
  return CollectibleCollection(
    id: CollectibleCollectionIdCodec.buildUserLocal(),
    title: title,
    mode: CollectibleCollectionMode.filter,
    filter: CollectibleCollectionFilter(
      kinds: kinds,
      relatedWorkId: workId,
    ),
  );
}
