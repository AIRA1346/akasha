# ADR-014: Core Archive Ontology — Entity, Record, Document, Artifact, Relationship Assertion

- 상태: 채택됨 — 의미 경계만 정의하며 구현 스키마는 도입하지 않음
- 날짜: 2026-07-10
- 관련: [ADR-008](ADR-008-record-entity-time-model.md), [ADR-013](ADR-013-connection-link-index.md), [Vault Format Specification v3](../../active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md), [P1-A 사례 fixture](../../active/P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md)

## 맥락

AKASHA의 Markdown Vault는 사용자가 소유하는 원본 아카이브이며, Work·Entity·Journal·Timeline·Canvas는 서로 다른 기록 경험을 보존한다. v3 계약은 `record_id`, `record_kind`, 생성·수정 시각, 출처, 증거, 외부 식별자, 구조화 링크를 공통으로 제공하지만, 파일·화면·도메인 모델이 곧 하나의 보편 의미 객체라는 뜻은 아니다.

향후 외부 도구의 원본, 사용자의 직접 기록, AI의 파생 해석을 함께 보존하려면 물리 파일, 탐색 링크, 의미 주장, 지속적 대상을 구분해야 한다. 이 ADR은 그 경계를 고정한다. 범용 `Record` 모델, 새 frontmatter, serializer, migration은 이 ADR의 범위가 아니다.

## 결정

### 1. Entity — 지속적 대상

**Entity**는 여러 기록과 문서가 가리킬 수 있고, 개별 기록이 사라지거나 갱신되어도 동일성을 유지하는 대상이다. 작품·인물·장소·개념·프로젝트 같은 대상이 이에 해당한다.

불변조건:

- 안정된 Entity ID가 있으며, 파일 경로나 표제어는 그 ID를 대신하지 않는다.
- Entity는 그것을 언급하거나 평가한 Record와 동일하지 않다.
- 하나의 Entity는 0개 이상의 Record, Document, Artifact, Relationship Assertion의 대상이 될 수 있다.
- 현재 Work는 특히 작품 대상의 Entity 역할을 할 수 있지만, Work의 도메인별 메타데이터를 일반 Entity로 평탄화하지 않는다.

### 2. Record — 특정 시점의 보존 가능한 발화·경험·해석

**Record**는 인간, 외부 도구, 또는 AI가 특정 맥락과 시점에 남긴 감상·경험·주장·관찰·해석·결과물이다. Record는 원본의 사실성을 보증하지 않는다. 무엇이, 누구 또는 어떤 도구에 의해, 어떤 근거로 남겨졌는지를 보존한다.

불변조건:

- 안정된 Record ID와 provenance(최소한 기원 주체·기원 방식·기록 시점 또는 이를 복원할 근거)를 가진다.
- 0개 이상의 Entity를 가리킬 수 있으며, Entity가 없어도 존재할 수 있다.
- 시간은 하나로 축약하지 않는다. 시스템 생성·수정 시각과 경험/사건 시각은 서로 다른 의미로 유지한다.
- 외부 원본을 가져온 Record와 그 원본을 입력으로 한 AI 해석은 같은 Record가 아니다.
- AI 파생 해석을 영속 보존할 때에는 원본을 변경하지 않고 별도 Record로 남긴다. 후속 provenance ADR에서 `derived_from` 및 입력 revision의 정확한 표현을 정한다.

현재 v3의 `record_id`, `record_kind`, `created_at`, `updated_at`, `source`, `evidence`, `external_ids`는 이 경계의 출발점이다. 다만 현재 `source`와 문자열 `evidence`만으로는 완전한 provenance를 표현하지 못한다.

### 3. Document — 인간 가독 Vault 저장·표현 단위

**Document**는 사람이 열어 읽고 편집하는 Vault의 Markdown 저장·표현 단위다. 현재는 주로 하나의 `.md` 파일이며, 경로·slug·제목은 탐색과 배치를 위한 정보다.

불변조건:

- Document는 의미 객체의 컨테이너 또는 표현일 수 있지만, 그 자체가 항상 Entity나 Record인 것은 아니다.
- 하나의 Document는 Entity 메타데이터, 하나 이상의 Record, 일반 본문, Reference를 함께 담을 수 있다.
- Document의 이동·이름 변경·분할·병합이 Entity 또는 Record ID를 바꾸어서는 안 된다.
- 한 의미 객체가 여러 Document에 표현되거나, 하나의 복합 Document가 여러 물리 파일로 구성될 수 있다.

현재 Work·Entity·Journal·Timeline Markdown은 보통 "Document + 주된 Record", 그리고 경우에 따라 Entity 앵커를 함께 담는다. 이 구현 관례는 1:1 의미론적 제약이 아니다.

### 4. Artifact — 참조되는 부속 자원

