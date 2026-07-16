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
| 현재 release gate | [Steam Service Release Readiness](active/STEAM_SERVICE_RELEASE_READINESS.md), [Steam Release](active/STEAM_RELEASE.md), [Commerce Contract](active/COMMERCE_CURRENCY_CONTRACT.md) |
| UX 계약 | [UX Design System](active/UX_DESIGN_SYSTEM.md), [Theme Regression Matrix](active/UX_THEME_REGRESSION_MATRIX.md) |
| 저장소 경계·정책 | [Research Boundary](active/RESEARCH_BOUNDARY.md), [Privacy](active/privacy.md) |

## Architecture

`docs/architecture/`에는 아직 구현 결정이나 이관 계획으로 사용되는 집중 설계
문서를 둔다. 상위 원칙과 충돌하면 Active의 Constitution, format specification,
CURRENT_STATE가 우선한다.

## Draft

`docs/draft/`에는 승인되지 않았거나 장기 후보인 계획을 둔다. 특히
[Ultimate Archive Backlog](draft/ULTIMATE_ARCHIVE_BACKLOG.md)는 활성 계약이
아니며 구현 우선순위를 자동으로 부여하지 않는다.

## History

`docs/history/`는 완료된 감사, 종료된 계획, 이전 스프린트와 증거를 보존한다.
2026-07 Active 정리에서 이동한 문서는
[closure-2026-07](history/closure-2026-07/README.md)에 모았다. 역사 문서의 내용과
당시 테스트 수치는 수정하거나 현재 기준선으로 재해석하지 않는다.

## 문서 갱신 규칙

- 현재 전체 테스트 개수와 분석 결과는 `CURRENT_STATE.md` 한 곳만 갱신한다.
- 다른 Active 문서는 품질 게이트 통과 여부만 기록하고 숫자는 CURRENT_STATE를
  참조한다.
- 파일 이동 시 저장소 전체 상대 링크 검사를 실행한다.
- `akasha-research`의 Draft/Candidate를 앱 요구사항으로 직접 가져오지 않는다.
  수용 절차는 [RESEARCH_BOUNDARY.md](active/RESEARCH_BOUNDARY.md)를 따른다.
