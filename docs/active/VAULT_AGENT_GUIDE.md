# Vault Agent Guide — Sanctum `.md` SSOT

> **지위:** 볼트 내 파일·에이전트·외부 편집기용 **운영 SSOT**  
> **갱신:** 2026-07-06
> **형식 명세:** [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) — 필드·타입·시간·관계 규칙의 **최상위 기준** (볼트 내 `.akasha/spec/spec_v3.md` 동봉)
> **볼트 현장:** `{vault}/VAULT_README.md` (앱이 볼트 연결 시 자동 생성)
> **프로토콜:** [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) — 읽기·쓰기 범위 · operation · 충돌 · dogfood (v1 계약)
> **상위:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [vault-layout-v2.md](../history/product/vault-layout-v2.md) · [user-local-catalog-policy.md](../history/policy/user-local-catalog-policy.md) · [entity-record-storage-masterplan.md](../history/programs/entity-record-storage-masterplan.md)

---

## 1. 한 줄

**제품 SSOT = Tier 2 `.md` Record.** `entity_id` / `work_id`는 불변 닻. 에이전트는 `.md`를 편집하고 ID는 바꾸지 않는다.

---

## 2. 디렉터리

```
{vault}/
├── VAULT_README.md              # 이 문서 요약 (앱 자동 생성)
├── catalog/user_entities.json   # Tier 1.5 ID·제목 인덱스 (배관)
├── posters/
├── works/{category}/{wk_id}.md  # workJournal (v3 canonical — ID 경로)
├── {manga|animation|…}/         # workJournal (legacy 제목 경로 — 읽기 호환)
├── entities/{type}/{id}.md      # entityJournal (v3 canonical — ID 경로)
├── timeline/                    # timelineEntry
├── journal/                     # freeformJournal
└── .akasha/
    ├── spec/spec_v3.md          # 형식 명세 동봉 사본 (Self-Describing Vault)
    ├── entity_path_index.json   # entity_id → 상대 경로
    ├── record_index.json        # record 요약 지도
    ├── link_index.json
    └── event_ledger.jsonl
```

신규 파일은 **ID 경로가 canonical**이다 (`works/movie/wk_u_abc12345.md`). 기존 제목 경로 파일은 읽기 호환으로 유지되며 에이전트가 이동·rename하지 않는다.

---

## 3. Record 종류 · 경로

| `record_kind` | 경로 | frontmatter 키 |
|---------------|------|----------------|
| `workJournal` | `{subtype}/` 또는 `works/{subtype}/` | `work_id`, `entity_id`, `category` |
| `entityJournal` | `entities/{entity_type}/` | `entity_id`, `entity_type` |
| `timelineEntry` | `timeline/` | `occurred_at` |
| `freeformJournal` | `journal/` | (entity 없음 가능) |

---

## 4. 파일 찾기 (에이전트 레시피)

### 4.1 ID로 찾기 (권장)

```bash
rg 'entity_id: "pe_u_……"' {vault}/entities/
rg 'work_id: "wk_……"' {vault}/
```

### 4.2 인덱스

`{vault}/.akasha/entity_path_index.json`:

```json
{
  "version": 1,
  "paths": {
    "pe_u_abc12345": "entities/person/표시제목.md"
  }
}
```

### 4.3 제목으로 추정

`entities/{entity_type}/{safeTitle}.md` — `\ / : * ? " < > |` → `_`

### 4.4 catalog

`catalog/user_entities.json` → `entities[].entityId`, `title`, `entityType`  
(`.md` 없는 catalog-only 항목 있음)

---

## 5. 편집 규칙

| 규칙 | 내용 |
|------|------|
| 인코딩 | UTF-8 |
| 형식 | YAML frontmatter (`---`) + Markdown 본문 |
| 불변 | `entity_id`, `work_id`, `record_id`, `record_kind`, `entity_type`, `schema_version` |
| 출처 (규약) | **에이전트가 create하는 파일은 `source: "agent"`** — §5.1 |
| 시스템 시각 | `created_at`·`updated_at`·`added_at` = UTC ISO-8601 (`Z` 필수) |
| 경험 시각 | `occurred_at` = **타임존 없는 wall-clock** (`Z`·offset 금지) — 명세 §2.3 |
| Work 포스터 | `poster:` (상대 `posters/…` 또는 URL) |
| Entity 포스터 | `poster_path:` |
| Work 슬롯 | `# 📝 메모`, `# 🎬 명대사` 등 — [sanctum-md-customization.md](../history/product/sanctum-md-customization.md) |

