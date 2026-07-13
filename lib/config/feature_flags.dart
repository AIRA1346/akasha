/// v1 출시 범위 플래그 — 스토어 스코프와 UI 노출을 맞춥니다.
class FeatureFlags {
  /// Steam Wallet / microtxn 인앱 구매.
  ///
  /// **false = 미구현.** Store Page에 IAP를 표시하거나 재심사에서 구매가
  /// 있다고 주장하지 않는다. Inventory POC / GetReport 증거가 검증되기 전에
  /// true로 올리지 말 것. 트랙: docs/active/STEAM_RELEASE_BLOCKER_CLOSURE.md
  /// POC: docs/active/steam_inventory_poc/README.md
  static const bool steamInAppPurchasesEnabled = false;

  /// 오늘의 회상 카드 — v1.1에서 활성화 예정
  static const bool showRecallCard = false;

  /// 글로벌 사전 추가·수정 제안 (로컬 큐 → export / GitHub Issue)
  static const bool catalogContributions = true;

  /// Home/Preview의 실험적 지식 그래프 CTA — v1.1에서 활성화 예정.
  ///
  /// UX-2에서 복원한 기존 Graph 전역 목적지는 이 플래그의 대상이 아니다.
  /// 이 값은 새 graph engine이나 확장 기능의 출시를 의미한다.
  static const bool showKnowledgeGraph = false;

  // ── R15 / post-v1 홈 실험 UI ─────────────────────────────────────────

  /// 발견의 여정 — 추천 연결·새 작품 (Discover 축). README v1 보류.
  static const bool showDiscoveryHome = false;

  /// 홈 지식 우주 오빗 시각화 (Discover·Graph 비전 UI).
  static const bool showHomeUniverseSection = false;

  /// 타임라인·일지 빠른 capture와 Home CTA — v1 이후.
  ///
  /// 기존 Records/Timeline 조회 목적지는 UX-2 전역 내비게이션으로 접근할
  /// 수 있으며, 이 값이 false일 때 새 projection이나 capture를 주장하지 않는다.
  static const bool showTimeline = false;

  // ── R15 워크벤치·프리뷰 크롬 ─────────────────────────────────────────

  /// 워크벤치 상단 경로 breadcrumb (`서재 > 작품 > 제목`).
  static const bool showWorkbenchBreadcrumb = false;

  /// 홈 프리뷰 패널 하단 빠른 메모 진입 바.
  static const bool showPreviewMemoBar = false;
}
