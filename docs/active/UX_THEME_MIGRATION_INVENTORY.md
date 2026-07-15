# AKASHA Theme Migration Inventory

> **지위:** UX-0 구현 이관 inventory
> **작성:** 2026-07-13
> **상위 계약:** [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md)
> **범위:** `lib/screens/**`, `lib/widgets/**`, `lib/features/**/presentation/**` 및 theme root·preferences·entitlement 경계
> **원칙:** 이 문서는 현재 코드와 목표 테마 계약의 차이를 추적한다. 제품 UX 결정은 상위 문서를 따른다.

---

## 1. UX-0 결론과 UX-1 구현 결과

UX-1 Theme foundation에 들어가기 전 필요한 두 inventory를 완료했다.

- [x] 공식 5개 테마의 reference color/art/effect 경계
- [x] 하드코딩 style과 theme scope의 migration 대상·Phase·위험도

2026-07-13 UX-1 foundation 구현으로 공식 카탈로그와 root theme 경계가 정렬됐다.

2026-07-14 UX-5A에서 `assets/themes/<presetId>/` namespace, 누락 asset fallback, reduced motion resolver, 다섯 테마 핵심 surface geometry matrix와 Windows golden을 고정했다. UX-5B에서 Classic Dark·Midnight Blue, UX-5C에서 Sakura·Amethyst·Nocturne의 실제 backdrop·Hero를 통합해 공식 artwork 10개를 실제 asset decode·paint 기준으로 고정했다. 실제 artwork 통합 상태와 회귀 범위는 [UX_THEME_REGRESSION_MATRIX.md](UX_THEME_REGRESSION_MATRIX.md)를 따른다. 이 작업은 `AkashaColors.*` 전수 정리 범위를 넓히지 않았으므로 UX-4D 종료 baseline **328 lines / 81 files**를 그대로 유지한다.

UX-5C 검증은 root analyze **0**, root test **1124**, Windows Debug/Release PASS이며 Release bundle의 공식 artwork 10개 hash가 workspace provenance와 일치한다.

2026-07-15 UX-5D에서 preset·catalog·persisted alias의 중복 등록을 `AkashaThemeRegistry` 하나로 통합하고 `LibraryTheme` runtime adapter, legacy picker/preferences 타입을 제거했다. effect는 Backdrop·Hero·Interaction·Motion 그룹으로 분리했다. 검증은 root analyze **0**, root test **1124**, Windows Debug/Release PASS이며 기존 golden은 갱신 없이 통과했다.

2026-07-15 UX-6에서 `ThemeOfferState`를 access state와 분리하고 no-IAP Theme Gallery도 공식 5종을 모두 발견 가능하게 바꿨다. 이 시점의 premium 3종은 `planned`로 표시하며 가격·구매 CTA·가짜 잔액을 노출하지 않았다. Windows custom chrome과 창모드·최대화·`F11` fullscreen 계약도 app root에 추가했다. control은 가로축 전체 폭·우측 정렬을 고정하고 root overlay 밖에서는 Tooltip을 만들지 않아 hover feedback이 버튼 영역을 벗어나지 않는다. 검증은 root analyze **0**, root test **1128**, Windows Debug/Release PASS이며 실제 Release runtime에서 `F11` 진입·복원과 fullscreen 중 Escape의 원래 window bounds 복원을 확인했다.

같은 날 후속 Commerce catalog foundation에서 사용자가 승인한 launch 정책을 별도 SSOT로 고정했다. Sakura·Amethyst·Nocturne는 각각 `500 Astra 또는 500 Echo` choose-one이며 혼합·재화 교환은 금지한다. Astra pack은 500/1,000/2,500 allowlist다. Theme Gallery와 read-only Store & Inventory는 동일 `CommerceCatalog`를 읽어 가격을 표시하지만 production 구매 CTA는 계속 비활성이다. `CommerceAccountSnapshot`의 미확인 잔액은 nullable이며 가짜 `0`을 만들지 않는다. 별도 [Steamworks ItemDef upload candidate](steam_inventory_production/itemdefs_steamworks_upload.json)는 POC ID를 퇴역시키고 Echo 10분당 10개·1,440분 창당 최대 6회를 고정했다. 거래와 playtime reward는 독립 sandbox gate이며 정상 빌드에서는 모두 비활성이다. 현재 검증은 root analyze **0**, root test **1184**, commerce domain **17**, backend **18**이다. Steamworks 게시와 partner E2E는 아직 남아 있다.

