import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/sample_data.dart';
import '../services/file_service.dart';
import '../services/markdown_parser.dart';
import '../services/works_registry.dart';
import '../services/registry_sync_service.dart';
import '../utils/helpers.dart';
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
  MediaCategory? _selectedCategory;
  final Set<String> _selectedWorkStatuses = {};
  final Set<String> _selectedMyStatuses = {};
  SortCriteria _sortCriteria = SortCriteria.titleAsc;

  // ── 접이식 섹션 상태 ──
  bool _hofExpanded = true;
  bool _libraryExpanded = true;
  bool _yearlyExpanded = true;
  bool _watchlistExpanded = true;

  @override
  void initState() {
    super.initState();
    _initVault();
  }

  Future<void> _initVault() async {
    final service = AkashaFileService();
    await service.init();
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
      if (_selectedCategory != null && item.category != _selectedCategory) {
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
    final registryWorks = WorksRegistry.getFilteredWorks(
      domain: _selectedDomain,
      category: _selectedCategory,
    );

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

    // 5. 정렬하여 반환
    return sortItems(result, _sortCriteria);
  }

  List<AkashaItem> get _hallOfFameItems =>
      _filteredItems.where((i) => i.isHallOfFame).toList();

  void _onDomainChanged(AppDomain? domain) {
    setState(() {
      _selectedDomain = domain;
      _selectedCategory = null;
      _selectedWorkStatuses.clear();
      _selectedMyStatuses.clear();
    });
  }

  void _onCategoryChanged(MediaCategory? category) {
    setState(() {
      _selectedCategory = category;
      _selectedWorkStatuses.clear();
      _selectedMyStatuses.clear();
    });
  }

  void _toggleWorkStatus(String label) {
    setState(() {
      if (!_selectedWorkStatuses.remove(label)) {
        _selectedWorkStatuses.add(label);
      }
    });
  }

  void _toggleMyStatus(String label) {
    setState(() {
      if (!_selectedMyStatuses.remove(label)) {
        _selectedMyStatuses.add(label);
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
    final hofItems = _hallOfFameItems;
    final watchlistItems = filtered.where((item) => item.myStatusLabel == '볼 예정').toList();
    final libraryItems = filtered.where((item) => item.myStatusLabel != '볼 예정').toList();

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

    return Scaffold(
      appBar: AppBar(
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
      body: Column(
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
            selectedCategory: _selectedCategory,
            selectedWorkStatuses: _selectedWorkStatuses,
            selectedMyStatuses: _selectedMyStatuses,
            sortCriteria: _sortCriteria,
            onDomainChanged: _onDomainChanged,
            onCategoryChanged: _onCategoryChanged,
            onToggleWorkStatus: _toggleWorkStatus,
            onToggleMyStatus: _toggleMyStatus,
            onSortChanged: (v) => setState(() => _sortCriteria = v),
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
                          onTap: () =>
                              setState(() => _hofExpanded = !_hofExpanded),
                          child: SectionHeader(
                            emoji: '👑',
                            title: 'S-Tier 인생 명작 컬렉션 (Hall of Fame)',
                            titleColor: const Color(0xFFFFD700),
                            isExpanded: _hofExpanded,
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
                          onTap: () =>
                              setState(() => _libraryExpanded = !_libraryExpanded),
                          child: SectionHeader(
                            emoji: '📚',
                            title: '전체 작품 라이브러리 (All Consumed Works)',
                            titleColor: const Color(0xFFF09819),
                            subtitle:
                                '${libraryItems.length}개의 작품이 아카이브되어 있습니다.',
                            isExpanded: _libraryExpanded,
                          ),
                        ),
                        if (_libraryExpanded)
                          _buildGrid(libraryItems),
                        const SizedBox(height: 16),
                      ],

                      // ── 3. 연도별 라이브러리 (Yearly Chronological Library) ──
                      if (libraryItems.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () =>
                              setState(() => _yearlyExpanded = !_yearlyExpanded),
                          child: SectionHeader(
                            emoji: '🗓️',
                            title: '연도별 라이브러리 (Yearly Chronological Library)',
                            titleColor: const Color(0xFFF09819),
                            subtitle:
                                '출시 연도별로 크로놀로지컬하게 정렬된 라이브러리입니다.',
                            isExpanded: _yearlyExpanded,
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
                            _buildGrid(noYearItems),
                          ],
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ── 4. 감상 예정 보관함 (Watchlist) ──
                      if (watchlistItems.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () =>
                              setState(() => _watchlistExpanded = !_watchlistExpanded),
                          child: SectionHeader(
                            emoji: '⌛',
                            title: '감상 예정 보관함 (Watchlist)',
                            titleColor: const Color(0xFFF09819),
                            subtitle:
                                '지석 님이 감상하기 위해 아껴두었거나, 나중에 꼭 감상하여 아카이빙할 예정인 작품 리스트입니다. 작품 문서 내에 status: "볼 예정"으로 설정하시면 자동으로 이 리스트에 꽂히게 됩니다.',
                            isExpanded: _watchlistExpanded,
                            trailing: Text(
                              '정렬 기준 : 🆕 ${_sortCriteria.label}  ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        if (_watchlistExpanded)
                          _buildGrid(watchlistItems),
                      ],
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
}
