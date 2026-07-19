/// v1 출시 범위 플래그 — 스토어 스코프와 UI 노출을 맞춥니다.
class FeatureFlags {
  /// Steam Wallet production purchase / exchange entry points.
  ///
  /// **true** on the Steam v1 **production Commerce candidate** (reviewed
  /// release change): Astra packs `40110–40112`, theme exchange, and Inventory
  /// provider entry points. This is not final store Go by itself — seal the RC
  /// BuildID, complete Steam-installed Matrix CURRENT-RC evidence, and Set Live
  /// separately.
  ///
  /// **false** on the IAP-off rollback source (`0ce9e052`) and any rollback
  /// BuildID derived from it. A false build must not be marketed as
  /// purchase-ready.
  ///
  /// Track: docs/active/STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md
  /// · docs/active/STEAM_SERVICE_RELEASE_READINESS.md
  /// Historical POC: docs/history/closure-2026-07/steam_inventory_poc/README.md
  static const bool steamInAppPurchasesEnabled = true;

  /// Explicit internal build gate for the production ItemDef sandbox flow.
  ///
  /// Enable only with
  /// `--dart-define=AKASHA_STEAM_SANDBOX_TRANSACTIONS=true` in a reviewed
  /// Steamworks developer build. Sandbox defines are **not** release IAP
  /// enablement and stay **false** by default on Production Release builds.
  static const bool steamInventorySandboxTransactionsEnabled =
      bool.fromEnvironment(
        'AKASHA_STEAM_SANDBOX_TRANSACTIONS',
        defaultValue: false,
      );

  /// Steam-verified Echo playtime reward evaluation.
  ///
  /// Production IAP candidate builds always enable Echo rewards. When IAP is
  /// false (rollback / no-IAP), rewards stay off unless
  /// `--dart-define=AKASHA_STEAM_PLAYTIME_REWARDS=true` for an internal sandbox.
  /// Steam remains the eligibility and window authority; the app only calls
  /// TriggerItemDrop and reconciles.
  static const bool steamInventoryPlaytimeRewardsEnabled =
      steamInAppPurchasesEnabled ||
      bool.fromEnvironment(
        'AKASHA_STEAM_PLAYTIME_REWARDS',
        defaultValue: false,
      );

  static const bool steamCommerceProviderEnabled =
      steamInAppPurchasesEnabled ||
      steamInventorySandboxTransactionsEnabled ||
      steamInventoryPlaytimeRewardsEnabled;

  static const bool steamCommerceTransactionsEnabled =
      steamInAppPurchasesEnabled || steamInventorySandboxTransactionsEnabled;

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
}
