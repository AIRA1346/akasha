/// v1 출시 범위 플래그 — 스토어 스코프와 UI 노출을 맞춥니다.
class FeatureFlags {
  /// 오늘의 회상 카드 — v1.1에서 활성화 예정
  static const bool showRecallCard = false;

  /// 글로벌 사전 추가·수정 제안 (로컬 큐 → export / GitHub Issue)
  static const bool catalogContributions = true;

  /// 지식 그래프 탐색 — v1.1에서 활성화 예정
  static const bool showKnowledgeGraph = true;

  // ── R15 / post-v1 홈 실험 UI ─────────────────────────────────────────

  /// 발견의 여정 — 추천 연결·새 작품 (Discover 축). README v1 보류.
  static const bool showDiscoveryHome = false;

  /// 홈 지식 우주 오빗 시각화 (Discover·Graph 비전 UI).
  static const bool showHomeUniverseSection = false;

  /// 타임라인·일지 빠른 액션 — v1 이후.
  static const bool showTimeline = false;

  // ── R15 워크벤치·프리뷰 크롬 ─────────────────────────────────────────

  /// 워크벤치 상단 경로 breadcrumb (`서재 > 작품 > 제목`).
  static const bool showWorkbenchBreadcrumb = false;

  /// 홈 프리뷰 패널 하단 빠른 메모 진입 바.
  static const bool showPreviewMemoBar = false;
}
