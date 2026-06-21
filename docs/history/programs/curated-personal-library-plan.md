# Curated Personal Library — 나만의 서재 큐레이션 설계

> **상태:** v1 curated **구현 완료** (2026-06-10) · v1.1 백로그: E2 워크벤치 polish · Case D 잔여  
> **기준일:** 2026-06-10  
> **지위:** `PersonalLibraryConfig` · `MyLibraryPipeline` 확장 SSOT  
> **상위:** [product-vision.md](../product-vision.md) · [ROADMAP.md](../../ROADMAP.md) M1 나만의 서재

---

## 1. 한 줄

**나만의 서재 = 사용자가 고른 `wk_` 목록(멤버십) + 기존 필터(매체·상태)를 함께 적용하는 큐레이션 뷰.**

`.md`는 “읽음”이 아니라 **볼트에 연동된 작품**을 뜻한다. 읽을 예정도 `.md` + YAML 상태로 표현하고, 서재에 담을 수 있다.

---

## 2. 제품 결정 (확정)

| # | 결정 | 근거 |
|---|------|------|
| D1 | **담기 대상 = 볼트 `.md`가 있는 작품** (없으면 담기 시 `.md` 생성) | Tier 2 철학 · “읽을 예정”은 주로 `myStatus`로 표현 |
| D2 | **멤버십은 서재 쪽에 `workId` 목록** — 각 작품 `.md`에 서재 ID를 쓰지 않음 | 서재 추가·삭제 시 전체 md 스캔/수정 방지 |
| D3 | **멤버십 + 필터** 동시 지원 | “인생 명작” 서재 안에서 만화/애니 필터 전환 |
| D4 | **`master_archive`는 기존 유지** (전체 볼트 작품 + 필터) | 기본 서재 · 삭제·이름 변경 불가 |
| D5 | **커스텀 서재만 explicit 멤버십** | 역할 분리: master=전체, custom=내가 고른 subset |
| D6 | **담기 1순위 UX = 드래그 앤 드롭** | 카드 → 사이드바 서재 · 시트/메뉴는 보조 |
| D7 | **`memberOrder` 단일 SSOT** | 멤버십·정렬 모두 `memberOrder: string[]` · Set은 파생 |
| D8 | **저장소 단일 쓰기** | 볼트 로드 성공 시 prefs 서재 데이터 삭제 · split-brain 방지 |

---

## 3. 현재 vs 목표

### 3.1 현재 (v1 구현됨)

```
PersonalLibraryConfig
  ├── name, domain, categories, workStatuses, myStatuses
  └── inclusionRules (저장만, 파이프라인 미사용)

MyLibraryPipeline
  └── 볼트 아카이브 전체 → 필터 → FranchiseFusion (전체 규칙)
```

커스텀 서재를 만들어도 **“만화만”“완료만” 같은 조건 뷰**일 뿐, **원하는 작품만 골라 담기**는 불가.

### 3.2 목표

```
PersonalLibraryConfig (curated)
  ├── memberOrder: [wk_..., wk_...]   ← 멤버십 + 표시 순서 SSOT (D7)
  └── filters (domain, categories, statuses)  ← 2차 좁히기

MyLibraryPipeline (curated)
  └── vault items ∩ memberOrder → filters → scoped fusion
```

---

## 4. 데이터 모델

### 4.1 `PersonalLibraryMode`

| mode | 대상 서재 | 멤버십 | 필터 |
|------|-----------|--------|------|
| `filter` | `master_archive` **+ 레거시 커스텀 서재** | 없음 (볼트 전체) | ✅ |
| `curated` | **신규** 사용자 생성 서재 | `memberOrder` | ✅ (멤버 위에 적용) |

**파이프라인 3갈래:**

```
filter (master + 레거시 커스텀) → archived 전체 + filters + full fusion
curated (신규)                  → memberOrder ∩ archived + filters + scoped fusion
```

### 4.2 `PersonalLibraryConfig` 확장 (스키마 v2)

```json
{
  "id": "lib_a1b2c3",
  "name": "인생 명작",
  "mode": "curated",
  "memberOrder": ["wk_000000189", "wk_000000042"],
  "domain": null,
  "categories": [],
  "workStatuses": [],
  "myStatuses": [],
  "inclusionRules": ["vault_md"]
}
```

| 필드 | 설명 |
|------|------|
| `mode` | `filter` \| `curated` |
| `memberOrder` | **SSOT (D7)** — 서재 멤버 `wk_` 목록 + UI 정렬 순서. 중복 없음, `addWork` = 끝에 append |
| `inclusionRules` | `vault_md` 고정 — 볼트 md 연동 작품만 파이프라인 대상 |

**파생 값 (저장하지 않음):** `memberWorkIds` = `Set.from(memberOrder)` — API·테스트 편의용.

