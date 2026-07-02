# AKASHA Documentation System

AKASHA 프로젝트의 문서 관리 시스템입니다. 본 프로젝트는 **코드가 유일한 진실(Source of Truth)**이며, 문서는 항상 코드의 구현 상태를 뒤따라 최신화됩니다.

인지 부하를 최소화하고 문서의 신뢰도를 유지하기 위해, 모든 문서는 다음 3가지 카테고리로 엄격히 분류하여 운영합니다.

---

## 📂 1. Active (현재 유효한 문서) · [`docs/active/`](active/)

현재 실제 프로젝트에 유효하게 적용되고 작동하는 문서들입니다. 이 디렉토리에 포함된 파일들만 항상 최신 상태로 유지 관리됩니다.

| 파일 | 역할 | 설명 |
|---|---|---|
| [PROJECT_CONSTITUTION.md](active/PROJECT_CONSTITUTION.md) | **Supreme SSOT** | 프로젝트 최상위 헌법. 정체성, 핵심 철학, 의사결정 필터 수록. |
| [CURRENT_STATE.md](active/CURRENT_STATE.md) | **Reality SSOT** | 실제 코드 및 레지스트리 상태 기준 구현 현황. |
| [VISION.md](active/VISION.md) | **Product SSOT** | 제품 비전 및 유저 여정, 데이터 티어 구분 정책. |
| [ARCHITECTURE.md](active/ARCHITECTURE.md) | **Architecture SSOT** | v4 런타임 및 해시 샤딩 인프라 아키텍처. |
| [PROJECT_STATUS.md](active/PROJECT_STATUS.md) | **Operational SSOT** | 품질 게이트 통과 스냅샷 및 릴리즈 준비 현황. |
| [STEAM_RELEASE.md](active/STEAM_RELEASE.md) | **Steam Release** | 무료 출시 스토어 카피, dogfood 상태, 업로드 체크리스트. |
| [ROADMAP.md](active/ROADMAP.md) | **Roadmap SSOT** | 5대 정체성 카테고리(Archive/Discovery/Graph/Library/Scale) 중심의 로드맵. |
| [privacy.md](active/privacy.md) | **Legal Policy** | 개인정보 처리방침. |

---

## 📂 2. Historical (과거 기록 문서) · [`docs/history/`](history/)

과거에 작성되었던 스프린트 계획, 회고, 게이트 리뷰, 아키텍처 의사결정 기록(ADR) 등입니다.
* **읽기 전용:** 이 디렉토리의 문서들은 역사적 사실의 기록을 위한 것으로, 더 이상 수정하거나 최신화하지 않습니다.
* 과거 설계 흐름이나 이전 결정의 맥락을 파악하고 싶을 때 참조합니다.

---

## 📂 3. Draft (실험 및 제안 문서) · [`docs/draft/`](draft/)

구현이 확정되지 않은 아이디어, 신규 기능의 초안 설계, 제안 문서 등이 위치하는 임시 공간입니다.
* 논의가 완료되어 구현이 확정되면, 해당 내용을 `Active` 문서군에 통합(or 이관)하고 Draft 내의 문서는 삭제하거나 `Historical`로 이동시킵니다.
