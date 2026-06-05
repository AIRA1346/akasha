import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 카테고리 & 상태 Enum 정의
// ════════════════════════════════════════════════════════════════

/// 대분류 (도메인)
enum AppDomain {
  subculture('서브컬처', Icons.auto_awesome),
  generalCulture('일반 문화', Icons.account_balance);

  final String label;
  final IconData icon;
  const AppDomain(this.label, this.icon);
}

/// 매체 카테고리
enum MediaCategory {
  manga('만화', Icons.menu_book),
  animation('애니메이션', Icons.movie_filter),
  game('게임', Icons.sports_esports),
  book('책/소설/라노벨', Icons.auto_stories),
  movie('영화', Icons.movie),
  drama('드라마', Icons.live_tv);

  final String label;
  final IconData icon;
  const MediaCategory(this.label, this.icon);

  /// 콘텐츠 계열(만화·책·애니 등 게임이 아닌 모든 것)인지 여부
  bool get isContentType => this != game;
}

/// 콘텐츠(만화·책·애니) — 작품 상태
enum ContentWorkStatus {
  serializing('연재중'),
  hiatus('휴재중'),
  completed('완결');

  final String label;
  const ContentWorkStatus(this.label);
}

/// 콘텐츠(만화·책·애니) — 나의 상태
enum ContentMyStatus {
  notStarted('볼 예정'),
  watching('보는 중'),
  finished('전부 봄'),
  dropped('하차함');

  final String label;
  const ContentMyStatus(this.label);
}

/// 게임 — 작품 상태
enum GameWorkStatus {
  released('출시됨'),
  earlyAccess('얼리액세스'),
  upcoming('출시예정');

  final String label;
  const GameWorkStatus(this.label);
}

/// 게임 — 나의 상태
enum GameMyStatus {
  backlog('볼 예정'),
  playing('플레이 중'),
  cleared('클리어(완결)'),
  abandoned('중도포기(하차)');

  final String label;
  const GameMyStatus(this.label);
}

// ────────────────────────────────────────────
//  상태 표시용 컬러 유틸리티
// ────────────────────────────────────────────

/// 나의 상태 라벨에 대응하는 컬러 도트 색상
Color myStatusDotColor(String label) {
  const map = {
    '볼 예정': Color(0xFF9D4EDD), // 보라색
    '아직 안 봄': Color(0xFF9D4EDD), // 하위 호환
    '할 예정(백로그)': Color(0xFF9D4EDD), // 하위 호환
    '보는 중': Colors.lightGreen,
    '플레이 중': Colors.lightGreen,
    '전부 봄': Color(0xFF9D4EDD), // 보라색
    '클리어(완결)': Color(0xFF9D4EDD), // 보라색
    '하차함': Colors.red,
    '중도포기(하차)': Colors.red,
  };
  return map[label] ?? Colors.grey;
}

/// 카테고리별 대표 그라디언트 색상 (포스터 플레이스홀더용)
List<Color> categoryGradient(MediaCategory category) {
  switch (category) {
    case MediaCategory.manga:
      return [const Color(0xFF7B2FF7), const Color(0xFFC471F5)]; // 보라-연보라
    case MediaCategory.animation:
      return [const Color(0xFFFF512F), const Color(0xFFF09819)]; // 오렌지-황토
    case MediaCategory.game:
      return [const Color(0xFF00B09B), const Color(0xFF96C93D)]; // 청록-연두
    case MediaCategory.book:
      return [const Color(0xFF0052D4), const Color(0xFF6FB1FC)]; // 파랑-하늘
    case MediaCategory.movie:
      return [const Color(0xFF373B44), const Color(0xFF4286F4)]; // 철청-하늘
    case MediaCategory.drama:
      return [const Color(0xFF11998E), const Color(0xFF38EF7D)]; // 청록-민트
  }
}
