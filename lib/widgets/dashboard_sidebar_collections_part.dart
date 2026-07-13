part of 'dashboard_sidebar.dart';

class _DashboardSidebarCollectionsSection extends StatelessWidget {
  const _DashboardSidebarCollectionsSection({
    required this.selectionMode,
    required this.collectibleCollections,
    required this.vaultItems,
    required this.activeCollectibleCollectionId,
    required this.onGoCollection,
    required this.onSelectCollectibleCollection,
  });

  final SidebarSelectionMode selectionMode;
  final List<CollectibleCollection> collectibleCollections;
  final List<AkashaItem> vaultItems;
  final String? activeCollectibleCollectionId;
  final Future<void> Function() onGoCollection;
  final void Function(String id) onSelectCollectibleCollection;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSidebarSectionTitle(
          l10n?.sidebarMyCollections ?? '내 컬렉션',
          trailingLabel: collectibleCollections.isNotEmpty
              ? (l10n?.sidebarViewAll ?? '모두 보기')
              : null,
          onTrailing: collectibleCollections.isNotEmpty
              ? () => onGoCollection()
              : null,
        ),
        const SizedBox(height: 6),
        if (collectibleCollections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              l10n?.sidebarNoCollections ?? '컬렉션이 없습니다',
              style: AkashaTypography.bodySecondary.copyWith(
                color: palette.textMuted,
              ),
            ),
          )
        else
          ...collectibleCollections
              .take(4)
              .map((col) => _buildCollectionRow(col, l10n)),
      ],
    );
  }

  Widget _buildCollectionRow(
    CollectibleCollection col,
    AppLocalizations? l10n,
  ) {
    final isActive =
        selectionMode == SidebarSelectionMode.collectibleCollection &&
        activeCollectibleCollectionId == col.id;
    final count = col.isCurated ? col.memberOrder.length : 0;
    final subtitle = count > 0
        ? (l10n?.libraryWorkCount(count) ?? '$count 작품')
        : (l10n?.sidebarCollections ?? '컬렉션');
    final coverItem = _coverItemForCollection(col);

    return _SidebarThumbnailTile(
      item: coverItem,
      title: col.title,
      subtitle: subtitle,
      isActive: isActive,
      fallbackIcon: Icons.favorite_outline,
      onTap: () => onSelectCollectibleCollection(col.id),
    );
  }

  AkashaItem? _coverItemForCollection(CollectibleCollection col) {
    if (!col.isCurated || col.memberOrder.isEmpty) return null;
    final byWorkId = <String, AkashaItem>{
      for (final item in vaultItems)
        if (item.workId.isNotEmpty) item.workId: item,
    };
    for (final CollectibleRef ref in col.memberOrder) {
      if (ref.kind == CollectibleKind.work) {
        final item = byWorkId[ref.id];
        if (item != null) return item;
      }
    }
    return null;
  }
}
