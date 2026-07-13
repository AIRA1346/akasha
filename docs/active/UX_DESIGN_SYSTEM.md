# AKASHA UX & Visual Design System

> **지위:** 사용자 경험·시각 표현 SSOT
> **작성:** 2026-07-13
> **적용 대상:** Windows 데스크톱 Shell, Home, Explore, Library, Collections, Graph, Timeline, Preview
> **제품 원칙:** [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md)
> **출시 범위:** [VISION.md](VISION.md)
> **구현 현실:** 코드 + [CURRENT_STATE.md](CURRENT_STATE.md)

이 문서는 AKASHA가 **어떻게 보이고, 어떻게 느껴지고, 사용자가 어떻게 이동하는지**를 규정한다. 제품의 존재 이유나 Vault 계약을 다시 정의하지 않는다.

---

## 1. Experience North Star

AKASHA는 게임형 대시보드나 콘텐츠 상점이 아니라, 사용자가 오래 소유할 수 있는 **개인 지식 우주이자 아카이브 작업 공간**이다.

핵심 경험은 다음 세 동사로 요약한다.

1. **기록한다** — 작품과 사람, 사건, 장소, 개념을 내 아카이브에 남긴다.
2. **연결한다** — 기록 사이의 관계와 시간 맥락을 발견하고 직접 다듬는다.
3. **발견한다** — 내 기록에서 다음 탐색과 회상을 자연스럽게 이어 간다.

시각 언어는 프리미엄 다크, 깊이감 있는 표면, 절제된 광원, 테마별 상징 아트를 사용한다. 장식은 분위기를 만들지만 콘텐츠와 조작을 가리지 않는다.

### 하지 않는 것

- 테마마다 화면 구조나 기능 위치가 달라지는 UI
- 실제 데이터가 없는 재화·추천·통계를 그럴듯하게 꾸미는 UI
- 모든 표면에 강한 glow와 gradient를 적용해 정보 위계를 흐리는 UI
- Graph라는 이름으로 단순 목록을 완성형 노드 그래프처럼 오해하게 하는 표현
- 좌측 메뉴와 하단 Dock이 서로 다른 선택 상태나 목적지 목록을 갖는 구조

---

## 2. 레퍼런스 해석

2026-07-12~13에 정리한 Classic Dark용 Astral reference, Amethyst, Sakura 레퍼런스는 픽셀 복제 대상이 아니다. 다음 네 가지를 위한 방향 기준이다.

- **구조:** 좌측 탐색, 중앙 작업 공간, 우측 선택 정보의 안정적인 3열 Shell
- **밀도:** Hero, 이어보기, 빠른 작업, 연결 Insight, 최근 활동이 한 화면 안에서 균형을 이루는 구성
- **분위기:** 어두운 기반 위에 테마별 색·아트·광원을 제한적으로 사용
- **일관성:** 테마가 바뀌어도 모든 패널, 카드, 텍스트, 조작의 위치와 크기는 동일

레퍼런스에서 테마가 바꿔도 되는 것은 accent, 표면 tint, hero/background artwork, texture, glow 강도, 선택적 ambient effect이다. 레이아웃, 간격, 글자 크기, 기능 가시성, hit target, breakpoint는 바꾸지 않는다.

`Astral`은 **Classic Dark의 시각 방향을 설명하기 위한 reference 작업명**이다. 저장 ID, 상품 ID, preset ID, 번역 key가 아니며 두 이름을 합친 별도 상품명을 만들지 않는다. Nocturne의 시각 방향은 아직 확정하지 않았다.

---

## 3. 정보 구조

