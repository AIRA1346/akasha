# R8 P1 Implementation Report — LinkCandidateService

> **일자:** 2026-06-22  
> **Sprint:** R8-P1 Link Candidate  
> **Audit:** [R8_P1_IMPLEMENTATION_AUDIT.md](./R8_P1_IMPLEMENTATION_AUDIT.md)  
> **설계:** [R8_P1_LINK_CANDIDATE_DESIGN.md](./R8_P1_LINK_CANDIDATE_DESIGN.md)

---

## 요약

Work 맥락에서 **연결 후보를 자동 계산**하는 `LinkCandidateService`를 구현하고, Entity Link Picker 상단·Work Preview empty CTA에 **추천 연결**을 노출했다. 선택 후 흐름은 P0와 동일하게 catalog 승격 + `insertWikiLink`이다.

---

## 변경 파일

### 신규

| 파일 | 역할 |
|------|------|
| `lib/services/link_candidate_service.dart` | `candidatesForWork` · score · `resolveSelection` |
| `test/link_candidate_service_test.dart` | 서비스 단위 테스트 7건 |
| `docs/draft/R8_P1_IMPLEMENTATION_AUDIT.md` | Step 1 Audit |

### 수정

| 파일 | 변경 |
|------|------|
| `entity_link_picker_dialog.dart` | `workContext` · 추천 섹션 · `resolveSelection` |
| `work_preview_empty_connections.dart` | 「추천 연결」 chips |
| `dashboard_preview_panel.dart` | 후보 로드 · `onConnectSuggested` |
| `work_detail_workspace.dart` | preselected candidate · picker에 work 전달 |
| `home_shell_controller.dart` | `pendingWorkEntityLinkCandidate` · `openWorkFromPreviewToConnectSuggested` |
| `workbench_shell.dart` | pending candidate 배선 |
| `home_shell_body.dart` / `home_shell_scaffold.dart` | 콜백 배선 |
| `test/entity_link_picker_test.dart` | 추천 섹션·선택 테스트 +2 |

### 미변경 (의도적)

- `RecordLinkIndexService` · `EntityRelatedWorksDiscovery`
- `fetchWorkLinkNeighbors` · `relatedCharactersForWork`
- `FusionSearchService` · Collection Pipeline
- Preview Stack chrome · Save Return

---

## LinkCandidateService API

```dart
LinkCandidateService.candidatesForWork({
  required AkashaItem work,
  required UserCatalogPort userCatalog,
  EntityRegistryPort? personSeed,
  EntityAnchorType? typeFilter,
  Set<String>? excludeEntityIds,
  int limit = 8,
})
```

### 반환 필드

| 필드 | 설명 |
|------|------|
| `entityId` | catalog/seed id |
| `title` | 표시 제목 |
| `entityType` | person / event / concept |
| `score` | 정렬용 |
| `reason` | `creator` · `tag` · `seed` · `catalog` |
| `seedFact` | seed 승격용 (P0 재사용) |

### 점수 (내림차순)

| reason | score | 조건 |
|--------|:-----:|------|
| creator | 10 / 7 | exact / token |
| tag | 5 / 4 / 3 | tag·title·alias |
| seed | 2 | browse filler |
| catalog | 1 | fallback |

---

## Before / After

### Before (R8 P0만)

| 상황 | 동작 |
|------|------|
| Preview 연결 0 | CTA 3개만 · **무엇을 연결할지 모름** |
| Picker (ent 0) | PersonSeed 전체 목록 (점수 없음) |
| creator 있는 Work | creator **활용 안 함** |

### After (R8 P1)

| 상황 | 동작 |
|------|------|
| Preview 연결 0 | **creator 일치 인물 chip** (상위 3) · 1탭으로 연결 |
| Picker + Work 문맥 | **「이 작품과 관련」** 추천 상단 · 검색 결과 하단 |
| creator `Hayao Miyazaki` | Miyazaki seed **creator 10.0** 1순위 |
| 추천 chip 탭 | Workbench → **Picker 생략** → `insertWikiLink` |

