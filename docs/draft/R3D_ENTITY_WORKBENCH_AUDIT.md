# R3-D Entity Workbench Audit — P1

> **갱신:** 2026-06-22  
> **방법:** `lib/` 코드 실측 (R3-C 이후)  
> **코드 수정:** 없음

---

## 검증 질문

Entity Preview = 탐험 중심, Entity Workbench = 편집 중심이라는 역할 분리가 코드에서 성립하는가?

**결론: 부분적 성립. Work 축은 대칭이나, Entity 축은 Preview가 Workbench보다 탐험 정보가 많다.**

---

## 분석 대상 파일

| 파일 | 역할 |
|------|------|
| `entity_detail_workspace.dart` | Entity Workbench 루트 (3·4열) |
| `entity_detail_info_panel.dart` | 좌측 정보 패널 |
| `entity_dashboard_preview_panel.dart` | Entity Preview (탐험) |
| `entity_link_neighbors.dart` | 이웃 데이터 조회 |
| `entity_link_neighbors_sections.dart` | 이웃 UI (Preview 전용) |
| `work_detail_info_form.dart` | Work Workbench 대칭 참조 |

---

## Preview vs Workbench — 정보 매트릭스

| 정보 | Entity Preview | Entity Workbench | 데이터 소스 |
|------|:--------------:|:----------------:|-------------|
| 제목·별칭·entityId | ✅ | ✅ | `UserCatalogEntity` |
| 포스터 | ✅ 120×120 | ✅ `WorkDetailInfoPoster` | entity / journal |
| **연결된 작품** | ✅ | ❌ | `fetchEntityLinkNeighbors` |
| **연결된 인물** | ✅ | ❌ | 동일 |
| **관련 사건** | ✅ | ❌ | 동일 |
| **관련 개념** | ✅ + tags | ❌ (tags만 편집) | 동일 / `draftTags` |
| incoming **건수** | ✅ 한 줄 | ✅ 경로 **목록** | `linkIndex.incomingRecordPaths` |
| incoming **경로 열기** | ❌ | ✅ `_IncomingLinksSection` | `RecordLinkNavigator` |
| same-day 기록 | ❌ | ✅ `_SameDaySection` | `SameDayRecordService` |
| 연결 맵 버튼 | ✅ | ✅ | `onGoKnowledgeGraph` |
| 빈 연결 CTA | ✅ `onRecordCta` | ❌ | — |
| journal 저장 | `기록하기 >` → Workbench | ✅ FilledButton | Sanctum |
| 태그 편집 | ❌ | ✅ `EditableTagChips` | — |
| 서재 담기 | ❌ | ✅ | — |
| Sanctum 편집 | ❌ | ✅ 4열 | `SanctumPagePanel` |

### Work 축 대칭 (참조)

| 정보 | Work Preview | Work Workbench |
|------|:------------:|:--------------:|
| 연결 4섹션 | ✅ | ✅ (`work_detail_info_form.dart` L121–128, `_loadLinkNeighbors`) |
| incoming 상세 | ❌ | ✅ |
| metadata | 읽기 전용 행 | 접힘 `ExpansionTile` |

**Entity Workbench만 연결 이웃 UI가 누락되어 Workbench < Preview 역전이 발생한다.**

---

## EntityDetailWorkspace 코드 사실

### 로드하는 데이터 (`initState`)

```dart
_loadIncoming();   // linkIndex.incomingRecordPaths
_loadSameDay();    // SameDayRecordService
// fetchEntityLinkNeighbors 호출 없음
```

### `EntityDetailInfoPanel` 레이아웃 순서

1. 포스터
2. 제목 · entityId · 별칭
3. 아카이브 상태
4. **태그 편집**
5. **저장 / 서재 / 삭제 버튼**
6. 연결 맵 버튼
7. **incoming Record 목록**
8. same-day 기록

연결 이웃 섹션 **없음**. 편집·관리 UI가 상단, 기록 맥락(incoming)이 하단.

---

## EntityDashboardPreviewPanel 코드 사실

