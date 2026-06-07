import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/library_theme.dart';
import '../services/entitlement_service.dart';
import '../services/file_service.dart';
import '../services/my_library_pipeline.dart';
import '../utils/helpers.dart';
import '../widgets/browse_poster_grid.dart';
import '../widgets/poster_card.dart';
import 'detail_screen.dart';

/// 나의 서재 — 볼트에 아카이브한 작품만 모아 보는 전용 화면 (v1 무료)
class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  static const _themePrefsKey = 'akasha_library_theme_id';

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
    await _loadThemePreference();
    await _loadItems();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_themePrefsKey);
    final theme = LibraryTheme.byId(savedId ?? '') ?? LibraryTheme.classic;
    if (mounted) setState(() => _theme = theme);
  }

  Future<void> _saveTheme(LibraryTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, theme.id);
    if (mounted) setState(() => _theme = theme);
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
    final entitlements = EntitlementService.instance;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '서재 테마',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '기본 테마는 무료 · 프리미엄 테마는 Steam IAP (출시 예정)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                ...LibraryTheme.all.map((theme) {
                  final locked = !entitlements.canUseTheme(theme);
                  final selected = _theme.id == theme.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.backgroundColor,
                      child: Icon(
                        locked ? Icons.lock_outline : Icons.palette_outlined,
                        color: theme.accentColor,
                        size: 18,
                      ),
                    ),
                    title: Text(theme.name),
                    trailing: selected
                        ? Icon(Icons.check, color: theme.accentColor)
                        : null,
                    onTap: () async {
                      if (locked) {
                        Navigator.pop(ctx);
                        await _promptIapPurchase(theme);
                        return;
                      }
                      await _saveTheme(theme);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptIapPurchase(LibraryTheme theme) async {
    final bought = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프리미엄 서재 테마'),
        content: Text(
          '「${theme.name}」 테마는 서재 꾸미기 팩(IAP)에 포함됩니다.\n'
          'Steam 출시 시 인앱 구매로 해제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('구매 (준비 중)'),
          ),
        ],
      ),
    );

    if (bought != true || !mounted) return;

    final success = await EntitlementService.instance
        .purchase(EntitlementService.libraryThemePackId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '구매가 완료되었습니다.'
              : 'Steam IAP 연동 전입니다. 출시 빌드에서 활성화됩니다.',
        ),
      ),
    );
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
              'Obsidian 볼트에 저장한 작품만 이곳에 모입니다.\n'
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
