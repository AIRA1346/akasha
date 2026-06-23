# R8 P2 Implementation Report — Discovery Surface

> **일자:** 2026-06-22  
> **Sprint:** R8-P2 Discovery Surface  
> **Audit:** [R8_P2_DISCOVERY_SURFACE_AUDIT.md](./R8_P2_DISCOVERY_SURFACE_AUDIT.md)

---

## 요약

연결 **후** Discovery 체감을 높이기 위해 Home · Preview · Graph **Surface**만 강화했다. Discovery Engine · Link Index · neighbors semantics **무변경**.

---

## 구현 항목

### P2-A — Home 「오늘의 연결」

**파일:** `home_dashboard_todays_links_section.dart`

| 변경 | 내용 |
|------|------|
| Work 우선순위 | **링크 수 내림차순** → addedAt |
| 타입 확장 | events · concepts 하이라이트 포함 |
| 연결 제안 | 링크 0 Work → `LinkCandidateService` 1건 「연결 제안」카드 |
| 갱신 | `linkIndex` 변경 시 재로드 |
| Home 탭 | `connectSuggestedForWork` → Workbench 연결 |

### P2-B — 링크 직후 발견

**파일:** `dashboard_preview_panel.dart`, `knowledge_graph_view.dart`

| 변경 | 내용 |
|------|------|
| Preview neighbors | `vaultItems`/`linkIndex` 변경 시 **neighbors 재로드** (Save Return 후 반영) |
| Graph counts | `didUpdateWidget` — vault/index 갱신 시 연결 수 **재계산** |

### P2-C — Preview 「다음으로 탐험할 연결」

**파일:** `work_preview_next_connections.dart`, `dashboard_preview_panel.dart`

| 변경 | 내용 |
|------|------|
| 조건 | `neighbors.hasAnyLink` 일 때 |
| 데이터 | `LinkCandidateService` + `excludeEntityIds: linked` |
| UI | chips 3개 · `onConnectSuggested` 재사용 |

---

## 변경 파일

| 파일 | P2 |
|------|-----|
| `home_dashboard_todays_links_section.dart` | A |
| `home_dashboard_view.dart` | A wiring |
| `dashboard_preview_panel.dart` | B + C |
| `work_preview_next_connections.dart` | C 신규 |
| `knowledge_graph_view.dart` | B |
| `home_shell_controller.dart` | `connectSuggestedForWork` |
| `home_shell_body.dart` / `home_shell_scaffold.dart` | 배선 |

---

## 금지 사항 준수

Search Index · Recall · Link Index Schema · Discovery Semantics · Collection Pipeline · Registry Sync · Preview Stack chrome · Save Return — **모두 유지**.

---

## 테스트

| 명령 | 결과 |
|------|------|
| `flutter test test/link_candidate_service_test.dart test/entity_link_picker_test.dart` | 22/22 PASS |
| `flutter test test/views/home_dashboard_view_test.dart` | (기존) |

---

## Before / After

| Surface | Before | After |
|---------|--------|-------|
| 오늘의 연결 | 최신 Work · Person/Work만 | **링크 밀도 우선** · event/concept · **연결 제안** |
| Preview (연결 후) | neighbors만 | **다음 탐험** chips |
| Preview (Save Return) | neighbors stale 가능 | **index 갱신 시 재로드** |
| Graph | counts 초기 1회 | **vault 변경 시 갱신** |

---

## 남은 Gap

- 「최근 발견」은 여전히 addedAt 기반 (의도적 분리)
- Graph 노드 시각화 · 3홉 proactive surfacing
- Place/Organization neighbors
- 링크 타임스탬프 기반 「오늘」정렬 (Schema 필요)

---

## 연결 → 발견 체감

P1이 **첫 엣지 생성**을 해결했다면, P2는 엣지 생성 **직후** 앱이 **2홉 Work · 미연결 후보 · 홈 하이라이트**를 Surface에 노출해 Level 1→2 **pull 경험**을 강화한다.
