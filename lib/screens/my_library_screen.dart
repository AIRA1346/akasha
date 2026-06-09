import 'package:flutter/material.dart';

import '../../models/library_theme.dart';
import '../../services/entitlement_service.dart';
import '../../services/file_service.dart';
import '../../services/library_theme_preferences.dart';
import '../../services/my_library_pipeline.dart';
import '../../utils/helpers.dart';
import '../../widgets/browse_poster_grid.dart';
import '../../widgets/library_theme_picker.dart';
import '../../widgets/poster_card.dart';
import 'detail_screen.dart';

/// @deprecated v1 통합 홈(`HomeScreen` 나만의 서재 모드)으로 대체. QA·레거시 참조용.
/// 나의 서재 — 볼트에 아카이브한 작품만 모아 보는 전용 화면 (v1 무료)
class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  List<AkashaItem> _items = [];
  bool _isLoading = true;
  SortCriteria _sortCriteria = SortCriteria.titleAsc;
  LibraryTheme _theme = LibraryTheme.classic;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await EntitlementService.instance.load();
    _theme = await LibraryThemePreferences.load();
    await _loadItems();
    if (mounted) setState(() {});
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final service = AkashaFileService();
    List<AkashaItem> loaded = [];
    if (service.vaultPath != null) {
      loaded = await service.loadAllItems();
    } else {
      loaded = List<AkashaItem>.from(service.inMemoryCache.values);
    }
    if (mounted) {
      setState(() {
        _items = loaded;
        _isLoading = false;
      });
    }
  }

  List<BrowseCard> get _libraryCards {
    final cards = MyLibraryPipeline.build(_items);
    return sortBrowseCards(cards, _sortCriteria);
  }

  void _navigateToDetail(AkashaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    ).then((_) => _loadItems());
  }

  Widget _buildPosterCard(BrowseCard card) {
    return PosterCard(
      item: card.item,
      formatSlots: card.formatSlots,
      franchiseId: card.franchiseId,
      onTap: () => _navigateToDetail(card.item),
    );
  }

  Future<void> _showThemePicker() async {
    final picked = await showLibraryThemePicker(context, current: _theme);
    if (picked != null && mounted) setState(() => _theme = picked);
  }

  @override
  Widget build(BuildContext context) {
    final vaultLinked = AkashaFileService().vaultPath != null;
    final cards = _libraryCards;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _theme.backgroundColor,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              secondary: _theme.accentColor,
            ),
      ),
      child: Scaffold(
        backgroundColor: _theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _theme.backgroundColor,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.collections_bookmark,
                  size: 22, color: _theme.accentColor),
              const SizedBox(width: 10),
              const Text('나의 서재'),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.palette_outlined, color: _theme.accentColor),
              tooltip: '서재 테마',
              onPressed: _showThemePicker,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _theme.accentColor,
                ),
              )
            : !vaultLinked
                ? _buildConnectVaultPrompt()
                : cards.isEmpty
                    ? _buildEmptyLibrary()
                    : _buildLibraryGrid(cards),
      ),
    );
  }

  Widget _buildConnectVaultPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 56, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              '볼트를 연동하면 나의 서재가 열립니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sanctum 볼트에 저장한 작품만 이곳에 모입니다.\n'
              '홈 화면에서 폴더를 연동해 주세요.',
              style: TextStyle(color: Colors.grey[500], height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLibrary() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              '아직 아카이브한 작품이 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '검색으로 작품을 추가하거나\n'
              '「새 작품」으로 직접 등록해 보세요.',
              style: TextStyle(color: Colors.grey[500], height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryGrid(List<BrowseCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${cards.length}개 작품',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const Spacer(),
              _buildSortDropdown(),
            ],
          ),
        ),
        Expanded(
          child: BrowsePosterGrid(
            cards: cards,
            cardBuilder: _buildPosterCard,
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortCriteria>(
          value: _sortCriteria,
          dropdownColor: const Color(0xFF2A2A3E),
          style: const TextStyle(fontSize: 12, color: Colors.white70),
          items: const [
            DropdownMenuItem(
              value: SortCriteria.titleAsc,
              child: Text('제목 ↑'),
            ),
            DropdownMenuItem(
              value: SortCriteria.ratingDesc,
              child: Text('평점 ↓'),
            ),
            DropdownMenuItem(
              value: SortCriteria.recentlyAdded,
              child: Text('최근 추가'),
            ),
            DropdownMenuItem(
              value: SortCriteria.yearDesc,
              child: Text('연도 ↓'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _sortCriteria = val);
          },
        ),
      ),
    );
  }
}
