import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../home/home_poster_card_factory.dart';
import '../../../widgets/universe_orbit_painter.dart';

/// 시안 사진과 동일한 프리미엄 홈 대시보드 마스터 뷰.
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({
    super.key,
    required this.vaultItems,
    required this.onOpenWork,
    required this.onOpenEntity,
    required this.onSearch,
    required this.onTimeline,
    required this.onGraph,
    required this.onExploreEntities,
  });

  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem) onOpenWork;
  final void Function(UserCatalogEntity) onOpenEntity;
  final VoidCallback onSearch;
  final VoidCallback onTimeline;
  final VoidCallback onGraph;
  final VoidCallback onExploreEntities;

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  int _activeDiscoveryTab = 0; // 0: 추천 연결, 1: 새로운 작품, 2: 주목할 인물

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0B10), // Deep Space Black
            Color(0xFF11131E), // Dark Navy
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 환영 인사말
            _buildWelcomeHeader(),
            const SizedBox(height: 28),

            // 2. 계속 탐험하기
            _buildContinueExploring(),
            const SizedBox(height: 36),

            // 3. 발견의 여정
            _buildDiscoveryJourney(),
            const SizedBox(height: 36),

            // 4. 지식 우주 현황 & 최근 추가된 작품 (가로 2열 배치)
            _buildUniverseAndRecentlyAdded(),
            const SizedBox(height: 36),

            // 5. 빠른 액션
            _buildQuickActions(),
            const SizedBox(height: 48),
          ],
        ),
      ),
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
    // 목업 리스트
    final mockCards = [
      _ContinueExploreData(
        title: 'Re:제로부터 시작하는 이세계 생활',
        category: '작품',
        exploreRate: 0.78,
        imageUrl: 'https://images.justwatch.com/poster/8734024/s592/re-jeborobuteo-sijaghaneun-isegye-saenghwal.jpg',
      ),
      _ContinueExploreData(
        title: '에밀리아',
        category: '인물',
        exploreRate: 0.45,
        imageUrl: 'https://api.ready.is/vault/emilia.png', // Fallback to icon if unavailable
      ),
      _ContinueExploreData(
        title: '마녀교',
        category: '개념',
        exploreRate: 0.62,
        imageUrl: '',
      ),
      _ContinueExploreData(
        title: '프리실라 바리에르',
        category: '인물',
        exploreRate: 0.33,
        imageUrl: '',
      ),
    ];

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
              ...mockCards.map((card) => _buildExploreCard(card)),
              _buildAddExploreCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCard(_ContinueExploreData data) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
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
          // 카드 포스터 영역
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (data.imageUrl.isNotEmpty)
                    Image.network(
                      data.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderPoster(data.category),
                    )
                  else
                    _buildPlaceholderPoster(data.category),
                  // 카테고리 태그 칩
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D3FD3).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data.category,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 정보 텍스트 영역
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
                          value: data.exploreRate,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF5D3FD3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(data.exploreRate * 100).toInt()}% 탐색',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[400],
                        fontFamily: 'Consolas',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          children: [
            Expanded(
              child: _buildDiscoveryCard(
                title: '사사적 유사성',
                rate: '92%',
                leftTitle: 'Re:제로부터 시작하는 이세계 생활',
                rightTitle: '무직전생',
                leftImg: 'https://images.justwatch.com/poster/8734024/s592/re-jeborobuteo-sijaghaneun-isegye-saenghwal.jpg',
                rightImg: 'https://images.justwatch.com/poster/245388040/s592/mujikjeonsaeng-sinsunghamyeon-ddanpanaji-ganda.jpg',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDiscoveryCard(
                title: '캐릭터 유사성',
                rate: '89%',
                leftTitle: '에밀리아',
                rightTitle: '알베도',
                leftImg: '',
                rightImg: '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDiscoveryCard(
                title: '개념적 연결',
                rate: '85%',
                leftTitle: '마녀교',
                rightTitle: '아카식 레코드',
                leftImg: '',
                rightImg: '',
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: TextButton(
        onPressed: () => setState(() => _activeDiscoveryTab = index),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          backgroundColor: isActive ? const Color(0xFF1B1D2A) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF6C63FF) : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryCard({
    required String title,
    required String rate,
    required String leftTitle,
    required String rightTitle,
    required String leftImg,
    required String rightImg,
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
                _buildDiscoveryThumb(leftTitle, leftImg),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                _buildDiscoveryThumb(rightTitle, rightImg),
              ],
            ),
          ),
        ],
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
                const UniverseOrbitWidget(),
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
    final items = [
      _RecentWorkData(
        title: '장송의 프리렌',
        meta: '2023 · 애니메이션',
        url: 'https://images.justwatch.com/poster/308119864/s592/jangsongui-peulilen.jpg',
      ),
      _RecentWorkData(
        title: '주술회전 2기',
        meta: '2023 · 애니메이션',
        url: 'https://images.justwatch.com/poster/306161476/s592/jusuhoejeon.jpg',
      ),
      _RecentWorkData(
        title: '스파이 패밀리 2기',
        meta: '2023 · 애니메이션',
        url: 'https://images.justwatch.com/poster/301594966/s592/seupai-paemili.jpg',
      ),
      _RecentWorkData(
        title: '데드 마운트 데스 플레이',
        meta: '2023 · 애니메이션',
        url: '',
      ),
      _RecentWorkData(
        title: '최애의 아이 2기',
        meta: '2024 · 애니메이션',
        url: '',
      ),
    ];

    return List.generate(items.length, (index) {
      final work = items[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 32,
                height: 32,
                child: work.url.isNotEmpty
                    ? Image.network(
                        work.url,
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
                    work.meta,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.assignment_turned_in_outlined,
                title: '작품 검색',
                desc: '새로운 작품을 찾아보세요',
                onTap: widget.onSearch,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_search_outlined,
                title: '인물 탐색',
                desc: '흥미로운 인물을 발견하세요',
                onTap: widget.onExploreEntities,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.hub_outlined,
                title: '그래프 탐색',
                desc: '관계의 벡터를 확인하세요',
                onTap: widget.onGraph,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.access_time_outlined,
                title: '타임라인',
                desc: '시간의 흐름을 따라가세요',
                onTap: widget.onTimeline,
              ),
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

class _ContinueExploreData {
  _ContinueExploreData({
    required this.title,
    required this.category,
    required this.exploreRate,
    required this.imageUrl,
  });

  final String title;
  final String category;
  final double exploreRate;
  final String imageUrl;
}

class _RecentWorkData {
  _RecentWorkData({
    required this.title,
    required this.meta,
    required this.url,
  });

  final String title;
  final String meta;
  final String url;
}