| 목적지 | 한 문장 역할 | 중복 금지 기준 |
|---|---|---|
| **Home** | 최근 기록과 연결을 이어 가는 개인 아카이브 입구 | 전체 카탈로그 그리드를 반복하지 않는다. |
| **Explore** | 아직 기록하지 않은 항목을 포함해 대상을 찾는 공간 | 내 아카이브 관리 기능을 중심에 두지 않는다. |
| **Library** | 사용자가 기록한 항목을 보고 정리하는 공간 | 전역 탐색 결과와 내 기록을 섞지 않는다. |
| **Collections** | 사용자가 의도적으로 만든 묶음을 큐레이션하는 공간 | Library 필터를 컬렉션처럼 중복 노출하지 않는다. |
| **Graph** | 기록 사이의 연결을 탐색하는 공간 | Canvas 편집기와 동일한 기능이라고 표현하지 않는다. |
| **Timeline** | 기록과 사건을 시간 축으로 회상하는 공간 | 완성 캘린더나 새 projection이 구현된 것처럼 표현하지 않는다. |

Graph와 Timeline은 좌측 전역 내비게이션으로 복원한다. 다만 복원 범위를 다음처럼 구분한다.

- **Graph 내비게이션 복원:** 현재 존재하는 연결 탐색 surface를 다시 접근 가능하게 한다. 실제 노드 그래프와 Canvas 확장은 별도 후속 작업이다.
- **Timeline 내비게이션 복원:** 현재 존재하는 Records/Timeline surface를 다시 접근 가능하게 한다. 완성형 캘린더와 `SA-05 Timeline projection`은 후속 범위다.

이 구분으로 기존 surface의 가시성 복원과 새로운 기능 개발을 혼동하지 않는다.

---

## 4. Desktop Shell 계약

### 4.1 Wide 규격

기준 viewport는 `1440px 이상`이다.

| 영역 | 기본 규격 | 역할 |
|---|---:|---|
| App bar | `64px` 높이 | 전역 검색과 계정·설정 utility |
| Left sidebar | `256px` 너비 | 전역 목적지, 내 아카이브, 최근 탐색 |
| Main canvas | 가변, 최소 `800px` | 현재 목적지의 주 작업 공간 |
| Preview rail | `288px` 너비 | 현재 선택 항목의 맥락과 빠른 작업 |
| Bottom dock | `56px` 높이 | 전역 목적지의 빠른 전환 |

현재 구현의 Sidebar `280px`, Preview `320px`는 중앙 공간을 압박한다. 목표값은 각각 `256px`, `288px`로 한다. Preview는 콘텐츠 특성상 `288–304px` 범위까지 허용하되 화면마다 임의로 다르게 두지 않는다.

### 4.2 반응형 규격

| 구간 | Left sidebar | Preview | Bottom dock |
|---|---|---|---|
| **Wide** `>= 1440` | `256px` 고정 | `288px` 고정, 선택 시 표시 | `56px`, 빠른 전환 |
| **Standard** `1180–1439` | `232px` 또는 compact rail | `288px` overlay | `56px`, 빠른 전환 |
| **Compact** `< 1180` | drawer | side/full sheet | 주 내비게이션 |

축소 우선순위는 장식 감소 → 보조 텍스트 축약 → Preview overlay 전환 → Sidebar drawer 전환이다. 핵심 콘텐츠나 주요 조작을 먼저 숨기지 않는다.

### 4.3 Left sidebar

위에서 아래의 순서를 유지한다.

1. AKASHA identity
2. Home · Explore · Library · Collections · Graph · Timeline
3. 내 아카이브와 사용자 컬렉션
4. 최근 탐색
5. 새 항목 추가 또는 현재 맥락의 주 CTA

Graph와 Timeline은 feature flag 상태와 무관하게 정보 구조의 정식 목적지다. 제품 빌드에서 감춰야 한다면 내비게이션 모델 자체를 삭제하지 않고 availability만 명시한다.

### 4.4 Top bar

Top bar는 두 영역으로 나눈다.

- **중앙/좌측:** 검색, 단축키, 필터, 아카이브 추가
- **우측 utility cluster:** 재화, 알림 확장 슬롯, 설정, 사용자 avatar

권장 우측 순서는 `Astra/Echo balance → Settings → Avatar`이다. Balance는 [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md)의 의미와 권한을 따른다.