**마이그레이션:**

| 기존 | 변환 |
|------|------|
| 커스텀 서재 (필터만) | `mode: filter` + 빈 `memberOrder` → 동작 동일 |
| JSON에 `memberWorkIds`만 있음 | 로드 시 `memberOrder`로 승격 (순서 유지) |
| 신규 curated 서재 | `mode: curated` + 사용자가 `memberOrder`에 담기 |

### 4.3 저장 위치 (D2 구현안)

| 상황 | 저장소 | 경로 |
|------|--------|------|
| **볼트 연결됨** | Sanctum 볼트 (Tier 2) | `{vault}/.akasha/personal_libraries.json` |
| **데모 모드** (볼트 없음) | SharedPreferences | 기존 `akasha_personal_libraries` 키 |

**이유 (쉬운 설명):**

- 서재 목록은 **유저 데이터**이므로 작품 `.md`와 같은 볼트 폴더에 두면 백업·이동 시 같이 따라감.
- 작품마다 `shelves:`를 넣으면 서재 하나 바꿀 때 **수십~수백 md 수정** → 느리고 충돌 위험.
- **서재 파일 하나**에 `workId` 배열만 두면 담기/빼기가 O(1) append.

활성 서재 ID·사이드바 모드는 기존처럼 SharedPreferences (`akasha_active_personal_library_id`).

**로드·저장 규칙 (D8 — split-brain 방지):**

| 순서 | 상황 | 동작 |
|:----:|------|------|
| 1 | 볼트 연결 + `.akasha/personal_libraries.json` 있음 | vault JSON 로드 → prefs `akasha_personal_libraries` **삭제** |
| 2 | 볼트 연결 + vault JSON 없음 + prefs 있음 | prefs → vault **일회 마이그레이션** → vault 저장 → prefs **삭제** |
| 3 | 볼트 없음 (데모) | prefs만 사용 |
| 4 | 저장 (`save`) | **항상 한 곳만** — 볼트 있으면 vault만, 없으면 prefs만 |

활성 서재 ID (`akasha_active_personal_library_id`)는 prefs 유지 (UI 상태).

---

## 5. 파이프라인 (`MyLibraryPipeline` v2)

### 5.1 `master_archive` (`mode: filter`)

**변경 없음.**

```
archivedItems(allUserItems)
  → domain/category filters
  → FranchiseFusionService.fuse (기존)
  → workStatus/myStatus filters
```

### 5.2 `curated` 서재

```
Step 1 — 멤버십
  items = allUserItems where workId ∈ library.memberOrder
          AND isArchivedInVault(item)   // filePath 있음

Step 2 — 필터 (기존 BrowseFilterState)
  domain, categories, workStatuses, myStatuses

Step 3 — Scoped Franchise Fusion (§6)

Step 4 — 정렬
  memberOrder 순서 (고아·필터 숨김 id는 order에 유지, 표시만 생략)
```

**Scoped fusion + order 정합성:** order 키 = **대표 `workId`**. 같은 franchise의 비대표 멤버 id가 order에 남아 있으면 로드/저장 시 **대표 id로 정규화**하거나 대표 뒤 그룹으로 병합.

### 5.3 고아 `workId` 처리

| 상황 | 동작 |
|------|------|
| md 삭제됨 · `memberOrder`에만 남음 | 서재 설정에 “목록에서 제거 (N건)” 배너 · **자동 prune 옵션** (저장 시 정리) |
| legacy slug ID | `WorksRegistry.resolveWorkId`로 정규화 후 매칭 |

### 5.4 “읽을 예정” (D1)

- `.md` 존재 = 볼트 연동 ≠ “완독”.
- 담기 시 md 없으면 **최소 아카이브 생성** (기존 `saveItem` / 아카이브 플로우 재사용).
- **Case B 기본값:** `myStatus` = **읽을 예정 / not started** (`HomeAutoArchive.itemFromRegistryWork`와 동일).
- **`workStatus`(콘텐츠 연재 상태)** 는 카테고리별 Fact 기본값 유지 (만화·애니 → 완결, 게임 → 출시됨 등). 콘텐츠 enum에 “예정”이 없으므로 `workStatus`를 예정으로 오버라이드하지 않음.
- 사용자는 워크벤치에서 언제든 상태 변경.

---

## 6. Franchise Fusion — Scoped Fusion

### 6.1 문제

전역 fusion은 같은 IP의 만화·애니를 **한 카드로 합침**.  
큐레이션 서재에서는 사용자가 **둘 다 넣었을 때만** 합치고, **한쪽만 넣었으면 그 한 장만** 보여야 직관적.

### 6.2 규칙: **Scoped Fusion**

| 서재 | fusion |
|------|--------|
| `master_archive` | **기존** `FranchiseFusionService.fuse` |
| `curated` | **Scoped fusion** — 멤버십 집합 안에서만 그룹핑 |

