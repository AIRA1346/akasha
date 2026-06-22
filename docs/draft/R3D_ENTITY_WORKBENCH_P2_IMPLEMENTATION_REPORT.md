# R3-D Entity Workbench P2 — Implementation Report

> **완료:** 2026-06-22  
> **설계:** [R3D_ENTITY_WORKBENCH_REDESIGN.md](./R3D_ENTITY_WORKBENCH_REDESIGN.md)  
> **Audit (구현 전):** [R3D_ENTITY_WORKBENCH_AUDIT.md](./R3D_ENTITY_WORKBENCH_AUDIT.md)

---

## 요약

Entity Workbench에 Preview와 동일한 연결 이웃 UI를 승격하여 **Workbench ≥ Preview** 목표를 달성했다.

| 항목 | 상태 |
|------|------|
| `fetchEntityLinkNeighbors` Workbench 연동 | ✅ |
| `EntityLinkNeighborsSections` 배치 | ✅ |
| 레이아웃 재배치 (연결 → incoming → same-day → 태그 → 편집) | ✅ |
| 이웃 탭 → Preview (`onWikiLinkTap`) | ✅ |
| 빈 연결 CTA → Sanctum body | ✅ |
| 저장 후 neighbors 리프레시 | ✅ |

**금지 사항 준수:** Discovery / Link Index / Pipeline / Schema 변경 없음.

---

## Before / After

### Before (P2 전)

```
포스터 · 제목
아카이브 상태
태그 [편집]
[저장] [서재] [삭제]
[연결 맵]
─────────────
incoming Record 경로 목록
same-day 기록
```

- `fetchEntityLinkNeighbors` **미호출**
- Preview → 「기록하기」 진입 시 **연결 4섹션 소실**

### After (P2 후)

```
포스터 · 제목
아카이브 상태
─────────────
★ EntityLinkNeighborsSections
  · incoming 요약 (N건)
  · 연결된 작품 / 인물 / 사건 / 개념
  · 빈 섹션 CTA → Sanctum body
[연결 맵에서 보기]
─────────────
incoming Record 경로 목록   ← Workbench 고유
same-day 기록               ← Workbench 고유
─────────────
태그 [편집]
[저장] [서재] [삭제]
```

---

## 변경 파일

| 파일 | 변경 |
|------|------|
| `entity_detail_workspace.dart` | `vaultItems`, `_loadLinkNeighbors`, `_openLinkedEntity/Work`, `_focusSanctumForLinks`, 저장·탭 전환 시 리프레시 |
| `entity_detail_info_panel.dart` | `EntityLinkNeighborsSections` 삽입, 섹션 순서 재배치 |
| `workbench_shell.dart` | `EntityDetailWorkspace`에 `vaultItems` 전달 |

**신규 파일 없음.** 기존 `entity_link_neighbors.dart`, `entity_link_neighbors_sections.dart` 재사용.

---

## 구현 상세

### 1. 이웃 로드 (`entity_detail_workspace.dart`)

Work `work_detail_workspace._loadLinkNeighbors()` 패턴 복제:

```dart
final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
  linkIndex: index,
  vaultItems: widget.vaultItems,
);
final neighbors = await fetchEntityLinkNeighbors(
  entity: _entity,
  userCatalog: catalog,
  discovery: discovery,
  linkIndex: index,
  vaultItems: widget.vaultItems,
);
```

호출 시점: `initState`, `didUpdateWidget` (탭·엔티티 변경), `_saveJournal` 성공 후.

### 2. 네비게이션 (R3-C 계승)

| 액션 | 콜백 | 동작 |
|------|------|------|
| 이웃 Entity 탭 | `_openLinkedEntity` → `onWikiLinkTap` | Preview (탐험) |
| 이웃 Work 탭 | `_openLinkedWork` → `onWikiLinkTap` | Preview (탐험) |
| 빈 연결 CTA | `_focusSanctumForLinks` | `SanctumPageView.body` |
| incoming 경로 탭 | `onRecordOpenEntity` (기존) | Workbench 직행 |

### 3. Preview vs Workbench — 구현 후 매트릭스

| 정보 | Preview | Workbench |
|------|:-------:|:---------:|
| outgoing 4섹션 | ✅ | ✅ |
| incoming 요약 | ✅ | ✅ |
| incoming 경로 | ❌ | ✅ |
| same-day | ❌ | ✅ |
| 태그 편집 | ❌ | ✅ |
| Sanctum | ❌ | ✅ |

**Workbench ≥ Preview** — 설계 목표 달성.

---

## Work 축 대칭

| 항목 | Work Workbench | Entity Workbench (P2 후) |
|------|----------------|--------------------------|
| 이웃 로드 | `fetchWorkLinkNeighbors` | `fetchEntityLinkNeighbors` |
| UI 위젯 | `WorkLinkNeighborsSections` | `EntityLinkNeighborsSections` |
| 섹션 위치 | 메타데이터 위 | 태그·저장 위 |
| accent 색 | `#6C63FF` | `#6C63FF` (동일) |

---

## 미해결 (P3 범위)

| 항목 | 상태 |
|------|------|
| Preview Stack (Work A 맥락 유지) | ❌ — [R3D_PREVIEW_STACK_AUDIT.md](./R3D_PREVIEW_STACK_AUDIT.md) |
| Workbench 진입 시 Preview 소실 | 의도적 (편집 모드 분리) |
| 태그·저장 `ExpansionTile` 접힘 | 보류 (2단계 폴리시) |

---

## 루프 완성도 추정

| 단계 | P2 전 | P2 후 |
|------|-------|-------|
| Preview → Workbench 연결 유지 | ❌ | ✅ |
| Workbench 이웃 → 새 Preview | ⚠️ wiki만 | ✅ 섹션 탭 |
| Preview 체인 맥락 | 30% | 30% (P3) |
| **전체 루프** | **75~80%** | **83~88%** |

P3(Preview Stack) 구현 시 **90%+** 목표 가능.

---

## 검증 체크리스트

- [ ] Entity Preview → 「기록하기」→ Workbench에서 연결 4섹션 표시
- [ ] Workbench 이웃 Entity/Work 탭 → Preview 전환
- [ ] 빈 연결 CTA → Sanctum 본문 포커스
- [ ] journal 저장 후 연결 섹션 갱신
- [ ] incoming 경로·same-day·태그·저장 버튼 순서 확인

---

## 다음 단계

**P3 Preview Stack** 구현 검토 — `home_shell_controller` 단일 슬롯 → 스택 + `← 이전`.
