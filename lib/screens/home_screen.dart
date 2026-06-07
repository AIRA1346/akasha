import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/sample_data.dart';
import '../models/dashboard_config.dart';
import '../services/file_service.dart';
import '../services/works_registry.dart';
import '../services/registry_sync_service.dart';
import '../utils/helpers.dart';
import '../utils/browse_section_filters.dart';
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
import 'home/home_registry_archive.dart';
import 'home/dialogs/registry_sync_dialog.dart';
import 'home/dialogs/vault_settings_dialog.dart';
import 'home/dialogs/dashboard_edit_dialog.dart';
import 'home/dialogs/add_work_dialog.dart';
import 'home/dialogs/clipboard_import_dialog.dart';
import 'home/dialogs/prompt_templates_dialog.dart';
import '../config/feature_flags.dart';
import '../widgets/today_recall_card.dart';
import '../utils/recall_picker.dart';
import 'my_library_screen.dart';
import '../services/user_preferences.dart';
import '../services/user_registry_preferences.dart';
import '../services/browse_pipeline.dart';
import '../models/browse_card.dart';
import 'detail_screen.dart';

// ════════════════════════════════════════════════════════════════
//  메인 홈 대시보드 (옵시디언 스타일 그리드)
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
  HomeSectionPreferences _sectionPrefs = HomeSectionPreferences();
  late final HomeRegistryHideActions _hideActions;
  bool _isSidebarOpen = true;

  String _displayName = UserPreferences.defaultDisplayName;
  bool _autoArchiveRegistry = false;
  StreamSubscription<void>? _vaultUpdateSubscription;
  Timer? _vaultReloadDebounce;
  late final HomeRegistrySync _registrySync;

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
  }

  @override
  void dispose() {
    _vaultReloadDebounce?.cancel();
    _vaultUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initVault() async {
    final service = AkashaFileService();
    await service.init();
    await _loadSidebarState(); // 사이드바 오픈 상태 로드
    await _loadDashboards();   // 대시보드 리스트 로드
    _sectionPrefs = await HomeSectionPreferences.load();
    _displayName = await UserPreferences.getDisplayName();
    _autoArchiveRegistry = await UserPreferences.isAutoArchiveRegistryEnabled();
    await UserRegistryPreferences.instance.load();
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

  void _syncFiltersToActiveDashboard() {
    _filterCtrl.syncToDashboard(_dashboardCtrl);
  }

  Future<void> _loadDashboards() async {
    await _dashboardCtrl.load();
    _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
    await _prefetchRegistryForCurrentFilters();
    if (mounted) setState(() {});
  }

  Future<void> _selectDashboard(String id) async {
    setState(() {
      _dashboardCtrl.select(id);
      _applyDashboardFilters(_dashboardCtrl.activeFilterSnapshot);
    });
    await _prefetchRegistryForCurrentFilters();
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

  List<BrowseCard> get _hallOfFameCards =>
      _filteredBrowseCards.where((c) => c.item.isHallOfFame).toList();

  void _onDomainChanged(AppDomain? domain) {
    setState(() {
      _filterCtrl.onDomainChanged(domain);
      _syncFiltersToActiveDashboard();
    });
    _prefetchRegistryForCurrentFilters();
  }

  void _toggleCategory(MediaCategory category) {
    setState(() {
      _filterCtrl.toggleCategory(category);
      _syncFiltersToActiveDashboard();
    });
    _prefetchRegistryForCurrentFilters();
  }

  void _clearCategories() {
    setState(() {
      _filterCtrl.clearCategories();
      _syncFiltersToActiveDashboard();
    });
    _prefetchRegistryForCurrentFilters();
  }

  void _toggleWorkStatus(String label) {
    setState(() {
      _filterCtrl.toggleWorkStatus(label);
      _syncFiltersToActiveDashboard();
    });
  }

  void _toggleMyStatus(String label) {
    setState(() {
      _filterCtrl.toggleMyStatus(label);
      _syncFiltersToActiveDashboard();
    });
  }

  void _navigateToDetail(AkashaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    ).then((result) async {
      if (result == true && mounted) {
        setState(() {
          _items.removeWhere((e) =>
              (item.workId.isNotEmpty && e.workId == item.workId) ||
              (e.title == item.title && e.category == item.category));
        });
      }
      await _loadItems();
    });
  }

  Widget _buildPosterCard(BrowseCard card) {
    return PosterCard(
      item: card.item,
      formatSlots: card.formatSlots,
      franchiseId: card.franchiseId,
      onTap: () => _navigateToDetail(card.item),
      onHideFromRegistry: _hideActions.registryHideActionFor(card.item),
      onHideFranchise: _hideActions.franchiseHideActionFor(card),
      onHideFormatSlot: _hideActions.formatSlotHideActionFor(card),
    );
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

  Future<void> _showCustomUrlDialog() async {
    await showRegistrySyncDialog(
      context,
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      onSyncNow: _syncRegistry,
      onUrlSaved: _refreshLastSyncTime,
    );
  }

  // ── 빌드 ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBrowseCards;
    final dailyRecall = FeatureFlags.showRecallCard
        ? RecallPicker.pickDailyRecall(_items)
        : null;
    final hofCards = sortBrowseCards(_hallOfFameCards, _sectionPrefs.hofSort);
    final watchlistCards = sortBrowseCards(
      filterWatchlistCards(filtered, _items),
      _sectionPrefs.watchlistSort,
    );
    final libraryCards = sortBrowseCards(
      filterLibraryCards(filtered, _items),
      _sectionPrefs.librarySort,
    );

    final yearGroups = BrowseYearGroups.fromLibraryCards(
      libraryCards,
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
        child: Scaffold(
          appBar: HomeAppBar(
            isSidebarOpen: _isSidebarOpen,
            isSyncing: _isSyncing,
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
            onOpenMyLibrary: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyLibraryScreen()),
              );
            },
          ),
          body: Row(
            children: [
              DashboardSidebar(
                isOpen: _isSidebarOpen,
                dashboards: _dashboardCtrl.dashboards,
                activeDashboardId: _dashboardCtrl.activeDashboardId,
                onAddDashboard: () => _showDashboardEditDialog(context, null),
                onSelectDashboard: _selectDashboard,
                onEditDashboard: (dash) =>
                    _showDashboardEditDialog(context, dash),
                onDeleteDashboard: _deleteDashboard,
              ),
              Expanded(
                child: Column(
                  children: [
                    if (AkashaFileService().vaultPath == null)
                      HomeVaultBanner(onConnectVault: _selectVaultFolder),
                    // ━━━ 필터 영역 ━━━
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
                    if (_isCatalogLoading)
                      const LinearProgressIndicator(minHeight: 2),

          // ━━━ 스크롤 가능한 메인 콘텐츠 ━━━
          Expanded(
            child: Column(
              children: [
                if (dailyRecall != null)
                  TodayRecallCard(
                    recall: dailyRecall,
                    onTap: () => _navigateToDetail(dailyRecall.item),
                  ),
                Expanded(
                  child: _isCatalogLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: Colors.grey[700]),
                              const SizedBox(height: 12),
                              Text('조건에 맞는 작품이 없습니다.',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : BrowseDashboardSections(
                          hofCards: hofCards,
                          libraryCards: libraryCards,
                          watchlistCards: watchlistCards,
                          yearGroups: yearGroups,
                          displayName: _displayName,
                          hofExpanded: _sectionPrefs.hofExpanded,
                          libraryExpanded: _sectionPrefs.libraryExpanded,
                          yearlyExpanded: _sectionPrefs.yearlyExpanded,
                          watchlistExpanded: _sectionPrefs.watchlistExpanded,
                          hofSortCriteria: _sectionPrefs.hofSort,
                          librarySortCriteria: _sectionPrefs.librarySort,
                          yearlySortCriteria: _sectionPrefs.yearlySort,
                          watchlistSortCriteria: _sectionPrefs.watchlistSort,
                          onHofExpandedChanged: (v) =>
                              _sectionPrefs.setHofExpanded(v, () => setState(() {})),
                          onLibraryExpandedChanged: (v) =>
                              _sectionPrefs.setLibraryExpanded(v, () => setState(() {})),
                          onYearlyExpandedChanged: (v) =>
                              _sectionPrefs.setYearlyExpanded(v, () => setState(() {})),
                          onWatchlistExpandedChanged: (v) =>
                              _sectionPrefs.setWatchlistExpanded(v, () => setState(() {})),
                          onHofSortChanged: (val) =>
                              _sectionPrefs.setHofSort(val, () => setState(() {})),
                          onLibrarySortChanged: (val) =>
                              _sectionPrefs.setLibrarySort(val, () => setState(() {})),
                          onYearlySortChanged: (val) =>
                              _sectionPrefs.setYearlySort(val, () => setState(() {})),
                          onWatchlistSortChanged: (val) =>
                              _sectionPrefs.setWatchlistSort(val, () => setState(() {})),
                          posterCardBuilder: _buildPosterCard,
                          gridBuilder: _buildGrid,
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('새 작품'),
        ),
      ),
    ));
  }

  // ── 포스터 카드 그리드 ──

  Widget _buildGrid(List<BrowseCard> cards) {
    return BrowsePosterGrid(
      cards: cards,
      cardBuilder: _buildPosterCard,
    );
  }

  // ── 3중 퓨전 검색 다이얼로그 ──

  Future<void> _showSearchDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => FusionSearchDialog(
        localItems: _items,
        onSelectLocal: _navigateToDetail,
        onSelectRemote: _archiveAndOpenRegistryWork,
        onCustomAdd: (query) => _showAddDialog(context, initialTitle: query),
      ),
    );
  }

  /// 원격 사전 작품 탭 → 로컬 .md 자동 아카이빙 후 상세 화면 이동
  Future<void> _archiveAndOpenRegistryWork(RegistryWork work) async {
    final newItem = await HomeRegistryArchive.persistRegistryWork(
      work,
      reloadItems: _loadItems,
      onDemoAdd: (item) => setState(() => _items.add(item)),
    );

    if (!mounted) return;
    _navigateToDetail(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${work.title}" 사전에서 아카이브에 추가되었습니다.')),
    );
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
      reloadItems: _loadItems,
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