**Scoped fusion 알고리즘:**

1. Step 2 필터 통과한 `AkashaItem` 목록만 사용.
2. `FranchiseRegistry.groupFor(workId)`로 franchiseId 그룹.
3. 그룹 내 **2개 이상** 멤버가 서재에 있으면 → IP 1카드 1장 (대표작 규칙은 기존 `franchise_representative_picker`).
4. 그룹 내 **1개**만 있으면 → 단일 작품 카드 (다른 매체는 끌어오지 않음).

**효과:** “인생 명작”에 만화만 넣으면 애니 카드가 딸려 오지 않음. 만화+애니 둘 다 넣으면 IP 1카드로 볼 수 있음.

---

## 7. UI / UX

### 7.1 서재 생성

| 단계 | UI |
|------|-----|
| 1 | 사이드바 `+` → 이름 입력 · **모드 curated 고정** (master는 자동 생성만) |
| 2 | 빈 서재 생성 · 안내: “작품 카드를 **서재 이름으로 끌어다 놓으세요**” |
| 3 | (선택) 기존 필터 UI는 **설정**에서 — 초기값 전체 |

**변경:** 현재 “추가 다이얼로그 = 필터만” → curated 서재는 **이름 중심**, 필터는 2차.

### 7.2 담기 원칙 (요약)

| 규칙 | 내용 |
|------|------|
| R1 | **`master_archive`에는 담기 UI 없음** — 볼트에 md가 생기면 자동 포함 |
| R2 | **커스텀 서재만** `memberOrder`에 append/remove |
| R3 | 담기 전 **`wk_` 확정** — 사전·볼트·직접등록 모두 `workId` 정규화 후 저장 |
| R4 | md 없으면 **담기 = 아카이브 생성 + 멤버 추가** 한 흐름 (분리 버튼 없음) |
| R5 | 데모 모드(볼트 미연결)는 담기 **비활성** + “볼트 연결 후 이용” 안내 |
| R6 | **드롭 대상 = 사이드바 curated 서재만** — `master_archive`는 drop zone 아님 |

---

### 7.3 담기 진입점 (어디서 넣나)

| 우선 | # | 화면 | 제스처 | 비고 |
|:----:|---|------|--------|------|
| ★ | **E0** | **홈 · 포스터 카드** | **드래그 → 사이드바 서재** | **1순위 (D6)** · §7.13 |
| | E1 | 홈 · 포스터 카드 | 우클릭 / `⋯` → `서재에 담기` | DnD 보조 · 여러 서재 동시 |
| | E2 | 워크벤치 | AppBar `☆` · `서재에 담기` | 상세 화면 보조 |
| | E3 | Fusion 검색 | 사전 행 · `담기` | md 없으면 Case B |
| | E4 | Fusion 검색 | 볼트 행 · `서재에 담기` | 시트 |
| | E5 | 빈 서재 CTA | “작품 검색” | 첫 담기 |
| | E6 | 서재 설정 | `+ 작품 추가` · 멤버 `×` | 관리·일괄 |
| | **E8** | **curated 서재 그리드** | **카드 드래그 → 순서 변경** | v1.1 · §7.13.4 |
| | **E9** | **서재 설정 멤버 목록** | **행 드래그 정렬** | v1 `memberOrder` 편집 (§7.13.4) |

**노출:** E0/E1은 `curated` 서재 **1개 이상** + 볼트 연결. 서재 0개면 사이드바 `+`로 생성 유도.

**접근성 보조:** E0 불가 환경(터치 only 등) → E1 시트 · E3 검색 동일 결과.

---

### 7.4 담기 UI — `WorkLibraryPanel` (공통 컴포넌트)

> UI SSOT: [curated-library-membership-ui-plan.md](./curated-library-membership-ui-plan.md) · apply: [unified-library-add-flow-plan.md](./unified-library-add-flow-plan.md)

모든 진입점(E1~E6)은 **동일 panel** (popover · dialog).

```
┌─────────────────────────────────────────┐
│  서재에 담기 — 「원피스」                  │
├─────────────────────────────────────────┤
│  ☑ 인생 명작          (12작)              │
│  ☐ 읽을 예정 2026                        │
│  ☐ 감상 완료 명작                        │
│  ─────────────────────────────────────  │
│  ＋ 새 서재 만들기…                       │
├─────────────────────────────────────────┤
│  [ 취소 ]              [ 적용 ]          │
└─────────────────────────────────────────┘
```

