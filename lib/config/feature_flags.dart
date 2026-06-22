/// v1 출시 범위 플래그 — 스토어 스코프와 UI 노출을 맞춥니다.
class FeatureFlags {
  /// 오늘의 회상 카드 — v1.1에서 활성화 예정
  static const bool showRecallCard = false;

  /// 글로벌 사전 추가·수정 제안 (로컬 큐 → export / GitHub Issue)
  static const bool catalogContributions = true;

  /// 지식 그래프 탐색 — v1.1에서 활성화 예정
  static const bool showKnowledgeGraph = false;
}