**Artifact**는 Document 또는 Record가 참조하는 부속 자원이다. 이미지·포스터·첨부 파일·외부에서 확보한 원본 파일·Canvas의 `layout.json`이 이에 해당한다.

불변조건:

- Artifact의 바이트와 경로는 Document 본문이나 Record의 주장과 구분한다.
- 하나의 Artifact는 여러 Document/Record가 참조할 수 있고, 하나의 Document/Record는 여러 Artifact를 참조할 수 있다.
- 파일의 존재만으로 Artifact가 어떤 의미를 증명하거나 어떤 Entity에 속한다고 추론하지 않는다.
- 현재는 범용 Artifact 식별자·MIME·해시·역할 스키마를 도입하지 않는다. 해당 세부 계약은 provenance 및 extension 논의 뒤에 결정한다.

### 5. Relationship Assertion — 독립적인 의미 주장

**Relationship Assertion**은 두 대상 사이의 관계를 독립적으로 보존해야 할 때의 의미 주장이다. 단순한 연결 표시가 아니라, "A가 B와 이 관계에 있다"는 발화 또는 사실 주장이다.

불변조건:

- 방향(subject/target), 어휘(predicate), 대상의 안정 ID 또는 보존 가능한 식별 근거를 가진다.
- 누가/무엇이 어떤 근거로 주장했는지의 출처가 있어야 한다.
- 주장·관측·유효 시점과 수명주기(철회, 대체, 병합 등)를 기록할 수 있어야 한다.
- 독립적인 provenance, evidence, 시간, 충돌 또는 수명주기가 필요하지 않다면 Relationship Assertion을 만들지 않는다.
- 관계는 사실로 단정하지 않는다. 상충하는 Assertion이 함께 존재할 수 있다.

정확한 저장 형태(별도 파일, Record의 특수 종류, 관계 로그)와 필드명은 후속 relation tiers 및 lifecycle ADR에서 결정한다.

## 링크와 Assertion의 구분

| 형식 | 현재 예 | 의미 | 독립 주장인가 |
| --- | --- | --- | --- |
| Reference | 제목, 외부 URL, 식별자, 파일 경로 | 읽는 사람이 다른 대상을 찾을 수 있게 하는 참조 | 아니오 |
| embedded/wiki link | 본문의 `[[제목]]`, `[[id:...]]` | 문서 안의 탐색 연결 또는 언급 | 아니오 |
| structured link | v3 `links`의 target/relation/label | Record에 붙는 타입 있는 연결·주석 | 기본적으로 아니오 |
| Relationship Assertion | 향후 명시적으로 승격된 관계 주장 | 방향·어휘·출처·시점·수명주기를 가진 독립 의미 | 예 |

wiki link, 일반 Reference, embedded link는 자동으로 "관계가 사실이다" 또는 "작성자가 그 관계를 주장했다"는 뜻이 아니다. `RecordLinkIndexService`가 본문의 wiki link를 색인하는 현재 동작도 탐색 기능이며, 관계 그래프의 진실 공급원이 아니다.

structured link의 `relation`은 유용한 힌트와 표현 어휘가 될 수 있다. 하지만 현재 v3 링크에는 독립 ID, 주장자, 증거, 시점, lifecycle이 없으므로 그 자체를 Relationship Assertion으로 해석하지 않는다. 필요한 경우에만 명시적인 승격 절차로 별도 Assertion을 만든다.

## Canvas의 분류

Canvas는 일반 Record가 아니라 `canvas.md`와 `layout.json`으로 구성된 **복합 Document**로 분류한다. `canvas.md`는 사람이 읽는 내용과 Canvas 메타데이터를, `layout.json`은 노드 좌표·표시·edge 같은 표현 상태를 보관한다. `layout.json`은 Canvas Document가 참조하는 Artifact다.

Canvas edge는 기본적으로 화면상 연결과 배치 의도를 위한 표현 상태다. edge의 `relation`이나 `edgeKind`가 존재해도, 그것만으로 지속적 관계 사실을 주장하지 않는다. 사용자가 명시적으로 "관계로 보존"하도록 승격하고 Assertion의 출처·대상·어휘·시점·수명주기를 제공한 경우에만 Relationship Assertion으로 취급한다.

대안과 선택 근거:

| 대안 | 배제 또는 선택 근거 |
| --- | --- |
| Canvas를 일반 Record로 취급 | Canvas의 주된 동일성은 발화가 아니라 복합 문서와 시각 표현이다. 현재 v3 Record 계약도 갖지 않는다. |
| Canvas edge를 즉시 관계 사실로 취급 | 배치와 탐색을 사실 주장으로 오인하며, provenance와 lifecycle이 없는 edge에 과도한 의미를 부여한다. |
| Canvas를 복합 Document로 취급 (선택) | 현재 `canvas.md` + `layout.json` 저장 구조, P0 다중 파일 복구, 사용자 편집 경험을 그대로 보존한다. |

