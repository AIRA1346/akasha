import 'package:flutter/material.dart';
import 'category_descriptor.dart';
import '../theme/akasha_colors.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 카테고리 & 상태 Enum 정의
// ════════════════════════════════════════════════════════════════

/// Registry·YAML 레거시 메타. 신규·UI에서는 **subculture만** 사용.
/// @see current compatibility: [LEGACY_REMOVAL_POLICY.md](../../docs/active/LEGACY_REMOVAL_POLICY.md) §4b
/// @see historical plan: [DOMAIN_DEPRECATION_PLAN.md](../../docs/history/closure-2026-07/DOMAIN_DEPRECATION_PLAN.md)
enum AppDomain {
  subculture('Subculture', Icons.auto_awesome),

  /// @deprecated AppDomain 폐기 — 읽기 호환만. [fromStorage]는 항상 [subculture].
  @Deprecated('Use AppDomain.subculture / AppDomain.fromStorage')
  generalCulture('General Culture', Icons.account_balance);

  final String label;
  final IconData icon;
  const AppDomain(this.label, this.icon);

  /// 신규 작품·기여·Registry canonical 값
  static const AppDomain newWorkDefault = subculture;

  /// Registry·YAML·JSON — unknown·generalCulture → subculture
  static AppDomain fromStorage(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'generalCulture') {
      return subculture;
    }
    for (final d in AppDomain.values) {
      if (d.name == raw) return d;
    }
    return subculture;
  }
}

/// 매체 카테고리
enum MediaCategory {
  manga('Manga', Icons.menu_book),
  webtoon('Webtoon', Icons.web_stories),
  animation('Animation', Icons.movie_filter),
  game('Game', Icons.sports_esports),
  book('Book / Novel / Light Novel', Icons.auto_stories),
  movie('Movie', Icons.movie),
  drama('Drama', Icons.live_tv),
  music('Music / OST', Icons.music_note);

  final String label;
  final IconData icon;
  const MediaCategory(this.label, this.icon);

  /// 콘텐츠 계열(만화·책·애니 등 게임이 아닌 모든 것)인지 여부
  bool get isContentType => CategoryRegistry.isContentType(this);
}

/// 콘텐츠(만화·책·애니) — 작품 상태
enum ContentWorkStatus {
  serializing('Serializing'),
  hiatus('Hiatus'),
  completed('Completed');

  final String label;
  const ContentWorkStatus(this.label);

  /// YAML에서 읽을 때 한국어 레거시 값도 인식
  static ContentWorkStatus fromStorage(String raw) {
    // 영어 label 매칭
    for (final v in values) {
      if (v.label == raw || v.name == raw) return v;
    }
    // 한국어 레거시 호환
    const legacy = {
      '연재중': ContentWorkStatus.serializing,
      '휴재중': ContentWorkStatus.hiatus,
      '완결': ContentWorkStatus.completed,
    };
    return legacy[raw] ?? serializing;
  }
}

/// 콘텐츠(만화·책·애니) — 나의 상태
enum ContentMyStatus {
  notStarted('Plan to Watch'),
  watching('Watching'),
  finished('Finished'),
  dropped('Dropped');

  final String label;
  const ContentMyStatus(this.label);

  /// YAML에서 읽을 때 한국어 레거시 값도 인식
  static ContentMyStatus fromStorage(String raw) {
    for (final v in values) {
      if (v.label == raw || v.name == raw) return v;
    }
    const legacy = {
      '볼 예정': ContentMyStatus.notStarted,
      '아직 안 봄': ContentMyStatus.notStarted,
      '보는 중': ContentMyStatus.watching,
      '전부 봄': ContentMyStatus.finished,
      '하차함': ContentMyStatus.dropped,
    };
    return legacy[raw] ?? notStarted;
  }
}

/// 게임 — 작품 상태
enum GameWorkStatus {
  released('Released'),
  earlyAccess('Early Access'),
  upcoming('Upcoming');

  final String label;
  const GameWorkStatus(this.label);

  /// YAML에서 읽을 때 한국어 레거시 값도 인식
  static GameWorkStatus fromStorage(String raw) {
    for (final v in values) {
      if (v.label == raw || v.name == raw) return v;
    }
    const legacy = {
      '출시됨': GameWorkStatus.released,
      '얼리액세스': GameWorkStatus.earlyAccess,
      '출시예정': GameWorkStatus.upcoming,
    };
    return legacy[raw] ?? released;
  }
}

/// 게임 — 나의 상태
enum GameMyStatus {
  backlog('Backlog'),
  playing('Playing'),
  cleared('Cleared'),
  abandoned('Abandoned');

  final String label;
  const GameMyStatus(this.label);

  /// YAML에서 읽을 때 한국어 레거시 값도 인식
  static GameMyStatus fromStorage(String raw) {
    for (final v in values) {
      if (v.label == raw || v.name == raw) return v;
    }
    const legacy = {
      '볼 예정': GameMyStatus.backlog,
      '할 예정(백로그)': GameMyStatus.backlog,
      '플레이 중': GameMyStatus.playing,
      '클리어(완결)': GameMyStatus.cleared,
      '중도포기(하차)': GameMyStatus.abandoned,
    };
    return legacy[raw] ?? backlog;
  }
}

