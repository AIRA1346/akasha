import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/sample_data.dart';
import '../models/dashboard_config.dart';
import '../services/file_service.dart';
import '../services/markdown_parser.dart';
import '../services/works_registry.dart';
import '../services/registry_sync_service.dart';
import '../services/image_cache_service.dart';
import '../utils/helpers.dart';
import '../widgets/web_image_search_dialog.dart';
import '../widgets/filter_section.dart';
import '../widgets/poster_card.dart';
import '../widgets/section_header.dart';
import '../widgets/star_rating.dart';
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

  // ── 필터 상태 ──
  AppDomain? _selectedDomain;
  final Set<MediaCategory> _selectedCategories = {}; // 변경: 다중 카테고리 지원
  final Set<String> _selectedWorkStatuses = {};
  final Set<String> _selectedMyStatuses = {};

  // ── 대시보드 리스트 및 활성 ID (Phase 11) ──
  List<DashboardConfig> _dashboards = [];
  String? _activeDashboardId;
  bool _isSidebarOpen = true;

  // ── 섹션별 정렬 상태 (Phase 10) ──
  SortCriteria _hofSortCriteria = SortCriteria.titleAsc;
  SortCriteria _librarySortCriteria = SortCriteria.titleAsc;
  SortCriteria _yearlySortCriteria = SortCriteria.titleAsc;
  SortCriteria _watchlistSortCriteria = SortCriteria.titleAsc;

  // ── 접이식 섹션 상태 ──
  bool _hofExpanded = true;
  bool _libraryExpanded = true;
  bool _yearlyExpanded = true;
  bool _watchlistExpanded = true;

  DashboardConfig? get _activeDashboard {
    if (_activeDashboardId == null || _dashboards.isEmpty) return null;
    return _dashboards.firstWhere(
      (d) => d.id == _activeDashboardId,
      orElse: () => _dashboards.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _initVault();
  }

  Future<void> _initVault() async {
    final service = AkashaFileService();
    await service.init();
    await _loadSidebarState(); // 사이드바 오픈 상태 로드
    await _loadDashboards();   // 대시보드 리스트 로드
    await _loadSortSettings(); // 정렬 설정 불러오기
    await _loadSectionExpandedStates(); // 접이식 섹션 상태 불러오기
    await _loadItems();
    
    // 첫 실행 시 사전 작품 로컬 자동 아카이빙 실행
    if (service.vaultPath != null) {
      await _autoArchiveRegistryWorks();
    }
    
    service.onVaultUpdated.listen((_) {
      if (mounted) {
        _loadItems();
      }
    });

    // 백그라운드 자동 동기화 시도 (Phase 4)
    _checkAutoSync();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final service = AkashaFileService();
    if (service.vaultPath != null) {
      final vaultItems = await service.loadAllItems();
      if (mounted) {
        setState(() {
          _items = vaultItems;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _items = buildSampleData();
          _isLoading = false;
        });
      }
    }
  }

  /// 글로벌 사전에 새로 올라온 작품이나 아카이빙되지 않은 사전을 마크다운 파일로 자동 생성합니다.
  Future<void> _autoArchiveRegistryWorks() async {
    final service = AkashaFileService();
    if (service.vaultPath == null) return;

    // 1. 현재 로컬 파일로 존재하는 모든 작품의 workId 수집
    final localWorkIds = _items
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // 2. 전체 레지스트리 작품 목록 가져오기
    final allRegistryWorks = WorksRegistry.getFilteredWorks();

    // 3. 존재하지 않는 작품들에 대해 기본 마크다운 생성
    int createdCount = 0;
    for (final work in allRegistryWorks) {
      if (!localWorkIds.contains(work.workId)) {
        final defaultMyStatus = '볼 예정';
        final defaultWorkStatus = work.category.isContentType
            ? ContentWorkStatus.completed.label
            : GameWorkStatus.released.label;

        final newItem = createItem(
          workId: work.workId,
          title: work.title,
          category: work.category,
          domain: work.domain,
          myStatus: defaultMyStatus,
          workStatus: defaultWorkStatus,
          creator: work.creator,
          releaseYear: work.releaseYear,
          rating: 0.0,
        );

        await service.saveItem(newItem);
        createdCount++;
      }
    }

    if (createdCount > 0) {
      debugPrint('Auto-archived $createdCount new works from registry.');
      // 새 파일들이 디스크에 작성되었으므로 다시 한 번 볼트 로드
      await _loadItems();
    }
  }

  // ── 필터링 & 정렬 로직 ──────────────────

  List<AkashaItem> get _filteredItems {
    // 1. 실제 사용자의 아카이브 데이터 필터링 (도메인, 카테고리 선 필터링)
    final userFiltered = _items.where((item) {
      if (_selectedDomain != null && item.domain != _selectedDomain) {
        return false;
      }
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(item.category)) {
        return false;
      }
      return true;
    }).toList();

    // 실제 등록된 작품의 workId 수집
    final userWorkIds = userFiltered
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // 2. 현재 도메인/카테고리 필터에 해당하는 사전(Registry) 작품 조회
    final List<RegistryWork> registryWorks = [];
    if (_selectedCategories.isEmpty) {
      registryWorks.addAll(WorksRegistry.getFilteredWorks(
        domain: _selectedDomain,
        category: null,
      ));
    } else {
      for (final cat in _selectedCategories) {
        registryWorks.addAll(WorksRegistry.getFilteredWorks(
          domain: _selectedDomain,
          category: cat,
        ));
      }
    }

    // 3. 사용자가 등록하지 않은 사전 작품들에 대해 가상 아이템 생성 및 병합
    final List<AkashaItem> fusedList = [...userFiltered];
    for (final work in registryWorks) {
      if (!userWorkIds.contains(work.workId)) {
        final defaultMyStatus = work.category.isContentType
            ? ContentMyStatus.notStarted.label
            : GameMyStatus.backlog.label;
        final defaultWorkStatus = work.category.isContentType
            ? ContentWorkStatus.completed.label
            : GameWorkStatus.released.label;

        final virtualItem = createItem(
          workId: work.workId,
          title: work.title,
          category: work.category,
          domain: work.domain,
          myStatus: defaultMyStatus,
          workStatus: defaultWorkStatus,
          creator: work.creator,
          releaseYear: work.releaseYear,
          rating: 0.0,
          posterPath: work.posterPath,
          description: work.description,
          tags: work.tags,
        );
        fusedList.add(virtualItem);
      }
    }

    // 4. 세부 상태 필터가 활성화된 경우 추가 필터링 수행
    var result = fusedList.where((item) {
      if (_selectedWorkStatuses.isNotEmpty &&
          !_selectedWorkStatuses.contains(item.workStatusLabel)) {
        return false;
      }
      if (_selectedMyStatuses.isNotEmpty &&
          !_selectedMyStatuses.contains(item.myStatusLabel)) {
        return false;
      }
      return true;
    }).toList();

    // 5. 정렬되지 않은 원본 필터 리스트 반환
    return result;
  }

  /// SharedPreferences에서 섹션별 정렬 상태 불러오기
  Future<void> _loadSortSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hofStr = prefs.getString('akasha_sort_hof');
      if (hofStr != null) {
        _hofSortCriteria = SortCriteria.values.firstWhere(
          (e) => e.name == hofStr,
          orElse: () => SortCriteria.titleAsc,
        );
      }

      final libStr = prefs.getString('akasha_sort_library');
      if (libStr != null) {
        _librarySortCriteria = SortCriteria.values.firstWhere(
          (e) => e.name == libStr,
          orElse: () => SortCriteria.titleAsc,
        );
      }

      final yearlyStr = prefs.getString('akasha_sort_yearly');
      if (yearlyStr != null) {
        _yearlySortCriteria = SortCriteria.values.firstWhere(
          (e) => e.name == yearlyStr,
          orElse: () => SortCriteria.titleAsc,
        );
      }

      final watchStr = prefs.getString('akasha_sort_watchlist');
      if (watchStr != null) {
        _watchlistSortCriteria = SortCriteria.values.firstWhere(
          (e) => e.name == watchStr,
          orElse: () => SortCriteria.titleAsc,
        );
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading sort settings: $e');
    }
  }

  /// SharedPreferences에 섹션별 정렬 상태 저장하기
  Future<void> _saveSortSetting(String sectionKey, SortCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('akasha_sort_$sectionKey', criteria.name);
    } catch (e) {
      debugPrint('Error saving sort setting for $sectionKey: $e');
    }
  }

  /// SharedPreferences에서 접이식 섹션들의 확장/축소 상태 불러오기
  Future<void> _loadSectionExpandedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hofExpanded = prefs.getBool('akasha_expanded_hof') ?? true;
      _libraryExpanded = prefs.getBool('akasha_expanded_library') ?? true;
      _yearlyExpanded = prefs.getBool('akasha_expanded_yearly') ?? true;
      _watchlistExpanded = prefs.getBool('akasha_expanded_watchlist') ?? true;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading expanded states: $e');
    }
  }

  /// SharedPreferences에 접이식 섹션들의 확장/축소 상태 저장하기
  Future<void> _saveSectionExpandedState(String sectionKey, bool expanded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('akasha_expanded_$sectionKey', expanded);
    } catch (e) {
      debugPrint('Error saving expanded state for $sectionKey: $e');
    }
  }

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

  Future<void> _loadDashboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dashJsonStr = prefs.getString('akasha_dashboards');
      final String? activeId = prefs.getString('akasha_active_dashboard_id');

      if (dashJsonStr != null) {
        final List<dynamic> decoded = jsonDecode(dashJsonStr);
        _dashboards = decoded.map((e) => DashboardConfig.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // 기본 대시보드 세트 구축
        _dashboards = [
          DashboardConfig(
            id: 'master_index',
            name: 'master_index',
            domain: null,
            categories: {},
          ),
          DashboardConfig(
            id: 'manga_dashboard',
            name: 'manga_dashboard',
            domain: AppDomain.subculture,
            categories: {MediaCategory.manga},
          ),
          DashboardConfig(
            id: 'game_dashboard',
            name: 'game_dashboard',
            domain: null,
            categories: {MediaCategory.game},
          ),
        ];
        await _saveDashboardsInternal(prefs);
      }

      if (activeId != null && _dashboards.any((d) => d.id == activeId)) {
        _activeDashboardId = activeId;
      } else {
        _activeDashboardId = _dashboards.first.id;
      }

      // 활성 대시보드의 필터 세팅 로드
      final active = _activeDashboard;
      if (active != null) {
        _selectedDomain = active.domain;
        _selectedCategories.clear();
        _selectedCategories.addAll(active.categories);
        _selectedWorkStatuses.clear();
        _selectedWorkStatuses.addAll(active.workStatuses);
        _selectedMyStatuses.clear();
        _selectedMyStatuses.addAll(active.myStatuses);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading dashboards: $e');
    }
  }

  Future<void> _saveDashboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveDashboardsInternal(prefs);
    } catch (e) {
      debugPrint('Error saving dashboards: $e');
    }
  }

  Future<void> _saveDashboardsInternal(SharedPreferences prefs) async {
    final String encoded = jsonEncode(_dashboards.map((e) => e.toJson()).toList());
    await prefs.setString('akasha_dashboards', encoded);
  }

  Future<void> _saveActiveDashboardId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('akasha_active_dashboard_id', id);
    } catch (e) {
      debugPrint('Error saving active dashboard ID: $e');
    }
  }

  void _selectDashboard(String id) {
    setState(() {
      _activeDashboardId = id;
      _saveActiveDashboardId(id);

      final active = _activeDashboard;
      if (active != null) {
        _selectedDomain = active.domain;
        _selectedCategories.clear();
        _selectedCategories.addAll(active.categories);
        _selectedWorkStatuses.clear();
        _selectedWorkStatuses.addAll(active.workStatuses);
        _selectedMyStatuses.clear();
        _selectedMyStatuses.addAll(active.myStatuses);
      }
    });
  }

  void _deleteDashboard(String id) {
    if (id == 'master_index') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ 대시보드 삭제'),
        content: const Text('이 대시보드 설정을 정말로 삭제하시겠습니까?\n아카이빙된 마크다운 파일은 유지되며, 대시보드 파일 뷰 목록에서만 제외됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _dashboards.removeWhere((d) => d.id == id);
                if (_activeDashboardId == id) {
                  _selectDashboard('master_index');
                }
              });
              _saveDashboards();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDashboardEditDialog(BuildContext context, DashboardConfig? config) async {
    final isNew = config == null;
    final nameCtrl = TextEditingController(text: config?.name ?? '');
    AppDomain? tempDomain = config?.domain;
    final Set<MediaCategory> tempCategories = config != null ? Set.from(config.categories) : {};
    final Set<String> tempMyStatuses = config != null ? Set.from(config.myStatuses) : {};
    final Set<String> tempWorkStatuses = config != null ? Set.from(config.workStatuses) : {};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          // 카테고리 선택에 따라 유효한 상태 옵션 수집
          final Set<String> availableWorkOpts = {};
          final Set<String> availableMyOpts = {};
          for (final cat in tempCategories.isEmpty ? MediaCategory.values : tempCategories) {
            availableWorkOpts.addAll(workStatusOptionsFor(cat));
            availableMyOpts.addAll(myStatusOptionsFor(cat));
          }

          // 유효하지 않은 상태 필터 소거
          tempWorkStatuses.retainAll(availableWorkOpts);
          tempMyStatuses.retainAll(availableMyOpts);

          return AlertDialog(
            title: Text(isNew ? '➕ 새 대시보드 추가' : '⚙️ 대시보드 설정 수정'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('대시보드 이름', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'manga_dashboard 등 입력...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('대분류 (도메인) 필터', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<AppDomain?>(
                      value: tempDomain,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('전체 도메인')),
                        ...AppDomain.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))),
                      ],
                      onChanged: (v) {
                        setD(() => tempDomain = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('소분류 (카테고리) 필터 (다중 선택 가능)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MediaCategory.values.map((cat) {
                        final isSelected = tempCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                          avatar: Icon(cat.icon, size: 12),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setD(() {
                              if (selected) {
                                tempCategories.add(cat);
                              } else {
                                tempCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('작품 상태 조건 필터 (다중 선택 가능)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableWorkOpts.map((status) {
                        final isSelected = tempWorkStatuses.contains(status);
                        return FilterChip(
                          label: Text(status, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setD(() {
                              if (selected) {
                                tempWorkStatuses.add(status);
                              } else {
                                tempWorkStatuses.remove(status);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('나의 상태 조건 필터 (다중 선택 가능)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableMyOpts.map((status) {
                        final isSelected = tempMyStatuses.contains(status);
                        return FilterChip(
                          label: Text(status, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setD(() {
                              if (selected) {
                                tempMyStatuses.add(status);
                              } else {
                                tempMyStatuses.remove(status);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  if (isNew) {
                    final newDash = DashboardConfig(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      domain: tempDomain,
                      categories: tempCategories,
                      myStatuses: tempMyStatuses,
                      workStatuses: tempWorkStatuses,
                    );
                    setState(() {
                      _dashboards.add(newDash);
                      _selectDashboard(newDash.id);
                    });
                  } else {
                    setState(() {
                      config.name = name;
                      config.domain = tempDomain;
                      config.categories = tempCategories;
                      config.myStatuses = tempMyStatuses;
                      config.workStatuses = tempWorkStatuses;

                      // 현재 수정 대상이 활성 대시보드라면 필터 변수 동기화
                      if (_activeDashboardId == config.id) {
                        _selectedDomain = tempDomain;
                        _selectedCategories.clear();
                        _selectedCategories.addAll(tempCategories);
                        _selectedWorkStatuses.clear();
                        _selectedWorkStatuses.addAll(tempWorkStatuses);
                        _selectedMyStatuses.clear();
                        _selectedMyStatuses.addAll(tempMyStatuses);
                      }
                    });
                  }
                  _saveDashboards();
                  Navigator.pop(ctx);
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AkashaItem> get _hallOfFameItems =>
      _filteredItems.where((i) => i.isHallOfFame).toList();

  void _onDomainChanged(AppDomain? domain) {
    setState(() {
      _selectedDomain = domain;
      _selectedCategories.clear();
      _selectedWorkStatuses.clear();
      _selectedMyStatuses.clear();

      final active = _activeDashboard;
      if (active != null) {
        active.domain = domain;
        active.categories = {};
        active.workStatuses = {};
        active.myStatuses = {};
        _saveDashboards();
      }
    });
  }

  void _toggleCategory(MediaCategory category) {
    setState(() {
      if (!_selectedCategories.remove(category)) {
        _selectedCategories.add(category);
      }
      _pruneInvalidStatuses();

      final active = _activeDashboard;
      if (active != null) {
        active.categories = Set.from(_selectedCategories);
        active.workStatuses = Set.from(_selectedWorkStatuses);
        active.myStatuses = Set.from(_selectedMyStatuses);
        _saveDashboards();
      }
    });
  }

  void _clearCategories() {
    setState(() {
      _selectedCategories.clear();
      _selectedWorkStatuses.clear();
      _selectedMyStatuses.clear();

      final active = _activeDashboard;
      if (active != null) {
        active.categories = {};
        active.workStatuses = {};
        active.myStatuses = {};
        _saveDashboards();
      }
    });
  }

  void _pruneInvalidStatuses() {
    if (_selectedCategories.isEmpty) {
      _selectedWorkStatuses.clear();
      _selectedMyStatuses.clear();
      return;
    }
    final Set<String> validWorkOpts = {};
    final Set<String> validMyOpts = {};
    for (final cat in _selectedCategories) {
      validWorkOpts.addAll(workStatusOptionsFor(cat));
      validMyOpts.addAll(myStatusOptionsFor(cat));
    }
    _selectedWorkStatuses.retainAll(validWorkOpts);
    _selectedMyStatuses.retainAll(validMyOpts);
  }

  void _toggleWorkStatus(String label) {
    setState(() {
      if (!_selectedWorkStatuses.remove(label)) {
        _selectedWorkStatuses.add(label);
      }

      final active = _activeDashboard;
      if (active != null) {
        active.workStatuses = Set.from(_selectedWorkStatuses);
        _saveDashboards();
      }
    });
  }

  void _toggleMyStatus(String label) {
    setState(() {
      if (!_selectedMyStatuses.remove(label)) {
        _selectedMyStatuses.add(label);
      }

      final active = _activeDashboard;
      if (active != null) {
        active.myStatuses = Set.from(_selectedMyStatuses);
        _saveDashboards();
      }
    });
  }

  void _navigateToDetail(AkashaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    ).then((_) => setState(() {})); // 돌아왔을 때 변경사항 반영
  }

  // ── 글로벌 작품 사전 동기화 메소드 ──

  Future<void> _checkAutoSync() async {
    final syncService = RegistrySyncService();
    if (await syncService.shouldAutoSync()) {
      setState(() => _isSyncing = true);
      final success = await syncService.sync();
      if (success) {
        await WorksRegistry.loadCachedRegistry();
        await _loadItems();
        await _autoArchiveRegistryWorks();
      }
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _syncRegistry() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    
    final success = await RegistrySyncService().sync();
    if (success) {
      await WorksRegistry.loadCachedRegistry();
      await _loadItems();
      await _autoArchiveRegistryWorks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('작품 사전 동기화 완료!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동기화 실패. 네트워크 연결 또는 URL 설정을 확인하세요.')),
        );
      }
    }
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _showCustomUrlDialog() async {
    final syncService = RegistrySyncService();
    final ctrl = TextEditingController(text: syncService.customDbUrl);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔗 커스텀 사전 DB URL 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원격 작품 사전 JSON 파일이 위치한 커스텀 URL을 지정합니다. 비워두면 기본 GitHub 저장소 주소로 재설정됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: '데이터베이스 JSON URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              await syncService.setCustomDbUrl(ctrl.text);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('동기화 주소가 변경되었습니다.')),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // ── 빌드 ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final hofItems = sortItems(_hallOfFameItems, _hofSortCriteria);
    final watchlistItems = sortItems(
      filtered.where((item) => item.myStatusLabel == '볼 예정').toList(),
      _watchlistSortCriteria,
    );
    final libraryItems = sortItems(
      filtered.where((item) => item.myStatusLabel != '볼 예정').toList(),
      _librarySortCriteria,
    );

    // ── 연도별 그룹화 연산 (Yearly Chronological Library) ──
    final Map<int, List<AkashaItem>> groupedByYear = {};
    final List<AkashaItem> noYearItems = [];
    for (final item in libraryItems) {
      if (item.releaseYear != null) {
        groupedByYear.putIfAbsent(item.releaseYear!, () => []).add(item);
      } else {
        noYearItems.add(item);
      }
    }
    final sortedYears = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));
    // 각 연도별 아이템 리스트를 _yearlySortCriteria로 다시 정렬
    for (final year in sortedYears) {
      groupedByYear[year] = sortItems(groupedByYear[year]!, _yearlySortCriteria);
    }
    final sortedNoYearItems = sortItems(noYearItems, _yearlySortCriteria);

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
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
              tooltip: '사이드바 토글 (Tab)',
              onPressed: () {
                setState(() {
                  _isSidebarOpen = !_isSidebarOpen;
                  _saveSidebarState(_isSidebarOpen);
                });
              },
            ),
            title: const Text(
              'A K A S H A',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: '검색',
                onPressed: () => _showSearchDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: 'AI 마크다운 가져오기',
                onPressed: () => _showClipboardImportDialog(),
              ),
              _isSyncing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: '글로벌 작품 사전 동기화 (길게 눌러 설정)',
                      onPressed: () => _syncRegistry(),
                      onLongPress: () => _showCustomUrlDialog(),
                    ),
              IconButton(
                icon: const Icon(Icons.copy_all),
                tooltip: 'AI 프롬프트 템플릿 복사',
                onPressed: () => _showPromptTemplatesDialog(),
              ),
              IconButton(
                icon: Icon(
                  AkashaFileService().vaultPath != null
                      ? Icons.folder
                      : Icons.folder_open_outlined,
                  color: AkashaFileService().vaultPath != null
                      ? Colors.tealAccent
                      : null,
                ),
                tooltip: '로컬 폴더(Vault) 설정',
                onPressed: () => _showVaultInfoDialog(),
              ),
            ],
          ),
          body: Row(
            children: [
              _buildSidebar(), // ── 좌측 반응형 설정 패널 ──
              Expanded(
                child: Column(
                  children: [
                    if (AkashaFileService().vaultPath == null)
                      Container(
                        width: double.infinity,
                        color: Colors.amber.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '현재 데모용 샘플 데이터를 보고 있습니다. 로컬 폴더(Obsidian Vault)를 연동하여 마크다운 파일로 실제 아카이빙을 시작해 보세요!',
                                style: TextStyle(fontSize: 12, color: Colors.amber),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () => _selectVaultFolder(),
                              icon: const Icon(Icons.folder_open, size: 16, color: Colors.amber),
                              label: const Text('폴더 연동', style: TextStyle(fontSize: 12, color: Colors.amber)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                side: const BorderSide(color: Colors.amber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ━━━ 필터 영역 ━━━
                    FilterSection(
                      selectedDomain: _selectedDomain,
                      selectedCategories: _selectedCategories,
                      selectedWorkStatuses: _selectedWorkStatuses,
                      selectedMyStatuses: _selectedMyStatuses,
                      onDomainChanged: _onDomainChanged,
                      onToggleCategory: _toggleCategory,
                      onClearCategories: _clearCategories,
                      onToggleWorkStatus: _toggleWorkStatus,
                      onToggleMyStatus: _toggleMyStatus,
                    ),
                    const Divider(height: 1),

          // ━━━ 스크롤 가능한 메인 콘텐츠 ━━━
          Expanded(
            child: filtered.isEmpty
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
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      // ── 1. S-Tier 인생 명작 컬렉션 (Hall of Fame) ──
                      if (hofItems.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            final newVal = !_hofExpanded;
                            setState(() => _hofExpanded = newVal);
                            _saveSectionExpandedState('hof', newVal);
                          },
                          child: SectionHeader(
                            emoji: '👑',
                            title: 'S-Tier 인생 명작 컬렉션 (Hall of Fame)',
                            titleColor: const Color(0xFFFFD700),
                            isExpanded: _hofExpanded,
                            trailing: _buildSectionSortDropdown(
                              currentCriteria: _hofSortCriteria,
                              onChanged: (val) {
                                setState(() => _hofSortCriteria = val);
                                _saveSortSetting('hof', val);
                              },
                            ),
                          ),
                        ),
                        if (_hofExpanded)
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: hofItems.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 165,
                                  child: PosterCard(
                                    item: hofItems[i],
                                    onTap: () =>
                                        _navigateToDetail(hofItems[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // ── 2. 전체 작품 라이브러리 (All Consumed Works) ──
                      if (libraryItems.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            final newVal = !_libraryExpanded;
                            setState(() => _libraryExpanded = newVal);
                            _saveSectionExpandedState('library', newVal);
                          },
                          child: SectionHeader(
                            emoji: '📚',
                            title: '전체 작품 라이브러리 (All Consumed Works)',
                            titleColor: const Color(0xFFF09819),
                            subtitle:
                                '${libraryItems.length}개의 작품이 아카이브되어 있습니다.',
                            isExpanded: _libraryExpanded,
                            trailing: _buildSectionSortDropdown(
                              currentCriteria: _librarySortCriteria,
                              onChanged: (val) {
                                setState(() => _librarySortCriteria = val);
                                _saveSortSetting('library', val);
                              },
                            ),
                          ),
                        ),
                        if (_libraryExpanded)
                          _buildGrid(libraryItems),
                        const SizedBox(height: 16),
                      ],

                      // ── 3. 연도별 라이브러리 (Yearly Chronological Library) ──
                      if (libraryItems.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            final newVal = !_yearlyExpanded;
                            setState(() => _yearlyExpanded = newVal);
                            _saveSectionExpandedState('yearly', newVal);
                          },
                          child: SectionHeader(
                            emoji: '🗓️',
                            title: '연도별 라이브러리 (Yearly Chronological Library)',
                            titleColor: const Color(0xFFF09819),
                            subtitle:
                                '출시 연도별로 크로놀로지컬하게 정렬된 라이브러리입니다.',
                            isExpanded: _yearlyExpanded,
                            trailing: _buildSectionSortDropdown(
                              currentCriteria: _yearlySortCriteria,
                              onChanged: (val) {
                                setState(() => _yearlySortCriteria = val);
                                _saveSortSetting('yearly', val);
                              },
                            ),
                          ),
                        ),
                        if (_yearlyExpanded) ...[
                          for (final year in sortedYears) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
                              child: Row(
                                children: [
                                  Text(
                                    '🗓️ $year년',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${groupedByYear[year]!.length}개 작품)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGrid(groupedByYear[year]!),
                          ],
                          if (noYearItems.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
                              child: Row(
                                children: [
                                  const Text(
                                    '🗓️ 연도 미지정',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${noYearItems.length}개 작품)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGrid(sortedNoYearItems),
                          ],
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ── 4. 감상 예정 보관함 (Watchlist) ──
                      GestureDetector(
                        onTap: () {
                          final newVal = !_watchlistExpanded;
                          setState(() => _watchlistExpanded = newVal);
                          _saveSectionExpandedState('watchlist', newVal);
                        },
                        child: SectionHeader(
                          emoji: '⌛',
                          title: '감상 예정 보관함 (Watchlist)',
                          titleColor: const Color(0xFFF09819),
                          subtitle:
                              '지석 님이 감상하기 위해 아껴두었거나, 나중에 꼭 감상하여 아카이빙할 예정인 작품 리스트입니다. 작품 문서 내에 status: "볼 예정"으로 설정하시면 자동으로 이 리스트에 꽂히게 됩니다.',
                          isExpanded: _watchlistExpanded,
                          trailing: _buildSectionSortDropdown(
                            currentCriteria: _watchlistSortCriteria,
                            onChanged: (val) {
                              setState(() => _watchlistSortCriteria = val);
                              _saveSortSetting('watchlist', val);
                            },
                          ),
                        ),
                      ),
                      if (_watchlistExpanded) ...[
                        if (watchlistItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 44,
                                    color: Colors.amber.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '아직 감상 예정 보관함이 비어 있습니다.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '새로운 작품을 추가하거나 작품 편집에서 나의 상태를 "볼 예정"으로 설정하면 자동으로 이곳에 정렬됩니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          _buildGrid(watchlistItems),
                      ],
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
    )));
  }

  // ── 섹션별 정렬 선택 드롭다운 (Phase 10) ──
  Widget _buildSectionSortDropdown({
    required SortCriteria currentCriteria,
    required ValueChanged<SortCriteria> onChanged,
  }) {
    return GestureDetector(
      onTap: () {}, // 클릭 이벤트가 부모 GestureDetector(섹션 접기/펼치기)로 전파되지 않도록 방지
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SortCriteria>(
            value: currentCriteria,
            isDense: true,
            icon: const Icon(Icons.sort, size: 14, color: Colors.grey),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            dropdownColor: const Color(0xFF2A2A3E),
            items: SortCriteria.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }

  // ── 포스터 카드 그리드 ──

  Widget _buildGrid(List<AkashaItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형: 화면 너비에 따라 열 수 자동 계산
        const cardMinWidth = 170.0;
        final crossAxisCount =
            (constraints.maxWidth / cardMinWidth).floor().clamp(2, 8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.50,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => PosterCard(
            item: items[i],
            onTap: () => _navigateToDetail(items[i]),
          ),
        );
      },
    );
  }

  // ── 검색 다이얼로그 ──

  Future<void> _showSearchDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    List<AkashaItem> results = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('🔍 작품 검색'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '제목, 작가, 태그로 검색...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    final q = query.toLowerCase();
                    setD(() {
                      results = _items.where((item) {
                        return item.title.toLowerCase().contains(q) ||
                            item.creator.toLowerCase().contains(q) ||
                            item.tags.any((t) => t.toLowerCase().contains(q));
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: results.isEmpty && ctrl.text.isNotEmpty
                      ? const Center(child: Text('결과 없음'))
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final item = results[i];
                            return ListTile(
                              leading: Icon(item.category.icon),
                              title: Text(item.title),
                              subtitle: Text(item.creator),
                              trailing: StarRating(
                                  rating: item.rating, size: 12),
                              onTap: () {
                                Navigator.pop(ctx);
                                _navigateToDetail(item);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 신규 등록 다이얼로그 ──
  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final posterUrlCtrl = TextEditingController();
    AppDomain selDomain = AppDomain.subculture;
    MediaCategory selCategory = MediaCategory.manga;
    String selWork = workStatusOptionsFor(selCategory).first;
    String selMy = myStatusOptionsFor(selCategory).first;
    double selRating = 0.0;
    RegistryWork? selectedRegistryWork;

    final result = await showDialog<AkashaItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final workOpts = workStatusOptionsFor(selCategory);
          final myOpts = myStatusOptionsFor(selCategory);

          if (!workOpts.contains(selWork)) selWork = workOpts.first;
          if (!myOpts.contains(selMy)) selMy = myOpts.first;

          final bool isPreRegistered = selectedRegistryWork != null;

          return AlertDialog(
            title: const Text('새 작품 등록 (아카이브 추가)'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ━━ 작품 사전 검색 ━━
                    const Text('공통 작품 사전 검색',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Autocomplete<RegistryWork>(
                      displayStringForOption: (option) =>
                          '${option.title} (${option.category.label})',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return WorksRegistry.search(textEditingValue.text);
                      },
                      onSelected: (RegistryWork selection) {
                        setD(() {
                          selectedRegistryWork = selection;
                          titleCtrl.text = selection.title;
                          creatorCtrl.text = selection.creator;
                          yearCtrl.text = selection.releaseYear?.toString() ?? '';
                          posterUrlCtrl.text = selection.posterPath ?? '';
                          selCategory = selection.category;
                          selDomain = selection.domain;
                        });
                      },
                      fieldViewBuilder:
                          (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: '사전에서 작품을 검색하여 선택해 보세요...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: selectedRegistryWork != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      textEditingController.clear();
                                      setD(() {
                                        selectedRegistryWork = null;
                                        titleCtrl.clear();
                                        creatorCtrl.clear();
                                        yearCtrl.clear();
                                        posterUrlCtrl.clear();
                                        selDomain = AppDomain.subculture;
                                      });
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 제목
                    TextField(
                      controller: titleCtrl,
                      enabled: !isPreRegistered, // 사전에 있으면 수정 불가 (정합성)
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 작가
                    TextField(
                      controller: creatorCtrl,
                      enabled: !isPreRegistered,
                      decoration: const InputDecoration(
                        labelText: '작가 / 제작사',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 연도
                    TextField(
                      controller: yearCtrl,
                      enabled: !isPreRegistered,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '출시 연도',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 포스터 이미지
                    const Text('포스터 이미지 (웹 URL 또는 로컬 파일)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: posterUrlCtrl,
                            decoration: InputDecoration(
                              hintText: 'https://... 또는 로컬 경로 입력',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.folder_open),
                                tooltip: '로컬 이미지 파일 선택',
                                onPressed: () async {
                                  final fileResult = await FilePicker.pickFiles(
                                    type: FileType.image,
                                  );
                                  if (fileResult != null && fileResult.files.single.path != null) {
                                    final path = fileResult.files.single.path!;
                                    final service = AkashaFileService();
                                    if (service.vaultPath != null) {
                                      final relativePath = await service.importPosterImage(path);
                                      if (relativePath != null) {
                                        posterUrlCtrl.text = relativePath;
                                      }
                                    } else {
                                      posterUrlCtrl.text = path;
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.image_search),
                          tooltip: '인터넷 이미지 검색',
                          onPressed: () async {
                            final selectedUrl = await showDialog<String>(
                              context: context,
                              builder: (ctx) => WebImageSearchDialog(
                                initialQuery: titleCtrl.text,
                                category: selCategory,
                              ),
                            );
                            if (selectedUrl != null) {
                              posterUrlCtrl.text = selectedUrl;
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 별점 (유저 고유 기록)
                    const Text('나의 별점',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    InteractiveStarRating(
                      rating: selRating,
                      onChanged: (v) => setD(() => selRating = v),
                    ),
                    const SizedBox(height: 18),

                    // 대분류 (도메인)
                    const Text('대분류 (도메인)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<AppDomain>(
                      value: selDomain,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: isPreRegistered
                          ? [
                              DropdownMenuItem(
                                value: selDomain,
                                child: Row(
                                  children: [
                                    Icon(selDomain.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(selDomain.label),
                                  ],
                                ),
                              )
                            ]
                          : AppDomain.values
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        Icon(d.icon, size: 18),
                                        const SizedBox(width: 8),
                                        Text(d.label),
                                      ],
                                    ),
                                  ))
                              .toList(),
                      onChanged: isPreRegistered
                          ? null
                          : (v) {
                              if (v != null) {
                                setD(() {
                                  selDomain = v;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 14),

                    // 카테고리
                    const Text('카테고리',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<MediaCategory>(
                      value: selCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: isPreRegistered
                          ? [
                              DropdownMenuItem(
                                value: selCategory,
                                child: Row(
                                  children: [
                                    Icon(selCategory.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(selCategory.label),
                                  ],
                                ),
                              )
                            ]
                          : MediaCategory.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Row(
                                      children: [
                                        Icon(c.icon, size: 18),
                                        const SizedBox(width: 8),
                                        Text(c.label),
                                      ],
                                    ),
                                  ))
                              .toList(),
                      onChanged: isPreRegistered
                          ? null
                          : (v) {
                              if (v != null) {
                                setD(() {
                                  selCategory = v;
                                  selWork = workStatusOptionsFor(v).first;
                                  selMy = myStatusOptionsFor(v).first;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 14),

                    // 작품 상태 (유저 고유 기록)
                    const Text('작품 상태',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('add_work_${selCategory.name}'),
                      value: selWork,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: workOpts
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setD(() => selWork = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    // 나의 상태 (유저 고유 기록)
                    const Text('나의 상태',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('add_my_${selCategory.name}'),
                      value: selMy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: myOpts
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setD(() => selMy = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('제목을 입력해 주세요.')),
                    );
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    createItem(
                      workId: selectedRegistryWork?.workId ?? '',
                      title: title,
                      category: selCategory,
                      domain: selDomain,
                      workStatus: selWork,
                      myStatus: selMy,
                      creator: creatorCtrl.text.trim(),
                      releaseYear: int.tryParse(yearCtrl.text.trim()),
                      rating: selRating,
                      posterPath: posterUrlCtrl.text.trim().isNotEmpty ? posterUrlCtrl.text.trim() : null,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('등록'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final service = AkashaFileService();
      if (service.vaultPath != null) {
        await service.saveItem(result);
        
        // 원격 이미지 등록 시 즉각 백그라운드 캐시 다운로드 예약
        if (result.posterPath != null && result.posterPath!.startsWith('http')) {
          ImageCacheService().cachePosterImage(result.workId, result.posterPath);
        }
        
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

  // ── 볼트 정보 다이얼로그 ──
  Future<void> _showVaultInfoDialog() async {
    final service = AkashaFileService();
    final path = service.vaultPath;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📂 로컬 볼트(Vault) 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              path != null
                  ? '현재 연동된 폴더:\n$path'
                  : '연동된 폴더가 없습니다. 마크다운 파일로 영속적으로 기록하려면 Obsidian Vault 폴더를 연동해 주세요.',
              style: const TextStyle(fontSize: 13),
            ),
            if (path != null) ...[
              const SizedBox(height: 12),
              const Text(
                '※ 이 폴더의 하위에 manga, game, book 등 카테고리별 마크다운 파일이 생성 및 수정됩니다.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          if (path != null)
            TextButton(
              onPressed: () async {
                await service.setVaultPath('');
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadItems();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('연동 해제'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _selectVaultFolder();
            },
            child: Text(path != null ? '폴더 변경' : '폴더 연동'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // ── AI 마크다운 가져오기 다이얼로그 ──
  Future<void> _showClipboardImportDialog() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final ctrl = TextEditingController(text: text);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🤖 AI 마크다운 가져오기'),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI가 생성한 마크다운 텍스트를 여기에 붙여넣으세요. 파싱하여 작품 목록에 추가합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '---\ntitle: "작품명"\n...',
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final content = ctrl.text.trim();
              if (content.isEmpty) return;
              try {
                final item = MarkdownParser.deserialize(content, '이름 없는 작품');
                final service = AkashaFileService();
                if (service.vaultPath != null) {
                  await service.saveItem(item);
                  await _loadItems();
                } else {
                  setState(() {
                    _items.add(item);
                  });
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${item.title}" 작품이 성공적으로 추가되었습니다.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('파싱에 실패했습니다: $e')),
                );
              }
            },
            child: const Text('파싱 및 가져오기'),
          ),
        ],
      ),
    );
  }

  // ── AI 프롬프트 템플릿 다이얼로그 ──
  Future<void> _showPromptTemplatesDialog() async {
    const template = '''
당신은 서브컬처(만화, 게임, 애니메이션, 책) 아카이빙 전문가입니다.
사용자가 요청한 작품의 정보를 아래 YAML Front-Matter 형식을 포함한 마크다운 문서로 작성해 주세요.

---
title: "작품의 정확한 제목"
category: manga | game | animation | book (카테고리에 맞게 하나만 선택)
domain: subculture | generalCulture (대분류에 맞게 하나만 선택)
creator: "원작자 / 제작사 / 감독 등"
release_year: 출시 또는 연재 시작 연도 (숫자만, 예: 2011)
rating: 5.0 (0.0~5.0 범위의 실수)
work_status: "연재중" | "휴재중" | "완결" (game 카테고리인 경우: "출시됨" | "얼리액세스" | "출시예정")
my_status: "아직 안 봄" | "보는 중" | "전부 봄" | "하차함" (game 카테고리인 경우: "할 예정(백로그)" | "플레이 중" | "클리어함" | "중도하차")
is_hall_of_fame: true | false (인생 명작 여부)
tags: [태그1, 태그2] (예: [청춘, 감동, 음악])
poster: "" (비워둠)
added_at: "현재 날짜 및 시간 (ISO 8601 형식, 예: 2026-06-05T19:00:00)"
---

# 📝 작품 특징
(작품의 줄거리, 특징, 추천 이유 등을 마크다운으로 작성)

# 🎬 명장면 & 명대사
> "명대사 내용 1" — 캐릭터 이름 / 상황 설명 (화수 등)

> "명대사 내용 2" — 캐릭터 이름 / 상황 설명

# 📖 감상문
(작품에 대한 감상문을 자유롭게 작성)
''';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📋 AI 프롬프트 템플릿'),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 템플릿을 AI에게 제공하면, 규격에 맞는 마크다운을 쉽게 받아올 수 있습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      template,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: template));
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('템플릿이 클립보드에 복사되었습니다.')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('복사하기'),
          ),
        ],
      ),
    );
  }

  // ── 사이드바 UI 빌드 ──
  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isSidebarOpen ? 260.0 : 0.0,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2F),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2D44), width: 1.5),
        ),
      ),
      child: _isSidebarOpen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.library_books, color: Colors.tealAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '대시보드 서재',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined, size: 20, color: Colors.grey),
                        tooltip: '새 대시보드 추가',
                        onPressed: () => _showDashboardEditDialog(context, null),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2D2D44), height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _dashboards.length,
                    itemBuilder: (context, index) {
                      final dash = _dashboards[index];
                      final isActive = dash.id == _activeDashboardId;
                      return SidebarItemWidget(
                        dash: dash,
                        isActive: isActive,
                        onTap: () => _selectDashboard(dash.id),
                        onEdit: () => _showDashboardEditDialog(context, dash),
                        onDelete: () => _deleteDashboard(dash.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A26),
                    border: Border(top: BorderSide(color: Color(0xFF2D2D44))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D44),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: const Text(
                          'Tab',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '키를 눌러 사이드바 토글',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── 사이드바 대시보드 아이템 호버 처리용 개별 위젯 (Phase 11) ──
class SidebarItemWidget extends StatefulWidget {
  final DashboardConfig dash;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SidebarItemWidget({
    super.key,
    required this.dash,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2A2A3E)
              : _isHovered
                  ? const Color(0xFF222235)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.0)
              : Border.all(color: Colors.transparent, width: 1.0),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  widget.dash.categories.isNotEmpty
                      ? widget.dash.categories.first.icon
                      : widget.dash.domain != null
                          ? widget.dash.domain!.icon
                          : Icons.dashboard_outlined,
                  size: 16,
                  color: isActive ? Colors.tealAccent : Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.dash.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.grey[300],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.dash.id != 'master_index' && (_isHovered || isActive)) ...[
                  IconButton(
                    icon: const Icon(Icons.settings, size: 14, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onEdit,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 14, color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
