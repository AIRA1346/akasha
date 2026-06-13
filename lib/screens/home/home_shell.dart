import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/enums.dart';
import '../../models/akasha_item.dart';
import '../../models/sample_data.dart';
import '../../models/dashboard_config.dart';
import '../../models/personal_library_config.dart';
import '../../services/file_service.dart';
import '../../services/works_registry.dart';
import '../../services/registry_sync_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/filter_section.dart';
import '../../widgets/poster_card.dart';
import '../../widgets/dashboard_sidebar.dart';
import 'home_registry_sync.dart';
import 'coordinators/home_membership_coordinator.dart';
import 'home_dashboard_controller.dart';
import 'home_browse_filter_controller.dart';
import 'home_registry_prefetch.dart';
import 'home_auto_archive.dart';
import 'home_registry_hide_actions.dart';
import 'home_section_preferences.dart';
import 'home_app_bar.dart';
import 'home_vault_banner.dart';
import 'dialogs/home_dialogs_facade.dart';
import 'views/browse_view.dart';
import 'views/personal_library_view.dart';
import 'dialogs/dashboard_edit_dialog.dart';
import '../../config/feature_flags.dart';
import '../../widgets/today_recall_card.dart';
import '../../utils/recall_picker.dart';
import 'home_personal_library_controller.dart';
import 'dialogs/personal_library_edit_dialog.dart';
import 'dialogs/personal_library_name_dialog.dart';
import 'dialogs/work_library_menu.dart';
import '../../models/membership_apply_result.dart';
import '../../models/work_drag_payload.dart';
import '../../services/my_library_pipeline.dart';
import '../../services/markdown_parser.dart';
import '../../data/adapters/works_registry_adapter.dart';
import '../../services/personal_library_membership_service.dart';
import '../../services/franchise_library_scope.dart';
import '../../services/franchise_fusion_service.dart';
import '../../services/franchise_registry.dart';
import '../../widgets/work_draggable_card.dart';
import '../../services/user_preferences.dart';
import '../../services/user_registry_preferences.dart';
import '../../services/browse_pipeline.dart';
import '../../models/browse_card.dart';
import '../../models/library_theme.dart';
import '../../services/entitlement_service.dart';
import '../../services/library_theme_preferences.dart';
import '../../widgets/library_theme_picker.dart';
import '../../features/workbench/data/workbench_controller.dart';
import '../../features/workbench/presentation/work_tab.dart';
import '../../features/workbench/presentation/workbench_shell.dart';
// Home shell ? Scaffold ? sidebar ? workbench ?? (Wave 1.3)

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<AkashaItem> _items = [];
  bool _isSyncing = false;
  bool _isCatalogLoading = false;
  DateTime? _lastSyncTime;

  final HomeBrowseFilterController _filterCtrl = HomeBrowseFilterController();
  final HomeDashboardController _dashboardCtrl = HomeDashboardController();
  final HomePersonalLibraryController _personalLibCtrl =
      HomePersonalLibraryController();
  late final PersonalLibraryMembershipService _libraryMembership =
      PersonalLibraryMembershipService(_personalLibCtrl, WorksRegistryAdapter());
  late final BrowsePipeline _browsePipeline =
      BrowsePipeline(WorksRegistryAdapter());
  late final MyLibraryPipeline _myLibraryPipeline =
      MyLibraryPipeline(WorksRegistryAdapter());
  late final HomeMembershipCoordinator _membershipCoordinator;
  HomeSectionPreferences _sectionPrefs = HomeSectionPreferences();
  late final HomeRegistryHideActions _hideActions;
  bool _isSidebarOpen = true;
  int _catalogContributionCount = 0;

  String _displayName = UserPreferences.defaultDisplayName;
  bool _autoArchiveRegistry = false;
  StreamSubscription<void>? _vaultUpdateSubscription;
  Timer? _vaultReloadDebounce;
  late final HomeRegistrySync _registrySync;
  LibraryTheme _libraryTheme = LibraryTheme.classic;
  final WorkbenchController _workbench = WorkbenchController();

  @override
  void initState() {
    super.initState();
    _hideActions = HomeRegistryHideActions(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      showMessage: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
    _registrySync = HomeRegistrySync(
      isMounted: () => mounted,
      onSyncingChanged: (v) => setState(() => _isSyncing = v),
      refreshLastSyncTime: _refreshLastSyncTime,
      reloadItems: _loadItems,
      autoArchiveWorks: _autoArchiveRegistryWorks,
      showSuccess: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      showError: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
    _membershipCoordinator = HomeMembershipCoordinator(
      personalLibraryController: _personalLibCtrl,
      membership: _libraryMembership,
      resolveItemForOpen: _resolveItemForOpen,
      reloadItems: _loadItems,
    );
    _initVault();
    if (FeatureFlags.catalogContributions) {
      _syncCatalogContributionCount();
    }
    _workbench.addListener(_onWorkbenchChanged);
    _workbench.loadPrefs();
  }

  void _onWorkbenchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _workbench.removeListener(_onWorkbenchChanged);
    _workbench.dispose();
    _vaultReloadDebounce?.cancel();
    _vaultUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initVault() async {
    final service = AkashaFileService();
    await service.init();
    await _loadSidebarState(); // ???? ?? ?? ??
    await _loadDashboards();
    await _loadPersonalLibraries();
    _sectionPrefs = await HomeSectionPreferences.load();
    _displayName = await UserPreferences.getDisplayName();
    _autoArchiveRegistry = await UserPreferences.isAutoArchiveRegistryEnabled();
    await UserRegistryPreferences.instance.load();
    await EntitlementService.instance.load();
    _libraryTheme = await LibraryThemePreferences.load();
    await _loadItems();

    if (service.vaultPath != null && _autoArchiveRegistry) {
      await _autoArchiveRegistryWorks();
    }

    await _prefetchRegistryForCurrentFilters();
    await _refreshLastSyncTime();

    _vaultUpdateSubscription = service.onVaultUpdated.listen((_) {
      _vaultReloadDebounce?.cancel();
      _vaultReloadDebounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _loadItems();
      });
    });

    // ????? ?? ??? ?? (Phase 4)
    _registrySync.checkAutoSync();
  }

  Future<void> _loadItems() async {
    final service = AkashaFileService();
    List<AkashaItem> loadedItems = [];
    if (service.vaultPath != null) {
      // ?? ??: ??? ?? ?? + ?? ???? loadAllItems ???? ??
      loadedItems = await service.loadAllItems();
    } else {
      loadedItems = buildSampleData();
      // ?? ??: ????? ?? ?? ?? ??
      final cache = service.inMemoryCache;
      for (final cachedItem in cache.values) {
        final exists = loadedItems.any(
          (e) =>
              (cachedItem.workId.isNotEmpty &&
                  e.workId == cachedItem.workId) ||
              (e.title == cachedItem.title &&
                  e.category == cachedItem.category),
        );
        if (!exists) loadedItems.add(cachedItem);
      }
    }

    if (mounted) {
      setState(() {
        _items = loadedItems;
      });
    }
  }

  Future<void> _prefetchRegistryForCurrentFilters() async {
    await prefetchRegistryForFilters(
      activeDashboardId: _dashboardCtrl.activeDashboardId,
      filters: _filterCtrl,
      onCatalogLoadingChanged: (v) => setState(() => _isCatalogLoading = v),
      isMounted: () => mounted,
      onDataChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _autoArchiveRegistryWorks({bool showFeedback = false}) async {
    final count = await HomeAutoArchive.run(
      prefetchFilters: _prefetchRegistryForCurrentFilters,
      showFeedback: showFeedback,
      showMessage: showFeedback
          ? (msg) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            }
          : null,
    );
    if (count > 0) await _loadItems();
  }

  // ?? ??? & ?? ?? ??????????????????

  List<BrowseCard> get _filteredBrowseCards => _browsePipeline.build(
        allUserItems: _items,
        filters: _filterCtrl.filterState,
      );

  // ?? ???? SharedPreferences ?? ?? (Phase 11) ??
  Future<void> _loadSidebarState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSidebarOpen = prefs.getBool('akasha_sidebar_open') ?? true;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveSidebarState(bool open) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('akasha_sidebar_open', open);
    } catch (_) {}
  }

  void _applyDashboardFilters(DashboardFilterSnapshot snap) {
    _filterCtrl.applySnapshot(snap);
  }

  void _syncFiltersToActiveView() {
    if (_isPersonalLibraryMode) {
      _personalLibCtrl.syncActiveFromFilters(
        domain: _filterCtrl.domain,
        categories: _filterCtrl.categories,
        workStatuses: _filterCtrl.workStatuses,
        myStatuses: _filterCtrl.myStatuses,
      );
      _personalLibCtrl.save();
      return;
    }
    _filterCtrl.syncToDashboard(_dashboardCtrl);
  }

  void _applyPersonalLibraryFilterSnapshot(PersonalLibraryConfig? library) {
    _applyDashboardFilters(_personalLibCtrl.filterSnapshotFor(library));
  }

  Future<void> _loadDashboards() async {
    await _dashboardCtrl.load();
    _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
    if (_personalLibCtrl.sidebarMode == SidebarSelectionMode.dashboard) {
      await _prefetchRegistryForCurrentFilters();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadPersonalLibraries() async {
    await _personalLibCtrl.load();
    if (_personalLibCtrl.sidebarMode == SidebarSelectionMode.personalLibrary) {
      _applyPersonalLibraryFilterSnapshot(_personalLibCtrl.activeLibrary);
      _sanitizeLibrarySortForActiveLibrary();
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectDashboard(String id) async {
    setState(() {
      _dashboardCtrl.select(id);
      _personalLibCtrl.selectDashboardMode();
      _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
      _workbench.showBrowse();
      _sanitizeLibrarySortForActiveLibrary();
    });
    await _prefetchRegistryForCurrentFilters();
  }

  void _selectPersonalLibrary(String id) {
    final wasCurated = _isCuratedLibraryActive;
    PersonalLibraryConfig? target;
    for (final lib in _personalLibCtrl.libraries) {
      if (lib.id == id) {
        target = lib;
        break;
      }
    }
    final willBeCurated = target?.isCurated ?? false;

    setState(() {
      _personalLibCtrl.selectPersonal(id);
      _applyPersonalLibraryFilterSnapshot(_personalLibCtrl.activeLibrary);
      _workbench.showBrowse();
      _syncLibrarySortOnPersonalLibraryChange(
        wasCurated: wasCurated,
        nowCurated: willBeCurated,
      );
    });
  }

  /// filter???????? ?? ?? ? ?? ???
  void _sanitizeLibrarySortForActiveLibrary() {
    if (_isCuratedLibraryActive) return;
    if (_sectionPrefs.librarySort.isManualOrder) {
      _sectionPrefs.librarySort = SortCriteria.titleAsc;
      _sectionPrefs.saveSort('library', SortCriteria.titleAsc);
    }
  }

  /// curated ?? ? ?? ?? ? ?? ? filter/master ?? ? ??
  void _syncLibrarySortOnPersonalLibraryChange({
    required bool wasCurated,
    required bool nowCurated,
  }) {
    if (nowCurated) {
      if (!wasCurated) {
        _sectionPrefs.librarySort = SortCriteria.manualOrder;
        _sectionPrefs.saveSort('library', SortCriteria.manualOrder);
      }
      return;
    }
    _sanitizeLibrarySortForActiveLibrary();
  }

  bool get _canAddToLibrary =>
      AkashaFileService().vaultPath != null &&
      _personalLibCtrl.libraries.any((l) => l.isCurated);

  void _onLibraryDragStarted() {
    if (!_isSidebarOpen) {
      setState(() => _isSidebarOpen = true);
      _saveSidebarState(true);
    }
  }

  Future<void> _onDropWorkToLibrary(
    String libraryId,
    WorkDragPayload payload,
  ) async {
    await _addWorkToLibrary(
      libraryId: libraryId,
      item: payload.item,
      switchToLibrary: true,
    );
  }

  BrowseCard _browseCardForItem(AkashaItem item) {
    final group = FranchiseRegistry.groupFor(item.workId);
    return BrowseCard(
      item: item,
      formatSlots: FranchiseFusionService.formatSlotsForWorkId(
        item.workId,
        allUserItems: _items,
      ),
      franchiseId: group?.id,
    );
  }

  Future<void> _addWorkToLibrary({
    required String libraryId,
    required AkashaItem item,
    bool switchToLibrary = false,
  }) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('?? ?? ? ??? ?? ? ????.')),
        );
      }
      return;
    }

    final outcome = await _membershipCoordinator.addWorkToLibrary(
      libraryId: libraryId,
      item: item,
    );

    if (outcome.vaultMdError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?? ?? ??: ${outcome.vaultMdError}')),
        );
      }
      return;
    }
    if (outcome.skipped || outcome.libraryName == null) return;
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.alreadyInLibrary
              ? '?? ?${outcome.libraryName}?? ?? ?????.'
              : '?${outcome.libraryName}?? ?????.',
        ),
        action: switchToLibrary
            ? SnackBarAction(
                label: '??',
                onPressed: () => _selectPersonalLibrary(libraryId),
              )
            : null,
      ),
    );
  }

  Future<void> _addRegistryWorkToLibrary(RegistryWork work) async {
    if (!_canAddToLibrary) return;

    AkashaItem? existing;
    for (final i in _items) {
      if (WorksRegistry.setContainsWorkId({work.workId}, i.workId)) {
        existing = i;
        break;
      }
    }

    final item = existing != null
        ? _resolveItemForOpen(existing)
        : HomeAutoArchive.itemFromRegistryWork(work);
    await _showAddToLibraryForCard(_browseCardForItem(item));
    if (mounted) setState(() {});
  }

  WorkLibraryMenuRequest _workLibraryMenuRequest(
    BrowseCard card,
    AkashaItem workItem, {
    required bool includeLibraryActions,
  }) {
    final fileService = AkashaFileService();
    final singleIds = FranchiseLibraryScope.workIdsForSingleFormat(card);
    final ipOption = includeLibraryActions &&
        FranchiseLibraryScope.offersEntireIpOption(card, _items);
    final needsTitle =
        includeLibraryActions && !fileService.isArchivedInVault(workItem);
    return WorkLibraryMenuRequest(
      displayTitle: workItem.title,
      draftItem: workItem,
      showTitleEditor: needsTitle,
      draftMetaLine:
          needsTitle ? '${workItem.myStatusLabel} ? ${workItem.category.label}' : null,
      singleWorkIds: singleIds,
      entireIpWorkIds: ipOption
          ? FranchiseLibraryScope.archivedWorkIdsForEntireIp(card, _items)
          : singleIds,
      showIpScopeOption: ipOption,
      membership: _libraryMembership,
      activeLibraryId:
          _isCuratedLibraryActive ? _personalLibCtrl.activeLibraryId : null,
      onCreateLibrary: includeLibraryActions ? _promptCreateCuratedLibrary : null,
      onHideFromRegistry: _hideActions.registryHideActionFor(workItem),
      onHideFranchise: _hideActions.franchiseHideActionFor(card),
      onApply: includeLibraryActions
          ? (input) => _membershipCoordinator.applyWorkLibraryPanel(
                card,
                draft: workItem,
                input: input,
                vaultItems: _items,
              )
          : null,
    );
  }

  void _showMembershipApplySnackBar(MembershipApplyResult? result) {
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.toSnackBarMessage())),
    );
  }

  Future<void> _openWorkLibraryMenu(BrowseCard card, Offset anchor) async {
    final canCurate = _canAddToLibrary;
    final hasHide = _hideActions.registryHideActionFor(card.item) != null ||
        _hideActions.franchiseHideActionFor(card) != null;
    if (!canCurate && !hasHide) return;

    final fileService = AkashaFileService();
    if (canCurate && fileService.vaultPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? ?? ? ??? ?? ? ????.')),
      );
      return;
    }

    final workItem = _resolveItemForOpen(card.item);

    if (!mounted) return;
    final result = await showWorkLibraryPopover(
      context,
      anchor: anchor,
      request: _workLibraryMenuRequest(
        card,
        workItem,
        includeLibraryActions: canCurate,
      ),
    );
    _showMembershipApplySnackBar(result);
    if (mounted) setState(() {});
  }

  Future<void> _showAddToLibraryForItem(AkashaItem item) async {
    await _showAddToLibraryForCard(_browseCardForItem(item));
  }

  Future<void> _showAddToLibraryForCard(BrowseCard card) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('?? ?? ? ??? ?? ? ????.')),
        );
      }
      return;
    }

    final workItem = _resolveItemForOpen(card.item);

    if (!mounted) return;
    final result = await showWorkLibraryDialog(
      context,
      request: _workLibraryMenuRequest(
        card,
        workItem,
        includeLibraryActions: true,
      ),
    );
    _showMembershipApplySnackBar(result);
    if (mounted) setState(() {});
  }

  Future<PersonalLibraryConfig?> _promptCreateCuratedLibrary() async {
    final name = await showPersonalLibraryNameDialog(context);
    if (name == null || !mounted) return null;
    final config = PersonalLibraryConfig(
      id: 'personal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      mode: PersonalLibraryMode.curated,
    );
    setState(() {
      _personalLibCtrl.add(config);
      _applyPersonalLibraryFilterSnapshot(config);
    });
    await _personalLibCtrl.save();
    return config;
  }

  Future<void> _showPersonalLibraryAddDialog() async {
    await _promptCreateCuratedLibrary();
  }

  void _deletePersonalLibrary(String id) {
    if (id == PersonalLibraryConfig.masterArchiveId) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('??? ??? ?? ??'),
        content: const Text('? ??? ???? ?????????'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('??'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _personalLibCtrl.remove(id);
              });
              _personalLibCtrl.save();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('??'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPersonalLibraryEditDialog(
    PersonalLibraryConfig config,
  ) async {
    final memberOrderBefore = config.isCurated
        ? List<String>.from(config.memberOrder)
        : const <String>[];
    final updated = await showPersonalLibraryEditDialog(
      context,
      config: config,
      vaultItems: _items,
      onAddWorks: config.isCurated && _canAddToLibrary
          ? () async {
              await _openSearchDialog();
              await _loadItems();
            }
          : null,
    );
    if (updated == null || !mounted) return;
    setState(() {
      if (_personalLibCtrl.activeLibraryId == updated.id) {
        _applyPersonalLibraryFilterSnapshot(updated);
      }
    });
    await _personalLibCtrl.save();

    final memberOrderChanged =
        memberOrderBefore.length != updated.memberOrder.length ||
            !_memberOrderListsEqual(memberOrderBefore, updated.memberOrder);
    if (updated.isCurated &&
        !_sectionPrefs.librarySort.isManualOrder &&
        memberOrderChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '?? ??? ??????. ?????? ??? ?? ???? ?????.',
          ),
        ),
      );
    }
  }

  bool _memberOrderListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _deleteDashboard(String id) {
    if (id == 'master_index') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('??? ???? ??'),
        content: const Text(
          '? ???? ??? ??? ?????????\n'
          '????? ???? ??? ????, ???? ?? ? ????? ?????.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('??'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _dashboardCtrl.remove(id);
                _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
              });
              _dashboardCtrl.save();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('??'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDashboardEditDialog(
    BuildContext context,
    DashboardConfig? config,
  ) async {
    await showDashboardEditDialog(
      context,
      config: config,
      onSaved: (dashboard, isNew) {
        setState(() {
          if (isNew) {
            _dashboardCtrl.add(dashboard);
          } else if (_dashboardCtrl.activeDashboardId == dashboard.id) {
            _applyDashboardFilters(_dashboardCtrl.filterSnapshotFor(dashboard));
          }
        });
        _dashboardCtrl.save();
      },
    );
  }

  Future<void> _syncCatalogContributionCount() async {
    await HomeDialogsFacade.refreshCatalogContributionCount(
      onCount: (count) {
        if (!mounted) return;
        setState(() => _catalogContributionCount = count);
      },
    );
  }

  Future<void> _openSearchDialog() async {
    await HomeDialogsFacade.showSearchDialog(
      context: context,
      localItems: _items,
      onSelectLocal: _openBrowseItem,
      onSelectRemote: _openRegistryWorkForArchive,
      onCustomAdd: (query) => _openAddDialog(initialTitle: query),
      onCatalogPropose: HomeDialogsFacade.catalogProposeCallback(
        context: context,
        refreshContributionCount: _syncCatalogContributionCount,
        showMessage: (msg) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      ),
      onAddLocalToLibrary:
          _canAddToLibrary ? _showAddToLibraryForItem : null,
      onAddRemoteToLibrary:
          _canAddToLibrary ? _addRegistryWorkToLibrary : null,
    );
  }

  Future<void> _openAddDialog({String? initialTitle}) async {
    await HomeDialogsFacade.showAddDialog(
      context: context,
      initialTitle: initialTitle,
      onSavedToVault: (item) async {
        await AkashaFileService().saveItem(item);
        await _loadItems();
      },
      onSavedInMemory: (item) => setState(() => _items.add(item)),
    );
  }

  Future<void> _openRegistryWorkForArchive(RegistryWork work) async {
    if (!mounted) return;
    _openBrowseItem(HomeAutoArchive.itemFromRegistryWork(work));
  }

  void _onDomainChanged(AppDomain? domain) {
    setState(() {
      _filterCtrl.onDomainChanged(domain);
      _syncFiltersToActiveView();
    });
    if (!_isPersonalLibraryMode) _prefetchRegistryForCurrentFilters();
  }

  void _toggleCategory(MediaCategory category) {
    setState(() {
      _filterCtrl.toggleCategory(category);
      _syncFiltersToActiveView();
    });
    if (!_isPersonalLibraryMode) _prefetchRegistryForCurrentFilters();
  }

  void _clearCategories() {
    setState(() {
      _filterCtrl.clearCategories();
      _syncFiltersToActiveView();
    });
    if (!_isPersonalLibraryMode) _prefetchRegistryForCurrentFilters();
  }

  void _toggleWorkStatus(String label) {
    setState(() {
      _filterCtrl.toggleWorkStatus(label);
      _syncFiltersToActiveView();
    });
  }

  void _toggleMyStatus(String label) {
    setState(() {
      _filterCtrl.toggleMyStatus(label);
      _syncFiltersToActiveView();
    });
  }

  AkashaItem _resolveItemForOpen(AkashaItem item) {
    for (final existing in _items) {
      if (item.workId.isNotEmpty && existing.workId == item.workId) {
        return existing;
      }
      if (existing.title == item.title &&
          existing.category == item.category) {
        return existing;
      }
    }
    return item;
  }

  void _openBrowseItem(AkashaItem item) {
    _workbench.openWork(_resolveItemForOpen(item));
  }

  Future<void> _onWorkbenchWorkSaved(AkashaItem saved) async {
    await _loadItems();
    if (!mounted) return;
    _workbench.updateTabItem(WorkTab.idFor(saved), saved, dirty: false);
  }

  Future<void> _onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    _workbench.closeTab(tabId);
    if (mounted) {
      setState(() {
        _items.removeWhere((e) =>
            (item.workId.isNotEmpty && e.workId == item.workId) ||
            (e.title == item.title && e.category == item.category));
      });
    }
    await _loadItems();
  }

  Widget _buildPosterCard(BrowseCard card) {
    final item = card.item;
    final canCurate = _canAddToLibrary;
    final libraryBadgeCount = canCurate
        ? _libraryMembership.countLibrariesContainingAny(
            FranchiseLibraryScope.relatedWorkIds(card, _items),
          )
        : 0;

    final hideRegistry = _hideActions.registryHideActionFor(item);
    final hideFranchise = _hideActions.franchiseHideActionFor(card);
    final canOpenMenu = canCurate || hideRegistry != null || hideFranchise != null;

    Widget poster = PosterCard(
      item: item,
      formatSlots: card.formatSlots,
      franchiseId: card.franchiseId,
      showPoster: _isPersonalLibraryMode,
      curatedLibraryCount: libraryBadgeCount,
      onTap: () => _openBrowseItem(item),
      onOpenLibraryMenu:
          canOpenMenu ? (pos) => _openWorkLibraryMenu(card, pos) : null,
      onHideFormatSlot: _hideActions.formatSlotHideActionFor(card),
    );

    if (canCurate) {
      final workId =
          item.workId.isNotEmpty ? item.workId : MarkdownParser.ensureWorkId(item);
      poster = WorkDraggableCard(
        payload: WorkDragPayload(
          workId: workId,
          item: item,
          source: _isPersonalLibraryMode
              ? WorkDragSource.libraryGrid
              : WorkDragSource.catalogGrid,
        ),
        onDragStarted: _onLibraryDragStarted,
        child: poster,
      );
    }

    return poster;
  }

  // ?? ??? ?? ?? ??? ??? ??

  Future<void> _refreshLastSyncTime() async {
    await RegistrySyncService().init();
    if (!mounted) return;
    setState(() => _lastSyncTime = RegistrySyncService().lastSyncTime);
  }

  Future<void> _syncRegistry() async {
    if (_isSyncing) return;
    await _registrySync.syncNow();
  }

  Future<void> _clearRegistryCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('?? ?? ??'),
        content: const Text(
          '???? ??? ??? ?? ??(registry_cache)? ????\n'
          '?? ??? ?? ???? ?? ?????.\n\n'
          '??????? ??? ?? ? ?????.\n'
          '?? ?? ??? ?? ?????? ?? ? ????.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('??'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('??'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCatalogLoading = true);
    try {
      await WorksRegistry.clearDiskCacheAndReloadBundle();
      await _prefetchRegistryForCurrentFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('?? ??? ???? ?? ???? ?? ??????.'),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?? ?? ? ??: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCatalogLoading = false);
    }
  }

  Future<void> _showCustomUrlDialog() async {
    await HomeDialogsFacade.showRegistrySync(
      context: context,
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      onSyncNow: _syncRegistry,
      onUrlSaved: _refreshLastSyncTime,
    );
  }

  Future<void> _showLibraryThemePicker() async {
    final picked =
        await showLibraryThemePicker(context, current: _libraryTheme);
    if (picked != null && mounted) {
      setState(() => _libraryTheme = picked);
    }
  }

  // ?? ?? ??????????????????????????????????

  bool get _isPersonalLibraryMode =>
      _personalLibCtrl.sidebarMode == SidebarSelectionMode.personalLibrary;

  bool get _isCuratedLibraryActive {
    final lib = _personalLibCtrl.activeLibrary;
    return _isPersonalLibraryMode && lib != null && lib.isCurated;
  }

  List<BrowseCard> get _personalBrowseCards {
    final library = _personalLibCtrl.activeLibrary;
    if (library == null) return const [];
    return _myLibraryPipeline.build(
      _items,
      library: library,
      filters: _filterCtrl.filterState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _isPersonalLibraryMode ? _personalBrowseCards : _filteredBrowseCards;
    final dailyRecall = FeatureFlags.showRecallCard && !_isPersonalLibraryMode
        ? RecallPicker.pickDailyRecall(_items)
        : null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.tab): () {
          if (ModalRoute.of(context)?.isCurrent == true) {
            setState(() {
              _isSidebarOpen = !_isSidebarOpen;
              _saveSidebarState(_isSidebarOpen);
            });
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Theme(
          data: _isPersonalLibraryMode
              ? Theme.of(context).copyWith(
                  scaffoldBackgroundColor: _libraryTheme.backgroundColor,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        secondary: _libraryTheme.accentColor,
                      ),
                )
              : Theme.of(context),
          child: Scaffold(
            backgroundColor: _isPersonalLibraryMode
                ? _libraryTheme.backgroundColor
                : null,
            appBar: HomeAppBar(
              isSidebarOpen: _isSidebarOpen,
              isSyncing: _isSyncing,
              showLibraryThemeButton: _isPersonalLibraryMode,
              onLibraryTheme: _showLibraryThemePicker,
              libraryThemeAccent: _libraryTheme.accentColor,
            onToggleSidebar: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
                _saveSidebarState(_isSidebarOpen);
              });
            },
            onSearch: _openSearchDialog,
            onClipboardImport: _openClipboardImportDialog,
            onSync: _syncRegistry,
            onSyncSettings: _showCustomUrlDialog,
            onPromptTemplates: () => HomeDialogsFacade.showPromptTemplates(context),
            onVaultSettings: _openVaultSettingsDialog,
            onClearRegistryCache: _clearRegistryCache,
            onCatalogInbox: FeatureFlags.catalogContributions
                ? _openCatalogContributionsInbox
                : null,
            catalogContributionCount: _catalogContributionCount,
          ),
          body: Row(
            children: [
              DashboardSidebar(
                isOpen: _isSidebarOpen,
                selectionMode: _personalLibCtrl.sidebarMode,
                dashboards: _dashboardCtrl.dashboards,
                activeDashboardId: _dashboardCtrl.activeDashboardId,
                personalLibraries: _personalLibCtrl.libraries,
                activePersonalLibraryId: _personalLibCtrl.activeLibraryId,
                onAddDashboard: () => _showDashboardEditDialog(context, null),
                onSelectDashboard: _selectDashboard,
                onEditDashboard: (dash) =>
                    _showDashboardEditDialog(context, dash),
                onDeleteDashboard: _deleteDashboard,
                onAddPersonalLibrary: _showPersonalLibraryAddDialog,
                onSelectPersonalLibrary: _selectPersonalLibrary,
                onEditPersonalLibrary: _showPersonalLibraryEditDialog,
                onDeletePersonalLibrary: _deletePersonalLibrary,
                onDropWorkToLibrary:
                    _canAddToLibrary ? _onDropWorkToLibrary : null,
                onLibraryDragStarted:
                    _canAddToLibrary ? _onLibraryDragStarted : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    if (AkashaFileService().vaultPath == null)
                      HomeVaultBanner(onConnectVault: _selectVaultFolder),
                    if (!_workbench.hasOpenWork) ...[
                      FilterSection(
                        selectedDomain: _filterCtrl.domain,
                        selectedCategories: _filterCtrl.categories,
                        selectedWorkStatuses: _filterCtrl.workStatuses,
                        selectedMyStatuses: _filterCtrl.myStatuses,
                        onDomainChanged: _onDomainChanged,
                        onToggleCategory: _toggleCategory,
                        onClearCategories: _clearCategories,
                        onToggleWorkStatus: _toggleWorkStatus,
                        onToggleMyStatus: _toggleMyStatus,
                      ),
                      const Divider(height: 1),
                    ],
                    if (!_isPersonalLibraryMode &&
                        !_workbench.hasOpenWork &&
                        _isCatalogLoading)
                      const LinearProgressIndicator(minHeight: 2),

          // ??? ??? ??? ?? ??? ???
          Expanded(
            child: Column(
              children: [
                if (dailyRecall != null && !_workbench.hasOpenWork)
                  TodayRecallCard(
                    recall: dailyRecall,
                    onTap: () => _openBrowseItem(dailyRecall.item),
                  ),
                Expanded(
                  child: WorkbenchShell(
                    controller: _workbench,
                    onWorkSaved: _onWorkbenchWorkSaved,
                    onWorkDeleted: _onWorkbenchWorkDeleted,
                    onAddToLibrary: _canAddToLibrary
                        ? _showAddToLibraryForItem
                        : null,
                    browseContent: _isPersonalLibraryMode
                        ? PersonalLibraryView(
                            filteredCards: filtered,
                            allItems: _items,
                            sectionPrefs: _sectionPrefs,
                            displayName: _displayName,
                            isCuratedLibraryActive: _isCuratedLibraryActive,
                            activeLibrary: _personalLibCtrl.activeLibrary,
                            posterCardBuilder: _buildPosterCard,
                            onStateChanged: () => setState(() {}),
                            onCuratedReorder: (cards, oldIndex, newIndex) async {
                              await PersonalLibraryView.applyCuratedGridReorder(
                                membership: _libraryMembership,
                                personalLibCtrl: _personalLibCtrl,
                                visibleCards: cards,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              );
                              if (mounted) setState(() {});
                            },
                            onSearch: _openSearchDialog,
                          )
                        : BrowseView(
                            filteredCards: filtered,
                            allItems: _items,
                            sectionPrefs: _sectionPrefs,
                            filterCategories: _filterCtrl.categories,
                            isCatalogLoading: _isCatalogLoading,
                            displayName: _displayName,
                            posterCardBuilder: _buildPosterCard,
                            onStateChanged: () => setState(() {}),
                          ),
                  ),
                ),
              ],
            ),
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Future<void> _openCatalogContributionsInbox() async {
    await HomeDialogsFacade.showCatalogContributionsInbox(context);
    await _syncCatalogContributionCount();
  }

  Future<void> _openVaultSettingsDialog() async {
    await HomeDialogsFacade.showVaultSettings(
      context: context,
      displayName: _displayName,
      autoArchiveRegistry: _autoArchiveRegistry,
      onDisplayNameSaved: (name) => setState(() => _displayName = name),
      onAutoArchiveChanged: (enabled) =>
          setState(() => _autoArchiveRegistry = enabled),
      runAutoArchive: _autoArchiveRegistryWorks,
      reloadItems: () async {
        await _loadPersonalLibraries();
        await _loadItems();
      },
      selectVaultFolder: _selectVaultFolder,
      onRegistryVisibilityChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _openClipboardImportDialog() async {
    await HomeDialogsFacade.showClipboardImport(
      context: context,
      existingItems: _items,
      onItemImportedToVault: (_) async => _loadItems(),
      onItemImportedInMemory: (item) => setState(() => _items.add(item)),
    );
  }

  // ?? ?? ??(Vault) ?? ?? ??
  Future<void> _selectVaultFolder() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await AkashaFileService().setVaultPath(selectedDirectory);
        await _loadPersonalLibraries();
        await _loadItems();
        await _autoArchiveRegistryWorks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?? ?? ? ??? ??????: $e')),
        );
      }
    }
  }

}