- 실제 provider가 없으면 임의의 `0`이나 가짜 잔액을 표시하지 않는다.
- entitlement/IAP가 비활성인 빌드는 balance chip을 숨기거나 명시적인 unavailable 상태로 표시한다.
- 화면 폭이 줄면 balance의 label부터 축약하고 설정과 avatar의 hit target은 유지한다.
- avatar 메뉴는 프로필, 테마, 계정 관련 진입점을 담을 수 있지만 Vault 설정과 제품 설정의 의미를 섞지 않는다.

### 4.5 Main canvas

Home의 목표 구조는 다음 순서를 기본으로 한다.

1. **Archive Hero** — 제품 정체성, 검색/기록 CTA, 실제 archive summary
2. **Continue Exploring** — 최근 열람·미완료·재방문 가치가 있는 기록
3. **Quick Actions** — 검색, 새 기록, 가져오기, Graph/Timeline 진입
4. **Connection Insight** — 최근 연결, 고립된 기록, 다시 볼 관계
5. **Today in Archive** — 실제 최근 변경과 오늘의 기록

모든 섹션은 실제 데이터 source와 empty/loading/error 상태를 먼저 정의한다. Hero 통계와 활동은 장식용 숫자를 사용하지 않는다. 데이터가 없을 때는 아카이브를 시작할 수 있는 행동을 보여 준다.

### 4.6 Preview rail

Preview는 별도 상세 화면이 아니라 선택을 유지한 채 다음 행동을 결정하는 contextual inspector다.

- 선택 항목 cover/identity
- 제목, 유형, 핵심 메타데이터
- `열기` 또는 `기록하기` 주 CTA
- 링크, 편집, 더보기 보조 동작
- 평가, 태그, 상태, 진행률
- 연결 요약과 최근 기록

긴 본문, 복잡한 편집, 전체 연결 목록은 Workbench/상세 화면에서 처리한다. Preview를 닫아도 중앙 화면의 scroll과 filter 상태는 유지한다.

### 4.7 Bottom dock

Wide에서도 레퍼런스의 빠른 전환 감각을 위해 Dock을 유지할 수 있다. 단, Sidebar와 Dock은 반드시 하나의 `AppDestination` 모델과 selection SSOT를 공유한다.

- Sidebar는 위치·아카이브 맥락·최근 기록을 제공한다.
- Dock은 목적지 전환만 제공한다.
- 목적지 순서, icon, label, availability, 현재 선택 상태를 별도로 구현하지 않는다.
- compact에서는 Dock이 주 내비게이션이 되고 Sidebar는 drawer로 전환한다.

---

## 5. Layout와 시각 토큰

### 5.1 불변 Layout tokens

테마와 독립된 공통 토큰을 사용한다.

| 범주 | 기준 |
|---|---|
| Spacing | `4, 8, 12, 16, 24, 32, 48` |
| Radius | control `8`, card `12`, hero/panel `16`, pill `999` |
| Icon | inline `16`, control `20`, nav `22–24` |
| Hit target | 최소 `40px`, 주요 nav/control `44px` 권장 |
| Grid gap | compact card `12`, 일반 card `16`, section `24` |
| Panel padding | compact `12`, 일반 `16`, hero `24–28` |
| Motion | micro `120–160ms`, panel `180–240ms`, reduced motion 지원 |

임의의 `7px`, `13px`, 화면별 panel width 같은 magic number를 추가하지 않는다. 예외는 이 문서 또는 공통 token에 먼저 의미를 부여한다.

### 5.2 Typography

타이포그래피는 분위기보다 정보 계층을 우선한다.

| 역할 | 크기/성격 |
|---|---|
| Display / Hero | `28–32`, semibold/bold |
| Page title | `22–24`, semibold |
| Section title | `16–18`, semibold |
| Body | `13–14`, regular |
| Label | `12–13`, medium |
| Caption | `11–12`, regular |

한글, 영문, 숫자에서 같은 계층이 유지되어야 하며 번역 길이가 늘어나도 fixed text box로 자르지 않는다. `AkashaTypography`와 `ThemeData.textTheme`를 연결해 컴포넌트의 개별 `fontSize` 사용을 줄인다.

### 5.3 Surface와 효과