| 요소 | 동작 |
|------|------|
| 체크박스 | `curated` 서재만 목록 (master 제외) |
| `(N작)` 표시 | **멤버 총수** (`memberOrder.length`) — 필터 후 보이는 수 아님 |
| 초기 상태 | `librariesContaining(workId)` 반영 |
| `적용` | diff 계산 → add/remove batch → `personal_libraries.json` 저장 |
| `＋ 새 서재` | 이름 입력 → curated 생성 → 해당 작품 자동 체크 |
| 활성 서재 힌트 | 현재 사이드바 선택 서재 상단 고정 + “여기에 담기” 빠른 버튼 (선택) |

**토스트:** `「인생 명작」에 담았습니다` / `2개 서재에서 제거했습니다`

---

### 7.5 담기 상태 머신 (md 유무 × 출처)

**진입점별 분기 (E0 vs E1~):**

```
                    ┌─────────────┐
                    │  담기 요청   │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │ vaultPath == null ?      │
              └────────────┬────────────┘
                    yes    │    no
                     ▼     │     ▼
              볼트 연결 안내  │  workId 확정
                             │
              ┌──────────────┴──────────────┐
              │ isArchivedInVault(item) ?   │
              └──────────────┬──────────────┘
                    yes      │      no
                     ▼       │       ▼
         ┌─────────┴─────────┐   WorkLibraryPanel
         │ 진입점?            │   「적용」→ ensureVaultMd
    E0 (DnD) │ E1~ (panel)    │        → applyCheckboxDiff
         ▼     │     ▼         │
  ensureVaultMd│ panel 즉시     │
  + addWork    │ (멀티 서재)    │
  (서재 고정)  │                │
         └─────┴────────────────┘
                           ▼
                 memberOrder 갱신 · save
```

#### 7.5.1 Case A — 볼트 md **있음** (가장 흔함)

| 진입점 | 동작 |
|--------|------|
| **E0 (DnD)** | `addWork(targetLibraryId)` **즉시** — 시트 생략 |
| **E1/E2/E4/E6** | `WorkLibraryPanel` (popover/dialog) → 체크 후 **「적용」** |

공통: **md 내용·상태는 변경하지 않음**

#### 7.5.2 Case B — md **없음** (사전·검색·미아카이브)

> **SSOT:** [unified-library-add-flow-plan.md](./unified-library-add-flow-plan.md) · `ArchiveThenAddDialog` **deprecated**

**`WorkLibraryPanel` 1단** — 별도 AlertDialog 없음. md 없으면 panel 상단 **제목**(기본값) + **「적용」** 시 `ensureVaultMd` → `applyCheckboxDiff`.

| 필드 | 기본값 | 비고 |
|------|--------|------|
| 제목 | Registry `displayTitle()` / 카드 제목 | panel inline · 수정 가능 |
| 카테고리 | 사전 Fact | 읽기 전용 메타 라인 |
| **작품 상태** (`workStatus`) | 카테고리별 Fact | `HomeAutoArchive`와 동일 |
| **내 상태** (`myStatus`) | **읽을 예정 / not started** | D1 |
| 포스터 URL | 비움 | |
| 본문 Markdown | 빈 템플릿 | 최소 생성 |

**「적용」:** `LibraryMembershipApply.ensureVaultMd` → `_loadItems()` → `applyCheckboxDiff`  
**실패 (Q5):** md 생성 성공 · member 실패 → **md 유지** + 스낵바 재적용 안내

**재사용 코드:** `HomeAutoArchive.itemFromRegistryWork`

#### 7.5.3 Case C — 직접 등록 작품 (`wk_` 없거나 로컬만)

1. `showAddWorkDialog`로 작품 생성·md 저장 (기존)
2. 저장 성공 후 **선택:** `WorkLibraryPanel` dialog 자동 오픈
3. `workId` 발급·정규화 후 `memberOrder`에 추가

#### 7.5.4 Case D — IP 1카드 (franchise 카드)에서 담기

| 사용자 의도 | 동작 |
|-------------|------|
| 카드가 **단일 work** | 해당 `workId` |
| 카드가 **franchise fusion** | 시트 상단 라디오: **「이 매체만」** / **「이 IP 전체 (볼트에 있는 매체)」** |
| IP 전체 | 볼트에 md 있는 멤버 `workId`만 일괄 `addWork` (v1.1 — v1은 **대표 workId 1개만**) |

**v1.1 ✅:** fusion 카드 시트 상단 라디오 — **「이 매체만」** / **「이 IP 전체 (볼트에 있는 매체)」**. DnD-A는 대표 1개 유지.

---

### 7.6 진입점별 상세 시퀀스

#### E0 · 드래그 앤 드롭 (1순위)

```
카드 ⠿ 드래그 → 사이드바 curated 행에 드롭
  → [md 있음] addWork(targetLibraryId) 즉시
  → [md 없음] ensureVaultMd(제목 기본값) → addWork — panel 없음 (D6)
```

드롭 성공 시: 서재 행 하이라이트 · 스낵바 · (선택) 해당 서재로 전환.  
상세: **§7.13**