| 항목 | UX-1 이전 | 현재 결과 |
|---|---|---|
| Preset | legacy ID 4개 | canonical ID 5개 + 단일 `AkashaThemeRegistry` |
| Access | 네 preset 모두 `requiresIap=false` | visual preset과 무료 2·premium 3 catalog 분리 |
| Picker | 네 preset 전부 노출·즉시 저장 | 공식 5종 gallery, 무료/보유만 controller가 저장 |
| Selection | preference와 effective 혼합 | preferred/effective + 5 access state resolver |
| Theme scope | Home Shell 내부 중첩 `Theme` | app root 전체 + Material overlay 상속 |
| Nocturne | Steam Inventory POC에만 존재 | canonical preset + near-black/silver-blue artwork 통합, SKU는 후속 |

UX-1 검증: root analyze 0 · root test 974 · Windows debug build PASS. Production IAP와 premium 구매 UI는 계속 비활성이다.

`AkashaColors.*` 감소 추적은 아래 §3의 단일 명령과 범위만 사용한다. UX-1 보고에 사용한 `444→424`와 UI scope의 `399→379`는 서로 다른 집계 방식이므로 더 이상 품질 지표로 사용하지 않는다.

---

## 2. 공식 reference inventory

`Astral`은 상품명이나 preset ID가 아니다. 사용자가 제공한 Astral 레퍼런스는 **Classic Dark의 시각 방향 작업명**으로만 사용한다.

| Canonical ID | Access | Reference color direction | Artwork | Effect | UX-1 asset 상태 |
|---|---|---|---|---|---|
| `classicDark` | bundled/free | near-black · deep navy · blue/violet accent | 우주 궤도, 성좌, 지식 연결 | 절제된 violet/blue glow, 희미한 별빛 | 실제 palette + backdrop/Hero 통합 · fallback 유지 |
| `midnightBlue` | bundled/free | deep navy · cool blue accent | 초승달, 궤도, 성좌 연결 | 낮은 blue glow, 차분한 깊이 | 실제 palette + backdrop/Hero 통합 · fallback 유지 |
| `sakura` | premium | charcoal rose · warm pink accent | 벚꽃 가지, 꽃잎, 절제된 천체 궤도 | warm pink glow | palette + backdrop/Hero + effect 통합 |
| `amethyst` | premium | black purple · amethyst accent | 자수정 결정 군집, 성좌 연결 | localized purple bloom/glow | palette + backdrop/Hero + effect 통합 |
| `nocturne` | premium | near-black · graphite · silver-blue accent | 초승달, 어두운 구름과 산악, 희미한 성좌 | 최소 silver-blue glow | palette + backdrop/Hero + effect 통합 |

Nocturne reference는 2026-07-14 확정됐다. palette와 artwork는 Midnight Blue보다 더 어둡고 무채색에 가까운 야간 역할을 갖지만 geometry와 기능 availability는 나머지 테마와 동일하다. Steam POC의 ItemDef와 비용은 시각 방향이나 production 상품값을 결정하지 않는다.

---

## 3. 기계적 style scan baseline

다음 수치는 2026-07-13 정규식 scan의 migration 후보 baseline이다. AST 의미 판정이 아니므로 icon size, domain status color처럼 유지 가능한 값도 포함한다. 숫자는 “즉시 전부 교체”가 아니라 이관 감소를 추적하는 기준이다.

### `AkashaColors` 고정 측정 계약

```powershell
rg -n "AkashaColors\." lib `
  --glob "!**/*.g.dart" `
  --glob "!**/*.freezed.dart"
```

- 검색 범위: `lib/**`만 포함한다.
- 제외 범위: 테스트, 문서, 생성 코드(`*.g.dart`, `*.freezed.dart`)는 포함하지 않는다.
- 수치 단위: 명령 출력의 **일치 line 수**다. 한 line에 참조가 여러 번 있어도 1건으로 센다.
- UX-2 시작 baseline: **422 lines / 106 files**.
- UX-2 종료 결과: **421 lines / 105 files**. UX-2와 무관한 전수 이관은 수행하지 않았다.
- UX-4B 시작 결과: **354 lines / 90 files**.
- UX-4B 종료 결과: **342 lines / 86 files**. Preview가 실제 사용하는 link neighbor chrome·character·connected work·theme cluster만 semantic palette로 이관했다.
- UX-4C 종료 결과: **334 lines / 83 files**. Explore·Library·Collections 역할 정리에서 실제로 만진 browse/empty/entity strip surface만 이관했다.
- UX-4D 종료 결과: **328 lines / 81 files**. Graph·Timeline에서 실제로 만진 empty/list/dialog surface만 이관했다.
- 앞으로의 전후 비교는 이 명령과 단위만 사용한다.