- 기본 hierarchy는 `background → surface → elevated surface → selected/focus` 네 단계다.
- border는 패널 분리와 focus에 사용하고, 모든 카드에 강한 외곽선을 두르지 않는다.
- glow는 선택, 주요 CTA, hero focal point에 제한한다.
- text 위의 artwork에는 contrast scrim을 둔다.
- ambient particle은 pointer hit test를 가로채지 않으며 reduced motion에서 정지하거나 사라진다.
- Poster/cover는 콘텐츠이고, 테마 art는 배경이다. 둘의 채도와 대비가 경쟁하지 않도록 한다.

---

## 6. Theme 확장 계약

### 6.1 현재 기반

2026-07-13 UX-1 foundation으로 `AkashaThemePreset`, `ThemeCatalogEntry`, `AkashaThemeController`, `AkashaThemeBackdrop`과 theme harness가 구현됐다. `LibraryTheme`는 저장 ID 호환 adapter로만 남아 있다. 여러 화면의 raw `Color`, `AkashaColors`, 고정 geometry 이관은 아직 후속 Phase에 남아 있다.

런타임의 themeable color SSOT는 `AkashaPalette`로 한다. 기능 widget은 theme ID로 분기하지 않고 `context.akashaPalette`의 semantic role만 읽는다.

선택 preset은 앱 시작 전에 load되고 `MaterialApp` root에 적용된다. Home Shell의 중첩 app theme는 제거됐으며 dialog, bottom sheet, popup menu, snackbar와 향후 route도 같은 effective theme를 상속한다.

### 6.2 공식 테마 카탈로그

우선 공식 테마는 정확히 5개다.

| Canonical ID | 표시명 | Access | 현재 판매 상태 |
|---|---|---|---|
| `classicDark` | Classic Dark / 클래식 다크 | `bundled` | 기본 무료 |
| `midnightBlue` | Midnight Blue / 미드나이트 블루 | `bundled` | 기본 무료 |
| `sakura` | Sakura / 벚꽃 | `premium` | 판매 계획 · 현재 미활성 |
| `amethyst` | Amethyst / 자수정 | `premium` | 판매 계획 · 현재 미활성 |
| `nocturne` | Nocturne / 녹턴 | `premium` | 판매 계획 · 현재 미활성 |

무료/유료 분류는 공식 상품 계획이고, 판매 활성 상태와는 별개다. `steamInAppPurchasesEnabled=false` 빌드에서는 Classic Dark와 Midnight Blue만 picker에 노출하고 premium 3종의 구매·잠금 UI를 표시하지 않는다.

현재 런타임은 legacy ID 4개를 모두 무료로 노출하므로 목표와 불일치한다. 이 현실과 migration 계획은 [UX_THEME_MIGRATION_INVENTORY.md](UX_THEME_MIGRATION_INVENTORY.md)에 기록한다.

### 6.3 목표 표현 계층

| 계층 | 책임 | 테마 변경 가능 |
|---|---|:---:|
| `AkashaThemePreset` | canonical id, palette, assets, effects | 예 |
| `ThemeCatalogEntry` | 표시명/l10n, bundled/premium, 가격, entitlement metadata | 해당 없음 |
| `AkashaPalette` | 배경·표면·텍스트·border·accent·focus·상태 의미색 | 예 |
| `AkashaThemeAssets` | hero, texture, optional ambient artwork, fallback | 예 |
| `AkashaThemeEffects` | glow, shadow, overlay, particle 강도 | 예 |
| `AkashaThemeBackdrop` | asset·scrim·gradient를 한 곳에서 합성하는 renderer | 예 |
| Layout tokens | spacing, radius, typography metrics, shell width, breakpoint | **아니오** |
| Component contracts | 구조, 순서, 상태, interaction, accessibility | **아니오** |

`LibraryTheme`는 실제로 앱 전체 visual theme를 나타내므로 향후 `AkashaThemePreset`과 compatibility adapter로 분리한다. 이름 변경은 저장 ID migration과 함께 구현한다.

### 6.4 Visual preset과 commerce metadata

두 모델의 책임을 섞지 않는다.

