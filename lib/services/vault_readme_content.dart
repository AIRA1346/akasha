/// `VAULT_README.md` 본문 — repo [VAULT_AGENT_GUIDE.md]와 동기화.
abstract final class VaultReadmeContent {
  static String build({required String generatedAtIso}) => '''
# AKASHA Sanctum Vault

> AKASHA가 볼트 연결 시 자동 생성·갱신합니다. 개인 메모는 `NOTES.md`를 사용하세요.  
> 상세 SSOT: AKASHA 저장소 `docs/active/VAULT_AGENT_GUIDE.md`  
> 생성: $generatedAtIso

---

## 디렉터리

```
{vault}/
├── catalog/user_entities.json   # ID·제목 인덱스 (앱 배관 — .md와 entity_id 동기화 유지)
├── posters/                     # 이미지 (본문에서 posters/… 상대경로)
├── works/{subtype}/             # 작품 journal (신규 경로, 설정 시)
├── {manga|animation|…}/         # 작품 journal (legacy 기본)
├── entities/
│   ├── person/
│   ├── event/
│   ├── concept/
│   ├── place/
│   ├── organization/
│   └── custom/
├── timeline/                    # record_kind: timelineEntry
├── journal/                     # record_kind: freeformJournal
└── .akasha/                     # 앱 인덱스 (직접 편집 비권장)
    ├── entity_path_index.json   # entity_id → 상대 경로
    ├── link_index.json
    └── event_ledger.jsonl
```

---

## Record 종류

| record_kind | 경로 | 비고 |
|-------------|------|------|
| `workJournal` | `{subtype}/` 또는 `works/{subtype}/` | `work_id` · `entity_id` 동일 권장 |
| `entityJournal` | `entities/{entity_type}/` | person · concept · event … |
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
- **`entity_id` / `work_id` 변경 금지** — 불변 닻(anchor)
- Work 포스터 필드: `poster:` · Entity: `poster_path:` (상대경로 `posters/…`)
- 본문은 자유 Markdown. Work는 `# 📝 메모`, `# 🎬 명대사` 등 슬롯 헤딩 사용 가능

### Entity journal 최소 예시

```yaml
---
entity_type: person
entity_id: "pe_u_abc12345"
record_kind: entityJournal
title: "표시 제목"
added_at: "2026-06-19T12:00:00.000Z"
tags: []
---

본문
```

### Work journal 최소 예시

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

## 건드리지 말 것

| 경로 | 이유 |
|------|------|
| `.akasha/` | 링크·경로 인덱스 — 앱이 재구축 |
| `catalog/user_entities.json` | `.md` 저장 후 앱이 동기화 |

**제품 SSOT = `.md` Record.** 에이전트는 `.md`를 편집하고 ID는 유지하세요.
''';
}
