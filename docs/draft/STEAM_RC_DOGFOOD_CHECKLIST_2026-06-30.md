# Steam RC Dogfood Checklist — 2026-06-30

> Scope: Steam v1 release-candidate dogfood for the personal Sanctum archive loop.
> Status: manual dogfood pending, automated gates green.

---

## 1. Automated Gates

| Gate | Result |
|------|--------|
| `flutter analyze lib` | PASS, 0 issue |
| `flutter test` | PASS, 647/647 |
| pushed tip | `2b3d292c` |

Notes:

- The first test run could not delete `build/unit_test_assets`.
- The folder was confirmed inside the workspace, removed, and the full suite passed on rerun.

---

## 2. Manual Dogfood Path

Run this on the built app, not only in tests.

### Vault Loop

- Select or open a real vault.
- Create or open one archived work.
- Add or edit a memo/review.
- Save, close the app, reopen, and confirm the record is still correct.
- Confirm the `.md` frontmatter and body are human-readable.

### Poster Localizing

- Paste an image URL through the normal poster correction flow.
- Confirm the vault receives a file under `posters/`.
- Confirm the record stores `poster: "posters/..."`, not the original URL.
- Restart the app and confirm the poster still renders.
- Existing records with old URL posters do not need migration for v1.

### Home UI

- Confirm the search-first top chrome feels natural.
- Open filters and close them again.
- Scroll the "continue exploring" rail.
- Select a work and confirm the right preview rail updates.
- Confirm the `내 감상` card is readable and not too dense.

### Personal Library

- Confirm the sidebar `나만의 서재` section appears.
- Create a new personal library if none exists.
- Select a personal library and return home.
- Confirm the bottom library tab still works.

### App Theme

- Open app theme from the app bar.
- Change theme.
- Confirm Home, sidebar, bottom nav, and preview rail do not clash visually.

---

## 3. Non-Blocking Known Items

| Item | v1 stance |
|------|-----------|
| Existing URL posters | Leave as-is; re-enter URL only if a poster breaks |
| WebP/resize pipeline | post-v1 |
| Infinite Taste Archive ADR | design direction only, no code change |
| Agent/player/tool selection | outside AKASHA product scope |

---

## 4. RC Decision Rule

Steam RC can proceed when:

- automated gates remain green
- the vault loop survives restart
- new poster localizing works on a real image URL
- no P0 visual/UI break appears in Home, preview rail, library, or theme

Public release should wait until this checklist is manually walked once.