| 분류 | occurrence | 영향 파일 | 판단 |
|---|---:|---:|---|
| `Color(0x...)` / `Colors.*` | 195 | 64 | 이 중 `Colors.transparent` 제외 시 169 / 54 |
| `AkashaColors.*` 직접 참조 | 328 lines | 81 | UX-4D 종료 시점의 고정 측정 계약 결과. UX-4D 시작은 334 / 83 |
| 고정 `fontSize` | 210 | 69 | 이 중 `< 11px` 51 / 31 |
| `EdgeInsets.*` 직접 선언 | 321 | 116 | 공통 spacing token 후보 |
| 고정 width/height/min/max | 599 | 130 | 콘텐츠 고유 크기와 shell metric을 분리해야 함 |
| 고정 radius | 137 | 60 | 공통 control/card/panel/pill token 후보 |
| 직접 gradient | 7 | 6 | effect/backdrop 계약으로 분류 |
| 직접 `BoxShadow` | 8 | 6 | shadow/glow semantic 분리 |
| 직접 blur/backdrop | 7 | 3 | 성능과 reduced motion 검증 필요 |
| 수동 `.withValues(alpha:)` | 118 | 53 | 테마별 대비를 중앙에서 보장하기 어려움 |

UI Dart 290개 중 155개가 color, typography, geometry, effect 가운데 하나 이상의 이관 후보를 가진다.

재현 분류식:

```text
Color(0x...) | Colors.*
AkashaColors.*
fontSize: number
EdgeInsets.* | fixed width/height/min/max
BorderRadius.circular(number) | Radius.circular(number)
LinearGradient | RadialGradient | SweepGradient
BoxShadow | BackdropFilter | ImageFiltered | ShaderMask
.withValues(alpha: ...)
```

---

## 4. Theme root·상태·commerce migration

| 파일 | 현재 사용 | 목표 계약 | Phase | 위험 |
|---|---|---|:---:|:---:|
| `lib/main.dart` | `MaterialApp`이 항상 Classic 사용 | root controller가 `effectiveThemeId` 구독 — **완료** | UX-1 | Closed |
| `lib/screens/home/home_shell_scaffold_layout_part.dart` | Home 내부 중첩 `Theme` | 중첩 app theme 제거, root 상속 — **완료** | UX-1 | Closed |
| `lib/screens/home/coordinators/home_vault_coordinator.dart` | preference/effective 혼합 | Home local theme SSOT 제거 — **완료** | UX-1 | Closed |
| `lib/services/library_theme_preferences.dart` | unknown ID를 Classic으로 소실 | canonical migration + raw unknown 보존 — **완료** | UX-1 | Closed |
| `lib/models/library_theme.dart` | visual·판매 결합 legacy 모델 | visual adapter와 catalog 분리 — **완료** | UX-1 | Closed |
| `lib/widgets/akasha_theme_picker.dart` | 무료 2종 목록 | 공식 5종 gallery, offer/access 상태 분리, root controller 저장 — **완료** | UX-6 | Closed |
| `lib/services/entitlement_service.dart` | SharedPreferences compatibility stub | production authority 사용 금지 주석·legacy type 명시; Store/Inventory는 `CommerceGateway` 경계 | Commerce foundation | Closed |
| `lib/widgets/commerce_center_dialog.dart` | 없음 | 공식 catalog 기반 read-only Store & Inventory; nullable balance·owned-only inventory·125% text 대응 | Commerce foundation | Closed |
| `lib/dev/steam_inventory_poc/**` | Nocturne ItemDef `20001`, exchange `20010`, Astra POC cost `100` | POC 유지; production catalog/SKU로 승격하지 않음 | Commerce 후속 | High |
| `l10n/app_ko.arb`, `l10n/app_en.arb` | “모든 테마 무료” 고정 안내 | 5종 표시명과 included/owned/planned/checking/locked 상태 l10n — **완료** | UX-6 | Closed |
| dialog/bottom-sheet coordinator 호출부 | overlay가 Classic을 상속할 수 있음 | root Theme로 dialog/menu/snackbar 일관 적용 — **완료** | UX-1 | Closed |

