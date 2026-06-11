import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/sample_data.dart';
import '../models/dashboard_config.dart';
import '../models/personal_library_config.dart';
import '../services/file_service.dart';
import '../services/works_registry.dart';
import '../services/registry_sync_service.dart';
import '../utils/helpers.dart';
import '../utils/browse_section_filters.dart';
import '../utils/browse_category_groups.dart';
import '../widgets/filter_section.dart';
import '../widgets/poster_card.dart';
import '../widgets/browse_dashboard_sections.dart';
import '../widgets/dashboard_sidebar.dart';
import '../utils/browse_year_groups.dart';
import '../widgets/fusion_search_dialog.dart';
import '../widgets/browse_poster_grid.dart';
import 'home/home_registry_sync.dart';
import 'home/home_dashboard_controller.dart';
import 'home/home_browse_filter_controller.dart';
import 'home/home_registry_prefetch.dart';
import 'home/home_auto_archive.dart';
import 'home/home_registry_hide_actions.dart';
import 'home/home_section_preferences.dart';
import 'home/home_app_bar.dart';
import 'home/home_vault_banner.dart';
import 'home/dialogs/registry_sync_dialog.dart';
import 'home/dialogs/vault_settings_dialog.dart';
import 'home/dialogs/dashboard_edit_dialog.dart';
import 'home/dialogs/add_work_dialog.dart';
import 'home/dialogs/catalog_add_contribution_dialog.dart';
import 'home/dialogs/catalog_contributions_inbox_dialog.dart';
import 'home/dialogs/clipboard_import_dialog.dart';
import 'home/dialogs/prompt_templates_dialog.dart';
import '../services/catalog_contribution_service.dart';
import '../config/feature_flags.dart';
import '../widgets/today_recall_card.dart';
import '../utils/recall_picker.dart';
import 'home/home_personal_library_controller.dart';
import 'home/dialogs/personal_library_edit_dialog.dart';
import 'home/dialogs/personal_library_name_dialog.dart';
import 'home/dialogs/archive_then_add_dialog.dart';
import 'home/dialogs/add_to_library_sheet.dart';
import '../models/work_drag_payload.dart';
import '../services/my_library_pipeline.dart';
import '../services/markdown_parser.dart';
import '../services/personal_library_membership_service.dart';
import '../widgets/work_draggable_card.dart';
import '../services/user_preferences.dart';
import '../services/user_registry_preferences.dart';
import '../services/browse_pipeline.dart';
import '../models/browse_card.dart';
import '../models/library_theme.dart';
import '../services/entitlement_service.dart';
import '../services/library_theme_preferences.dart';
import '../widgets/library_theme_picker.dart';
import '../workbench/workbench_controller.dart';
import '../workbench/work_tab.dart';
import 'workbench/workbench_shell.dart';
//  메인 홈 대시보드 (Sanctum vault 스타일 그리드)
// ════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AkashaItem> _items = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isCatalogLoading = false;
  DateTime? _lastSyncTime;

  final HomeBrowseFilterController _filterCtrl = HomeBrowseFilterController();
  final HomeDashboardController _dashboardCtrl = HomeDashboardController();
  final HomePersonalLibraryController _personalLibCtrl =
      HomePersonalLibraryController();
  late final PersonalLibraryMembershipService _libraryMembership =
      PersonalLibraryMembershipService(_personalLibCtrl);
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
    _initVault();
    if (FeatureFlags.catalogContributions) {
      _refreshCatalogContributionCount();
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
    await _loadSidebarState(); // 사이드바 오픈 상태 로드
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

    // 백그라운드 자동 동기화 시도 (Phase 4)
    _registrySync.checkAutoSync();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final service = AkashaFileService();
    List<AkashaItem> loadedItems = [];
    if (service.vaultPath != null) {
      // 볼트 모드: 디스크 기준 로드 + 캐시 동기화는 loadAllItems 내부에서 처리
      loadedItems = await service.loadAllItems();
    } else {
      loadedItems = buildSampleData();
      // 데모 모드: 메모리에만 있는 신규 항목 병합
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
        _isLoading = false;
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

  // ── 필터링 & 정렬 로직 ──────────────────

  List<BrowseCard> get _filteredBrowseCards => BrowsePipeline.build(
        allUserItems: _items,
        filters: _filterCtrl.filterState,
      );

  // ── 대시보드 SharedPreferences 연동 로직 (Phase 11) ──
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
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectDashboard(String id) async {
    setState(() {
      _dashboardCtrl.select(id);
      _personalLibCtrl.selectDashboardMode();
      _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
      _workbench.showBrowse();
    });
    await _prefetchRegistryForCurrentFilters();
  }

  void _selectPersonalLibrary(String id) {
    setState(() {
      _personalLibCtrl.selectPersonal(id);
      _applyPersonalLibraryFilterSnapshot(_personalLibCtrl.activeLibrary);
      _workbench.showBrowse();
    });
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

  Future<void> _addWorkToLibrary({
    required String libraryId,
    required AkashaItem item,
    bool switchToLibrary = false,
  }) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('볼트 연결 후 서재에 담을 수 있습니다.')),
        );
      }
      return;
    }

    var workItem = _resolveItemForOpen(item);
    if (!fileService.isArchivedInVault(workItem)) {
      final ok = await showArchiveThenAddDialog(context, draft: workItem);
      if (!ok || !mounted) return;
      await _loadItems();
      workItem = _resolveItemForOpen(item);
    }

    final workId = MarkdownParser.ensureWorkId(workItem);
    PersonalLibraryConfig? lib;
    for (final l in _personalLibCtrl.libraries) {
      if (l.id == libraryId) {
        lib = l;
        break;
      }
    }
    if (lib == null || !lib.isCurated) return;

    final already = _libraryMembership.containsWork(lib, workId);
    await _libraryMembership.addWork(libraryId, workId);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          already ? '이미 「${lib.name}」에 담긴 작품입니다.' : '「${lib.name}」에 담았습니다.',
        ),
        action: switchToLibrary
            ? SnackBarAction(
                label: '보기',
                onPressed: () => _selectPersonalLibrary(libraryId),
              )
            : null,
      ),
    );
  }

  Future<void> _addRegistryWorkToLibrary(RegistryWork work) async {
    if (!_canAddToLibrary) return;
    final draft = HomeAutoArchive.itemFromRegistryWork(work);
    final fileService = AkashaFileService();
    AkashaItem? existing;
    for (final i in _items) {
      if (WorksRegistry.setContainsWorkId({work.workId}, i.workId)) {
        existing = i;
        break;
      }
    }

    if (existing != null && fileService.isArchivedInVault(existing)) {
      await showAddToLibrarySheet(
        context,
        workId: MarkdownParser.ensureWorkId(existing),
        displayTitle: existing.title,
        membership: _libraryMembership,
        activeLibraryId: _personalLibCtrl.activeLibraryId,
        onCreateLibrary: _promptCreateCuratedLibrary,
      );
    } else {
      final ok = await showArchiveThenAddDialog(context, draft: draft);
      if (!ok || !mounted) return;
      await _loadItems();
      final saved = _resolveItemForOpen(draft);
      await showAddToLibrarySheet(
        context,
        workId: MarkdownParser.ensureWorkId(saved),
        displayTitle: saved.title,
        membership: _libraryMembership,
        activeLibraryId: _personalLibCtrl.activeLibraryId,
        onCreateLibrary: _promptCreateCuratedLibrary,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _showAddToLibraryForCard(AkashaItem item) async {
    final fileService = AkashaFileService();
    if (fileService.vaultPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('볼트 연결 후 서재에 담을 수 있습니다.')),
        );
      }
      return;
    }

    var workItem = _resolveItemForOpen(item);
    if (!fileService.isArchivedInVault(workItem)) {
      final ok = await showArchiveThenAddDialog(context, draft: workItem);
      if (!ok || !mounted) return;
      await _loadItems();
      workItem = _resolveItemForOpen(item);
    }

    final workId = MarkdownParser.ensureWorkId(workItem);
    await showAddToLibrarySheet(
      context,
      workId: workId,
      displayTitle: workItem.title,
      membership: _libraryMembership,
      activeLibraryId: _personalLibCtrl.activeLibraryId,
      onCreateLibrary: _promptCreateCuratedLibrary,
    );
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
        title: const Text('🗑️ 나만의 서재 삭제'),
        content: const Text('이 서재를 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPersonalLibraryEditDialog(
    PersonalLibraryConfig config,
  ) async {
    final updated = await showPersonalLibraryEditDialog(
      context,
      config: config,
      vaultItems: _items,
      onAddWorks: config.isCurated && _canAddToLibrary
          ? () async {
              await _showSearchDialog(context);
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
  }

  void _deleteDashboard(String id) {
    if (id == 'master_index') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ 대시보드 삭제'),
        content: const Text(
          '이 대시보드 설정을 정말로 삭제하시겠습니까?\n'
          '아카이빙된 마크다운 파일은 유지되며, 대시보드 파일 뷰 목록에서만 제외됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
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
            child: const Text('삭제'),
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

  Widget _buildEmptyMainContent() {
    if (_isPersonalLibraryMode) {
      final vaultLinked = AkashaFileService().vaultPath != null;
      final library = _personalLibCtrl.activeLibrary;
      final libName = library?.name ?? '나만의 서재';
      final isCuratedEmpty =
          library != null && library.isCurated && library.memberOrder.isEmpty;
      final isFilterEmpty = library != null && !library.isCurated;
      final hasMembersButFiltered =
          library != null &&
              library.isCurated &&
              library.memberOrder.isNotEmpty &&
              vaultLinked;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                vaultLinked
                    ? (isCuratedEmpty
                        ? Icons.collections_bookmark_outlined
                        : Icons.inventory_2_outlined)
                    : Icons.folder_off_outlined,
                size: 48,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 12),
              Text(
                !vaultLinked
                    ? '볼트를 연동하면 나만의 서재가 열립니다'
                    : isCuratedEmpty
                        ? '작품을 담아 서재를 채워 보세요'
                        : hasMembersButFiltered
                            ? '필터 조건에 맞는 작품이 없습니다'
                            : isFilterEmpty
                                ? '$libName에 표시할 아카이브 작품이 없습니다'
                                : '$libName에 표시할 작품이 없습니다',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                !vaultLinked
                    ? '홈 상단에서 Sanctum 볼트 폴더를 연동해 주세요.'
                    : isCuratedEmpty
                        ? '검색으로 작품을 추가하거나, 카드 ⠿ 핸들을 서재로 끌어다 놓으세요.'
                        : hasMembersButFiltered
                            ? '상단 필터를 조정해 보세요.'
                            : '검색으로 작품을 추가해 보세요.',
                style: TextStyle(color: Colors.grey[500], height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (vaultLinked && isCuratedEmpty) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showSearchDialog(context),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('작품 검색'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            '조건에 맞는 작품이 없습니다.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
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

    Widget poster = PosterCard(
      item: item,
      formatSlots: card.formatSlots,
      franchiseId: card.franchiseId,
      showPoster: _isPersonalLibraryMode,
      onTap: () => _openBrowseItem(item),
      onHideFromRegistry: _hideActions.registryHideActionFor(item),
      onHideFranchise: _hideActions.franchiseHideActionFor(card),
      onHideFormatSlot: _hideActions.formatSlotHideActionFor(card),
      onAddToLibrary: canCurate ? () => _showAddToLibraryForCard(item) : null,
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

  // ── 글로벌 작품 사전 동기화 메소드 ──

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
        title: const Text('사전 캐시 삭제'),
        content: const Text(
          '디스크에 저장된 글로벌 사전 캐시(registry_cache)를 삭제하고\n'
          '앱에 포함된 번들 사전으로 다시 로드합니다.\n\n'
          '포스터·메타가 옛날로 보일 때 사용하세요.\n'
          '최신 원격 사전은 이후 「동기화」로 받을 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
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
            content: Text('사전 캐시를 삭제하고 번들 사전으로 다시 로드했습니다.'),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('캐시 삭제 중 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCatalogLoading = false);
    }
  }

  Future<void> _showCustomUrlDialog() async {
    await showRegistrySyncDialog(
      context,
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

  // ── 빌드 ──────────────────────────────────

  bool get _isPersonalLibraryMode =>
      _personalLibCtrl.sidebarMode == SidebarSelectionMode.personalLibrary;

  List<BrowseCard> get _personalBrowseCards {
    final library = _personalLibCtrl.activeLibrary;
    if (library == null) return const [];
    return MyLibraryPipeline.build(
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

    final List<BrowseCard> catalogCards;
    final List<BrowseCard> hofCards;
    final List<BrowseCard> watchlistCards;
    final BrowseCategoryGroups? categoryGroups;

    if (_isPersonalLibraryMode) {
      catalogCards = sortBrowseCards(
        filterLibraryCards(filtered, _items),
        _sectionPrefs.librarySort,
      );
      hofCards = sortBrowseCards(
        filtered.where((c) => c.item.isHallOfFame).toList(),
        _sectionPrefs.hofSort,
      );
      watchlistCards = sortBrowseCards(
        filterWatchlistCards(filtered, _items),
        _sectionPrefs.watchlistSort,
      );
      categoryGroups = null;
    } else {
      catalogCards = sortBrowseCards(filtered, _sectionPrefs.librarySort);
      hofCards = const [];
      watchlistCards = sortBrowseCards(
        filterWatchlistCards(filtered, _items),
        _sectionPrefs.watchlistSort,
      );
      categoryGroups = BrowseCategoryGroups.fromCards(
        catalogCards,
        _sectionPrefs.librarySort,
        restrictToCategories: _filterCtrl.categories,
      );
    }

    final yearGroups = BrowseYearGroups.fromLibraryCards(
      _isPersonalLibraryMode ? catalogCards : filtered,
      _sectionPrefs.yearlySort,
    );

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
            onSearch: () => _showSearchDialog(context),
            onClipboardImport: _showClipboardImportDialog,
            onSync: _syncRegistry,
            onSyncSettings: _showCustomUrlDialog,
            onPromptTemplates: () => showPromptTemplatesDialog(context),
            onVaultSettings: _showVaultInfoDialog,
            onClearRegistryCache: _clearRegistryCache,
            onCatalogInbox: FeatureFlags.catalogContributions
                ? _showCatalogContributionsInbox
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

          // ━━━ 스크롤 가능한 메인 콘텐츠 ━━━
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
                        ? _showAddToLibraryForCard
                        : null,
                    browseContent: !_isPersonalLibraryMode && _isCatalogLoading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '글로벌 작품 사전 불러오는 중…',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? _buildEmptyMainContent()
                            : BrowseDashboardSections(
                                hofCards: hofCards,
                                libraryCards: catalogCards,
                                watchlistCards: watchlistCards,
                                yearGroups: yearGroups,
                                categoryGroups: categoryGroups,
                                displayName: _displayName,
                                isPersonalLibraryMode: _isPersonalLibraryMode,
                                showHallOfFame: _isPersonalLibraryMode,
                                hofExpanded: _sectionPrefs.hofExpanded,
                                libraryExpanded:
                                    _sectionPrefs.libraryExpanded,
                                yearlyExpanded: _sectionPrefs.yearlyExpanded,
                                watchlistExpanded:
                                    _sectionPrefs.watchlistExpanded,
                                hofSortCriteria: _sectionPrefs.hofSort,
                                librarySortCriteria:
                                    _sectionPrefs.librarySort,
                                yearlySortCriteria: _sectionPrefs.yearlySort,
                                watchlistSortCriteria:
                                    _sectionPrefs.watchlistSort,
                                onHofExpandedChanged: (v) => _sectionPrefs
                                    .setHofExpanded(v, () => setState(() {})),
                                onLibraryExpandedChanged: (v) =>
                                    _sectionPrefs.setLibraryExpanded(
                                        v, () => setState(() {})),
                                onYearlyExpandedChanged: (v) => _sectionPrefs
                                    .setYearlyExpanded(
                                        v, () => setState(() {})),
                                onWatchlistExpandedChanged: (v) =>
                                    _sectionPrefs.setWatchlistExpanded(
                                        v, () => setState(() {})),
                                onHofSortChanged: (val) => _sectionPrefs
                                    .setHofSort(val, () => setState(() {})),
                                onLibrarySortChanged: (val) => _sectionPrefs
                                    .setLibrarySort(
                                        val, () => setState(() {})),
                                onYearlySortChanged: (val) => _sectionPrefs
                                    .setYearlySort(
                                        val, () => setState(() {})),
                                onWatchlistSortChanged: (val) =>
                                    _sectionPrefs.setWatchlistSort(
                                        val, () => setState(() {})),
                                posterCardBuilder: _buildPosterCard,
                                gridBuilder: _buildGrid,
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

  // ── 포스터 카드 그리드 ──

  Widget _buildGrid(List<BrowseCard> cards) {
    return BrowsePosterGrid(
      cards: cards,
      cardBuilder: _buildPosterCard,
      cardMinWidth: _isPersonalLibraryMode ? 170 : 176,
      childAspectRatio: _isPersonalLibraryMode ? 0.48 : 0.78,
    );
  }

  // ── 3중 퓨전 검색 다이얼로그 ──

  Future<void> _showSearchDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => FusionSearchDialog(
        localItems: _items,
        onSelectLocal: _openBrowseItem,
        onSelectRemote: _openRegistryWorkForArchive,
        onCustomAdd: (query) => _showAddDialog(context, initialTitle: query),
        onCatalogPropose: FeatureFlags.catalogContributions
            ? (query) => _proposeCatalogAdd(context, query)
            : null,
        onAddLocalToLibrary:
            _canAddToLibrary ? _showAddToLibraryForCard : null,
        onAddRemoteToLibrary:
            _canAddToLibrary ? _addRegistryWorkToLibrary : null,
      ),
    );
  }

  Future<void> _refreshCatalogContributionCount() async {
    await CatalogContributionService.instance.load();
    if (!mounted) return;
    setState(() {
      _catalogContributionCount =
          CatalogContributionService.instance.pendingCount;
    });
  }

  Future<void> _showCatalogContributionsInbox() async {
    await showCatalogContributionsInboxDialog(context);
    await _refreshCatalogContributionCount();
  }

  Future<void> _proposeCatalogAdd(BuildContext context, String query) async {
    final saved = await showCatalogAddContributionDialog(
      context,
      initialTitle: query,
      searchQuery: query,
    );
    if (saved == true) {
      await _refreshCatalogContributionCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('글로벌 사전 추가 제안이 저장되었습니다. (제안함에서 export)'),
        ),
      );
    }
  }

  /// 원격 사전 작품 탭 → 아카이브 생성 화면으로 이동
  Future<void> _openRegistryWorkForArchive(RegistryWork work) async {
    if (!mounted) return;
    _openBrowseItem(HomeAutoArchive.itemFromRegistryWork(work));
  }

  // ── 신규 등록 다이얼로그 ──
  Future<void> _showAddDialog(BuildContext context, {String? initialTitle}) async {
    final result = await showAddWorkDialog(context, initialTitle: initialTitle);
    if (result != null) {
      final service = AkashaFileService();
      if (service.vaultPath != null) {
        await service.saveItem(result);
        await _loadItems();
      } else {
        setState(() => _items.add(result));
      }
    }
  }

  // ── 로컬 볼트(Vault) 폴더 선택 ──
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
          SnackBar(content: Text('폴더 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _showVaultInfoDialog() async {
    await showVaultSettingsDialog(
      context,
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

  Future<void> _showClipboardImportDialog() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    await showClipboardImportDialog(
      context,
      initialText: data?.text ?? '',
      existingItems: _items,
      onItemImported: (item) async {
        if (AkashaFileService().vaultPath != null) {
          await _loadItems();
        } else {
          setState(() => _items.add(item));
        }
      },
    );
  }

}
