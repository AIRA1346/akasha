# Code Quality Review Report — MVR 종합 (Phase 4)

> **일자:** 2026-06-12  
> **범위:** MVR 2.5일 상당 — Phase 0~1 + 3B + E3/E4 + 종합 판정  
> **Full Review 잔여:** Phase 2 E1/E5 · Phase 3A Registry · Phase 3C Workbench → **출시 후**  
> **입력:** [baseline](code-metrics-baseline.md) · [structure](code-quality-structure-review.md)

---

## 1. Executive Summary (출시 관점)

AKASHA 앱 코드는 **v1 Steam 출시에 구조적 blocker는 없다 (전 축 Amber/Green)**.  
Registry·CI·도메인 분리(Tier1/Tier2, membership apply SSOT)는 **성숙**했고, repo cleanup 이후 analyze·test gate도 green이다.

**핵심 기술부채는 한 곳:** `home_screen.dart` (1385줄, 70 import)에 오케스트레이션·UI가 남아 있어, v1.1 기능 추가 시 **변경 반경이 커질 위험**이 있다. 다만 `HomeRegistrySync`·`LibraryMembershipApply`·`MyLibraryPipeline` 등 **확장할 패턴이 이미 존재**하므로, 출시 후 coordinator 추출로 흡수 가능한 **Amber** 수준이다.

**M2 blocking 이슈(IAP microtxn, P0 QA)는 구조가 아니라 기능·운영** — `EntitlementService` 경계는 깨끗하며 Steamworks 배선만 남음.

---

## 2. 점수표 (D1~D6)

| 축 | 등급 | 한 줄 근거 |
|----|:----:|------------|
| **D1 결합** | 🟡 Amber | `home_screen` God object · registry static 전역 |
| **D2 응집** | 🟡 Amber | 500줄+ 6개 · 일부는 도메인 복잡도 정당화 |
| **D3 확장** | 🟡 Amber | 5k 앱 성능 OK · E1 카테고리 추가는 다점 터치 |
| **D4 테스트** | 🟡 Amber | unit 254 green · `testWidgets` 10 · 싱글톤 mock 부분적 |
| **D5 일관성** | 🟡 Amber | Controller 네이밍 혼재 · policy/config 계층은 양호 |
| **D6 성능** | 🟢 Green | 490/5k validation 문서상 무위험 · home `setState`는 관찰 대상 |

**종합:** 🟡 **Amber** — 출시 가능 · v1.1에서 국소 리팩터 권장

---

## 3. Must-fix (출시 전) — 구조 · 최대 3건

| # | 항목 | 태그 | 조치 |
|---|------|------|------|
| — | *(구조 Red 없음)* | `structure` | MVR 기준 **Must-fix 0건** |

**정책 (코드 변경 없음):**

- `home_screen`에 **신규 비즈니스 로직 추가 금지** — coordinator/service로만 확장
- M2 IAP는 `EntitlementService` + Steam callback **단일 배선** 유지

---

## 4. Must-fix — 기능·운영 (구조와 분리)

| # | 항목 | 태그 | M2 |
|---|------|------|:--:|
| F1 | Steam IAP `purchaseCosmetic` → `grantCosmeticEntitlement` | `feature` | ⏳ |
| F2 | Release exe P0 QA 12건 | `ops` | ⏳ |
| F3 | Steam depot·Privacy URL | `ops` | ⏳ |

→ [release-readiness-checklist.md](../release-readiness-checklist.md) R3~R6

---

## 5. Should-fix (v1.1) — Top 5

> 실행 계획: [app-architecture-refactor-plan.md](../programs/app-architecture-refactor-plan.md) §8

| 순위 | 항목 | 축 | 추정 |
|:----:|------|-----|------|
| 1 | `HomeMembershipCoordinator` — 담기 wiring 화면에서 이전 | D1 | 2~3일 |
| 2 | curated 담기 + browse smoke `testWidgets` | D4 | 1일 |
| 3 | `fusion_search_dialog` → service 추출 | D2 | 2일 |
| 4 | Controller 네이밍/문서 정리 (또는 ChangeNotifier 통일) | D5 | 1~2일 |
| 5 | 490 manifest 앱 cold start 실측 기록 | D6 | 0.5일 |

---

## 6. Won't-fix / Defer

| 항목 | 이유 |
|------|------|
| Riverpod 전면 | ROADMAP v1.1+ |
| `home_screen` 1PR 전면 분할 | 출시 diff |
| `works_registry` static 제거 | 5k까지 불필요 |
| tool/ 113파일 전수 검토 | MVR 범위 외 |
| 5k synthetic 재실험 | 기존 validation SSOT 충분 |

---

## 7. 대안 비교 (Amber 항목)

### 7.1 홈 상태 관리

| 안 | 비용 | v1 적합 | 비고 |
|----|------|:-------:|------|
| **A. coordinator 확대** (현행) | 낮음 | ✅ | `HomeRegistrySync` 패턴 확장 |
| B. Riverpod scope | 높음 | ❌ | 전면 마이그레이션 |
| C. Home `ChangeNotifier` 통일 | 중간 | 🔶 | setState 제거에 유리 |

**권장:** A → v1.1에서 C 일부 검토

### 7.2 IAP

| 안 | 비용 | v1 적합 |
|----|------|:-------:|
| **A. EntitlementService 스텁 유지 + Steam 배선** | 낮음 | ✅ |
| B. UI에서 Steam API 직접 호출 | 낮음 | ❌ 경계 파괴 |

---

## 8. 확장 시나리오 요약 (MVR)

| ID | 비용 | MVR 결론 |
|----|:----:|----------|
| E1 새 MediaCategory | **M** | enums·parser·folder·chip 다점 — 체크리스트화됨 |
| E2 curated 필드 | **S** | `PersonalLibraryConfig` + storage |
| E3 5k manifest | **S** (앱) | 성능 Red 아님 · 공급은 data 트랙 |
| E4 Steam IAP | **S** (구조) | 단일 서비스 · **기능 미완** |
| E5 discovery insert | — | tool only · Full Review |
| E6 i18n | **L** | ARB 미도입 |

---

## 9. Full Review 잔여 백로그

| Phase | 내용 | 시점 |
|-------|------|------|
| 2.1 | E1 체크리스트 실측 | v1.1 |
| 2.3 | E5 discovery 경로 추적 | 카탈로그 G1+ |
| 3A | Registry 런타임 심층 | 5k 실측 전 |
| 3C | Workbench E2 재사용성 | E2 마일스톤 |
| 1.2 | services 의존 그래프 mermaid | 여유 시 |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-12 | MVR 실행 — Phase 0~1, 3B, E3/E4, Phase 4 종합 |
