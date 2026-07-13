# AKASHA Roadmap (로드맵)

> **지위:** 프로젝트 개발 로드맵 SSOT (5대 정체성 카테고리 기준)
> **갱신:** 2026-07-13 — UX·Theme 횡단 트랙 연결
> **최상위 지침:** [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) · [VISION.md](VISION.md) · [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md)
> **기능 거부 기준:** [Constitution §8](AKASHA_ARCHIVE_CONSTITUTION.md) (구 PROJECT_CONSTITUTION 필터는 [historical](../history/PROJECT_CONSTITUTION.md))

---

## Steam v1 우선순위 (2026-06-30)

**v1은 글로벌 작품 사전 앱이 아니라 개인 아카이브 앱이다.**

| 우선 | 카테고리 | v1에서 |
|:----:|----------|--------|
| **P0** | **A. Archive** | 핵심 — vault · Sanctum · 기록 UI |
| **P0** | **D. Personal Library** | 핵심 — 서재 · Collection |
| P1 | C. Knowledge Graph | 기존 Workbench·연결 — 확장은 post-v1 |
| — | B. Discovery | **optional** — starter catalog 검색 유지 |
| — | E. Scale | **post-v1** — vault 파생 인덱스 · akasha-db/CDN |

**Steam v1 무료 출시:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md) 트랙. Architecture Closure 선언됨. IAP는 `steamInAppPurchasesEnabled=false` — 결제 검증 전 Store/앱에 구매로 표시하지 않음.

---

## 횡단 트랙: UX & Theme (2026-07-13)

사용자 경험과 시각 표현은 A–E 제품 카테고리를 가로지르는 공통 계약이다. 정보 구조, Desktop Shell, 컴포넌트 규격, 테마 확장 기준은 [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md)를 따른다.

구현 순서는 Theme foundation → Responsive Shell → Graph/Timeline 기존 경로 복원 → Home 고도화 → Preview·핵심 화면 정돈 → 테마별 asset/effect와 회귀 검증이다. 기존 Graph/Timeline 내비게이션을 다시 보이게 하는 일은 새 그래프 엔진, 완성 캘린더, `SA-05 Timeline projection` 완료를 의미하지 않는다.

**현재:** UX-1 Theme foundation과 UX-2 Responsive Shell·기존 Graph/Timeline 접근성 복원을 완료했다. 다음 구현 단계는 UX-3 Home 고도화이며, 기존 Home 콘텐츠 재설계는 UX-2 범위에 포함하지 않았다.

공식 테마 카탈로그는 무료 `classicDark`·`midnightBlue`, premium `sakura`·`amethyst`·`nocturne`다. UX-1 foundation으로 no-IAP picker는 무료 2종만 제공하며 premium 구매·잠금 UI는 commerce 활성 전 노출하지 않는다. 잔여 style 이관은 [UX_THEME_MIGRATION_INVENTORY.md](UX_THEME_MIGRATION_INVENTORY.md)에서 추적한다.

---

## 로드맵 핵심 원칙 (Feature Audit Filter)

신규 기능·마이그레이션·외부 연동은 [Constitution §8](AKASHA_ARCHIVE_CONSTITUTION.md)을 통과해야 한다.

1. 아카이브를 더 오래·이해할 수 있게·쓸 수 있게·옮길 수 있게 하는가?
2. 사용자 소유를 지키며 AI/도구를 교체 가능하게 두는가?
3. 원본 · 가져오기 · 파생을 구분하는가?
4. 도메인 의미를 평탄화하지 않는가?
5. 폐기 가능한 인덱스를 원본으로 만들지 않는가?
6. 사용자가 검사·내보내기·삭제·비활성화를 정직하게 할 수 있는가?

**제품 카테고리(A–E)**는 백로그 분류용이다. 카테고리에 들어맞아도 §8을 실패하면 핵심에 넣지 않는다.  
**v1에서는 보존·기록 품질이 발견·규모 확장보다 항상 우선**한다.

---

## 📂 A. Archive (기록) — **v1 핵심**
> **목표:** 사용자가 만난 작품과 감상을 안전하고 자유롭게 기록하는 Sanctum 볼트 시스템

