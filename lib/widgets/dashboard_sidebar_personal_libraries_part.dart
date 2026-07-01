part of 'dashboard_sidebar.dart';

class _DashboardSidebarPersonalLibrariesSection extends StatelessWidget {
  const _DashboardSidebarPersonalLibrariesSection({
    required this.selectionMode,
    required this.personalLibraries,
    required this.activePersonalLibraryId,
    required this.vaultItems,
    required this.onAddPersonalLibrary,
    required this.onSelectPersonalLibrary,
  });

  final SidebarSelectionMode selectionMode;
  final List<PersonalLibraryConfig> personalLibraries;
  final String? activePersonalLibraryId;
  final List<AkashaItem> vaultItems;
  final VoidCallback onAddPersonalLibrary;
  final void Function(String id) onSelectPersonalLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardSidebarSectionTitle(
          l10n?.sidebarMyLibraries ?? '나만의 서재',
          onAdd: onAddPersonalLibrary,
        ),
        const SizedBox(height: 6),
        if (personalLibraries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              l10n?.sidebarCreateMyLibraryPrompt ?? '나만의 서재를 만들어 보세요',
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textCaption,
              ),
            ),
          )
        else
          ...personalLibraries.map((lib) => _buildLibraryRow(lib, l10n)),
      ],
    );
  }

  Widget _buildLibraryRow(PersonalLibraryConfig library, AppLocalizations? l10n) {
    final isActive = selectionMode == SidebarSelectionMode.personalLibrary &&
        library.id == activePersonalLibraryId;
    final memberCount =
        library.isCurated ? library.memberOrder.length : 0;
    
    final subtitle = library.isMasterArchive
        ? (l10n?.libraryMasterArchive ?? '전체 아카이브')
        : library.isCurated
            ? (memberCount > 0
                ? (l10n?.libraryWorkCount(memberCount) ?? '$memberCount 작품')
                : (l10n?.libraryCurated ?? '큐레이션 서재'))
            : (l10n?.libraryFiltered ?? '필터 서재');

    return _SidebarThumbnailTile(
      item: _coverItemForLibrary(library),
      title: library.name,
      subtitle: subtitle,
      isActive: isActive,
      fallbackIcon: _iconForLibrary(library),
      onTap: () => onSelectPersonalLibrary(library.id),
    );
  }

  IconData _iconForLibrary(PersonalLibraryConfig library) {
    if (library.isMasterArchive) return Icons.inventory_2_outlined;
    if (library.isCurated) return Icons.collections_bookmark_outlined;
    if (library.categories.length == 1) {
      return library.categories.first.icon;
    }
    return Icons.filter_list_outlined;
  }

  AkashaItem? _coverItemForLibrary(PersonalLibraryConfig library) {
    if (!library.isCurated || library.memberOrder.isEmpty) return null;

    final byWorkId = <String, AkashaItem>{
      for (final item in vaultItems)
        if (item.workId.isNotEmpty) item.workId: item,
    };
    for (final workId in library.memberOrder) {
      final item = byWorkId[workId];
      if (item != null) return item;
    }
    return null;
  }
}