### 5.1 출처(source) 규약

`source`는 이 Record를 처음 만든 주체다: `user` · `app` · `agent` · `importTool` · `script`.

- 에이전트가 **create**하는 파일: `source: "agent"` 기록.
- 기존 파일 **편집** 시: `source`·`created_at`·`source_operation_id`는 **변경 금지** (앱 소유 provenance). `updated_at`만 갱신 가능.
- 이 구분은 미래의 AI가 "사용자가 직접 쓴 기억"과 "도구가 대신 쓴 기억"을 구별하는 근거다.

### 5.2 시간 규약 (명세 §2.2–2.3)

- `created_at` / `updated_at` / `added_at`: 기계가 파일을 쓴 물리 순간 — **UTC `Z`**.
- `occurred_at` (timeline): 사용자가 **경험한** 시각 — 타임존 없는 wall-clock (`"2026-07-05T22:30:00.000"`). 사용자가 "7월 5일 밤 10시"라고 말하면 그 숫자 그대로 기록한다. UTC로 변환하지 않는다.

### Entity journal 예시 (v3)

```yaml
---
schema_version: 3
record_kind: entityJournal
record_id: "rec_pe_u_abc12345"
entity_type: person
entity_id: "pe_u_abc12345"
title: "나츠키 스바루"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
added_at: "2026-07-06T12:00:00.000Z"
source: "agent"
aliases: []
tags: []
---

본문
```

### Work journal 예시 (v3)

```yaml
---
schema_version: 3
record_kind: workJournal
record_id: "rec_wk_000012345"
work_id: "wk_000012345"
entity_type: work
entity_id: "wk_000012345"
title: "작품명"
category: manga
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
added_at: "2026-07-06T12:00:00.000Z"
source: "agent"
---

# 📝 메모
```

### 5.3 연결 (관계 어휘 — 명세 §4.1)

본문 wiki 링크는 `[[entity_id|표시]]`. frontmatter `links[].relation`은 **통제 어휘**만 사용:

- 핵심 8종: `related`(기본) · `about` · `appears_in` · `created_by` · `part_of` · `member_of` · `located_in` · `inspired_by`
- 유저 정의: `u:` 네임스페이스 필수 (`u:voiced_by`, 토큰 `[a-z0-9_]{1,40}`)
- 이 밖의 relation 문자열을 **새로 쓰지 않는다.** 기존 파일의 미지 relation은 보존.

```yaml
links:
  - relation: "appears_in"
    target_id: "wk_u_xyz98765"
    target_title: "Re:Zero"
```

---

## 6. 건드리지 말 것

| 경로 | 이유 |
|------|------|
| `.akasha/` | 앱 인덱스·ledger — 재구축 가능 |
| `catalog/user_entities.json` | `.md` 저장 후 앱이 catalog mirror |

개인 메모는 볼트 루트 `NOTES.md` 사용 (`VAULT_README.md`는 앱이 갱신).

---

## 7. ID 체계 (요약)

상위 타입 7종 (명세 §3) — 이 밖의 타입 신설 금지:

| 타입 | prefix | 예 |
|------|--------|-----|
| work (global) | `wk_` + 9자리 | `wk_000012345` |
| work (user local) | `wk_u_` | `wk_u_a1b2c3d4` |
| person | `pe_u_` | `pe_u_x9y8z7w6` |
| event | `ev_u_` | |
| place | `pl_u_` | |
| concept | `co_u_` | |
| organization | `or_u_` | |
| object (물건) | `ob_u_` | |

- legacy `cu_` ID는 object로 읽는다. **신규 `cu_` 발급 금지.**
- user local 토큰은 소문자 영숫자 8자 (`[a-z0-9]{8}`).
- 하위 분류는 `entity_subtype`에 `u:` 네임스페이스로 (`u:pet`, `u:camera`).

상세: [ADR-011](../history/adr/ADR-011-entity-type-subtype.md) · [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) §3

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-24 | 초판 — VAULT_README 자동 생성 · entity_path_index · 에이전트 SSOT |
| 2026-06-30 | [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) 링크 |
| 2026-07-06 | **명세 v3 동기화** — v3 예시(schema_version·record_id·created_at) · source 규약 §5.1 · 시간 규약 §5.2 · 관계 어휘 §5.3 · object 타입 · ID 경로 canonical |