#### E1 · 포스터 카드 (보조)

```
우클릭 / Shift+F10 / long-press
  → WorkLibraryPopover (즉시)
  → [md 없음] panel 제목 행 · 「적용」 시 ensureVaultMd + member diff
  → [md 있음] 서재 체크만
```

카드 배지 (선택): 담긴 서재 수 `★2` — `librariesContaining(workId).length`  
드래그 중: 카드 반투명 · 유효 drop zone(사이드바 curated 행) amber 링

#### E2 · 워크벤치

```
AppBar [☆] 탭
  → md 없으면 상단 배너: "볼트에 저장된 뒤 서재에 담을 수 있습니다" + [저장하고 담기]
  → md 있으면 WorkLibraryPanel
```

**`저장하고 담기`:** `_saveArchive()` 성공 콜백 → `WorkLibraryPanel`.

#### E3 · 검색 · 사전 결과

```
행 [담기]
  → WorkLibraryPanel dialog (Case B 제목 행)
  → 「적용」 → ensureVaultMd + member diff
```

검색 다이얼로그는 닫지 않고 체크만 갱신해도 됨 (연속 담기).

#### E4 · 검색 · 볼트 결과

```
행 [서재에 담기] → WorkLibraryPanel (Case A)
```

#### E5 · 빈 curated 서재

```
EmptyState
  제목: "아직 담은 작품이 없습니다"
  [🔍 작품 검색] → FusionSearchDialog
  [＋ 서재 설정] → E6
```

#### E6 · 서재 설정 · 멤버 관리

```
설정 다이얼로그
  섹션 「담긴 작품 (N)」
    · 리스트: 제목 · 매체 · [제거]
    · [+ 작품 추가] → FusionSearchDialog (담기 모드)
  섹션 「필터」 (기존 UI)
  [고아 ID 정리 (k건)] — md 삭제된 id 일괄 prune
```

---

### 7.7 빼기

| 방법 | 동작 |
|------|------|
| `WorkLibraryPanel` 체크 해제 | `removeWork` |
| 서재 설정 멤버 `×` | 동일 |
| **E10** 카드를 그리드 **밖·휴지통**에 드롭 (v1.1) | 활성 curated에서 `removeWork` |
| **md 파일 삭제** | 서재 목록에 **고아** 남음 → 설정 배너 · prune |
| **서재 삭제** | `memberOrder` 전체 폐기 · **md는 유지** |

**master_archive:** 빼기 없음. md 삭제 시 master에서만 사라짐.

---

### 7.8 담기 후 홈 갱신

| 이벤트 | UI |
|--------|-----|
| `addWork` / `removeWork` | `HomePersonalLibraryController.save()` |
| curated 서재 활성 중 | `setState` → `_personalBrowseCards` 재계산 |
| 다른 서재 보는 중 | 스낵바만 · 그리드 unchanged |
| 스낵바 액션 | `「인생 명작」 보기` → `_selectPersonalLibrary(id)` |

---

### 7.9 서비스 API (담기 전용)

```dart
// lib/services/library_membership_apply.dart

Future<AkashaItem> ensureVaultMd({
  required AkashaItem draft,
  String? titleOverride,
});

Future<MembershipApplyResult> applyPanel({
  required AkashaItem draft,
  required WorkLibraryPanelApplyInput input,
  required PersonalLibraryMembershipService membership,
  required Future<void> Function() reloadItems,
  required List<String> Function(bool useEntireIp) resolveWorkIds,
});

// PersonalLibraryMembershipService
Future<MembershipApplyResult> applyCheckboxDiff({...});
Set<String> librariesContaining(String workId);
```

`applyPanel`: Case B/E1/E3 — md 생성 + member diff.  
**Q5:** member 실패 시 md **유지** · `LibraryApplyException(vaultMdCreated: true)` + 재적용 스낵바.

---

### 7.10 담기 관련 테스트 (추가)

| ID | 시나리오 |
|----|----------|
| T9 | 볼트 없음 → 담기 비활성 안내 |
| T10 | 사전 검색 → WorkLibraryPanel → 1개 서재 check |
| T11 | 시트에서 2개 서재 동시 체크 |
| T12 | 체크 해제 → removeWork |
| T13 | 워크벤치 “저장하고 담기” |
| T14 | 새 서재 만들기 + 첫 작품 동시 |
| T15 | saveItem 실패 시 member 미추가 |
| T16~T21 | §7.13.8 DnD 시나리오 |

---

### 7.13 드래그 앤 드롭 (D6 — 상세)

#### 7.13.1 설계 목표

| 목표 | 내용 |
|------|------|
| 직관성 | “이 작품 → 이 서재”를 **한 동작**으로 |
| 속도 | 멀티 서재가 아닐 때 **시트 생략** (대상 서재가 drop zone에서 확정) |
| 데스크톱 | Windows Steam v1 주 타깃 — **마우스 드래그** 최적화 |
| 보조 | 우클릭 시트(E1)는 **여러 서재 동시** 담기용 |