// ────────────────────────────────────────────
//  상태 표시용 컬러 유틸리티
// ────────────────────────────────────────────

/// 나의 상태 enum 값에 대응하는 컬러 도트 색상
Color myStatusDotColor(String label) {
  // 영어 label 기반 매핑
  const map = {
    // ContentMyStatus
    'Plan to Watch': Color(0xFF9D4EDD),
    'Watching': Colors.lightGreen,
    'Finished': Color(0xFF9D4EDD),
    'Dropped': Colors.red,
    // GameMyStatus
    'Backlog': Color(0xFF9D4EDD),
    'Playing': Colors.lightGreen,
    'Cleared': Color(0xFF9D4EDD),
    'Abandoned': Colors.red,
    // 한국어 레거시 호환
    '볼 예정': Color(0xFF9D4EDD),
    '아직 안 봄': Color(0xFF9D4EDD),
    '할 예정(백로그)': Color(0xFF9D4EDD),
    '보는 중': Colors.lightGreen,
    '플레이 중': Colors.lightGreen,
    '전부 봄': Color(0xFF9D4EDD),
    '클리어(완결)': Color(0xFF9D4EDD),
    '하차함': Colors.red,
    '중도포기(하차)': Colors.red,
  };
  return map[label] ?? AkashaColors.textMuted;
}

/// 카테고리별 대표 그라디언트 색상 (포스터 플레이스홀더용)
List<Color> categoryGradient(MediaCategory category) {
  // 모든 카테고리에 대해 차분한 연한 회색 그라디언트로 통일 (Phase 9)
  return [const Color(0xFF374151), const Color(0xFF4B5563)];
}

// ────────────────────────────────────────────
//  다국어 번역 확장 메서드
// ────────────────────────────────────────────

extension MediaCategoryL10n on MediaCategory {
  String localizedLabel(dynamic l10n) {
    if (l10n == null) return label;
    switch (this) {
      case MediaCategory.manga:
        return l10n.mediaCategoryManga;
      case MediaCategory.webtoon:
        return l10n.mediaCategoryWebtoon;
      case MediaCategory.animation:
        return l10n.mediaCategoryAnimation;
      case MediaCategory.game:
        return l10n.mediaCategoryGame;
      case MediaCategory.book:
        return l10n.mediaCategoryBook;
      case MediaCategory.movie:
        return l10n.mediaCategoryMovie;
      case MediaCategory.drama:
        return l10n.mediaCategoryDrama;
      case MediaCategory.music:
        try {
          return l10n.mediaCategoryMusic;
        } catch (_) {
          final localeStr = l10n.localeName?.toString() ?? '';
          if (localeStr.startsWith('ko')) {
            return '음악 / OST';
          }
          return label;
        }
    }
  }
}

extension ContentWorkStatusL10n on ContentWorkStatus {
  String localizedLabel(dynamic l10n) {
    if (l10n == null) return label;
    switch (this) {
      case ContentWorkStatus.serializing:
        return l10n.statusContentWorkSerializing;
      case ContentWorkStatus.hiatus:
        return l10n.statusContentWorkHiatus;
      case ContentWorkStatus.completed:
        return l10n.statusContentWorkCompleted;
    }
  }
}

extension ContentMyStatusL10n on ContentMyStatus {
  String localizedLabel(dynamic l10n) {
    if (l10n == null) return label;
    switch (this) {
      case ContentMyStatus.notStarted:
        return l10n.statusContentMyNotStarted;
      case ContentMyStatus.watching:
        return l10n.statusContentMyWatching;
      case ContentMyStatus.finished:
        return l10n.statusContentMyFinished;
      case ContentMyStatus.dropped:
        return l10n.statusContentMyDropped;
    }
  }
}

extension GameWorkStatusL10n on GameWorkStatus {
  String localizedLabel(dynamic l10n) {
    if (l10n == null) return label;
    switch (this) {
      case GameWorkStatus.released:
        return l10n.statusGameWorkReleased;
      case GameWorkStatus.earlyAccess:
        return l10n.statusGameWorkEarlyAccess;
      case GameWorkStatus.upcoming:
        return l10n.statusGameWorkUpcoming;
    }
  }
}

extension GameMyStatusL10n on GameMyStatus {
  String localizedLabel(dynamic l10n) {
    if (l10n == null) return label;
    switch (this) {
      case GameMyStatus.backlog:
        return l10n.statusGameMyBacklog;
      case GameMyStatus.playing:
        return l10n.statusGameMyPlaying;
      case GameMyStatus.cleared:
        return l10n.statusGameMyCleared;
      case GameMyStatus.abandoned:
        return l10n.statusGameMyAbandoned;
    }
  }
}
