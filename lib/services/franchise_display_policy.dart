/// 프랜차이즈(IP) 표시 정책 — 제품 규칙의 단일 출처
///
/// | 영역 | 규칙 |
/// |------|------|
/// | 그리드(홈·대시보드) | IP당 카드 **1장 고정** (`FranchiseFusionService`) |
/// | 매체 섹션 | 동일 카드를 포함 매체마다 배치 (`BrowseCategoryGroups`) |
/// | 검색 | IP당 **1행** — 형제 매체 중 하나라도 매칭되면 노출 |
///
/// 그리드 경로에서는 `RegistryVisibilityService.shouldMaterializeVirtual`이
/// 항상 형제 매체 가상 카드를 억제합니다.
class FranchiseDisplayPolicy {
  FranchiseDisplayPolicy._();

  static const bool gridOneCardPerIp = true;
}