#### 7.13.2 DnD 종류 (3가지)

| ID | 방향 | v1 | 데이터 |
|----|------|:--:|--------|
| **DnD-A** | 포스터 카드 → **사이드바 curated 서재** | ✅ | `memberOrder` append |
| **DnD-B** | curated 그리드 내 **카드 순서 변경** | **v1.1** | `memberOrder` 갱신 |
| **DnD-C** | 카드 → **휴지통** (서재에서 제거) | v1.1 | `removeWork` |

**v1 순서 편집:** DnD-B 대신 **E9 서재 설정 멤버 리스트** 드래그만 제공.

`master_archive` · 대시보드 서재 섹션은 **DropTarget 아님**.

#### 7.13.3 DnD-A — 카드 → 서재 (담기)

**레이아웃:**

```
┌ Sidebar ─────────┐  ┌ Main grid ────────────────┐
│ 나만의 서재       │  │  [포스터] [포스터] ...     │
│  ┌─────────────┐ │  │       ↘ drag              │
│  │ 인생 명작 ◀─┼─┼──┼─────────┘                 │
│  └─────────────┘ │  │  (drop = 담기)             │
│  │ 읽을 예정    │ │  │                           │
└──────────────────┘  └────────────────────────────┘
```

**드래그 시작**

| 플랫폼 | 시작 제스처 |
|--------|-------------|
| Windows | **⠿ 핸들**(호버 시 우상단) 또는 대시보드 그리드에서만 드래그 시작 — 카드 본문 탭은 상세 열기 유지 |
| 터치 | LongPress → 드래그 (스크롤과 구분) |

**사이드바 접힘:** 드래그 시작 시 사이드바 **자동 펼침** (또는 접힌 상태 좁은 drop strip — 구현 시 택1).

**페이로드 `WorkDragPayload`:**

```dart
class WorkDragPayload {
  final String workId;
  final AkashaItem item;
  final WorkDragSource source; // catalogGrid | libraryGrid | searchResult
}
```

**DropTarget (사이드바 `SidebarItemWidget`)**

| 상태 | UI |
|------|-----|
| `onWillAccept` | curated 행 배경 `amberAccent` 12% · 테두리 점선 |
| `onAccept` | §7.5 상태 머신 · `targetLibraryId` 고정 |
| 이미 담김 | drop 허용 · 스낵바 “이미 담긴 작품” (중복 no-op) |
| `master_archive` | `onWillAccept: false` |

**드롭 후 플로우 (대상 서재 확정)**

```
onAccept(libraryId, payload)
  → vault 없음 ? 볼트 안내
  → md 없음 ? ensureVaultMd(제목 기본값) → addWork(libraryId)
  → md 있음 ? addWork(libraryId, workId)
  → save · 스낵바 · [해당 서재 보기]
```

**시트 생략 조건:** drop zone이 **서재 1개를 명확히 지정**했을 때. 여러 서재에 넣으려면 E1 시트.

**대시보드(사전) 그리드에서도 동일:** Tier 1 카드도 드래그 가능 → drop 시 Case B(아카이브 생성) 자주 발생.

#### 7.13.4 순서 편집 (`memberOrder`)

**v1 — E9 서재 설정 멤버 리스트만**

- `ReorderableListView` 등으로 행 드래그 → `memberOrder` 갱신.
- **Scoped fusion 카드** 1장 = order 항목 1개 (대표 `workId` 기준).
- 필터로 숨겨진 id는 order에서 **유지** (필터 해제 시 원래 순서).

**v1.1 — DnD-B (그리드 내 reorder)** ✅

- 활성 curated 그리드에서 **좌측 `swap_vert` 핸들**(teal)로만 시작 · 우측 amber 핸들은 DnD-A(담기) 전용.
- E9와 **같은 `memberOrder` SSOT** — 한 곳만 바꿔도 일치.
- **직접 배치 순** 정렬 모드에서만 그리드 reorder 활성 (§7.13.4b).

#### 7.13.4b 정렬 2계층 (v1.1.1) ✅

curated 메인 그리드 정렬 드롭다운:

| 옵션 | `memberOrder` | 그리드 DnD-B | 비고 |
|------|:-------------:|:------------:|------|
| **직접 배치 순** | 읽기·쓰기 SSOT | ✅ | 기본값 (filter→curated 진입 시) |
| 작품명·별점·연도·최근 | **변경 없음** | ❌ | `sortBrowseCards` 보기용만 |
| E9 멤버 리스트 | 읽기·쓰기 | — | 정렬 모드와 무관하게 항상 편집 |