1. 타입 배지 · 닫기
2. 아바타 · 제목 · 별칭 · entityId
3. **`기록하기 >`** (Workbench 진입)
4. `FutureBuilder` → `fetchEntityLinkNeighbors` → **`EntityLinkNeighborsSections`**
5. 연결 맵 버튼

탐험(연결)이 저장 CTA **아래**이지만, Workbench에는 연결 블록 자체가 없음.

---

## 중복 분석

| 요소 | 중복? | 판정 |
|------|-------|------|
| `EntityLinkNeighborsSections` | Preview만 사용 | Workbench **누락** — 중복 아님 |
| incoming 건수 vs 경로 목록 | 부분 중복 | Preview=요약, Workbench=상세 — **병합 가치 있음** |
| 연결 맵 버튼 | 양쪽 존재 | ✅ 허용 (동일 진입) |
| tags | Preview=표시, Workbench=편집 | 역할 분리 ✅ |
| `fetchEntityLinkNeighbors` | Preview만 호출 | Workbench에서 **재호출만** 하면 됨 (엔진 변경 없음) |

---

## 누락 분석 (Workbench 기준)

| 누락 | 탐험 루프 영향 |
|------|----------------|
| 연결된 작품/인물/사건/개념 | **높음** — Preview→Workbench 후 이웃 탐색 불가 |
| outgoing wiki 이웃 탭 | **높음** — `onOpenEntity`/`onOpenWork` 없음 |
| 빈 연결 CTA | **중간** — R3-C Work Preview만 적용 |
| incoming 요약 한 줄 | **낮음** — 경로 목록이 더 상세 |

---

## Workbench 진입 시 Preview 소실

`home_shell_body.dart` L444–455:

```dart
if (entityPreviewItem != null && !workbench.hasOpenDetail)
  EntityDashboardPreviewPanel(...)
```

`openEntityFromPreview()` → `closeAllPreviews()` + `workbenchCoord.openEntity()`  
→ `hasOpenDetail == true` → **Preview 패널 제거**

사용자가 Preview에서 연결을 본 뒤 「기록하기」로 들어가면 **연결 UI가 사라진 편집 화면**만 남음.

---

## R3-C 이후 Wiki 정책 (Entity 맥락)

`handleWikiLinkTap` (R3-C): `showBrowse()` → `openEntityPreview`  
Entity Workbench Sanctum에서 wiki 탭 시 **다른 Entity Preview**로 이동 — 편집 탭은 백그라운드 유지되나 Preview는 탐험 전환.

incoming/same-day: `onRecordOpenEntity` → Workbench 직행 (기록 맥락 예외).

---

## 헌법 정합

| 축 | Entity Preview | Entity Workbench |
|----|----------------|------------------|
| 발견 | ✅ 이웃 탭 | ❌ |
| 연결 | ✅ 표시 | ⚠️ incoming만 (역방향) |
| 기록 | CTA만 | ✅ Sanctum |
| 탐색 | ✅ | ❌ (연결 맵 버튼만) |

**Entity Workbench는 「편집기」로만 구현되어 있고 「탐험 허브」가 아니다.**

---

## P5 (R3-C) 결정 재확인

R3-C에서 Entity Workbench 연결 섹션 구현을 보류한 이유: Preview와 UI 중복.

**R3-D 재판정:** Work 축이 이미 Workbench 상단에 연결 섹션을 갖춘 상태에서, Entity만 Preview 독점은 **비대칭 버그**에 가깝다. 구현 시 **위젯 재사용**으로 중복 비용 최소화 가능.

---

## Audit 결론

| 항목 | 상태 |
|------|------|
| Preview > Workbench 연결 정보 | **확인됨** |
| Work ↔ Entity Workbench 대칭 | **불일치** |
| 데이터/API 추가 필요 | **없음** (`fetchEntityLinkNeighbors` 재사용) |
| 구현 위험 | 낮음 (UI 배선 + `_loadLinkNeighbors` 패턴 복제) |

다음: [R3D_ENTITY_WORKBENCH_REDESIGN.md](./R3D_ENTITY_WORKBENCH_REDESIGN.md)
