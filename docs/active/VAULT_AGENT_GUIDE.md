# Vault Agent Guide — Sanctum `.md` SSOT

> **지위:** 볼트 내 파일·에이전트·외부 편집기용 **운영 SSOT**  
> **갱신:** 2026-07-03
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
├── works/{subtype}/             # workJournal (신규 경로, 설정 시)
├── {manga|animation|…}/         # workJournal (legacy, v1 기본)
├── entities/{type}/             # entityJournal
├── timeline/                    # timelineEntry
├── journal/                     # freeformJournal
└── .akasha/
    ├── entity_path_index.json   # entity_id → 상대 경로
    ├── link_index.json
    └── event_ledger.jsonl
```

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
| 불변 | `entity_id`, `work_id` |
| Work 포스터 | `poster:` (상대 `posters/…` 또는 URL) |
| Entity 포스터 | `poster_path:` |
| Work 슬롯 | `# 📝 메모`, `# 🎬 명대사` 등 — [sanctum-md-customization.md](../history/product/sanctum-md-customization.md) |

### Entity journal 예시

```yaml
---
entity_type: person
entity_id: "pe_u_abc12345"
record_kind: entityJournal
title: "나츠키 스바루"
added_at: "2026-06-19T12:00:00.000Z"
tags: []
---

본문
```

### Work journal 예시

```yaml
---
work_id: "wk_000012345"
entity_type: work
entity_id: "wk_000012345"
record_kind: workJournal
title: "작품명"
category: manga
added_at: "2026-06-19T12:00:00.000Z"
---

# 📝 메모
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

| 타입 | prefix | 예 |
|------|--------|-----|
| work (global) | `wk_` + 9자리 | `wk_000012345` |
| work (user local) | `wk_u_` | `wk_u_a1b2c3d4` |
| person | `pe_u_` | `pe_u_x9y8z7w6` |
| concept | `co_u_` | |
| event | `ev_u_` | |
| place | `pl_u_` | |
| organization | `or_u_` | |

상세: [ADR-011](../history/adr/ADR-011-entity-type-subtype.md)

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-24 | 초판 — VAULT_README 자동 생성 · entity_path_index · 에이전트 SSOT |
| 2026-06-30 | [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) 링크 |