- filter·`master_archive` · 대시보드 카탈로그: 직접 배치 순 **옵션 없음** (기존 4종).
- 저장: `memberOrder` → `{vault}/.akasha/personal_libraries.json` (신규 필드 없음).

#### 7.13.5 DnD-C — 빼기 (v1.1) ✅

- curated 그리드 하단 또는 사이드바 **「서재에서 제거」** 휴지통 DropTarget.
- `onAccept` → `removeWork(activeLibraryId, workId)` · md는 유지.

#### 7.13.6 구현 (Flutter)

| 컴포넌트 | 역할 |
|----------|------|
| `WorkDraggableCard` | `PosterCard` 래퍼 · `LongPressDraggable<WorkDragPayload>` |
| `PersonalLibraryDropTarget` | `DashboardSidebar` curated 행 · `DragTarget<WorkDragPayload>` |
| `LibraryGridReorderScope` | curated 모드 그리드 · DnD-B (v1.1) |
| `LibraryDragFeedback` | 드래그 중 미니 포스터 + 제목 툴팁 |
| `ScrollConfiguration` | 드래그 중 그리드/사이드바 자동 스크롤 (v1.1) |

**제스처 충돌 방지**

| 충돌 | 해결 |
|------|------|
| **DnD-A vs DnD-B** (v1.1) | v1: DnD-A만 · 순서는 E9. v1.1: 그리드 reorder는 **전용 핸들**만 |
| 탭(상세 열기) vs DnD-A | **⠿ 핸들** 또는 대시보드 그리드에서만 드래그 시작 · 본문 탭 = 상세 |
| 그리드 스크롤 vs 드래그 | 핸들에서만 드래그 시작 |
| 워크벤치 패널 리사이즈 | 기존 `workbench_resizable_panel`과 히트 영역 분리 |
| 크로스 패널 (그리드→사이드바) | Phase 2: **사이드바 열림** 상태 우선 · `Overlay` + `DragTarget` 검토 |
| 대시보드 사전 카드 | registry-only `BrowseCard`도 `workId` 확정 후 동일 `WorkDragPayload` |

#### 7.13.7 빈 서재 · 온보딩

- 빈 curated 선택 시 그리드에 **점선 drop 힌트**: “왼쪽 다른 화면에서 작품을 끌어오거나 검색하세요”.
- 사이드바 curated 행에 **항상 drop 가능** 표시(아이콘 `add_box_outlined`).

#### 7.13.8 DnD 테스트

| ID | 시나리오 |
|----|----------|
| T16 | 대시보드 카드 → curated 서재 drop · md 있음 |
| T17 | 사전 카드 drop · Case B · 대상 서재 고정 |
| T18 | 이미 담긴 작품 drop · no-op + 안내 |
| T19 | E9 멤버 리스트 reorder · `memberOrder` persist (v1) |
| T20 | master_archive 행에 drop · 거부 |
| T21 | 볼트 없음 · drag 시작 시 안내 |

---

### 7.14 필터 바 (D3)

커스텀 서재 선택 시 **기존 홈 필터 칩 그대로** 노출.

- 예: `인생 명작` 40작 담음 → 상단에서 `애니`만 체크 → 12작만 표시.
- 필터 변경은 **서재 설정에 저장** (현재 `syncActiveFromFilters` 패턴 유지).

### 7.15 빈 상태

| 상태 | 메시지 |
|------|--------|
| curated · 멤버 0건 | “작품을 담아 서재를 채워 보세요” + 검색 · DnD 힌트 (§7.6 E5) |
| filter-only · 필터만 설정 | “볼트 작품이 표시됩니다” (기존과 동일 — curated 빈 서재와 메시지 구분) |
| 멤버 있으나 필터로 0건 | “필터 조건에 맞는 작품이 없습니다” |

---

## 8. API · 서비스 계층

### 8.1 `PersonalLibraryMembershipService` (신규)

| 메서드 | 역할 |
|--------|------|
| `addWork(libraryId, workId)` | 중복 제거 · order append · save |
| `removeWork(libraryId, workId)` | |
| `librariesContaining(workId)` | 카드 UI 체크 상태 |
| `pruneOrphans(library)` | md 없는 id 제거 |
| `migratePrefsToVault()` | 최초 볼트 연결 시 |

### 8.2 `HomePersonalLibraryController` 확장

- `load()` / `save()` → vault json ↔ prefs 이중 경로
- `add()` 시 `mode: curated` 기본

### 8.3 `MyLibraryPipeline.build` 시그니처

```dart
static List<BrowseCard> build(
  List<AkashaItem> allUserItems, {
  required PersonalLibraryConfig library,
  BrowseFilterState filters = const BrowseFilterState(),
});
```

`library`를 넘겨 mode 분기.

---

## 9. 구현 단계

### Phase 1 — 데이터 · 파이프라인 (코어)