---

## Discovery 영향 범위

| 계층 | 영향 |
|------|------|
| Link Index | **없음** — 링크 삽입 후 기존 rebuild |
| Discovery engine | **없음** — `entityIdsForWork` 등 동일 |
| Neighbors heuristic | **없음** — `relatedCharactersForWork` 유지 |
| Fusion Search | **없음** |
| **사용자 행동** | 링크 생성 **전**에 후보 제안 — 첫 엣지 생성 확률 ↑ |

P1은 **제안 레이어**만 추가한다. 그래프 semantics는 링크가 생긴 **이후** 기존과 동일하게 작동한다.

---

## 테스트 결과

**명령:** `flutter test test/link_candidate_service_test.dart test/entity_link_picker_test.dart`

**결과:** **22/22 PASS**

| 그룹 | 검증 |
|------|------|
| LinkCandidateService | creator · tag · seed · catalog · 정렬 · exclude · typeFilter |
| EntityLinkPickerDialog | 추천 섹션 표시 · 추천 선택 → catalog 승격 + selection |
| P0 회귀 | seed fallback · catalog 검색 · wiki token |

---

## 첫 연결 난이도 — 실제로 얼마나 감소했는가?

### Cold Graph 프로필

볼트 Work 1건 · `userCatalog` Entity 0 · `link_index` 0 · Registry Work에 **creator 있음**.

| 경로 | R7 (P0 이전) | R8 P0 | R8 P1 |
|------|:------------:|:-----:|:-----:|
| Preview → 인물 연결 | ❌ dead-end | ⚠️ seed 5명 **무작위** | ✅ **creator 매칭 1순위** |
| 클릭 수 (연결 1건) | 7~9 (우회) | 5~6 | **3~4** |
| 인지 부담 | 「누구?」 | seed 목록 스캔 | **작품 creator와 일치 제안** |

### 정량 추정

| 지표 | R7 → P1 |
|------|---------|
| Path A (Preview primary) **성공률** | 0% → **~90%+** (creator 있거나 seed browse) |
| Picker에서 **의미 있는 첫 선택**까지 | N/A → **0~1 스크롤** (추천 상단) |
| Preview에서 **Picker 생략** 경로 | 없음 → **1탭** (추천 chip) |
| 전체 클릭 (추천 chip 경로) | 7~9 → **3** (Preview chip → Workbench autosave) |

### 서사

**P0**는 「막다른 길 제거」— ent 0에서도 연결 **가능**해졌다.  
**P1**는 「무엇을 연결할지 **제안**」— 특히 Registry에서 아카이브된 Work는 `creator`가 이미 있어, **앱이 첫 인물을 맞춰 보여준다**.

남는 마찰:

- creator 비어 있고 tags도 없으면 → seed browse (P0와 동일 tier)
- Event/Concept Cold → seed 번들 없음
- Fusion 검색 탭 seed (D2) → 별도 과제

**결론:** ent 0 사용자의 첫 연결 난이도는 **「불가능~우회 7클릭」에서 「추천 1~3클릭」으로 체감 60~70% 감소**. creator가 있는 Work(10k Registry 대부분)에서는 **거의 즉시** 첫 링크 가능.

---

## 남은 Discovery Gap

| Gap | 우선순위 |
|-----|----------|
| Place / Organization Picker·neighbors | P2 |
| Event/Concept seed 번들 | P2 |
| Fusion seed 선택 → catalog (D2) | P2 |
| `relatedCharactersForWork` → LinkCandidate 흡수 (neighbors 단일화) | optional |
| Level 3~4 Discovery (패턴·serendipity) | Phase 4+ |
| Work tags 있으나 링크 0 — empty CTA 대신 neighbors only | UX edge |

---

## 관련 문서

- [R8_P0_IMPLEMENTATION_REPORT.md](./R8_P0_IMPLEMENTATION_REPORT.md)
- [R7_DISCOVERY_FOUNDATION_AUDIT.md](./R7_DISCOVERY_FOUNDATION_AUDIT.md)