## 현재 Vault 유형의 매핑

| 현재 유형 | Entity | Record | Document | Artifact | Relationship Assertion |
| --- | --- | --- | --- | --- | --- |
| Work | 작품 대상(Work ID) | 현재 Work Markdown의 주된 기록 | Work `.md` | poster/첨부물(있다면) | 현재 없음; 링크는 Assertion이 아님 |
| Entity | 인물·장소·개념 등의 대상 | 현재 Entity journal의 주된 기록 | Entity `.md` | poster/첨부물(있다면) | 현재 없음 |
| Journal | 선택적으로 언급되는 대상 | 독립 `jr_*` 기록 | Journal `.md` | 첨부물(있다면) | 현재 없음 |
| Timeline | 선택적으로 참조되는 대상 | 독립 `tl_*` 경험·사건 기록 | Timeline `.md` | 첨부물(있다면) | 현재 없음 |
| Canvas | Canvas 자체는 보통 Entity가 아님 | 일반 Record가 아님 | `canvas.md` + `layout.json` 복합 Document | `layout.json`, 이미지 등 | 명시 승격 전에는 없음 |

이 표의 "주된 기록"은 현재 파일 표현을 설명할 뿐, 한 파일 안에 하나의 Record만 허용한다는 제약은 아니다. 특히 Work의 도메인 상태, Journal의 서술 자유도, Timeline의 발생 시각, Canvas의 시각 상태는 각각 유지한다.

## 물리 파일과 의미 객체를 1:1로 두지 않는 이유

- 하나의 Work/Entity Markdown은 Entity 앵커, 주된 Record, 본문 Reference와 메타데이터를 함께 담는다.
- 하나의 원본 Record에서 여러 AI 파생 Record가 나올 수 있으며, 원본 파일을 다시 쓰는 방식으로 이를 표현하면 provenance가 사라진다.
- Canvas 하나는 두 물리 파일의 일관된 조합이며, 그 edge는 다수의 탐색 연결을 표현할 수 있다.
- 하나의 이미지·첨부물은 여러 기록의 근거나 표현 자원이 될 수 있다.
- 파일 이동·분할·병합·복구는 저장 배치를 바꾸지만, 사용자가 보존하려는 대상·기록·주장의 동일성까지 바꾸어서는 안 된다.

따라서 파일 경로는 Vault 상의 위치이고, Record/Entity/Assertion ID는 장기 의미 식별자라는 구분을 유지한다.

## 현재 계약에 migration 없이 적용하는 규칙

- Markdown Vault를 SSOT로 유지하고 v3와 기존 Work·Entity·Journal·Timeline·Canvas 파일을 재작성하지 않는다.
- P0의 unknown YAML 무손실 보존을 계속 적용한다. 향후 도구가 기록한 확장 필드는 앱이 이해하지 못해도 보존되어야 한다.
- 기존 `record_id`, `record_kind`, Entity ID, `created_at`, `updated_at`, Timeline의 `occurred_at`, `source`, `evidence`, `external_ids`, `links`를 새 의미론과 호환되는 기존 근거로 읽는다.
- wiki link/일반 Reference/기존 structured link를 Assertion으로 역해석하거나 자동 승격하지 않는다.
- Canvas의 `layout.json`을 Record serializer 대상으로 편입하지 않는다.

## 아직 결정하지 않는 항목

- Document에 독립적·안정적 Document ID가 필요한지와 한 Document에 여러 Record를 어떻게 주소화할지
- `derived_from`, 입력 revision, 모델·프롬프트·도구·사용자 승인 등 provenance의 정확한 형태와 공개 범위
- Relationship Assertion의 저장 위치, ID, 검증, conflict 처리, relation vocabulary의 확장 권한
- archive, tombstone, supersede, merge, retract를 Record와 Assertion에 어떻게 적용할지
- Artifact의 안정 ID, 내용 해시, MIME, 저작권/접근 권한, 대용량 외부 보관 방식
- Work·Journal·Timeline의 현재 고유 필드를 어느 수준까지 공통 검색·표현할지

## 결과와 후속 순서

이 ADR은 지금 일반 모델을 만들지 말아야 할 근거이기도 하다. 공통 envelope는 유지하되, 각 도메인 모델의 고유 의미를 평탄화하지 않는다. 이후 ADR은 아래 순서로 진행한다.

1. provenance — 원본, 가져오기, 저자/agent, 파생, evidence, 입력 revision
2. relation tiers — Reference/structured link/Relationship Assertion의 승격·저장·검증 경계
3. lifecycle — archive, tombstone, supersede, merge, retract와 복구·동기화 의미
4. extension namespace — 알 수 없는 확장 필드와 도구별 namespace의 충돌 없는 공존 규칙

각 ADR의 결론이 쌓인 뒤에만 범용 Record 모델 또는 additive 계약을 검토한다.