```text
AkashaThemePreset
- id
- palette
- assets
- effects

ThemeCatalogEntry
- presetId
- displayNameL10nKey
- accessType: bundled | premium
- astraCost?
- echoCost?
- entitlementItemDefId?
```

`requiresIap`는 visual preset의 필드가 아니다. Sakura와 Amethyst의 production SKU·가격은 아직 없으며 임의로 만들지 않는다. Nocturne의 Steam Inventory POC ItemDef `20001`과 Astra 비용 `100`은 feasibility evidence일 뿐 production catalog 확정값이 아니다.

### 6.5 Preferred와 effective theme

사용자 선택과 현재 적용값을 분리한다.

- `preferredThemeId`: 사용자가 마지막으로 선택한 canonical ID. provider 장애나 fallback 때문에 삭제·덮어쓰기 금지.
- `effectiveThemeId`: 현재 preset availability와 access state에서 계산한 실제 렌더링 ID. 사용자 설정으로 별도 저장하지 않음.

| Access state | 의미 | Effective 처리 |
|---|---|---|
| `free` | bundled 테마 | preferred 적용 |
| `owned` | authority가 premium 소유 확인 | preferred 적용 |
| `locked` | authority가 정상 조회 후 미소유 확인 | `classicDark` fallback |
| `checking` | 소유권 확인 중 | `classicDark` fallback, preferred 보존 |
| `unavailable` | provider 없음·비활성·조회 실패 | `classicDark` fallback, preferred 보존 |

no-IAP 빌드에서는 premium entry를 picker에서 숨긴다. 기존 저장값이 premium이면 preferred는 보존하고 effective만 Classic Dark로 안전하게 해석한다. provider가 나중에 `owned`를 확인하면 보존한 preferred를 다시 적용할 수 있어야 한다.

기존 저장 ID는 `classic → classicDark`, `midnight → midnightBlue`, `obsidian → amethyst`로 normalize한다. `sakura`, `amethyst`는 유지한다. 알 수 없는 값은 삭제하지 않고 effective만 Classic Dark로 둔다. 실제 저장 증거가 없는 `astral` alias는 만들지 않는다.

### 6.6 Palette 필수 semantic roles

현재 surface 중심 palette를 다음 역할까지 확장한다.

- `textPrimary`, `textSecondary`, `textMuted`, `textOnAccent`
- `background`, `surface`, `surfaceElevated`, `surfaceInteractive`
- `sidebar`, `bottomDock`, `previewRail`, `searchField`
- `borderSubtle`, `borderStrong`, `focusRing`
- `accent`, `accentHover`, `accentPressed`, `accentSoft`
- `onAccent`
- `success`, `warning`, `danger`, `info`
- `scrim`, `shadow`, `artworkOverlay`

`onAccent`는 흰색으로 고정하지 않고 각 accent와 최소 AA 대비가 나오도록 선택한다. 성공·경고·오류와 Astra/Echo처럼 의미가 고정된 색은 가독성을 해치지 않는 범위에서만 조정한다. 테마 accent와 무조건 섞지 않는다.

### 6.7 테마가 절대 바꾸지 않는 것

- 목적지 목록, 기능 availability, widget 순서
- panel 너비, breakpoint, spacing, radius, 글자 크기
- 버튼/카드의 hit target
- loading/empty/error의 의미
- 키보드 focus 순서와 단축키
- 데이터 source와 권한 판정

테마 전용 widget fork를 만들지 않는다. 특정 asset이 없으면 같은 geometry의 gradient/solid fallback을 사용한다.

---

## 7. 공통 Component 계약

우선 공통화할 단위는 다음과 같다.

| Component | 반드시 통일할 것 |
|---|---|
| Navigation item | 높이, icon, label, selected/focus/disabled 상태 |
| Search chrome | 검색 상태, 단축키, clear, filter, loading |
| Hero panel | content slot, artwork slot, overlay, fallback, stats |
| Stat tile | label, value, icon, unavailable/empty 상태 |
| Archive card | cover ratio, title 줄 수, metadata, progress, selected/focus |
| Section header | 제목, count, collapse, `모두 보기` |
| Action tile/button | primary/secondary/quiet/danger hierarchy |
| Chip | tag/status/type/currency 의미 분리 |
| Preview section | heading, divider, action slot, loading/empty |
| State view | empty, loading, error, permission, unavailable |