* **[x] Sanctum 볼트 연동:** 폴더 연동, watch, 원자적 저장 및 동기화
* **[x] 아카이브 자동화:** 아카이브 시 `.md` 파일 자동 생성 및 YAML front-matter 템플릿 적용
* **[x] 마크다운 감상 기록:** 워크벤치 내 본문 Markdown 편집 및 저장 기능 완결
* **[x] Sanctum C1~C4:** wiki 칩 · 출연 · 갤러리 · 완성도 · HTML보내기
* **[x] 클립보드 가져오기:** YAML/Markdown 파싱 · 수동 가져오기
* **[x] (v1) Agent Vault Protocol v1 범위 문서:** [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) · 현장 [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md)
* **[x] (architecture) Infinite Archive Hardening Plan:** index · taste signal · agent write · ID path 기준 정렬
* **[x] (architecture) Ultimate Archive pre-release audit:** Vault Layout v3 canonical 후보 — 새 Work/Entity ID path · operation contract
* **[x] (pre-release slice) Vault Layout v3 feasibility:** path resolver · 새 Work/Entity ID path · schema fixture 검증
* **[x] (pre-release slice) ArchiveOperation model + validator:** agent/app/script write intent · identity/path/payload 검증
* **[x] (pre-release slice) Candidate Store + promotion validator:** agent 추출 후보를 정식 archive와 분리
* **[x] (architecture) Ultimate Archive backlog:** 발견된 후속 작업 전체 목록화
* **[x] (pre-release slice) Operation execution service:** 검증된 `promoteCandidate`를 Entity journal · catalog mirror · candidate close까지 연결
* **[x] (pre-release slice) Operation idempotency + applied log:** agent/script retry를 안전하게 만들기
* **[x] (pre-release slice) Operation conflict checks:** expectedRevision/hash/mtime 기준으로 동시 편집 보호
* **[x] (pre-release slice) Operation crash recovery marker:** write 성공 후 log 실패 상황을 roll-forward
* **[ ] (post-launch) Agent Vault Protocol 구현·dogfood:** 대화 → vault operation · 충돌 · watch (§8 체크리스트)
* **[ ] (post-launch) Structured archive operation contract:** create/update/append/tag/rating/status/link/promote/merge operation 검증
* **[ ] (v1.1+) 오늘의 회상 카드:** 리마인드 카드 (보류)
* **[ ] (v1.1+) 타임라인 / 완성 캘린더:** 날짜 기준 시각화 (보류)

---

## 📂 B. Discovery (검색 및 발견) — **v1 optional / post-v1 확장**
> **목표:** starter catalog로 작품을 **찾는** 보조 수단. v1 핵심은 **내 vault에 기록**하는 것.

* **[x] 글로벌 사전 (akasha-db) 검색:** 로컬 볼트 + 사전 + 직접 등록 연계 — **optional catalog**
* **[x] 다국어 카탈로그 지원:** 다언어 타이틀 검색
* **[x] 검색 Recall@10:** CI 품질 자산 — **v1 blocking 아님**
* **[x] Wikidata (wikidata_ko):** post-v1 Discovery spine — 구현 유지
* **[ ] (post-v1) 취향 기반 추천 (Discover):** 보류
* **[x] 외부 API 자동 연동 제외:** TMDB · IGDB 메타·포스터 fetch는 폐기, `externalIds.*` 식별자만 유지

---

## 📂 C. Knowledge Graph (연결 · 도메인 확장)
> **목표:** Work를 넘어 Entity·관계·Canvas로 **사용자 소유 연결**을 확장한다. “문화 위키”가 목표가 아니다.

* **[x] `wk_` 영구 ID 및 Entity-Record 분리:** 데이터 모델 개편 완료 (Tier 1 vs Tier 2)
* **[x] 워크벤치 Multi-tab 환경:** Work 탭과 Entity 탭의 다중 레이아웃 및 탭 동기화
* **[x] Phase 6.2 Workbench Parity:** 엔티티 상세 정보와 마크다운 편집기 통합
* **[x] Phase 6.3 incoming/sameDay 패널:** `SameDayRecordRef` 및 역방향 `incoming` 링크 표시
* **[ ] Phase 3 Entity Types (미착수):** Work 이외 Person, Event, Place, Concept — 도메인 의미 유지한 채 확장
* **[ ] Phase 5 Connection (미착수):** 위키식 `[[링크]]` · Record ↔ Entity 연결 (Assertion 물리 저장은 별도 계약)

