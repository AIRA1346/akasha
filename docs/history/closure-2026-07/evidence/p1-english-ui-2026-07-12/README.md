# P1 — Release Build English UI Visual Verification

> **Date:** 2026-07-12  
> **Build:** `scripts/build_release.ps1` → `build\windows\x64\runner\Release\akasha.exe` (then rebuild after l10n fixes with `flutter build windows --release`)  
> **Track:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](../../STEAM_RELEASE_BLOCKER_CLOSURE.md)
> **IAP:** remains `FeatureFlags.steamInAppPurchasesEnabled = false` (unchanged)

## Method

1. Seed `flutter.akasha_catalog_locale=en` in `%APPDATA%\Rune Atelier\AKASHA\shared_preferences.json`
2. Launch Release `akasha.exe`
3. Capture window screenshots (`scripts/p1_english_ui_capture.ps1`)
4. Inspect screenshots visually (not source-only)
5. Fix confirmed Korean / FeatureFlag leaks in small units
6. Rebuild Release, recapture, re-verify
7. `flutter analyze` + full `flutter test`

Evidence PNGs live in this folder.

## Checklist

| Area | Result | Evidence / notes |
|---|---|---|
| Preferences English + Display language = English | **PASS** | `02-preferences-esc.png`, `05-restart-preferences.png` |
| English locale persists after restart | **PASS** | `04-restart-english-persisted.png`, `05-restart-preferences.png` |
| Home chrome (sidebar, hero, search placeholder) | **PASS** | `01-home-english-seed.png` — Home/Explore/Library/Collections English |
| Vault-unlinked banner (first-run critical) | **PASS after fix** | Was Korean in `01-…`; fixed via l10n → `12-home-english-after-fix.png` |
| FeatureFlag Graph hidden | **PASS** | Graph tile absent in sidebar screenshots |
| FeatureFlag Timeline hidden | **PASS after fix** | Was visible despite `showTimeline=false`; gated in sidebar + `selectTimeline` |
| FeatureFlag Discovery / Universe / Recall | **PASS** | Not present on Home English screenshots |
| Knowledge Graph entry | **PASS** | Not in primary nav |
| IAP / purchase / locked theme UI | **PASS** | No purchase chrome observed; IAP flag false |
| Explore / Library / Collections nav | **PARTIAL** | Library English labels visible (`08`/`10` mis-clicks earlier); Explore grid not fully exercised with vault offline |
| Work add / open / edit / save | **DEFERRED** | Requires usable vault + file picker; vault path in prefs pointed at unavailable `G:\…` so catalog-only mode |
| Entity / Journal / Canvas deep flows | **DEFERRED** | Same vault availability limit this session |
| Dialog / SnackBar / Tooltip / context menu sweep | **PARTIAL** | Preferences OK; vault create success dialog localized in code (not visually exercised) |
| Empty / loading / confirm chrome | **PARTIAL** | Empty Continue cards English; loading not separately captured |
| Remaining hardcoded KO outside this session's surfaces | **OPEN** | Other dialogs still have KO `const Text` (candidate review, hidden registry, etc.) — track as follow-up small PRs when those surfaces appear in dogfood |

## Fixes landed in this P1 slice

1. `HomeVaultBanner` → arb keys (`homeVaultBanner*`)
2. Default vault create success / failure strings → arb keys
3. Sidebar Timeline gated by `FeatureFlags.showTimeline`
4. `selectTimeline()` no-ops when flag off
5. Regression: `test/home_vault_banner_l10n_test.dart`

## Verification (this slice)

| Gate | Result |
|---|---|
| `flutter analyze --no-pub` | **No issues found** |
| `flutter test --no-pub` | **933 passed** |
| Release visual re-check | Banner English · Timeline hidden · Preferences English (`12-` / `13-`) |


After P1 English verification closes major chrome:

- **A.** Fast resubmit: clear Store IAP, keep purchase UI hidden  
- **B.** Full Astra/Echo + Steam Wallet + GetReport before claiming IAP  

IAP stays disabled until that decision.
