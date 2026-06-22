import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../home/home_poster_card_factory.dart';
import '../../../widgets/universe_orbit_painter.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/archiving/entity_anchor.dart';
import 'dashboard_preview_panel.dart';

/// 시안 사진과 동일한 프리미엄 홈 대시보드 마스터 뷰.
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.onOpenWork,
    required this.onOpenEntity,
    required this.onSearch,
    required this.onTimeline,
    required this.onGraph,
    required this.onExploreEntities,
    this.selectedPreviewItem,
    this.onPreviewItem,
    this.onClosePreview,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final void Function(AkashaItem) onOpenWork;
  final void Function(UserCatalogEntity) onOpenEntity;
  final VoidCallback onSearch;
  final VoidCallback onTimeline;
  final VoidCallback onGraph;
  final VoidCallback onExploreEntities;
  final AkashaItem? selectedPreviewItem;
  final void Function(AkashaItem)? onPreviewItem;
  final VoidCallback? onClosePreview;

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  int _activeDiscoveryTab = 0;
  AkashaItem? _selectedPreviewItem; // 0: 추천 연결, 1: 새로운 작품, 2: 주목할 인물

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F111A), // 매우 어두운 네이비톤 배경
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopSearchBar(),
                  const SizedBox(height: 40),
                  _buildWelcomeHeader(),
                  const SizedBox(height: 28),
                  _buildContinueExploring(),
                  const SizedBox(height: 40),
                  _buildDiscoveryJourney(),
                  const SizedBox(height: 40),
                  _buildUniverseAndRecentlyAdded(),
                  const SizedBox(height: 40),
                  _buildQuickActions(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (_selectedPreviewItem != null)
            DashboardPreviewPanel(
              item: _selectedPreviewItem!,
              onClose: () => setState(() => _selectedPreviewItem = null),
              onOpenDetail: () => widget.onOpenWork(_selectedPreviewItem!),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '인물':
        return const Color(0xFF00E5FF);
      case '개념':
        return const Color(0xFFFFB74D);
      case '장소':
        return const Color(0xFF81C784);
      case '사건':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  Widget _buildTopSearchBar() {
    return Row(
      children: [
        // 1. 검색 인풋창 (옵시디언/노션 스타일)
        Expanded(
          child: GestureDetector(
            onTap: widget.onSearch,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161824),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '작품, 인물, 사건, 장소, 개념을 검색하세요...',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      'Ctrl K',
                      style: TextStyle(fontSize: 9, color: Colors.grey[500], fontFamily: 'Consolas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 2. 테마 단추 (라이트/다크)
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.grey[400]),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        // 3. 종 단추 (알림)
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_none_rounded, size: 18, color: Colors.grey[400]),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        // 4. 아바타 프로필
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://images.justwatch.com/poster/8734024/s592/re-jeborobuteo-sijaghaneun-isegye-saenghwal.jpg',
              headers: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '안녕하세요, 탐험가님!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Image.network(
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Emojis/main/Emojis/Hand%20Gestures/Waving%20Hand.png',
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) => const Text('👋', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '오늘도 지식의 우주를 탐험해볼까요?',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueExploring() {
    final sortedItems = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final recentItems = sortedItems.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '계속 탐험하기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...recentItems.map((item) => _buildExploreCard(item)),
              _buildAddExploreCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCard(AkashaItem item) {
    // 임시 탐색률 산출
    final exploreRate = (item.review.length / 500).clamp(0.1, 1.0);
    final isSelected = _selectedPreviewItem?.workId == item.workId;

    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.08),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedPreviewItem = item;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10), // inner radius
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. 이미지 배경
                if (item.posterPath != null && item.posterPath!.isNotEmpty)
                  Image.network(
                    item.posterPath!,
                    headers: const {
                      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    },
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderPoster(item.category.name),
                  )
                else
                  _buildPlaceholderPoster(item.category.name),

                // 2. 어두운 그라디언트 오버레이 (하단 가독성 확보)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),

                // 3. 텍스트 및 배지 오버레이
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 카테고리 태그 칩
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item.category.name).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category.name,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: exploreRate,
                                minHeight: 3,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCategoryColor(item.category.name),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(exploreRate * 100).toInt()}% 탐색',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
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

  Widget _buildPlaceholderPoster(String category) {
    IconData icon;
    Color grad;
    if (category == '인물') {
      icon = Icons.person_outline_rounded;
      grad = const Color(0xFF00E5FF);
    } else if (category == '개념') {
      icon = Icons.psychology_outlined;
      grad = const Color(0xFFFFB74D);
    } else {
      icon = Icons.movie_outlined;
      grad = const Color(0xFF6C63FF);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            grad.withValues(alpha: 0.2),
            const Color(0xFF1E1E2E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 26,
          color: grad.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildAddExploreCard() {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onSearch,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '탐색 기록 더 보기',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryJourney() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              '발견의 여정',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _buildTabButton(0, '추천 연결'),
            _buildTabButton(1, '새로운 작품'),
            _buildTabButton(2, '주목할 인물'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _buildDiscoveryContent(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.onGraph,
            child: const Text(
              '더 많은 연결 보기',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeDiscoveryTab == index;
    return TextButton(
      onPressed: () => setState(() => _activeDiscoveryTab = index),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.grey[600],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  List<Widget> _buildDiscoveryContent() {
    if (widget.vaultItems.length < 2) {
      return [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                '더 많은 작품을 추가하여 발견의 여정을 시작하세요.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        )
      ];
    }

    if (_activeDiscoveryTab == 0) {
      // 추천 연결: 최근 작품들의 간이 연결
      final sorted = List<AkashaItem>.from(widget.vaultItems)..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      final a = sorted[0];
      final b = sorted[1];
      final c = sorted.length > 2 ? sorted[2] : sorted[0];
      
      return [
        Expanded(
          child: _buildDiscoveryCard(
            title: '최근 추가된 항목',
            rate: '100%',
            leftItem: a,
            rightItem: b,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDiscoveryCard(
            title: '유사한 카테고리',
            rate: '85%',
            leftItem: b,
            rightItem: c,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDiscoveryCard(
            title: '발견의 시작',
            rate: '70%',
            leftItem: c,
            rightItem: a,
          ),
        ),
      ];
    } else if (_activeDiscoveryTab == 1) {
      // 새로운 작품
      final sorted = List<AkashaItem>.from(widget.vaultItems)..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return sorted.take(3).map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildDiscoveryCardSingle(
              title: '새로운 작품',
              item: item,
            ),
          ),
        );
      }).toList();
    } else {
      // 주목할 인물
      final persons = widget.userCatalog.all.where((e) => e.anchorType == EntityAnchorType.person).toList();
      if (persons.isEmpty) {
        return [
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  '등록된 인물이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          )
        ];
      }
      return persons.take(3).map((person) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildDiscoveryCardEntity(
              title: '주목할 인물',
              entity: person,
            ),
          ),
        );
      }).toList();
    }
  }

  Widget _buildDiscoveryCard({
    required String title,
    required String rate,
    required AkashaItem leftItem,
    required AkashaItem rightItem,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                rate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDiscoveryThumbForWork(leftItem),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                _buildDiscoveryThumbForWork(rightItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCardSingle({
    required String title,
    required AkashaItem item,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedPreviewItem = item;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _buildDiscoveryThumbForWork(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryCardEntity({
    required String title,
    required UserCatalogEntity entity,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onOpenEntity(entity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _buildDiscoveryThumb(entity.title, ''), // 엔티티는 URL이 없을 수 있음
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryThumbForWork(AkashaItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedPreviewItem = item;
          });
        },
        child: _buildDiscoveryThumb(item.title, item.posterPath ?? ''),
      ),
    );
  }

  Widget _buildDiscoveryThumb(String label, String url) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    headers: const {
                      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    },
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildThumbPlaceholder(label),
                  )
                : _buildThumbPlaceholder(label),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbPlaceholder(String label) {
    return Container(
      color: const Color(0xFF222533),
      child: Center(
        child: Text(
          label.isNotEmpty ? label.substring(0, 1) : '?',
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseAndRecentlyAdded() {
    final workCount = widget.vaultItems.length;
    final allEntities = widget.userCatalog.all;
    final personCount = allEntities.where((e) => e.anchorType == EntityAnchorType.person).length;
    final placeCount = allEntities.where((e) => e.anchorType == EntityAnchorType.place).length;
    final eventCount = allEntities.where((e) => e.anchorType == EntityAnchorType.event).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 지식 우주 현황 (CustomPainter)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161824),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '지식 우주 현황',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                UniverseOrbitWidget(
                  workCount: workCount,
                  personCount: personCount,
                  placeCount: placeCount,
                  eventCount: eventCount,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 최근 추가된 작품
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161824),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '최근 추가된 작품',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onSearch,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '모두 보기',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._buildRecentlyAddedList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecentlyAddedList() {
    final sortedItems = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final recentItems = sortedItems.take(5).toList();

    return List.generate(recentItems.length, (index) {
      final work = recentItems[index];
      final isSelected = _selectedPreviewItem?.workId == work.workId;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedPreviewItem = work;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: work.posterPath != null && work.posterPath!.isNotEmpty
                          ? Image.network(
                              work.posterPath!,
                              headers: const {
                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                              },
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF222533)),
                            )
                          : Container(color: const Color(0xFF222533)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${work.releaseYear ?? ''} · ${work.category.name}',
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (index == 0) // 가장 최근 추가된 1개에만 NEW 뱃지 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2838),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2C3E5A), width: 0.8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '빠른 액션',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: '작품 검색',
                    desc: '새로운 이세계 지식을 검색하고 라이브러리에 등록하세요.',
                    onTap: widget.onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.person_search_outlined,
                    title: '인물 탐색',
                    desc: '이세계에 존재하는 매력적인 주인공들과 그 관계를 분석합니다.',
                    onTap: widget.onExploreEntities,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.hub_outlined,
                    title: '그래프 탐색',
                    desc: '연결된 사건과 지식의 성운을 입체적인 망으로 보여줍니다.',
                    onTap: widget.onGraph,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.access_time_outlined,
                    title: '타임라인',
                    desc: '각 작품과 사건이 발생한 역사적 순서의 궤적을 확인합니다.',
                    onTap: widget.onTimeline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
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
}
