# P1-A Core Archive Ontology 사례 fixture

- 상태: 의미론 검증용 사례. 제품 fixture, 모델, serializer, migration은 아님.
- 기준 ADR: [ADR-014](../history/adr/ADR-014-core-archive-ontology.md)
- 목적: 현재 Vault 파일을 읽을 때 물리 저장 단위와 장기 의미 단위를 혼동하지 않도록 하는 회귀 사례다.

## 사례 1 — Work 파일은 대상과 주된 기록을 함께 담는다

`works/<domain>/<slug>.md`에는 안정된 Work ID와 v3 `record_id`가 있고, 제목·상태·평가·본문·포스터 참조가 함께 있을 수 있다.

| 관점 | 분류 |
| --- | --- |
| 작품 자체 | Entity |
| 사용자가 남긴 상태·평가·메모 | 주된 Record |
| Markdown 파일 | Document |
| 포스터 이미지 | Artifact |
| 본문의 `[[다른 작품]]` | Reference / wiki link |

`[[다른 작품]]`이 존재한다고 두 작품 사이의 프랜차이즈·영향·유사성 관계가 사실로 보존된 것은 아니다. 그러한 주장이 근거·주장자·시점과 함께 독립 보존되어야 할 때만 Relationship Assertion이 된다.

## 사례 2 — Journal의 언급은 관계 주장이 아니다

`journals/<date>-<slug>.md`의 `jr_*` Record가 "오늘 A를 보고 B가 떠올랐다"고 적을 수 있다. A와 B는 Entity일 수도 있고 제목만 있는 Reference일 수도 있다.

- Journal Markdown은 Document이고, 그 서술은 특정 시점의 Record다.
- 본문 wiki link는 독자가 A/B를 탐색하도록 돕는 연결이다.
- "A가 B에 영향을 주었다"를 장기 관계로 남기려면 Journal Record를 출처로 하여 별도 Relationship Assertion으로 명시 승격해야 한다.

## 사례 3 — Timeline은 경험 시간과 저장 시간을 분리한다

`timeline/<date>-<slug>.md`의 `tl_*`는 선택적 Entity ID와 `occurred_at`을 가질 수 있다.

| 시간 | 의미 |
| --- | --- |
| `occurred_at` | 경험·사건이 일어난 시각 또는 사용자가 그 의미로 지정한 시각 |
| `created_at` / 기존 `added_at` | Vault에 해당 Record가 생성·수집된 시각 |
| `updated_at` | Vault 표현이 수정된 시각 |

파일을 나중에 편집해도 원래의 경험 시간을 덮어쓰지 않는다. 이 구분은 모든 Record를 하나의 `date` 필드로 평탄화하지 말아야 하는 이유다.

## 사례 4 — AI 파생 해석은 원본을 바꾸지 않는다

사용자가 작성한 Journal Record를 입력으로 AI가 "반복적으로 등장하는 취향"을 해석할 수 있다.

| 대상 | 보존 규칙 |
| --- | --- |
| 사용자 Journal 원본 | 기존 Record와 본문을 그대로 보존 |
| AI 해석 | 별도의 파생 Record로 보존 |
| 두 Record의 연결 | [Provenance ADR](PROVENANCE_AND_DERIVED_INPUT_ADR.md)의 입력 revision·변환·actor 계약으로 보존 |

현재 v3에는 이 연결의 완전한 스키마가 없으므로, 이 사례는 구현 지시가 아니다. 단, 파생 결과를 원본 frontmatter나 본문에 자동 병합하는 것은 이 ADR의 의미론에 맞지 않는다.

## 사례 5 — 외부 가져오기와 사용자의 해석은 다른 Record다

외부 서비스의 후기·메타데이터·내보낸 대화는 원본 표현 또는 Artifact와 함께 가져올 수 있다. 사용자가 그것에 대해 남긴 의견, 또는 AI가 만든 요약은 별도의 Record다.

- 외부 식별자와 원본 출처는 provenance의 일부다.
- 가져온 텍스트가 Document에 붙어 있더라도, 원본 작성자와 AKASHA 사용자의 발화를 하나로 합치지 않는다.
- 같은 외부 원본으로부터 여러 해석·번역·요약이 생겨도 각각의 파생 Record는 공존할 수 있다.

## 사례 6 — Canvas edge는 기본적으로 화면 상태다

Canvas는 `canvas.md`와 `layout.json`의 복합 Document다. `layout.json`의 edge가 A 노드를 B 노드에 연결하고 `relation` 값을 표시할 수 있다.

| 요소 | 기본 분류 |
| --- | --- |
| `canvas.md` | Document의 Markdown 구성 요소 |
| `layout.json` | Document가 참조하는 Artifact / 표현 상태 |
| node 좌표, 색, 표시 여부 | 표현 상태 |
| edge | 탐색·배치 연결 |

사용자가 edge를 이동·숨김·삭제해도 Entity나 Record의 의미를 자동 변경하지 않는다. 사용자가 별도로 관계 보존을 명시하고 출처·대상·어휘·시점·수명주기를 제공했을 때만 edge를 Relationship Assertion으로 승격할 수 있다.

## 사례 7 — 구조화 링크도 아직 독립 관계는 아니다

v3 `links`의 `target`, `relation`, `label`은 Record 내부의 구조화된 연결이다. 예를 들어 Timeline Record에 `relation: appears_in` 링크를 남길 수 있다.

- 현재 링크는 Record의 맥락에서 읽는 탐색·분류 힌트다.
- 링크만으로 누가 그 관계를 주장했는지, 언제 유효한지, 어떤 증거가 있는지, 철회되었는지를 표현할 수 없다.
- 따라서 기존 structured link를 일괄 변환하지 않는다. 미래에 독립 관계가 필요하다고 명시한 경우에만 새로운 Assertion을 추가한다.

## 사례 8 — 파일 이동·휴지통·복구는 의미 객체의 삭제가 아니다

P0의 recoverable write와 Vault trash는 파일을 보존·복구하는 저장 계층의 안전장치다.

- 파일 경로 변경은 Document의 위치 변화이며, Entity/Record ID의 변화가 아니다.
- `.trash` 이동은 현재 물리 삭제 상태이지, "이 Record는 철회되었다"라는 lifecycle Assertion이 아니다.
- 앞으로 tombstone·supersede·merge를 도입하더라도 P0 백업·충돌 보존·unknown YAML 보존을 대체하지 않는다.

## 사례 판정 규칙

새 기능을 검토할 때 다음 질문에 모두 답할 수 있어야 한다.

1. 이것은 지속 대상(Entity), 특정 발화·경험(Record), 사람이 읽는 파일(Document), 부속 바이트(Artifact), 또는 독립 주장(Relationship Assertion) 중 무엇인가?
2. 단순 탐색 링크를 관계 사실로 과해석하고 있지 않은가?
3. 파일의 이동·분할·충돌 복구 후에도 의미 객체의 안정 ID와 provenance가 남는가?
4. AI/외부 파생 결과가 원본을 덮어쓰지 않고 별도의 Record로 공존하는가?
5. Canvas의 표현 상태를 명시적 승격 없이 장기 관계 주장으로 바꾸고 있지 않은가?