현재 `lib/`에는 명시적인 `Navigator.push`/`MaterialPageRoute` page 이동이 없다. 그러나 설정·프로필·상점 route가 생기면 지금 구조에서는 root Classic으로 돌아가므로 UX-1에서 먼저 경계를 고친다.

---

## 5. Theme core migration

| 파일 | 현재 사용 | 목표 semantic token/component | Phase | 위험 |
|---|---|---|:---:|:---:|
| `lib/theme/akasha_colors.dart` | Classic 고정색과 surface helper 44개 | themeable widget 직접 사용 금지; domain constant만 남김 | UX-1 | Critical |
| `lib/theme/akasha_palette.dart` | surface 중심 role 약 18개 | text/onAccent/state/focus/scrim/shadow/currency role 확장 | UX-1 | Critical |
| `lib/theme/akasha_typography.dart` | TextStyle 색을 `AkashaColors`에 고정, 작은 caption 포함 | `ThemeData.textTheme` + semantic foreground | UX-1 | Critical |
| `lib/theme/akasha_theme.dart` | `onPrimary`와 button foreground를 흰색 고정, Material subtheme 일부만 정의 | 대비 기반 `onAccent`; input/button/dialog/menu/snackbar/focus 포함 | UX-1 | Critical |
| `lib/theme/akasha_spacing.dart` | 4–24 중심 5단계 | `4, 8, 12, 16, 24, 32, 48` geometry token | UX-1 | High |
| `lib/theme/akasha_radius.dart` | radius 4단계 | control 8 · card 12 · panel 16 · pill 999 | UX-1 | High |
| 신규 `AkashaThemeBackdrop` | 공통 renderer 없음 | asset + scrim + gradient + fallback + reduced motion | UX-1 | High |
| 신규 theme harness | Sakura projection 단위 테스트만 존재 | 5 preset registry, free 2 실제 렌더, paid 3 fallback, Material surface fixture | UX-1 | Critical |

---

## 6. Surface migration inventory

### 6.1 영역별 규모

`raw/static`은 각각 raw `Color/Colors`와 `AkashaColors` 직접 참조다. `geometry`는 spacing·dimension·radius 후보를 합한 값이다.

| 영역 | 파일 수 | raw / static | font / `<11` | geometry | effect | 목표 계약 | Phase | 위험 |
|---|---:|---:|---:|---:|---:|---|:---:|:---:|
| Shell / Navigation | 31 | 8 / 20 | 4 / 1 | 71 | 1 | `AkashaShellMetrics`, `NavigationItem`, utility semantic color | UX-2 | Critical |
| Home dashboard | 11 | 9 / 37 | 0 / 0 | 101 | 1 | `HeroPanel`, `ArchiveCard`, `StatTile`, `SectionHeader`, effect token | UX-3 | High |
| Preview | 12 | 6 / 47 | 17 / 13 | 79 | 0 | `PreviewSection`, caption/label token, 상태색 | UX-4 | High |
| Graph / Canvas / Timeline | 8 | 26 / 20 | 17 / 4 | 56 | 3 | node/edge palette, canvas metrics, focus/semantics | UX-2/4 | Critical |
| Workbench / Sanctum | 84 | 19 / 81 | 25 / 7 | 172 | 2 | workbench component theme, root theme 상속 | UX-1/4 | High |
| Dialog / Search | 40 | 47 / 66 | 85 / 12 | 209 | 0 | dialog/search/list-tile Material theme와 공통 component | UX-1/4 | High |

### 6.2 대표 파일별 이관표

