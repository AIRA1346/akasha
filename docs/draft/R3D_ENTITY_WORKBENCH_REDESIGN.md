# R3-D Entity Workbench Redesign — P2

> **갱신:** 2026-06-22  
> **전제:** [R3D_ENTITY_WORKBENCH_AUDIT.md](./R3D_ENTITY_WORKBENCH_AUDIT.md)  
> **제약:** Discovery / Link Index / Schema 변경 없음 · 기존 위젯 재사용

---

## 설계 질문

> Entity Workbench가 Preview보다 더 많은 연결 정보를 보여주는가?

**현재:** 아니오. Preview가 outgoing 이웃 4섹션 + incoming 건수를 갖고, Workbench는 incoming 경로 + same-day만 갖는다.

**목표:** Workbench ≥ Preview (탐험) + 편집 고유 기능 (incoming 상세, same-day, tags, Sanctum).

---

## 역할 재정의

| 계층 | 역할 | Entity에서의 의미 |
|------|------|-------------------|
| **Preview** | 가벼운 탐험 · 연결 훑어보기 | 「이 인물이 어디에 연결되나」 |
| **Workbench** | 탐험 허브 + 기록 | 「연결을 확인하고 journal을 쓴다」 |

Workbench는 Preview를 **대체**하지 않고 **확장**한다. Preview 진입 없이 Workbench를 열어도 (Records, promote) 연결 구조를 볼 수 있어야 한다.

---

## 현재 vs 목표 레이아웃

### 현재 (`entity_detail_info_panel.dart`)

```
포스터
제목 · entityId · 별칭
아카이브 상태
태그 [편집]
[저장] [서재] [삭제]
[연결 맵]
─────────────
incoming Record N개 (경로 목록)
same-day 기록
```

### 목표 (Work `work_detail_info_form.dart` 대칭)

```
포스터
제목 · entityId · 별칭
아카이브 상태
─────────────
★ 연결 (최상단 — 탐험 허브)
  · incoming 요약 (N건)
  · 연결된 작품
  · 연결된 인물
  · 관련 사건
  · 관련 개념
  · [연결 맵에서 보기]
  · 빈 섹션 CTA → Sanctum 포커스
─────────────
incoming Record 상세 (경로 목록)  ← Workbench 고유
same-day 기록                    ← Workbench 고유
─────────────
태그 [편집]                       ← 접힘 또는 하단
[저장] [서재] [삭제]
```

**원칙:** outgoing 이웃 = Preview와 동일 위젯 · incoming 상세 = Workbench만 유지.

---

## 구현 설계 (코드 변경 예정 — Audit 후)

### 1. `EntityDetailWorkspace` — 이웃 로드

Work `work_detail_workspace.dart` `_loadLinkNeighbors()` 패턴 복제:

```dart
EntityLinkNeighbors _linkNeighbors = const EntityLinkNeighbors();
bool _loadingLinkNeighbors = false;

Future<void> _loadLinkNeighbors() async {
  // fetchEntityLinkNeighbors(entity, userCatalog, discovery, linkIndex, vaultItems)
}
```

호출 시점: `initState`, journal 저장 후 (`_saveJournal` 성공), vault 갱신 시(선택).

### 2. `EntityDetailInfoPanel` — 파라미터 추가

| 신규 prop | 타입 |
|-----------|------|
| `linkNeighbors` | `EntityLinkNeighbors` |
| `loadingLinkNeighbors` | `bool` |
| `entityTags` | `List<String>` |
| `onOpenLinkedEntity` | `void Function(UserCatalogEntity)?` |
| `onOpenLinkedWork` | `void Function(AkashaItem)?` |
| `onFocusSanctumForLinks` | `VoidCallback?` |

### 3. UI 삽입 위치

`EntityDetailInfoPanel` — 아카이브 상태 **다음**, 태그 **이전**:

```dart
EntityLinkNeighborsSections(
  neighbors: linkNeighbors,
  entityTags: draftTags,
  loading: loadingLinkNeighbors,
  onOpenEntity: onOpenLinkedEntity,
  onOpenWork: onOpenLinkedWork,
  onRecordCta: onFocusSanctumForLinks,
  sectionTitleStyle: /* Workbench accent, Work와 동일 */,
),
if (onGoKnowledgeGraph != null) ... /* 기존 버튼 */,
const Divider(),
// 기존 incoming · same-day 유지
```

### 4. 네비게이션 배선

| 액션 | 콜백 | 정책 (R3-C 계승) |
|------|------|------------------|
| 이웃 Entity 탭 | `handleWikiLinkTap` → `openEntityPreview` | 탐험 |
| 이웃 Work 탭 | `openWorkPreview` | 탐험 |
| 빈 CTA | `_focusSanctumBody()` | 편집 |
| incoming 경로 탭 | `onRecordOpenEntity` | 기록 맥락 · Workbench |

Entity Workbench에서 이웃 탭 시 `workbench.showBrowse()` + Preview (R3-C와 동일).

### 5. incoming 중복 처리

| Preview | Workbench (목표) |
|---------|------------------|
| `incomingLinkCount` 한 줄 | `EntityLinkNeighborsSections` 상단 요약 **+** `_IncomingLinksSection` 경로 목록 |

요약·상세 **병치** — 정보 손실 없음.

### 6. 메타데이터 접힘 (선택, 2단계)

1단계: 태그·저장 버튼을 연결 섹션 **아래**로만 이동 (접힘 없이).  
2단계: Work처럼 `ExpansionTile`로 태그·저장 묶기.

**1단계만으로도 탐험 허브화 목표 달성.**

---

## Workbench vs Preview — 목표 매트릭스

| 정보 | Preview | Workbench (목표) |
|------|:-------:|:----------------:|
| outgoing 4섹션 | ✅ | ✅ |
| incoming 요약 | ✅ | ✅ |
| incoming 경로 | ❌ | ✅ |
| same-day | ❌ | ✅ |
| 태그 편집 | ❌ | ✅ |
| Sanctum | ❌ | ✅ |
| 기록하기 CTA | ✅ | — (이미 내부) |

**Workbench ≥ Preview** 달성.

---

## 변경 파일 (구현 Sprint)

| 파일 | 변경 |
|------|------|
| `entity_detail_workspace.dart` | `_loadLinkNeighbors`, 콜백 배선 |
| `entity_detail_info_panel.dart` | 섹션 재배치, `EntityLinkNeighborsSections` |
| `workbench_shell.dart` | wiki/preview 콜백 (기존 유지) |

**신규 파일 없음.** `entity_link_neighbors_sections.dart` 재사용.

---

## 금지 사항 준수

| 항목 | 준수 |
|------|------|
| `fetchEntityLinkNeighbors` 로직 변경 | ❌ 불필요 |
| Link Index | ❌ |
| Discovery | ❌ |
| 새 엔티티 타입 | ❌ |

---

## 성공 기준 (P2)

1. Entity Preview → 「기록하기」→ Workbench 후에도 **연결 4섹션**이 보인다.
2. Workbench에서 이웃 탭 → Preview (탐험 루프 유지).
3. Work Workbench와 **시각·정보 대칭** (accent 색·섹션 순서).

---

## 루프 기여도 추정

| 단계 | P2 전 | P2 후 |
|------|-------|-------|
| Entity Preview → 연결 확인 | ✅ | ✅ |
| → Workbench → **다시 연결 확인** | ❌ | ✅ |
| Workbench에서 이웃 → 새 Preview | ⚠️ wiki만 | ✅ 섹션 탭 |

**탐험 루프 완성도: +8~10%p** (전체 75~80% → 83~88%).

Preview Stack (P3)과 합치면 90%+ 목표 가능.

---

## 구현 우선순위

| 순위 | 작업 | ROI |
|------|------|-----|
| 1 | `_loadLinkNeighbors` + 섹션 삽입 | 최고 |
| 2 | `onOpenLinkedEntity/Work` Preview 배선 | 높음 |
| 3 | 저장 후 neighbors 리프레시 | 중간 |
| 4 | 태그·저장 접힘 | 낮음 (폴리시) |
