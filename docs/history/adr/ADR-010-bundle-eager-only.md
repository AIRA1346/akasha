# ADR-010: App Bundle — Eager Shards Only (Phase 2.3)

> **상태:** Accepted (2026-06-14)  
> **Phase:** [architecture-evolution-phases.md](../programs/architecture-evolution-phases.md) §2.3

---

## Context

- `assets/registry/shards/**`에 **전체 카탈로그** 동봉 → APK·설치 크기 선형 증가
- Phase 2.1~2.2: search_index 분할 + browse 윈도우 → **나머지 shard는 on-demand** 가능
- `manifest.json`의 `eager: true` = franchise primary 등 cold-start 필수 shard

**Trigger:** `assets/registry` > 15MB ([catalog-scale-baseline](../programs/catalog-scale-baseline-490.md))

---

## Decision

### 번들 구성 (v2)

| 포함 | 항목 |
|------|------|
| Always | `manifest.json`, `search_index/` (v2), `search_index.json` (v1 fallback), `legacy_aliases.json`, `franchise_groups.json` |
| Shards | **`eager: true`만** (기본) · `--sync-assets` 전체는 G1 전환기 호환 |
| Read path | 번들 → disk cache → CDN (`RegistrySyncService`) |

### CLI

```bash
dart run tool/registry_builder.dart --sync-assets --bundle-eager-only
```

- **기본 (`--sync-assets`만):** 전체 shard (Steam v1 오프라인·현행)
- **`--bundle-eager-only`:** eager shard만 assets에 복사 · orphan prune

### Flip 조건

| 시점 | 동작 |
|------|------|
| @5181, ~3.4MB eager | **eager-only** (G1 flip) |
| >15MB full sync | **금지** — `discovery_batch.ps1` / `--bundle-eager-only` 필수 |
| >15MB | CI/release mandatory (already in `build_release.ps1`) |

---

## Consequences

**Positive:** APK·업데이트 크기와 카탈로그 수 **분리**  
**Negative:** eager 외 browse·검색은 **네트워크 또는 캐시** 의존 (이미 sync path 존재)

---

## Compliance

- `registry_builder.dart` — `--bundle-eager-only`
- Release script flip @15MB trigger
