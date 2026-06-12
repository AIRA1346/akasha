# Repo Cleanup Plan — 코드·문서 정리 (M2 일시 중단)

> **상태:** Phase 1~2 완료 · Phase 3 선택 · G-CLEAN 검증 중  
> **작성:** 2026-06-12 (v2 — 1차 검토 반영)  
> **전제:** Steam M2(depot·IAP·수동 QA) **일시 중단** · 출시 재개는 본 프로그램 게이트 후  
> **인벤토리:** [cleanup-inventory.md](../cleanup-inventory.md)

---

## 1. 목표

| 포함 | 제외 |
|------|------|
| dead·broken 코드 제거 | Steam depot / IAP / Playtest |
| Tier A SSOT 문서 숫자·링크 동기화 | `home_screen` 대규모 분할 |
| untracked·active AniList fetch 제거 | 카탈로그 G1 대량 insert |
| analyze **error 0** (+ warning quick wins) | Riverpod · UI i18n |
| 완료 plan 헤더 상태 통일 | `docs/archive/` 44건 일괄 이동 |

**완료 정의:** §7 게이트 전부 PASS · `git status` untracked 0

---

## 2. SSOT 숫자 (정리 기준선 @2026-06-12)

| 항목 | 값 | 출처 |
|------|-----|------|
| Registry works | **490** | `akasha-db/manifest.json` → `entryCount` |
| `flutter test` | **254/254** | 로컬 green |
| analyze lib | **error 7 · warning 9** | Phase 0 스캔 (error 전부 `my_library_screen.dart`) |

---

## 3. 문서 Tier (drift 수정 범위)

### Tier A — **반드시** 갱신 (현재 수치 반영)

| 파일 | drift 유형 |
|------|------------|
| [README.md](../../README.md) | 「430작」→ 490 · 규모 표 |
| [docs/README.md](../README.md) | Registry 430 → 490 |
| [ROADMAP.md](../../ROADMAP.md) | **현재 섹션** 사전 규모 · test 96/96 |
| [project-status-snapshot.md](../project-status-snapshot.md) | §2 `250/250` → 254 · 운영 결정 문맥 |
| [product-vision.md](../product-vision.md) | v1 범위 「430+」 |
| [release-readiness-checklist.md](../release-readiness-checklist.md) | 유지 (이미 490/254) |
| [programs/m2-steam-store-page.md](m2-steam-store-page.md) | 유지 (이미 490+) |
| [programs/catalog-growth-charter.md](catalog-growth-charter.md) | 「430」→ **「@430 시점 결정」** footnote 유지 |

**Tier A DoD:** 위 파일에서 **「현재 Registry = 490」** 불일치 0.  
역사적 「430은 출시 부족」**결정 문장**은 유지 가능 (날짜 각주).

### Tier B — 링크·상태만

| 파일 | 조치 |
|------|------|
| [product/my-library-design.md](../product/my-library-design.md) | As-Is → 통합 홈 모드 To-Be (§1~2) |
| 완료 plan 3종 | 헤더 「완료 + 잔여 백로그」 분리 |

### Tier C — **손대지 않음**

`docs/archive/` · sprint 회고 · 마일스톤 완료 체크리스트의 당시 숫자

---

## 4. Phase별 실행

### Phase 0 — 인벤토리 ✅

산출: [cleanup-inventory.md](../cleanup-inventory.md)

| # | 작업 | 상태 |
|---|------|:----:|
| 0.1 | dead code `rg` 스캔 | ✅ |
| 0.2 | Tier A drift 목록 | ✅ |
| 0.3 | analyze baseline | ✅ |
| 0.4 | git / untracked | ✅ |
| 0.5 | Keep / Delete / Defer 표 | ✅ |

### Phase 1 — 코드 (예상 0.5~1일)

**순서:** 문서 선행(`my-library-design`) → 삭제 → analyze fix

| # | 대상 | 조치 | 근거 |
|---|------|------|------|
| 1.1 | `lib/screens/my_library_screen.dart` | **Delete** | call site 0 · **analyze error 7건** (`AkashaItem` import 누락) |
| 1.2 | `showAddToLibrarySheet` | **Delete** | call site 0 |
| 1.3 | `EntitlementService.purchase()` | **Delete** | `@Deprecated` wrapper · call site 0 |
| 1.4 | `tool/discovery/anilist_client.dart` | **Delete** (untracked) | `discovery_source_fetch`가 anilist **UnsupportedError** |
| 1.5 | analyze warning 9건 | **Fix** | unused import · unused field `_isLoading` 등 |