선택은 Preview를 바꾸고, 열기는 Workbench/상세 맥락으로 진입한다. single click과 double click, Enter, Escape, Back의 의미가 화면마다 달라지지 않도록 한다.

`Escape`는 가장 위의 menu/dialog/Preview를 닫거나 이전 맥락으로 돌아가는 데만 사용한다. 닫을 대상이 없을 때 설정을 여는 동작으로 사용하지 않는다.

---

## 8. Graph와 Timeline의 UX 경계

### Graph

- 첫 단계는 기존 연결 surface의 발견 가능성과 정직한 명칭을 회복한다.
- 연결 목록, neighbor summary, relation type filter는 Graph의 기초 정보가 될 수 있다.
- 실제 node/edge 공간 탐색, zoom/pan, layout, 편집은 Graph/Canvas 후속 설계에서 다룬다.
- 읽기 탐색 Graph와 자유 배치 Canvas의 역할을 합치지 않는다.

### Timeline

- 첫 단계는 기존 Records/Timeline surface와 빠른 기록 진입을 다시 노출한다.
- 기록 시간, 작품 발행일, 사건 발생일, 파일 수정 시각을 하나의 날짜처럼 섞지 않는다.
- 고급 calendar와 bounded projection은 [TIMELINE_TIME_SEMANTICS_PLAN.md](../architecture/TIMELINE_TIME_SEMANTICS_PLAN.md) 및 Roadmap의 별도 범위다.

---

## 9. 접근성·지역화·상태 기준

- 본문과 주요 control은 WCAG AA 대비를 목표로 한다.
- hover만으로 의미를 전달하지 않고 focus-visible을 제공한다.
- 키보드만으로 모든 전역 목적지, 검색, Preview action에 접근할 수 있어야 한다.
- 색만으로 status와 currency 종류를 구분하지 않는다.
- 한국어와 영어의 긴 label, Windows text scaling `125%`, viewport 축소에서 overflow가 없어야 한다.
- animation과 particle은 reduced motion 설정을 따른다.
- network/catalog failure가 Vault 기록 열람을 막지 않는다.
- 없는 값은 `0`, `알 수 없음`, 빈 문자열을 임의로 서로 대체하지 않는다.

---

## 10. 신규 테마 승인 기준

새 테마는 palette를 등록하는 것만으로 완료되지 않는다. 다음 matrix를 통과해야 한다.

### Theme matrix

- Classic Dark
- Midnight Blue
- Sakura
- Amethyst
- Nocturne

### Surface matrix

- Home
- Explore/Library card grid
- Collections
- Graph/Timeline
- Preview/Workbench 진입
- dialog, menu, snackbar, empty/loading/error

### Viewport matrix

- `1600×900` 이상 wide
- `1366×768` standard
- `1024×720` compact boundary
- Windows text scaling `125%`

### Gate

- overflow 없음
- unreadable contrast 없음
- 누락 asset에서 정상 fallback
- focus/selection이 모든 테마에서 식별 가능
- golden 또는 screenshot regression 검토
- 핵심 widget smoke test와 전체 analyze/test 통과

themeable feature code에는 새 raw hex와 `Colors.*`를 추가하지 않는다. 예외인 domain/status color는 semantic token 정의부에만 둔다.

---

## 11. 구현 순서

### Phase UX-0 — 계약 고정

- [x] 이 문서로 IA, Shell, Theme 경계를 확정
- [x] 레퍼런스별 color/art/effect inventory 작성
- [x] 현재 화면의 hardcoded style inventory를 migration 목록으로 전환
- 증거와 Phase별 대상: [UX_THEME_MIGRATION_INVENTORY.md](UX_THEME_MIGRATION_INVENTORY.md)

### Phase UX-1 — Theme foundation

