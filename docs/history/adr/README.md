# Architecture Decision Records (ADR)

> AKASHA Registry·아카이빙 정책 결정 기록.
>
> 상태: `초안` · `승인` · `폐기` · `대체`

| ADR | 제목 | 상태 | URV-A 선행 |
|-----|------|------|------------|
| [ADR-001](ADR-001-dual-layer-entity-model.md) | Dual-layer (Work + Franchise) | **승인** | — |
| [ADR-002](ADR-002-music-registry-model.md) | 음악 Registry 모델 — **A안 vs B안** | 초안 · **A/B 검토** | ✅ |
| [ADR-003](ADR-003-series-minimum-unit.md) | 시리즈 작품 최소 단위 (에피소드 밖) | 초안 · **원칙 승인** | ✅ |
| [ADR-004](ADR-004-work-collection-policy.md) | 작품 수집 정책 (2차 창작 분리) | 초안 · **원칙 승인** | ✅ |
| [ADR-005](ADR-005-minimum-recordable-unit.md) | **매체별 최소 기록 단위** | 초안 · **대부분 승인 가능** | ✅ |
| [ADR-006](ADR-006-franchise-boundary-hierarchy.md) | **Franchise 경계·계층·깊이** | 초안 | ✅ |
| [ADR-007](ADR-007-app-layering.md) | App 레이어 가드레일 | **승인** | — |
| [ADR-008](ADR-008-record-entity-time-model.md) | **ArchiveRecord** · Entity · Time · Link | **승인** | — |
| [ADR-010](ADR-010-bundle-eager-only.md) | App Bundle — Eager Shards Only | **대체됨** | — |
| [ADR-015](../../architecture/ADR-015-full-local-registry-bundle.md) | 작품 레지스트리 전체 로컬 번들 | **승인** | — |

**리뷰 메모:** ADR-002 음악 — A/B 유지 · **B안(곡=Work) 가중** (미결정).

관련:

- [architecture-evolution-phases.md](../programs/architecture-evolution-phases.md) — Phase 1~6 실행
- [universal-registry-validation.md](../validation/universal-registry-validation.md)
- [registry-growth-strategy.md](../strategy/registry-growth-strategy.md)
