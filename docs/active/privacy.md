# AKASHA Privacy Policy

> **Effective:** 2026-07-19
> **Developer:** Rune Atelier  
> **Contact:** GitHub Issues on [akasha](https://github.com/AIRA1346/akasha) (or your support email when published)

---

## Summary

AKASHA is a **local-first** Windows desktop app. Your Sanctum vault (Markdown files, posters, ratings, notes) stays **on your device**. We do not operate a central server that stores your personal archive.

---

## Data stored locally

When you connect a Sanctum vault folder, AKASHA reads and writes:

- Markdown (`.md`) files with YAML front-matter
- Images under `posters/` that you add
- App preferences (vault path, library layout, theme) via local storage

You choose the vault folder. You can back up, sync, or edit files outside the app (e.g. Obsidian).

---

## Bundled catalog data

AKASHA ships its read-only `akasha-db` catalog metadata inside the application:

- Work titles, years, creators, categories, search tokens
- **No** posters, descriptions, ratings, or user content in the catalog

Production search, browse, filters, and work details do not download registry data or
check a registry CDN. Catalog updates arrive with an application update. No account is
required.

---

## Data we do not collect (v1)

- No AKASHA account or login
- No analytics SDK in the open-source v1 scope described here
- No upload of your vault contents to Rune Atelier servers

Steam may collect platform data per [Valve's privacy policy](https://store.steampowered.com/privacy_agreement/) when you use Steam features such as install, updates, purchases, or store/community features.

---

## In-app purchases

AKASHA’s **base app is free**. Steam v1 includes optional **cosmetic** in-app purchases (Astra currency packs and paid theme packages).

- Astra purchases are processed through the **Steam Wallet**.
- Rune Atelier does **not** receive your payment card or other payment-instrument details.
- **Steam Inventory** is the account authority for Astra balances, Echo balances, and theme entitlements. The app reads Inventory results to show balances and ownership.
- Your personal vault contents are **not** uploaded for purchase processing.
- Rune Atelier does **not** operate its own payment server or an external checkout path around Steam.

Steam platform processing of purchases and Inventory follows [Valve’s privacy policy](https://store.steampowered.com/privacy_agreement/).

---

## Children's privacy

AKASHA is not directed at children under 13. We do not knowingly collect personal data from children.

---

## Changes

We may update this policy before or after Steam release. The effective date at the top will change.

---

## Your rights

Because personal data stays on your device, you control it by managing your vault folder and uninstalling the app. For questions, open a GitHub issue or contact the developer email listed on the Steam store page.
