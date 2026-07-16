# R11 Registry ↔ Vault Discovery Bridge Audit

> **일자:** 2026-06-22  
> **유형:** 갭 분석 + Bridge 구현 스프린트 (R11)  
> **선행:** [R9_DISCOVERY_ENGINE_AUDIT.md](./R9_DISCOVERY_ENGINE_AUDIT.md), [R10_PLACE_ORG_AUDIT.md](./R10_PLACE_ORG_AUDIT.md)  
> **SSOT:** [PROJECT_CONSTITUTION.md](../history/closure-2026-07/PROJECT_CONSTITUTION_STUB.md), [CURRENT_STATE.md](../active/CURRENT_STATE.md)

**방법:** 코드 인용 기준 · Engine / Index / Registry 구조 변경 없음.

---

## Executive Summary

R9 시점 Discovery는 **Vault `link_index` 그래프만** 소비한다. Tier 1 **WorksRegistry 10k**는 Fusion Search·Browse·`itemFromRegistryWork` Preview로만 접근되며, **자동 neighbor 확장·LinkCandidate·Home Surface에는 미참여**했다.

R11은 **Proposal + Surface 레이어**에 Registry Bridge를 추가한다. Discovery Engine semantics는 그대로 두고, creator / tag / linked entity 신호로 **미아카이브 Registry Work**를 Surface에 노출한다.

| 질문 | R11 이전 | R11 이후 |
|------|----------|----------|
| Vault Work → Registry Work 발견 | ❌ (검색 수동만) | ✅ Bridge 후보 |
| creator 기반 Registry 탐색 | ⚠️ Fusion 쿼리만 | ✅ Preview · Home · Entity |
| Registry Work가 Discovery Graph 참여 | ❌ md 없음 | ⚠️ 아카이브 후만 |
| Registry vs Vault Preview 차이 | 암묵적 (filePath 없음) | ✅ 사전 배너 · 아카이브 CTA |
| Schema 변경 없이 Bridge 가능 | — | ✅ |

---

## 1. 분석 대상 현황 (R11 이전)

### 1.1 Registry Work Preview

| 항목 | 코드 | 판정 |
|------|------|------|
| 진입 | `home_dialogs_coordinator.openSearchDialog` → `HomeAutoArchive.itemFromRegistryWork` → `onPreviewLocalWork` | ✅ Preview만 |
| vault md | `filePath` 없음 · Link Index 미스캔 | ❌ 그래프 외부 |
| UI 구분 | `DashboardPreviewPanel` — Vault와 동일 레이아웃 | ❌ 사전 표시 없음 |
| 기록하기 | `openWorkFromPreview` → Workbench 강제 진입 | ❌ Bridge UX 부적합 |

### 1.2 itemFromRegistryWork

`home_auto_archive.dart` L86–106: `RegistryWork` → `AkashaItem` (creator · tags 복사). **메모리 Preview 전용** — vault 저장은 별도 `HomeRegistryArchive.persistRegistryWork`.

### 1.3 Registry Search

| 경로 | 역할 | Discovery Bridge |
|------|------|------------------|
| `FusionSearchService` | 쿼리 기반 10k + local | 사용자 주도 · neighbor 없음 |
| `WorksRegistry.search` | 인메모리 토큰 매칭 | **R11 후보 원천** (Index 변경 없음) |

### 1.4 LinkCandidateService · creator · tags · PersonSeed

| 신호 | 대상 | Registry Work |
|------|------|---------------|
| creator | Person seed / catalog | ❌ |
| tag | catalog Entity | ❌ |
| seed | PersonSeedRegistry | ❌ |

**판정:** LinkCandidate는 **Vault 내 Entity 연결 제안** 전용. Registry Work 제안 **없음**.

### 1.5 Preview / Discovery Surface

| Surface | Vault Graph | Registry Bridge (R11 전) |
|---------|:-----------:|:------------------------:|
| Work Preview neighbors | ✅ | ❌ |
| Home 오늘의 연결 | ✅ vault only | ❌ |
| Entity Preview | ✅ | ❌ |
| Knowledge Graph | ✅ vault only | ❌ |

---

## 2. Audit 질문 답변

### Q1. Vault Work에서 Registry Work를 발견할 수 있는가?

**R11 이전:** 사용자가 **Fusion Search**로만 가능. Vault Preview · neighbors · LinkCandidate 경로 **없음**.

