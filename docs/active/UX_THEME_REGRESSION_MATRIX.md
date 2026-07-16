# AKASHA Theme Package & Regression Matrix

> **지위:** UX-5A/B/C/D 테마 패키지 계약·시각 회귀 SSOT
> **작성:** 2026-07-15
> **상위 계약:** [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md)
> **범위:** Classic Dark, Midnight Blue, Sakura, Amethyst, Nocturne의 공통 geometry, asset fallback, reduced motion, 회귀 게이트

---

## 1. UX-5A 결론

UX-5A는 테마별 최종 artwork를 제작하는 단계가 아니라, artwork가 들어와도 기능과 배치가 깨지지 않게 만드는 패키지·회귀 기반이다.

- 공식 preset은 `classicDark`, `midnightBlue`, `sakura`, `amethyst`, `nocturne` 다섯 개로 고정한다.
- bitmap asset은 반드시 `assets/themes/<presetId>/` namespace 아래에 둔다.
- asset이 없거나 로드에 실패하면 공통 gradient/solid fallback을 사용하며 navigation, layout, feature availability는 변하지 않는다.
- feature widget은 preset ID로 분기하지 않고 root `ThemeData`의 `AkashaThemeVisuals`와 semantic palette를 소비한다.
- reduced motion에서는 ambient artwork와 decorative motion duration을 제거한다. 배경·Hero·texture와 geometry는 유지한다.
- 무료/premium, 가격, entitlement는 `ThemeCatalogEntry` 책임이다. visual preset에 commerce 상태를 넣지 않는다.

공식 다섯 테마는 각각 실제 backdrop·Hero asset을 사용한다. 생성 방식·reference 역할·hash·최종 prompt는 [assets/themes/ARTWORK_PROVENANCE.md](../../assets/themes/ARTWORK_PROVENANCE.md)에 고정했다. premium artwork가 bundle에 존재해도 no-IAP 빌드의 판매·구매·entitlement UI는 활성화하지 않는다.

---

## 2. Package contract

| 계약 | 구현 기준 | 실패 시 처리 |
|---|---|---|
| Namespace | `assets/themes/<presetId>/...` | 테스트 실패 |
| Optional layers | backdrop · Hero · texture · ambient | 누락 layer만 생략 |
| Shared fallback | preset의 asset 목록이 비어 있음 | 공통 gradient/brand fallback |
| Registry | preset · catalog · persisted alias를 `AkashaThemeRegistry`에 한 번만 등록 | invariant test 실패 |
| Effects | Backdrop · Hero · Interaction · Motion을 독립 그룹으로 관리 | cross-coupling test 실패 |
| Motion | `disableAnimations` 또는 `accessibleNavigation` | ambient 제거 · duration `0` |
| Geometry | spacing · radius · typography · Shell/Preview width | 테마별 변경 금지 |
| Access | bundled 2 · premium 3 | catalog resolver가 결정 |

실제 asset을 추가할 때는 `pubspec.yaml` 등록, namespace 검사, missing-asset fallback, reduced-motion 검사를 함께 통과해야 한다.

---

## 3. Regression matrix

| Surface / contract | 5 preset | 1600×900 | 1366×768 | 1024×720 | 125% text | 검증 파일 |
|---|:---:|:---:|:---:|:---:|:---:|---|
| Material surface harness | ✅ | ✅ | ✅ | ✅ | ✅ | `test/akasha_theme_harness_test.dart` |
| Responsive Shell | ✅ | ✅ | ✅ | ✅ | ✅ | `test/home_shell_responsive_layout_test.dart` |
| Home Hero | ✅ | ✅ | ✅ | ✅ | ✅ | `test/views/home_dashboard_hero_test.dart` |
| Preview rail / compact sheet | ✅ | rail | overlay | sheet | ✅ | `test/views/dashboard_preview_panel_test.dart` |
| Destination context header | ✅ | ✅ | ✅ | ✅ | ✅ | `test/views/destination_context_header_test.dart` |
| Graph / Timeline empty state | ✅ | ✅ | ✅ | ✅ | ✅ | `test/views/destination_surface_state_test.dart` |
| Asset fallback / reduced motion | contract | n/a | n/a | n/a | n/a | `test/widgets/akasha_theme_backdrop_test.dart`, `test/akasha_theme_test.dart` |
| Root overlay inheritance | root theme | n/a | n/a | n/a | n/a | `test/akasha_root_theme_test.dart` |

