# 연구 경계 및 표준 연동 수용 규칙 (RESEARCH_BOUNDARY)

> **Status:** Active repository-boundary policy
> **Authority:** 앱 저장소와 독립 `akasha-research` 저장소의 수용 경계
> **Updated:** 2026-07-17

본 문서는 **AKASHA 앱 저장소(akasha)** 관점에서 별도 분리 운영되는 **AKASHA 아카이브 연구 저장소(akasha-research)**와의 규격 결합 경계 및 승인 수용 절차를 선언합니다.

---

## 1. 독립성 원칙 (Independence)

1.  **연구와 제품 구현의 물리적 격리**:
    *   연구 표준 저장소(`akasha-research`)와 앱 제품 저장소(`akasha`)는 완전히 분리되어 관리됩니다. 제품 소스 코드 및 문서 내에 공인되지 않은 연구 초안 문서를 임의 삽입하거나 혼용하지 않습니다 (**MUST NOT**).
2.  **연구 초안의 비요구사항 선언**:
    *   연구 저장소에서 진행 중인 `Exploration`, `Draft`, `Candidate` 상태의 연구 내용 및 설계 후보안들은 앱 제품의 개발 요구사항으로 취급되지 않습니다 (**SHALL NOT**).

---

## 2. 규격 수용 및 반영 절차 (Integration Protocol)

앱 구현체에 새로운 아카이브 연구 규약을 반영하기 위해서는 반드시 다음 단계를 순서대로 밟아야 합니다 (**MUST**):

```text
  [연구 저장소 규격 Stable 승인]
               │
               ▼
  [앱 저장소 내 ADR (Architectural Decision Record) 초안 작성]
               │
               ▼
  [사용자 마이그레이션(Migration) 영향도 평가 및 백업 복구 검증]
               │
               ▼
  [프로덕션 코드 리팩터링 및 Conformance Test Vector 통과 확인]
```

1.  **연구 표준 Stable 상태 확인**:
    *   이관 대상 표준 규격은 `akasha-research` 내에서 최종적으로 `Stable` 판정을 받은 것이어야 합니다. 단, `Stable` 규격이라 하더라도 실제 앱 제품 로드맵 상의 영향도에 따라 반영 시기와 구체적 수용 여부는 제품 측에서 독립적으로 결정합니다 (**SHALL**).
2.  **독립 ADR 수립**:
    *   수용 시에는 표준 규격을 앱 인프라에 안착시킬 상세 설계 및 영향도를 작성한 ADR을 `docs/active/` 혹은 `docs/adr/` 하위에 명시적으로 상정하고 합의를 거쳐야 합니다 (**MUST**).
3.  **마이그레이션 계획 수립 및 검증**:
    *   기존 볼트 규격(v3 등)의 물리 파일 배치나 frontmatter 데이터 스키마를 수정 또는 변경하는 어떠한 규격이라도, 사용자 데이터 자동 마이그레이션 및 **무손실(의미 보존 및 출처 보존 수준) 백업 복구 계획이 입증되기 전에는 프로덕션 반영이 엄격히 금지됩니다 (MUST NOT)**. 디지털 서명이 개입되지 않는 한, 공백이나 포맷 수준의 바이트 단위 동일성(Byte-Preserving)까지 무리하게 강제하지는 않습니다 (**SHALL NOT**).
4.  **연구로의 피드백 제공 (Feedback Loop)**:
    *   앱 제품 구동 및 테스트 중 발견된 버그, 병목 현상, 예외 반례 및 실증 증거들은 연구 저장소(`akasha-research`)로 적극적으로 피드백되어 표준의 결함을 분석하고 개선하는 데에 활용되어야 합니다 (**SHALL**).
