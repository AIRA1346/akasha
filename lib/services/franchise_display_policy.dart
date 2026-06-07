/// 프랜차이즈(IP) 표시 정책 — 제품 규칙의 단일 출처
///
/// | 영역 | 규칙 |
/// |------|------|
/// | 그리드(홈·대시보드) | IP당 카드 **1장 고정** (`FranchiseFusionService`) |
/// | 검색 | `tracksMultipleFormats` 토글 시 매체 버전 **개별 행** 가능 |
///
/// 그리드 경로에서는 `RegistryVisibilityService.shouldMaterializeVirtual`이
/// 항상 형제 매체 가상 카드를 억제합니다. 검색 힌트·dedupe만 토글을 따릅니다.
class FranchiseDisplayPolicy {
  FranchiseDisplayPolicy._();

  static const bool gridOneCardPerIp = true;
}