**Keep (삭제 금지):**

| 대상 | 이유 |
|------|------|
| `sample_data.dart` | 볼트 미연결 시 `buildSampleData()` — 데모 UX |
| `TodayRecallCard` / `RecallPicker` | `FeatureFlags.showRecallCard` v1.1 경로 |
| `tool/discovery/anilist_strip` 등 | removal test · CI denylist |

**Defer:**

| 대상 | 이유 |
|------|------|
| `home_screen.dart` 분할 | ROADMAP 백로그 · diff 큼 |
| `test/phase*_test.dart` 이동 | CI 히스토리 |

### Phase 2 — Tier A 문서 (예상 0.5일)

§3 Tier A 표 일괄 갱신. archive 일괄 수정 **하지 않음**.

### Phase 3 — plan·tool 메타 (선택 0.5일)

| # | 작업 |
|---|------|
| 3.1 | `curated-personal-library-plan.md` 헤더: 「v1 구현 완료 · E2/polish = v1.1 백로그」 |
| 3.2 | `unified-library-add-flow-plan.md` §2.3 → historical (call site 0 @2026-06-10) |
| 3.3 | AniList **migration** 스크립트 → `tool/` 주석에 「legacy · active fetch 아님」 |
| 3.4 | `cleanup-inventory.md` → `docs/archive/` 이동 또는 삭제 |

---

## 5. Git 전략

| 항목 | 결정 |
|------|------|
| 미 push 커밋 2개 | 정리 **전** `push` 권장 (release readiness 분리) |
| 정리 PR | `chore/repo-cleanup` 또는 `main` 직접 — 1 PR |
| `manifest.json` timestamp | registry 변경 PR과 **분리** |

---

## 6. 재검토 결과 (2026-06-12)

### 6.1 v1 대비 변경점 (v1 계획 → v2)

| v1 | v2 수정 |
|----|---------|
| `sample_data` 삭제 후보 | **Keep** — active demo path |
| Recall import 정리 | **Defer** — flag-off live path |
| grep `430` active 0 | **Tier A만** 0 |
| `anilist_client` commit/archive 고민 | **Delete** (untracked) |
| Phase 2 docs 48건 | **Tier A 8건** |

### 6.2 신규 발견 (Phase 0 재검토)

| # | 발견 | 영향 |
|---|------|------|
| N1 | `MyLibraryScreen` **analyze error 7** | Phase 1 **P0** — 삭제 시 error 0 |
| N2 | `project-status-snapshot` §2 **250 vs 254** | Tier A 수정 |
| N3 | `ROADMAP` **96/96** 잔존 | Tier A 수정 |
| N4 | `curated-personal-library-plan` 헤더 모순 | Tier B |
| N5 | analyze warning 9 — 대부분 unused import | Phase 1.5 |

### 6.3 리스크

| 리스크 | 완화 |
|--------|------|
| `my-library-design.md` As-Is 오해 | Phase 1 전 To-Be 갱신 |
| 정리 지연 → M2 재개 밀림 | Phase 1~2만 blocking · Phase 3 선택 |
| inventory 문서 부채 | Phase 3.4 archive |

---

## 7. 정리 게이트 (G-CLEAN)

```powershell
.\scripts\flutter.ps1 test
.\scripts\flutter.ps1 analyze lib/          # error 0
C:\src\flutter\bin\dart.bat run tool/ci_registry_check.dart
git status                                   # untracked 0
```

| ID | Pass |
|----|:----:|
| G-CLEAN-1 | test 254/254 |
| G-CLEAN-2 | analyze lib **error 0** |
| G-CLEAN-3 | ci_registry_check |
| G-CLEAN-4 | Tier A doc drift 0 (§3) |
| G-CLEAN-5 | deprecated lib call site 0 |
| G-CLEAN-6 | untracked 0 |
| G-CLEAN-7 | inventory 모든 Delete 항목 처리 |

---

## 8. 정리 후 M2 재개

[release-readiness-checklist.md](../release-readiness-checklist.md) — G-QA 수동 12건 → depot → IAP

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-12 | v2 — 1차 계획 검토 반영 · Phase 0 재검토 · inventory 분리 |