- [x] `AkashaThemePreset`, `AkashaThemeAssets`, `AkashaThemeEffects` 계약
- [x] `ThemeCatalogEntry`와 preferred/effective access resolver 경계
- [x] semantic text/onAccent/state/focus palette 확장
- [x] theme controller와 preset 적용 범위를 app root로 승격
- [x] 공통 `AkashaThemeBackdrop`과 asset 누락 fallback
- [x] Classic Dark와 Midnight Blue 실제 이관
- [x] Sakura, Amethyst, Nocturne canonical ID와 중립 fallback preset
- [x] dialog/menu/snackbar/input/button Material subtheme 연결
- [x] 5개 preset 전용 theme harness 구성
- [ ] spacing/radius/typography의 잔여 component 이관 — UX-2~4에서 inventory 순서로 계속

UX-1에서는 Home 재설계, Responsive Shell 변경, Graph/Timeline 복원, currency UI, Steam entitlement 연결, premium 3종의 최종 art를 수행하지 않는다. `LibraryTheme` compatibility layer도 즉시 삭제하지 않는다.

### Phase UX-2 — Responsive Shell

- Sidebar `256px`, Preview `288px`, App bar `64px`, Dock `56px`
- Sidebar와 Dock의 단일 destination model
- 여러 boolean 대신 단일 Shell route, Work/Entity nullable 쌍 대신 단일 Preview target 계약
- Graph/Timeline 내비게이션 복원
- 우측 utility cluster의 설정·재화·avatar slot
- standard/compact overlay와 drawer 동작

### Phase UX-3 — Home 고도화

- 실제 archive summary 기반 Hero
- Continue Exploring와 Quick Actions 정돈
- Connection Insight와 Today in Archive
- 모든 section의 loading/empty/error

### Phase UX-4 — Preview와 핵심 화면

- Preview 정보 밀도와 action hierarchy 정돈
- Explore/Library/Collections의 역할과 entity strip 범위 정리
- Graph/Timeline의 명칭, copy, empty state, interaction 정돈

### Phase UX-5 — Theme packs와 회귀 검증

- Classic Dark, Midnight Blue, Sakura, Amethyst, Nocturne asset/effect pack
- theme × surface × viewport matrix 검증
- screenshot/golden 기준과 reduced motion 검증

---

## 12. Deferred / Non-goals

- 이 문서만으로 production IAP나 재화 구매를 활성화하지 않는다.
- 가짜 avatar 계정, 가짜 알림, 가짜 추천 engine을 만들지 않는다.
- 새 node graph engine이나 Timeline projection 구현을 Theme 작업에 끼워 넣지 않는다.
- 각 테마를 별도 페이지/widget tree로 만들지 않는다.
- 레퍼런스의 장식을 그대로 복제하기 위해 콘텐츠 가독성과 성능을 희생하지 않는다.

---

## 13. 관련 문서와 결정 권한

| 질문 | SSOT |
|---|---|
| 왜 존재하며 무엇을 거부하는가 | [AKASHA_ARCHIVE_CONSTITUTION.md](AKASHA_ARCHIVE_CONSTITUTION.md) |
| Steam v1에 무엇이 들어가는가 | [VISION.md](VISION.md) |
| 사용자가 어떻게 경험하고 어떻게 보여야 하는가 | **이 문서** |
| 데이터와 runtime 구조 | [ARCHITECTURE.md](ARCHITECTURE.md) |
| 실제 구현 상태 | 코드 + [CURRENT_STATE.md](CURRENT_STATE.md) |
| 구현 순서 | [ROADMAP.md](ROADMAP.md) |
| 재화의 의미와 authority | [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md) |
| Timeline 시간 의미 | [TIMELINE_TIME_SEMANTICS_PLAN.md](../architecture/TIMELINE_TIME_SEMANTICS_PLAN.md) |
| Theme migration 현실과 UX-0 inventory | [UX_THEME_MIGRATION_INVENTORY.md](UX_THEME_MIGRATION_INVENTORY.md) |

기존 `docs/draft/`의 R14 UI/UX 감사와 Home redesign 문서는 역사적 분석 자료다. 현재의 UX 결정은 이 문서를 따른다.