공식 다섯 테마는 Windows의 `960×640` stable component fixture와 `960×320` Home Hero를 screenshot golden으로 추가 고정한다.

- `test/goldens/theme_classic_dark_standard.png`
- `test/goldens/theme_midnight_blue_standard.png`
- `test/goldens/theme_sakura_standard.png`
- `test/goldens/theme_amethyst_standard.png`
- `test/goldens/theme_nocturne_standard.png`
- `test/goldens/theme_classic_dark_hero.png`
- `test/goldens/theme_midnight_blue_hero.png`
- `test/goldens/theme_sakura_hero.png`
- `test/goldens/theme_amethyst_hero.png`
- `test/goldens/theme_nocturne_hero.png`

Golden은 palette·Material component·실제 backdrop·Hero artwork의 시각 기준이다. 실제 제품 viewport overflow와 geometry는 위의 3개 viewport widget test가 담당한다. 테스트는 asset을 precache한 뒤 캡처해 경로 존재뿐 아니라 실제 decode·paint 결과를 검증한다.

```powershell
C:\src\flutter\bin\flutter.bat test --no-pub --update-goldens test\akasha_theme_golden_test.dart
```

Golden 갱신은 의도한 palette/component 변경을 검토한 뒤에만 수행한다. 단순 실패를 없애기 위한 무검토 갱신은 금지한다.

---

## 4. UX-5A gate

- 다섯 preset의 ID와 asset namespace가 유효하다.
- 다섯 preset에서 핵심 surface의 geometry가 동일하다.
- 공식 다섯 테마 golden이 서로 다른 실제 palette와 artwork를 렌더한다.
- 누락 asset에서도 콘텐츠와 layout이 유지된다.
- reduced motion에서 ambient·decorative motion이 비활성화된다.
- dialog, bottom sheet, popup, snackbar가 root effective theme을 상속한다.
- 전체 `flutter analyze`, `flutter test`, Windows Debug/Release build가 통과한다.

2026-07-14 UX-5B 결과: 해당 단계의 root analyze/test와 Windows Debug/Release build가 통과했다. Release asset bundle의 4개 SHA-256이 workspace provenance와 일치한다.

2026-07-14 UX-5C 결과: 해당 단계의 root analyze/test와 Windows Debug/Release build가 통과했다. 공식 5테마의 backdrop/Hero 10개가 Windows golden에서 실제 decode·paint됐고 Release asset bundle의 SHA-256이 workspace provenance와 모두 일치한다. `AkashaColors.*` 고정 측정은 **328 lines / 81 files**를 유지한다.

2026-07-15 UX-5D 결과: 해당 단계의 root analyze/test와 Windows Debug/Release build가 통과했다. 단일 `AkashaThemeRegistry`, ID-only preference migration, Backdrop·Hero·Interaction·Motion effect group을 고정했다. 기존 10개 Windows golden은 갱신 없이 통과했고 `AkashaColors.*`는 **328 lines / 81 files**를 유지한다. 현재 전체 품질 기준선은 [CURRENT_STATE.md](CURRENT_STATE.md)를 따른다.

---

## 5. UX-5B/C/D 결과와 남은 범위

- **UX-5B 완료:** Classic Dark·Midnight Blue 실제 backdrop·Hero asset 4개, 총 `6,282,701 bytes`를 통합했다. texture/ambient는 장식을 늘리기 위해 억지로 추가하지 않고 optional layer로 유지한다.
- **UX-5C 완료:** Sakura·Amethyst·Nocturne reference, palette, effect와 실제 backdrop·Hero asset 6개를 통합했다. 공식 artwork 전체는 10개, 총 `15,760,349 bytes`다.
- **UX-5D 완료:** duplicated preset/catalog/alias 목록과 `LibraryTheme` adapter를 제거하고, 새 테마 등록점과 surface effect 계약을 단일화했다.
- 실제 Steam entitlement, 가격, 구매, 재화 UI는 Commerce 후속 범위이며 Theme pack 완료 조건에 섞지 않는다.
- runtime 다운로드형 pack은 아직 구현하지 않았다. manifest schema, signature/trust, version migration, cache invalidation을 합의한 뒤 compile-time registry 위에 별도 loader로 추가한다.
- Nocturne는 near-black·graphite 바탕과 절제된 silver-blue accent, 초승달·구름·산악 모티프로 확정했다. Midnight Blue보다 훨씬 어둡고 무채색에 가까운 별도 시각 역할을 갖는다.