---

## 📂 D. Personal Library (나의 서재 & 큐레이션) — **v1 핵심**
> **목표:** 아카이브한 기록을 사용자가 의미 있게 전시·큐레이션하는 공간

* **[x] 나의 서재 기본 뷰:** 아카이브한 작품만 모아 보는 전용 홈 모드 구축
* **[x] 대시보드-서재 역할 분리:** 카탈로그 탐색 공간(Dashboard)과 나의 기록 공간(Library) 정비
* **[x] UX-1 공식 테마 foundation:** canonical 5종 · app-root theme · 무료 2종 picker · premium 3종 fallback preset. Commerce 활성 전 구매·잠금 UI 미노출
* **[x] UX-2 Responsive Shell:** 단일 `AppDestination`·`PreviewTarget`, 3단계 `ShellLayoutSpec`, Sidebar/Dock selection SSOT, 기존 Graph/Timeline 접근성, provider 없는 utility slot 숨김
* **[x] Cast Collection / Hero Collection:** 인물·속성별 큐레이션 컬렉션 연동 기능
* **[ ] (v1.1+) 서재 진열 방식 커스텀:** 그리드 밀도 및 표시 항목 개인화 (보류)
* **[ ] (장기) Mixed Library:** 서로 다른 매체의 기록을 하나의 컬렉션으로 통합 (보류)

---

## 📂 E. Scale (인프라 및 성능 확장) — **post-v1 / pre-release guard**
> **목표:** 원본 vault를 유지한 채 파생 인덱스로 대규모 탐색을 가능하게 한다. akasha-db 규모는 **v1 blocking 아님**.

* **[x] v4 해시 샤딩:** manifest v4 · CDN — **optional catalog 인프라**
* **[x] registry_builder · CI gates:** 품질 자동화 — post-v1 scale 관측
* **[x] 10,048 works milestone:** 성과 보존 — v1 메시지에서 과장하지 않음
* **[x] Steam 릴리즈 빌드 패키징:** M2 (installer · 스토어 · 무료 출시)
* **[x] SA-03 derived index / Work projection:** 페이지·필터 ms급 · full rebuild는 명시적 복구 작업
* **[ ] (next scale gate) SA-05 Timeline projection:** 도메인별 bounded projection — Universal Record 금지
* **[ ] (post-v1) Derived vault indexes 확장:** tag · link · incoming · taste · snippet index
* **[ ] (post-v1) AI 자동 수집 파이프라인 (E1~E2):** 보류
* **[ ] (post-v1) 50k+ CDN 및 R2 확장:** 보류
* **[ ] (장기) Riverpod 마이그레이션:** 상태 관리 프레임워크 고도화 (보류)
* **[ ] (장기) 모바일 이관:** Windows 품질 안정화 후 크로스플랫폼 확장 (보류)

---

## 🗓️ 주요 마일스톤 진행 이력

* **M1 (기능 동결) ✅** — 기본 체크리스트 완료 및 430작 카탈로그 배포 (2026 Q2)
* **M-v4 (데이터 아키텍처 v4) ✅** — `wk_` 영구 ID, 해시 샤딩 v4 CDN 배포 완료 (2026-06-10)
* **M2 (Steam 출시 준비) ✅** — depot, 스토어 페이지, 무료 출시 기준 정리 (2026-06-13)
* **Wave 1 (Home 리팩터) ✅** — 홈 화면 뷰어 리팩터링 및 코디네이터 분리 (2026-06-14)
* **Phase 1 E2E ✅** — 발견/아카이브/기록/큐레이션 E2E 품질 검증 완료 (2026-06-14)
* **M3 (Steam v1 무료 출시) 🔶** — **개인 아카이브 중심** 무료 출시 진행 중
