# AKASHA Roadmap (로드맵)

> **지위:** 프로젝트 개발 로드맵 SSOT (5대 정체성 카테고리 기준)
> **갱신:** 2026-07-12 — 권위 계층 정렬 · Steam v1 = Free Personal Sanctum Archive
> **최상위 지침:** [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) · [VISION.md](VISION.md) · [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md)
> **기능 거부 기준:** Constitution §8 (구 PROJECT_CONSTITUTION 필터는 [historical](../history/PROJECT_CONSTITUTION.md))

---

## Steam v1 우선순위 (2026-06-30)

**v1은 글로벌 작품 사전 앱이 아니라 개인 아카이브 앱이다.**

| 우선 | 카테고리 | v1에서 |
|:----:|----------|--------|
| **P0** | **A. Archive** | 핵심 — vault · Sanctum · 기록 UI |
| **P0** | **D. Personal Library** | 핵심 — 서재 · Collection |
| P1 | C. Knowledge Graph | 기존 Workbench·연결 — 확장은 post-v1 |
| — | B. Discovery | **optional** — starter catalog 검색 유지 |
| — | E. Scale | **post-v1** — akasha-db 확장·CDN 트랙 |

**Steam v1 무료 출시:** 사용자 지시에 따라 진행. dogfood는 **사용자 직접 완료**. 유료 테마/IAP는 post-launch 보류.

---

## 📌 로드맵 핵심 원칙 (Feature Audit Filter)
모든 신규 기능은 아래 5개 핵심 카테고리 중 하나에 기여해야 하며, 의사결정 필터(**기록 / 연결 / 발견**)를 통과해야 합니다.
**v1에서는 「기록」이 발견·규모 확장보다 항상 우선**합니다.

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
* **[ ] (pre-release next) Operation crash recovery marker:** write 성공 후 log 실패 상황을 roll-forward
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
* **[ ] (post-v1) 외부 API 연동:** TMDB · IGDB — 보류

---

## 📂 C. Knowledge Graph (지식 그래프 & 연결)
> **목표:** 작품을 넘어 인물·사건·장소·개념이 연결되는 문화 지식 네트워크 구축

* **[x] `wk_` 영구 ID 및 Entity-Record 분리:** 데이터 모델 개편 완료 (Tier 1 vs Tier 2)
* **[x] 워크벤치 Multi-tab 환경:** Work 탭과 Entity 탭의 다중 레이아웃 및 탭 동기화
* **[x] Phase 6.2 Workbench Parity:** 엔티티 상세 정보와 마크다운 편집기 통합
* **[x] Phase 6.3 incoming/sameDay 패널 (진행 중):** `SameDayRecordRef` 및 역방향 `incoming` 링크 표시 통합 마이그레이션
* **[ ] Phase 3 Entity Types (미착수):** Work 이외의 Person, Event, Place, Concept 스키마 정의 및 지원
* **[ ] Phase 5 Connection (미착수):** 위키식 `[[링크]]` 지원 및 Record ↔ Entity 자유 연결 그래프

---

## 📂 D. Personal Library (나의 서재 & 큐레이션) — **v1 핵심**
> **목표:** 단순 목록을 넘어 사용자가 구성한 의미 있는 지식 공간 (Curated Space)

* **[x] 나의 서재 기본 뷰:** 아카이브한 작품만 모아 보는 전용 홈 모드 구축
* **[x] 대시보드-서재 역할 분리:** 카탈로그 탐색 공간(Dashboard)과 나의 기록 공간(Library) 정비
* **[x] 나의 서재 테마 커스텀:** 배경색/테마 프리셋 피커. v1 테마는 무료 제공, 결제 연동은 post-launch 보류
* **[x] Cast Collection / Hero Collection:** 인물·속성별 큐레이션 컬렉션 연동 기능
* **[ ] (v1.1+) 서재 진열 방식 커스텀:** 그리드 밀도 및 표시 항목 개인화 (보류)
* **[ ] (장기) Mixed Library:** 서로 다른 매체의 기록을 하나의 컬렉션으로 통합 (보류)

---

## 📂 E. Scale (인프라 및 성능 확장) — **post-v1 track**
> **목표:** akasha-db·CDN·대규모 catalog — **v1 출시 blocking 아님**. 엔지니어링 자산으로 유지.

* **[x] v4 해시 샤딩:** manifest v4 · CDN — **optional catalog 인프라**
* **[x] registry_builder · CI gates:** 품질 자동화 — post-v1 scale 관측
* **[x] 10,048 works milestone:** 성과 보존 — v1 메시지에서 과장하지 않음
* **[x] Steam 릴리즈 빌드 패키징:** M2 (installer · 스토어 · 무료 출시)
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
