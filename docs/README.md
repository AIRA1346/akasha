# AKASHA 문서 체계

문서는 권위와 수명주기에 따라 구분한다. 현재 구현 사실과 품질 기준선은
[CURRENT_STATE.md](active/CURRENT_STATE.md)만 SSOT로 사용하며, 완료된 계획과
감사 문서의 수치는 역사적 스냅샷으로만 해석한다.

## Active

`docs/active/`에는 현재 의사결정과 구현에 계속 적용되는 문서만 둔다.

| 범주 | 문서 |
|---|---|
| 최상위 원칙 | [Archive Constitution](active/AKASHA_ARCHIVE_CONSTITUTION.md), [Vision](active/VISION.md) |
| 구현 현실 | [Current State](active/CURRENT_STATE.md), [Architecture](active/ARCHITECTURE.md), [Roadmap](active/ROADMAP.md) |
| Vault 형식·프로토콜 | [Vault Format v3](active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md), [Agent Vault Protocol](active/AGENT_VAULT_PROTOCOL_V1.md), [Vault Agent Guide](active/VAULT_AGENT_GUIDE.md), [Local Agent Command Protocol](active/LOCAL_AGENT_COMMAND_PROTOCOL.md) |
| Archive 계약 ADR | [AI Write Gateway](active/AI_ARCHIVE_WRITE_GATEWAY_ADR.md), [Provenance](active/PROVENANCE_AND_DERIVED_INPUT_ADR.md), [Relation Tiers](active/RELATION_TIERS_AND_ASSERTIONS_ADR.md), [Lifecycle](active/LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md), [Extension Namespace](active/EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md), [Gateway Permission](active/GATEWAY_PERMISSION_AND_RECEIPT_ADR.md) |
| 활성 보강 계획 | [Infinite Archive Hardening](active/INFINITE_ARCHIVE_HARDENING_PLAN.md), [Agent Entity Creation and Scale](active/AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md), [Domain Deprecation](active/DOMAIN_DEPRECATION_PLAN.md) |
| 현재 release gate | [Steam Service Release Readiness](active/STEAM_SERVICE_RELEASE_READINESS.md), [Steam Release](active/STEAM_RELEASE.md), [Commerce Contract](active/COMMERCE_CURRENCY_CONTRACT.md), [Steam inventory production](active/steam_inventory_production/README.md) |
| UX 계약 | [UX Design System](active/UX_DESIGN_SYSTEM.md), [Theme Regression Matrix](active/UX_THEME_REGRESSION_MATRIX.md) |
| 제거 게이트 | [Legacy Removal Policy](active/LEGACY_REMOVAL_POLICY.md) |
| 저장소 경계·정책 | [Research Boundary](active/RESEARCH_BOUNDARY.md), [Privacy](active/privacy.md) |

## Steam (runtime / development)

`docs/steam/`는 Windows Steam **런타임·개발 실행** 계약이다. release gate·commerce·ItemDef는 `docs/active/`의 Steam 문서를 따른다.

| 문서 | 역할 |
|---|---|
| [Steam Runtime Execution Contract](steam/STEAM_RUNTIME_EXECUTION_CONTRACT.md) | AppID, Overlay, `steam_appid.txt`, release payload 경계 (commerce 범위 밖) |
| [Windows Steam Development](steam/WINDOWS_STEAM_DEVELOPMENT.md) | `tool/run_windows_steam_dev.ps1` 등 로컬 Steam-library 개발 가이드 |

Release/commerce SSOT: [STEAM_SERVICE_RELEASE_READINESS.md](active/STEAM_SERVICE_RELEASE_READINESS.md) · [STEAM_RELEASE.md](active/STEAM_RELEASE.md) · [steam_inventory_production](active/steam_inventory_production/README.md).

## Architecture

`docs/architecture/`에는 아직 구현 결정이나 이관 계획으로 사용되는 집중 설계
문서를 둔다. 상위 원칙과 충돌하면 Active의 Constitution, format specification,
CURRENT_STATE가 우선한다.

현재 작품 레지스트리 packaging 결정은
[ADR-015: 전체 로컬 번들](architecture/ADR-015-full-local-registry-bundle.md)을 따른다.
이는 역사적 eager-only 결정인 ADR-010을 대체하되, production CDN 호출 제거와 cache
migration까지 Phase 2에서 완료했다. 현재 production 작품 레지스트리는 bundle-only다.

## Draft

`docs/draft/`에는 승인되지 않았거나 장기 후보인 계획만 둔다. 활성 계약이 아니며
구현 우선순위를 자동으로 부여하지 않는다.

2026-07-19 위생 분류 후 잔류 draft (2):

| 문서 | 비고 |
|---|---|
| [Ultimate Archive Backlog](draft/ULTIMATE_ARCHIVE_BACKLOG.md) | Non-binding draft backlog (D-004 ownership · D-007 journal polish) |
| [Canvas Editor Decomposition Plan](draft/CANVAS_EDITOR_DECOMPOSITION_PLAN.md) | Open B1–B6 plan |

Ownership Audit·Agent Vault UI Dogfood Review는 `history/`로 이동했다 (시점 감사; open 항목은 backlog D-004/D-007).
완료된 R3–R14 UX/Discovery 감사·보고와 Foundation 감사는 `history/`로 이동했다.
`LEGACY_REMOVAL_POLICY`는 active 제거 게이트로 승격했다.

## History

`docs/history/`는 완료된 감사, 종료된 계획, 이전 스프린트와 증거를 보존한다.
2026-07 Active 정리에서 이동한 문서는
[closure-2026-07](history/closure-2026-07/README.md)에 모았다. 역사 문서의 내용과
당시 테스트 수치는 수정하거나 현재 기준선으로 재해석하지 않는다.

추가 하위 아카이브 (체계 변경 아님 · 탐색용):

- [closure-2026-07/ux-discovery](history/closure-2026-07/ux-discovery/README.md) — UX Recovery / R3–R5 / R14 · Agent Vault UI dogfood
- [closure-2026-07/foundation](history/closure-2026-07/foundation/README.md) — Foundation F0–F4 audit
- [programs/discovery-r6-r13](history/programs/discovery-r6-r13/README.md) — Discovery R6–R13
- [programs/canvas-editor](history/programs/canvas-editor/README.md) — Canvas B.1 completed plan
- [programs/akasha-db-ownership](history/programs/akasha-db-ownership/README.md) — akasha-db ownership A/B/C audit snapshot

## 문서 갱신 규칙

- 현재 전체 테스트 개수와 분석 결과는 `CURRENT_STATE.md` 한 곳만 갱신한다.
- 다른 Active 문서는 품질 게이트 통과 여부만 기록하고 숫자는 CURRENT_STATE를
  참조한다.
- 파일 이동 시 저장소 전체 상대 링크 검사를 실행한다.
- `akasha-research`의 Draft/Candidate를 앱 요구사항으로 직접 가져오지 않는다.
  수용 절차는 [RESEARCH_BOUNDARY.md](active/RESEARCH_BOUNDARY.md)를 따른다.
