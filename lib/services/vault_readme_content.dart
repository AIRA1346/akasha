/// `VAULT_README.md` 본문 — repo [VAULT_AGENT_GUIDE.md]와 동기화.
abstract final class VaultReadmeContent {
  static String build({required String generatedAtIso}) =>
      '''
# AKASHA Sanctum Vault

> AKASHA가 볼트 연결 시 자동 생성·갱신합니다. 개인 메모는 `NOTES.md`를 사용하세요.  
> **형식 명세 (이 볼트에 동봉): `.akasha/spec/spec_v3.md`** — 필드·시간·관계 규칙의 기준  
> 상세 가이드: AKASHA 저장소 `docs/active/VAULT_AGENT_GUIDE.md`  
> 생성: $generatedAtIso

---

## 디렉터리

```
{vault}/
├── catalog/user_entities.json   # ID·제목 인덱스 (앱 배관 — .md와 entity_id 동기화 유지)
├── posters/                     # 이미지 (본문에서 posters/… 상대경로)
├── works/{category}/{wk_id}.md  # 작품 journal (v3 canonical 경로)
├── works/{category}/            # 작품 journal (v3 폴더 레이아웃)
├── {manga|animation|…}/         # 작품 journal (legacy 기본)
├── entities/
│   ├── person/
│   ├── event/
│   ├── concept/
│   ├── place/
│   ├── organization/
│   └── object/                  # record_kind: entityJournal (custom 대체)
├── timeline/                    # record_kind: timelineEntry
├── journal/                     # record_kind: freeformJournal
├── .trash/                      # 삭제 기록 격리 보관 (복구 안전핀)
└── .akasha/                     # 앱 인덱스 (직접 편집 비권장)
    ├── spec/spec_v3.md          # 형식 명세 동봉 사본 (Self-Describing Vault)
    ├── entity_path_index.json   # entity_id → 상대 경로
    ├── record_index.json        # record 요약 지도 (id/title/tags/path)
    ├── link_index.json
    └── event_ledger.jsonl
```

---

## Record 종류

| record_kind | 경로 | 비고 |
|-------------|------|------|
| workJournal | works/{category}/ 또는 {category}/ | `works/{category}/{wk_id}.md` 형태로 생성 |
| entityJournal | entities/{entity_type}/ | person · concept · event · object … |
| `timelineEntry` | `timeline/` | |
| `freeformJournal` | `journal/` | |

---

## 파일 찾기

1. **ID가 있을 때 (권장)** — frontmatter 검색:
   ```bash
   rg 'entity_id: "pe_u_……"' entities/
   rg 'work_id: "wk_……"' .
   ```
2. **인덱스** — `.akasha/entity_path_index.json` → `paths["entity_id"]`
3. **제목만** — `entities/person/{제목}.md` (특수문자 `\\ / : * ? " < > |` → `_`)
4. **catalog** — `catalog/user_entities.json` → `entityId`, `title`, `entityType`

---

## 편집 규칙

- UTF-8 Markdown + YAML frontmatter (`---` … `---`)
- **`entity_id` / `work_id` / `record_id` 변경 금지** — 불변 닻(anchor)
- **`source` / `created_at` 변경 금지** — 기록 주체의 증거. 에이전트가 새 파일을 만들면 `source: "agent"`
- 시스템 시각(`created_at`·`updated_at`·`added_at`)은 UTC `Z` · 경험 시각(`occurred_at`)은 타임존 없는 wall-clock (명세 §2.2–2.3)
- `links[].relation`은 관계 어휘(명세 §4.1)만: 핵심 8종 또는 `u:` 네임스페이스
- Work 포스터 필드: `poster:` · Entity: `poster_path:` (상대경로 `posters/…`)
- 본문은 자유 Markdown. Work는 `# 📝 메모`, `# 🎬 명대사` 등 슬롯 헤딩 사용 가능

### Entity journal 최소 예시

```yaml
---
schema_version: 3
record_id: "rec_pe_u_abc12345"
entity_type: person
entity_id: "pe_u_abc12345"
record_kind: entityJournal
title: "표시 제목"
added_at: "2026-06-19T12:00:00.000Z"
created_at: "2026-06-19T12:00:00.000Z"
updated_at: "2026-06-19T12:00:00.000Z"
source: "user"
tags: []
---

본문
```

### Work journal 최소 예시

```yaml
---
schema_version: 3
record_id: "rec_wk_000012345"
entity_type: work
entity_id: "wk_000012345"
record_kind: workJournal
title: "작품명"
category: manga
added_at: "2026-06-19T12:00:00.000Z"
created_at: "2026-06-19T12:00:00.000Z"
updated_at: "2026-06-19T12:00:00.000Z"
source: "user"
---

# 📝 메모
```

---

## 건드리지 말 것

| 경로 | 이유 |
|------|------|
| `system/` | 서재·컬렉션·운영 로그 — **삭제 금지** (복구 불가) |
| `.akasha/` | 링크·경로 인덱스 — 앱이 재구축 (삭제해도 안전, 재생성 가능) |
| `.trash/` | 사용자 삭제 기록 격리 보관 — 앱 복구 경로 |
| `catalog/user_entities.json` | `.md` 저장 후 앱이 동기화 |

**제품 SSOT = `.md` Record.** 에이전트는 `.md`를 편집하고 ID는 유지하세요.
''';
}