**R11:** `RegistryDiscoveryCandidateService.candidatesForVaultWork` — creator / tag / linked entity → `WorksRegistry.search` (기존 API, Schema 무변경).

### Q2. creator 기반 Registry 탐색 경로가 있는가?

**R11 이전:** `FusionSearchService`가 local·remote `creator` 토큰 검색. **쿼리 필수** · Preview 연동 없음.

**R11:** Vault Work `creator` → 동일 creator Registry Work 자동 제안 (Interstellar → Nolan → Memento 등).

### Q3. Registry Work가 Discovery Graph에 참여하는가?

**아카이브 전:** ❌ — `record_link_index_service`는 vault `.md`만 스캔 (R9 §4.3).

**아카이브 후:** ✅ vault 노드로 편입 · 링크는 사용자 작성 시 그래프 확장.

Bridge는 **Graph 밖 제안 → Archive → Graph 편입** 흐름을 Surface에서 연결한다.

### Q4. Registry Preview와 Vault Preview의 차이는?

| | Vault Preview | Registry Preview |
|--|---------------|------------------|
| 데이터 | `vaultItems` + `filePath` | `itemFromRegistryWork` · filePath 없음 |
| neighbors | Link Index 기반 | 항상 0 (Engine 미변경) |
| R11 UI | Registry Bridge 섹션 | 사전 배너 · 아카이브 CTA · typeLabel `사전 ·` |
| 기록하기 | Workbench | **아카이브** (Preview 유지) |

### Q5. Bridge를 Schema 변경 없이 가능한가?

**가능.** 사용 API:

- `WorksRegistry.search` / `getWorkById` — 기존 in-memory
- `WorksRegistry.setContainsWorkId` — vault 중복 제외
- `RegistryVisibilityService.shouldMaterializeVirtual` — hidden/sibling 정책 재사용
- `EntityRelatedWorksDiscovery.entityIdsForWork` — linked entity (Engine semantics 무변경)
- `HomeRegistryArchive.persistRegistryWork` — 기존 아카이브

**금지 준수:** Search Index · Link Index Schema · Discovery Semantics · Registry 구조 · Preview Stack (`PreviewPanelChrome`) 미변경.

---

## 3. UI vs Engine 분리

| 레이어 | Registry R11 이전 | R11 Bridge |
|--------|-------------------|------------|
| Link Index / Discovery | Registry 미포함 (by design) | 변경 없음 |
| **RegistryDiscoveryCandidateService** | 없음 | **신규 Proposal** |
| Work / Entity Preview | vault only | + 사전 추천 섹션 |
| Home | vault only | + 사전에서 발견 |
| Registry Preview UX | 동일 | 배너 · 아카이브 · Preview 유지 |

---

## 4. 구현 계획 (R11)

### P0 — Registry Discovery Candidate (Work Preview)

- `registry_discovery_candidate_service.dart`
- `registry_discovery_candidates_section.dart`
- `dashboard_preview_panel.dart` — vault Work 하단 「사전에서 더 보기」

### P1 — Registry Recommendation Surface

- `home_dashboard_registry_bridge_section.dart`
- `entity_dashboard_preview_panel.dart` — Entity 맥락 사전 추천

### P2 — Registry Preview UX

- `vault_work_presence.dart` — registry-only 판별
- `work_preview_registry_surface.dart` — 사전 배너 · 아카이브 CTA
- `home_shell_controller.archiveRegistryWorkFromPreview` — Workbench 강제 진입 대신 아카이브 후 Preview 갱신
- `openWorkFromPreview` — registry-only 시 아카이브

---

## 5. 성공 기준 검증

```
Vault Work → creator/tag/entity → Registry Work (Preview 칩)
    → Archive → vault md → Link Graph 편입
```

| 단계 | R11 구현 |
|------|----------|
| Vault → Registry 발견 | Preview · Home · Entity Surface |
| Registry Preview | 사전 표시 · 탐험 push 스택 유지 |
| Archive | 볼트 CTA · 기록하기 → 아카이브 (registry-only) |
| Graph 편입 | 아카이브 후 기존 Engine |

---

## 6. 의도적 비범위

- Registry Work **자동 링크 생성** — 사용자 wiki 작성 유지
- Registry **3홉** neighbor — R9 천장(2홉 vault) 유지
- Fusion Search 대체 — Bridge는 **맥락 제안** 보조