| # | 작업 | 산출 |
|---|------|------|
| 1.1 | `PersonalLibraryConfig` v2 필드 + JSON 마이그레이션 | model |
| 1.2 | `{vault}/.akasha/personal_libraries.json` IO | service |
| 1.3 | `MyLibraryPipeline` curated 경로 | pipeline |
| 1.4 | `FranchiseFusionService.fuseScoped` | fusion |
| 1.5 | 단위 테스트: 멤버십 ∩ 필터 · scoped fusion | test |
| 1.6 | **최소 서재 생성** (이름만 · `mode: curated`) — DnD 전제 | UI |

### Phase 2 — 담기 UX (§7.3~7.10 · §7.13)

| # | 작업 |
|---|------|
| 2.1 | `PersonalLibraryMembershipService` + `applyMembershipChanges` |
| 2.2 | **DnD-A** `WorkDraggableCard` + `PersonalLibraryDropTarget` (E0) |
| 2.3 | `LibraryMembershipApply.ensureVaultMd` — DnD Case B | ✅ |
| 2.4 | **E9** 서재 설정 멤버 리스트 reorder (`memberOrder`) — DnD-B는 v1.1 |
| 2.5 | `WorkLibraryPanel` (E1 멀티 서재) | ✅ |
| 2.6 | E2 워크벤치 · E3/E4 검색 · E6 설정 · E5 빈 상태 |
| 2.7 | 담기 후 스낵바 · 사이드바 접힘 시 auto-expand · T9~T21 테스트 |

### Phase 3 — 생성 플로우 정리

| # | 작업 |
|---|------|
| 3.1 | 서재 추가 다이얼로그 UX polish (이름 중심 · 필터 2차) |
| 3.2 | master vs curated 라벨·아이콘 구분 (사이드바) |
| 3.3 | 고아 ID prune · prefs→vault 마이그레이션 (D8) |

### Phase 4 — (v1.1) polish

| # | 작업 | 상태 |
|---|------|:----:|
| 4.1 | **DnD-B** 그리드 reorder · **DnD-C** 휴지통 drop | ✅ |
| 4.1b | **직접 배치 순** 정렬 2계층 (§7.13.4b) | ✅ |
| 4.1c | 드래그 중 자동 스크롤 | ⬜ |
| 4.2 | 서재별 테마 (기존 `LibraryTheme` 연동 검토) | ⬜ |
| 4.3 | dogfood · Steam 스크린샷 “드래그로 서재 담기” | ⬜ |

---

## 10. 테스트 시나리오

| ID | 시나리오 | 기대 |
|----|----------|------|
| T1 | curated 서재에 3작 담기 (DnD 또는 시트) | 3카드만 표시 |
| T2 | 40작 서재 · 애니 필터 | 애니만 subset |
| T3 | 같은 IP 만화만 담기 | 애니 카드 안 뜸 (scoped) |
| T4 | 같은 IP 만화+애니 담기 | IP 1카드 1장 |
| T5 | 사전에서 담기 · md 없음 | md 생성 + 멤버 추가 |
| T6 | md 삭제 | prune 또는 고아 배너 |
| T7 | master_archive | 기존 동작 회귀 없음 |
| T8 | 볼트 이동 | `.akasha/personal_libraries.json` 유지 |

---

## 11. 비목표 (v1)

| 항목 | 이유 |
|------|------|
| 서재 공유·동기화 (클라우드) | Tier 2 로컬 철학 |
| 사전 작품 md 없이 **가상 카드만** 서재에 유지 | D1에서 md 생성으로 통일 |
| 작품 md에 `shelves:` 역방향 저장 | D2 거부 |
| Tier 1 사전 작품 자동 전체 담기 | 큐레이션 아님 |

---

## 12. ROADMAP 반영

| 마일스톤 | 항목 |
|----------|------|
| M2 Steam | 스크린샷에 “커스텀 서재” 1장 (Phase 4) |
| v1.1 | 정렬 · 서재별 테마 |
| M1 회귀 | `master_archive` · 필터-only 레거시 서재 호환 |

---

## 13. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | 초안 — D1~D5 확정 · scoped fusion · vault 저장 |
| 2026-06-10 | §7.3~7.12 담기 진입점 · 상태 머신 · UI 시트 · 진입점별 시퀀스 |
| 2026-06-10 | D6 · §7.13 드래그 앤 드롭 (담기 1순위 · 순서 정렬 · v1.1 제거) |
| 2026-06-10 | v1.1 구현 반영 — DnD-B/C · §7.13.4b 직접 배치 순 · Phase 4 상태 |
| 2026-06-10 | 구현 전 검토 반영 — D7~D8 · `memberOrder` SSOT · filter 레거시 · DnD-A/E9 분리 · D8 prefs 정리 · Case B `myStatus` |
