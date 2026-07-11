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
| [VAULT_AGENT_GUIDE.md](active/VAULT_AGENT_GUIDE.md) | **Vault Agent Guide** | 볼트 내 파일·에이전트·외부 편집기용 운영 가이드 및 ID 체계. |
| [AGENT_VAULT_PROTOCOL_V1.md](active/AGENT_VAULT_PROTOCOL_V1.md) | **Agent Vault Protocol v1** | 에이전트와 볼트 간의 쓰기/읽기/충돌 감지 v1 통신 규격. |
| [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](active/AI_ARCHIVE_WRITE_GATEWAY_ADR.md) | **AI Write Gateway ADR** | 외부 AI/도구의 후보 생성·권한 있는 기록 적용 경계. |
| [PROVENANCE_AND_DERIVED_INPUT_ADR.md](active/PROVENANCE_AND_DERIVED_INPUT_ADR.md) | **Provenance ADR** | 원본·가져오기·AI 파생 기록의 입력 revision·출처 보존 의미 계약. |
| [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) | **Format Specification v3** | 볼트의 물리 디렉터리 레이아웃, YAML Frontmatter 스키마 계약 및 위키링크 문법 규격. |
| [INFINITE_ARCHIVE_HARDENING_PLAN.md](active/INFINITE_ARCHIVE_HARDENING_PLAN.md) | **Archive Hardening Plan** | 무한 볼트 성장을 보장하기 위한 인덱스, 취향 신호, 쓰기 계약 및 ID 경로 계획. |
| [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](active/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) | **Pre-release Audit** | 출시 전 볼트 레이아웃 v3 및 통합 작업(Operation) 규칙 Feasibility 감사. |
| [ULTIMATE_ARCHIVE_BACKLOG.md](active/ULTIMATE_ARCHIVE_BACKLOG.md) | **Archive Backlog** | 아카이브 시스템 고도화(인덱스 샤딩, 데이터 무결성 등) 관련 장기 아키텍처 백로그. |
| [AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md](active/AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md) | **Agent Entity Creation & Scale** | 고용량 에이전트 인덱싱 및 엔티티 생성 관련 상세 아키텍처. |
| [AGENT_VAULT_LOOP_SLICE.md](active/AGENT_VAULT_LOOP_SLICE.md) | **Agent Vault Loop Slice** | 에이전트의 볼트 루프 적용 및 마일스톤 슬라이스 계획. |
| [DOMAIN_DEPRECATION_PLAN.md](active/DOMAIN_DEPRECATION_PLAN.md) | **Domain Deprecation Plan** | 레거시 카테고리 도메인 폐기 및 단일화 로드맵. |
| [SPRINT_B1_DOGFOOD.md](active/SPRINT_B1_DOGFOOD.md) | **Sprint B1 Dogfood** | 스프린트 B1 독푸딩 범위 및 UI/UX 정합성 검증 결과. |

---

## 📂 2. Architecture (아키텍처 감사 및 설계 설계) · [`docs/architecture/`](architecture/)

시스템 타임스탬프, 데이터 무결성, 날짜 의미론 등 세부 컴포넌트 단위의 아키텍처 감사(Audit) 및 구현 설계서들이 위치합니다.

| 파일 | 역할 | 설명 |
|---|---|---|
| [DATE_SEMANTICS_AUDIT.md](architecture/DATE_SEMANTICS_AUDIT.md) | **Date Semantics Audit** | `UA-114` 날짜 의미론 감사 및 타임존 왜곡 방지 분석 보고서. |
| [VAULT_TIMESTAMP_CONTRACT_ALIGNMENT_PLAN.md](architecture/VAULT_TIMESTAMP_CONTRACT_ALIGNMENT_PLAN.md) | **Timestamp Alignment Plan** | `UA-115` 시스템 타임스탬프의 UTC instant 계약 통일 및 구현 설계서. |
| [TIMELINE_TIME_SEMANTICS_PLAN.md](architecture/TIMELINE_TIME_SEMANTICS_PLAN.md) | **Timeline Semantics Plan** | `UA-116` 타임라인 사건 시각(`occurredAt`/`timeAnchor`)의 로컬 타임존 왜곡 방지 설계안. |

---

## 📂 3. Historical (과거 기록 문서) · [`docs/history/`](history/)

과거에 작성되었던 스프린트 계획, 회고, 게이트 리뷰, 아키텍처 의사결정 기록(ADR) 등입니다.
* **읽기 전용:** 이 디렉토리의 문서들은 역사적 사실의 기록을 위한 것으로, 더 이상 수정하거나 최신화하지 않습니다.
* 과거 설계 흐름이나 이전 결정의 맥락을 파악하고 싶을 때 참조합니다.

---

## 📂 4. Draft (실험 및 제안 문서) · [`docs/draft/`](draft/)

구현이 확정되지 않은 아이디어, 신규 기능의 초안 설계, 제안 문서 등이 위치하는 임시 공간입니다.
* 논의가 완료되어 구현이 확정되면, 해당 내용을 `Active` 문서군에 통합(or 이관)하고 Draft 내의 문서는 삭제하거나 `Historical`로 이동시킵니다.