| 파일 | 현재 사용 | 목표 semantic token/component | Phase | 위험 |
|---|---|---|:---:|:---:|
| `lib/screens/home/home_browse_search_chrome.dart` | semantic palette 이관, 실제 content width 기준 compact 판정 | 잔여 spacing/radius token 이관 | UX-2/4 | Medium |
| `lib/widgets/dashboard_sidebar.dart` | `256/232/drawer` 공통 spec과 destination registry 적용 | 잔여 nav spacing token 이관 | UX-2/4 | Medium |
| `lib/widgets/dashboard_sidebar_footer_part.dart` | 하단 `접기` 전용 surface | UX-6에서 행과 파일 제거; Top bar toggle/`Ctrl+B`로 계약 통일 | UX-6 | Closed |
| `lib/screens/home/home_shell_scaffold_bottom_nav_part.dart` | `56px` 공통 metric·palette·destination registry 적용 | 잔여 typography token 이관 | UX-2/4 | Medium |
| `lib/screens/home/views/dashboard_preview_panel.dart` | `PreviewPanelLayoutSpec` 기반 288px rail·680px compact sheet와 공통 section spacing | Explore/Library 역할 정리와 함께 실제 surface 시각 회귀 지속 | UX-4 | Medium |
| `lib/screens/home/views/entity_dashboard_preview_panel.dart` | Work와 동일한 Preview surface·content·Hero geometry | entity strip 역할 정리와 함께 실제 surface 시각 회귀 지속 | UX-4 | Medium |
| `lib/screens/home/views/home_dashboard/home_dashboard_view.dart` | 고정 32px padding, max width 없음 | responsive content gutter/max width | UX-3 | High |
| `lib/screens/home/views/home_dashboard/home_dashboard_continue_section.dart` | raw/static 색, geometry, 직접 gradient | ArchiveCard rail + effect token | UX-3 | High |
| `lib/screens/home/views/home_dashboard/home_dashboard_discovery_cards.dart` | raw/static 색과 카드별 geometry | 공통 dashboard card | UX-3 | High |
| `lib/screens/home/views/home_dashboard/home_dashboard_universe_section.dart` | 고정 색·geometry, feature flag | Insight card + graph semantic palette | UX-3/4 | High |
| `lib/widgets/universe_orbit_painter.dart` | 직접 색·painter effect | graph/effect tokens 주입 | UX-3/4 | High |
| `lib/widgets/poster_card_style.dart` | raw colors, 직접 shadow/glow | `ArchiveCardTheme` | UX-1/3 | Critical |
| `lib/widgets/poster_image.dart` | 직접 gradient/shadow | artwork overlay/scrim token | UX-1/3 | High |
| `lib/screens/home/views/canvas_editor_view.dart` | raw/static 색, 고정 font/geometry/effect | Canvas palette + metric + focus contract | UX-4 | Critical |
| `lib/screens/home/views/canvas_node_card.dart` | raw colors, micro text, shadow | Graph node component theme | UX-4 | Critical |
| `lib/screens/home/views/timeline_view.dart` | raw colors, 고정 spacing | Timeline semantic state + layout token | UX-4 | High |
| `lib/screens/home/views/candidate_review_view.dart` | raw color hotspot, 고정 geometry | review status tokens + common state view | UX-4 | High |
| `lib/widgets/web_image_search_dialog.dart` | raw 21, font 6, geometry 28 후보 | Dialog/Input/ListTile Material theme | UX-1/4 | High |
| `lib/widgets/fusion_search_dialog_tiles.dart` | raw/static 색과 font hotspot | Search result tile component | UX-1/4 | High |
| `lib/features/workbench/presentation/widgets/workbench_panel_styles.dart` | Classic static surface와 직접 색 | Workbench component theme | UX-1/4 | High |

이 표에 없는 155개 후보는 scan baseline의 mechanical tail로 관리한다. 먼저 semantic role과 공통 component를 만든 뒤, `AkashaColors.*` 및 raw 값의 잔여 건수를 Phase별로 감소시킨다. 개별 화면부터 무작정 치환해 새로운 의미 없는 token을 늘리지 않는다.

---

## 7. Theme ID 직접 분기

현재 feature widget에서 `if (theme.id == ...)`로 시각 구조를 바꾸는 분기는 발견되지 않았다. ID 사용은 registry lookup, Classic fallback, picker의 selected 비교에 집중돼 있다. 이 장점은 유지한다.

허용:

- preset registry lookup
- compatibility alias normalization
- picker의 selected state 비교
- access resolver의 `presetId` key

금지:

- theme ID에 따른 widget tree·spacing·기능 visibility 분기
- `requiresIap`를 visual widget에서 직접 읽기
- Nocturne만을 위한 별도 Home/Preview widget

---

## 8. Contrast·Focus 위험

| 항목 | 근거 | 목표 | Phase | 위험 |
|---|---|---|:---:|:---:|
| Accent foreground | `akasha_theme.dart`가 `onPrimary`와 button text를 흰색으로 고정 | preset별 `onAccent` AA 검증 | UX-1 | Critical |
| Micro text | `<11px` 51건 / 31파일, Preview에 집중 | caption 최소 11–12px, text scale 125% 검증 | UX-1/4 | High |
| Manual alpha | 118건 / 53파일 | semantic muted/disabled/overlay tokens | UX-1–4 | High |
| Status color | white/black/teal/red가 foreground·overlay·status를 겸함 | success/warning/danger/info/currency role 분리 | UX-1 | High |
| Gesture-only cards | PosterCard 등이 `GestureDetector`/`MouseRegion` 중심 | FocusableActionDetector, Semantics, Enter/Space | UX-1/3 | Critical |
| Canvas controls | gesture 중심 node interaction | focus-visible, keyboard, context-menu key 계약 | UX-4 전 | Critical |
| Ambient effects | 향후 petal/crystal effect | `IgnorePointer`, reduced motion, 정적 fallback | UX-5 | High |

