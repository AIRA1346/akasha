part of 'collectible_collection_edit_dialog.dart';

class _CollectibleCollectionEditSession {
  _CollectibleCollectionEditSession({
    required this.config,
    required List<UserCatalogEntity> catalogEntities,
    required List<AkashaItem> vaultItems,
  })  : titleCtrl = TextEditingController(text: config?.title ?? ''),
        mode = config?.mode ?? CollectibleCollectionMode.filter,
        tags = List<String>.from(config?.filter?.tagsAll ?? const []),
        relatedWorkId = config?.filter?.relatedWorkId,
        kinds = List<CollectibleKind>.from(
          config?.filter?.kinds ?? const [CollectibleKind.person],
        ),
        selectedRefs = <CollectibleRef>{...?config?.memberOrder},
        memberCount = config?.memberOrder.length ?? 0,
        pickableEntities = catalogEntities
            .where(
              (e) =>
                  !e.isWorkEntity &&
                  collectibleKindFromAnchor(e.anchorType) != null,
            )
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title)),
        pickableWorks = buildCollectibleWorkPickerOptions(
          catalogEntities: catalogEntities,
          vaultItems: vaultItems,
        );

  final CollectibleCollection? config;
  final TextEditingController titleCtrl;
  CollectibleCollectionMode mode;
  List<String> tags;
  String? relatedWorkId;
  List<CollectibleKind> kinds;
  Set<CollectibleRef> selectedRefs;
  final int memberCount;
  final List<UserCatalogEntity> pickableEntities;
  final List<CollectibleWorkPickerOption> pickableWorks;

  bool get isNew => config == null;

  CollectibleCollectionFilter buildFilter() {
    return CollectibleCollectionFilter(
      kinds: kinds,
      tagsAll: tags.isEmpty ? null : tags,
      relatedWorkId: relatedWorkId,
    );
  }

  Set<String> knownWorkIds() =>
      pickableWorks.map((work) => work.workId).toSet();

  CollectibleWorkPickerOption? selectedWorkOption() {
    if (relatedWorkId == null) return null;
    for (final work in pickableWorks) {
      if (work.workId == relatedWorkId) return work;
    }
    return null;
  }

  List<CollectibleRef> buildMemberOrder() {
    final ordered = <CollectibleRef>[];
    if (config != null && config!.isCurated) {
      for (final ref in config!.memberOrder) {
        if (selectedRefs.contains(ref)) {
          ordered.add(ref);
        }
      }
    }
    for (final ref in selectedRefs) {
      if (ordered.any(
        (existing) => collectibleRefKey(existing) == collectibleRefKey(ref),
      )) {
        continue;
      }
      ordered.add(ref);
    }
    return ordered;
  }
}