---

## 9. 저장 ID migration

| 기존 저장값 | Canonical ID | 처리 |
|---|---|---|
| `classic` | `classicDark` | known alias로 변환 |
| `midnight` | `midnightBlue` | known alias로 변환 |
| `sakura` | `sakura` | 유지 |
| `amethyst` | `amethyst` | 유지 |
| `obsidian` | `amethyst` | 기존 compatibility alias 유지 |
| 없음 | `classicDark` | 기본 preferred/effective |
| 미상 값 | raw preference 보존 | effective만 `classicDark`; 값 삭제 금지 |

Migration 순서:

1. 기존 key `akasha_library_theme_id`를 읽는다.
2. known legacy ID를 canonical ID로 normalize한다.
3. 새 preferred key에 canonical ID를 기록한다.
4. 한 stable release 이상 기존 key read fallback을 유지한다.
5. provider 상태와 관계없이 preferred 값을 덮어쓰지 않는다.
6. `effectiveThemeId`는 저장하지 않고 preset availability와 access state에서 계산한다.

현재 배포 코드가 `astral`을 저장한 증거는 없다. `astral → classicDark` alias를 미리 만들지 않는다.

---

## 10. UX-1 경계

### 이번 Phase에서 수행

- 공식 canonical ID 5개와 compatibility adapter
- `AkashaThemePreset`, palette, assets, effects 계약
- `ThemeCatalogEntry`와 access resolver 경계
- preferred/effective theme state
- semantic text/onAccent/state/focus palette
- app root theme controller
- `AkashaThemeBackdrop`과 asset fallback
- Classic Dark / Midnight Blue 실제 이관
- dialog, menu, snackbar, bottom sheet, 향후 route의 root theme 상속
- Sakura / Amethyst / Nocturne ID와 중립 fallback preset
- theme component gallery/harness
- high-risk Theme core와 공통 Poster/Card chrome의 1차 이관

### 이번 Phase에서 금지

- Home 재설계
- Responsive Shell과 Sidebar/Preview 폭 변경
- Graph/Timeline 복원
- currency UI
- Steam entitlement·구매 연결
- Sakura/Amethyst/Nocturne 최종 art
- `LibraryTheme` compatibility layer 즉시 삭제
- 155개 style 후보 전체의 무계획 일괄 치환

---

## 11. UX-1 완료 증거

- [x] canonical theme ID 5개 unique/fallback test
- [x] legacy ID와 unknown preference migration test
- [x] `preferredThemeId` / `effectiveThemeId` resolver test
- [x] `free/owned/locked/checking/unavailable` state test
- [x] no-IAP Theme Gallery는 공식 5종과 승인 가격을 노출, premium 3종은 planned이며 구매 CTA 없음
- [x] 저장된 Midnight Blue로 시작할 때 Classic flash 없음
- [x] dialog/menu/snackbar/bottom sheet가 root effective theme 상속
- [x] 모든 preset의 asset fallback과 `onAccent` contrast 검증
- [x] theme harness에서 무료 2종 실제 렌더, premium 3종 fallback 렌더
- [x] analyze 0 · root test 974 · Windows debug build PASS
- [x] scan baseline 대비 잔여 hardcoded style 수 보고
- [ ] 새 RC 뒤에만 Steam release/reviewer 문구 갱신

### UX-2 검증 결과

- [x] root analyze **0** · root test **1011**
- [x] Sidebar/Dock destination registry·selection 일치 및 중복 방지
- [x] `PreviewTarget` 전환·close와 중앙 상태 보존
- [x] `1600×900`, `1366×768`, `1024×720`, Windows text scale 125% layout
- [x] Classic Dark/Midnight Blue geometry 동일성
- [x] 키보드 전역 목적지·drawer focus/close smoke test
- [x] Windows Debug/Release build PASS
- [x] 가짜 currency/avatar/notification, 신규 Graph/Timeline 기능 없음
