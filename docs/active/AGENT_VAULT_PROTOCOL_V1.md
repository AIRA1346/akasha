# Agent Vault Protocol v1

> **2026-07-11 status correction:** This document's direct-file agent write
> workflow is retained only for external-editor compatibility and historical
> dogfood. It is no longer AKASHA's recommended AI integration path. New AI
> candidate/application work follows
> [AI_ARCHIVE_WRITE_GATEWAY_ADR.md](AI_ARCHIVE_WRITE_GATEWAY_ADR.md).

> **지위:** Steam v1 **Agent ↔ Sanctum vault** 상호작용 SSOT
> **갱신:** 2026-07-06 (형식 명세 v3 동기화)
> **형식 명세:** [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md) — 필드·시간·관계 규칙은 명세가 최상위 기준 (볼트 내 `.akasha/spec/spec_v3.md` 동봉)
> **Git:** code/test baseline **7be7b51b** · current tip은 `git log -1` 기준
> **상위:** [VISION.md](VISION.md) · [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) · [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md)
> **구현 참고:** `AkashaFileService` watch · `TimelineEntryParser` · `EntityVaultStore` (제품 코드 — 본 문서는 **파일 프로토콜 계약**)

---

## 1. 목적 · v1 핵심 루프

AKASHA v1의 제품 핵심은 **글로벌 catalog가 아니라 Personal Sanctum vault**이다.

```
사용자 대화 / 직접 작성
  → Agent(또는 앱)가 vault .md / YAML에 기록
  → Flutter UI가 볼트를 읽어 예쁘게 표시
  → 사용자·Agent가 같은 파일을 안전하게 편집
```

**Agent Vault Protocol v1**은 외부 에이전트(Cursor·CLI·자동화)가 위 루프에 **안전하게 참여**하기 위한 **파일 기반** 읽기·쓰기·금지·충돌 규칙이다. v1 검증은 **수동·Agent dogfood**(§8)로 수행한다.

이 문서는 v1의 파일 프로토콜 계약이다. 대량 agent write, batch import, structured operation layer, taste/index 확장은 [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md)의 post-v1 hardening 범위로 다룬다.

| 구분 | v1 | post-v1 |
|------|:--:|:-------:|
| **파일 프로토콜** (vault `.md` 읽기·단일 Record 편집) | ✅ | — |
| **manual / Agent dogfood** (§8 체크리스트) | ✅ | 자동화 회귀 |
| create / update / append / tag / rating / status / link (파일 단위) | ✅ | — |
| 충돌 감지·백업·diff 확인 | ✅ (프로토콜) | 자동 merge 고도화 |
| **Agent SDK · HTTP API · 자동 operation layer** | ❌ | 검토·구현 |
| catalog 대량 변경 · registry · akasha-db | ❌ | optional automation |
| Entity 파일 rename · 경로 일괄 이동 | ❌ | R2-C path guard 연동 |
| Collection / Library **앱 설정** 직접 쓰기 | ❌ | 전용 API 또는 vault-side manifest |
| Steam 무료 출시 | — | 앱 내 구매/Agent operation layer와 분리 |

---

## 2. Agent가 읽을 수 있는 vault 범위

### 2.1 In scope (읽기 허용)

| 경로 | 용도 |
|------|------|
| `{vault}/**/*.md` | workJournal · entityJournal · timeline · journal Record |
| `{vault}/posters/**` | Work 포스터 이미지 (바이너리 참조만; 내용 분석은 Agent 재량) |
| `{vault}/catalog/user_entities.json` | Tier 1.5 ID·제목 인덱스 (**읽기 전용** — mirror) |
| `{vault}/.akasha/spec/spec_v3.md` | **형식 명세 동봉 사본** — 필드·시간·관계 규칙 (읽기 전용) |
| `{vault}/.akasha/entity_path_index.json` | entity_id → 상대 경로 (**읽기 전용**) |
| `{vault}/.akasha/record_index.json` | record 요약 지도 (**읽기 전용**) |
| `{vault}/.akasha/link_index.json` | `[[링크]]` 인덱스 (**읽기 전용**) |
| `{vault}/VAULT_README.md` | 볼트 현장 요약 (앱 자동 생성) |

### 2.2 Out of scope (읽기 불필요 · v1 Agent가 건드리지 않음)

| 경로 | 이유 |
|------|------|
| repo `assets/registry/**` · `akasha-db/**` | 글로벌 catalog — **optional**, vault 밖 |
| `{vault}/.akasha/event_ledger.jsonl` | 앱 내부 감사 — 재구축 가능 |
| 숨김·스킵 디렉터리 | `.git` · `.obsidian` · `.cursor` · `.trash` 등 — [file_service.dart](../../lib/services/file_service.dart) `_skipDirNames` |

### 2.3 Record 종류

[vault-layout-v2.md](../history/product/vault-layout-v2.md) · [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) §3과 동일:

| `record_kind` | 대표 경로 | 식별 키 |
|---------------|-----------|---------|
| `workJournal` | `{subtype}/` 또는 `works/{subtype}/` | `work_id`, `entity_id` |
| `entityJournal` | `entities/{type}/` | `entity_id`, `entity_type` |
| `timelineEntry` | `timeline/` | `occurred_at` — **신규 저장은 `timelineEntry`**; legacy `timeline` parse 호환 |
| `freeformJournal` | `journal/` | (선택) |

---

## 3. Agent가 편집 가능한 필드

### 3.1 불변 (Agent가 변경 금지)

| 필드 | 이유 |
|------|------|
| `entity_id` | Record 닻 — [user-local-catalog-policy.md](../history/policy/user-local-catalog-policy.md) |
| `work_id` | Work 조인 키 |
| `record_id` | Record 식별자 (v3) |
| `record_kind` | 파서·라우팅 |
| `entity_type` (entityJournal) | 스키마 |
| `category` (workJournal) | taxonomy — 변경 시 앱 혼란 |
| `schema_version` | 형식 버전 선언 (v3) |
| `created_at` · `source` · `source_operation_id` | **provenance** — 기록 주체·생성 시각의 증거. 기존 파일에서 절대 수정 금지 |

### 3.1a 출처(source) 규약

- 에이전트가 **create**하는 모든 파일: `source: "agent"` 기록 (enum: `user` · `app` · `agent` · `importTool` · `script`).
- 기존 파일 **편집** 시: `source`는 최초 생성 주체를 나타내므로 그대로 두고, `updated_at`만 UTC `Z`로 갱신한다.
- 이 규약이 "사용자가 직접 쓴 기억"과 "도구가 대신 쓴 기억"의 구분을 보존한다.

### 3.1b 시간 규약 (명세 §2.2–2.3)

| 필드 | 의미 | 형식 |
|------|------|------|
| `created_at` · `updated_at` · `added_at` | 기계가 파일을 쓴 물리 순간 | **UTC ISO-8601 `Z` 필수** |
| `occurred_at` (timeline) | 사용자가 **경험한** 시각 | **타임존 없는 wall-clock** (`"2026-07-05T22:30:00.000"`) — `Z`·offset 금지. 사용자의 말("어제 밤 10시")을 그 숫자 그대로 기록, UTC 변환 금지 |

### 3.2 frontmatter — 편집 허용 (v1)

**Work journal (`workJournal`)**

| 필드 | operation | 비고 |
|------|-----------|------|
| `title` | update | 파일명 rename은 **v1 Agent 금지** — 앱 rename API 사용 |
| `rating` | update | 숫자 |
| `status` / `my_status` | update | 작품 상태 · 나의 상태 라벨 |
| `poster` | update | `posters/…` 상대 경로 또는 URL |
| `tags` | tag | YAML list — append·dedupe |
| `added_at` | update | ISO-8601 — 신규 create 시 설정 |
| 커스텀 키 | append/update | 앱이 보존; unknown key 삭제 금지 |

**Entity journal (`entityJournal`)**

| 필드 | operation | 비고 |
|------|-----------|------|
| `title` | update | rename 금지 (§3.1) |
| `tags` | tag | |
| `poster_path` | update | Entity 포스터 |
| `added_at` | update | |

**Timeline / freeform journal**

| 필드 | operation |
|------|-----------|
| `title`, `occurred_at`, `tags` | update / tag |
| 본문 | append / update |

### 3.3 Markdown 본문 — 편집 허용

| 영역 | operation | 규칙 |
|------|-----------|------|
| 슬롯 섹션 | update / append | `# 📝 메모` · `# 🎬 명대사` · `# 📋 시놉시스` — [sanctum-md-customization.md](../history/product/sanctum-md-customization.md) |
| 커스텀 섹션 | append / update | `# 🎵 OST` 등 자유 — **삭제 금지** (비우기만 허용) |
| Wiki 링크 | link | `[[entity_id\|표시]]` · `[[work_id]]` — [link-identity-policy.md](../history/policy/link-identity-policy.md) |
| 구조화 링크 relation | link | **관계 어휘 준수** (명세 §4.1): 핵심 8종(`related`·`about`·`appears_in`·`created_by`·`part_of`·`member_of`·`located_in`·`inspired_by`) 또는 `u:` 네임스페이스만. 미지 문자열 신규 쓰기 금지, 기존 값 보존 |
| 이미지 | append | `posters/` · `attachments/` 상대 경로 권장 |

**원칙:** 앱은 `bodyRaw` round-trip — Agent는 슬롯 **추가·갱신** 우선, 기존 커스텀 블록 **보존**.

---

## 4. 금지 작업 (v1 Agent MUST NOT)

| # | 금지 | 대안 |
|---|------|------|
| F1 | **임의 파일 삭제** (`.md` · `posters/` · catalog) | 본문 비우기 · `tags: []` · 앱 UI에서 제거 |
| F2 | **경로 변경** — rename · move · 다른 subtype 폴더로 이동 | `title` frontmatter만 수정; rename은 앱 |
| F3 | **registry / akasha-db / repo manifest** 수정 | catalog는 optional; vault만 편집 |
| F3a | **registry manifest 4파일** (커밋·Agent 편집 모두 제외) | `assets/registry/manifest.json` · `assets/registry/search_index/manifest.json` · `akasha-db/manifest.json` · `akasha-db/search_index/manifest.json` |
| F4 | **`catalog/user_entities.json` 직접 쓰기** | `.md` 저장 후 앱이 mirror |
| F5 | **`.akasha/*` 인덱스 직접 편집** | 앱 재스캔·재빌드에 맡김 |
| F6 | **대량 catalog 삽입** (수백 work 일괄 생성) | v1은 **사용자 대화 단위** create |
| F7 | **Personal Library / Collection 앱 state** 직접 변경 | UI 또는 향후 vault-side 설정 API |
| F8 | **`entity_id` / `work_id` 재발급·교체** | 새 Record는 create operation |

---

## 5. 편집 operation 단위 (v1 API 계약)

Agent·자동화는 아래 **단위 operation**으로만 쓰기를 표현한다. v1은 **파일 프로토콜 + dogfood**; SDK·자동 operation layer는 post-v1.

| operation | 설명 | 대상 예 |
|-----------|------|---------|
| **create** | 새 `.md` + frontmatter + 최소 본문 | 사용자 대화로 신규 작품·인물 기록 |
| **update** | frontmatter 필드 또는 슬롯 섹션 **전체 교체** | `rating: 4` · 시놉시스 갱신 |
| **append** | 본문·슬롯 **끝에 추가** | 감상 한 단락 · 명대사 한 줄 |
| **tag** | `tags` list에 **dedupe append** | `#재미있음` |
| **rating** | `rating` 숫자 set | `5` |
| **status** | `status` / `my_status` set | `전부 봄` · `감상 중` |
| **link** | 본문에 `[[…]]` 추가 | 인물·작품 연결 |

**순서 권장:** `create` → `tag` / `rating` / `status` → `append` → `link`.

**create 시 필수 (v3 계약):**

- UTF-8 · `---` YAML frontmatter + Markdown 본문
- `schema_version: 3` · `record_id` (`rec_{entity_id}` — journal 계열) · `record_kind`
- `created_at` / `updated_at` / `added_at` = UTC `Z` · `source: "agent"` (§3.1a–3.1b)
- 불변 ID 발급 규칙 준수 (`wk_u_*` · `pe_u_*` · `ob_u_*` 등 7종 — [ADR-011](../history/adr/ADR-011-entity-type-subtype.md), 명세 §3. 신규 `cu_` 발급 금지)
- 경로 규칙: **ID 경로 canonical** (`works/{category}/{wk_id}.md` · `entities/{type}/{entity_id}.md`) — [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) §2–3
- 완전한 v3 예시: [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) §5

---

## 6. 충돌 처리

### 6.1 사용자 수정 감지

Flutter 앱은 볼트 변경을 다음으로 감지한다:

- 디렉터리 **watch** (`.md` · `.akasha_*.tmp`)
- **fingerprint** 폴링 (path · mtime · size)
- debounce **~400ms** 후 UI reload

Agent는 저장 직전·직후 **동일 파일 mtime**을 확인하거나, 앱이 열린 상태에서는 **짧은 간격 연속 write**를 피한다.

### 6.2 백업 (v1 프로토콜 — Agent 책임)

구현 전 **Agent 측 필수 관행:**

1. 편집 전 `{path}.agent-bak` 또는 타임스탬프 suffix 복사
2. **atomic write:** 임시 파일 → rename (앱과 동일 — `.akasha_{µs}_{name}.tmp`)
3. 실패 시 bak에서 복원

앱은 v1에서 Agent bak을 자동 관리하지 않음.

### 6.3 diff 기반 확인

| 상황 | v1 기대 동작 |
|------|----------------|
| Agent write 후 사용자가 앱에서 미저장 편집 중 | Agent **재시도 전** diff 확인 · 사용자에게 요약 |
| 동일 path 다른 `entity_id` | `EntityVaultPathConflict` — **쓰기 중단** · [entity_vault_path_conflict.dart](../../lib/services/entity_vault_path_conflict.dart) |
| frontmatter vs catalog title 불일치 | **frontmatter + journal wins** — [user-local-catalog-policy.md](../history/policy/user-local-catalog-policy.md) |

**v1 Agent 출력:** 변경 요약(어떤 필드·몇 줄 append)을 사용자에게 보여 준 뒤 저장.

### 6.4 post-v1 (범위 밖)

- 앱 내 Agent 세션 lock
- 3-way merge UI
- 실시간 collaborative editing

---

## 7. Flutter watcher가 기대하는 저장 형식

Agent 저장은 **앱 native save**와 동일 형식을 따른다.

| 항목 | 요구 |
|------|------|
| 인코딩 | UTF-8 |
| 구조 | YAML frontmatter (`---` … `---`) + Markdown 본문 |
| 줄바꿈 | OS 기본 허용; 일관된 `\n` 권장 |
| atomic write | temp `.akasha_*.tmp` → rename (§6.2) |
| flush | 디스크 flush 후 rename |
| watch 트리거 | `.md` 최종 경로에 rename 완료 |
| 스킵 | `VAULT_README.md` · dot-dir · `posters/` 내부 `.md` 없음 |

**파싱:** `MarkdownParser.deserialize` / `serialize` — 슬롯 merge 시 `bodyRaw` 보존.

**리로드:** 저장 후 앱은 vault fingerprint 갱신 → 그리드·워크벤치 **자동 reload** (사용자 Ctrl+S 불필요).

---

## 8. Dogfood 체크리스트 (사용자 직접 · Agent v1)

**전제:** `dogfood_precheck` green · 볼트 연결 · Release 또는 dev 빌드.
**금지:** registry manifest 수정 · M3 출시 착수.

| ID | 시나리오 | Pass 기준 |
|----|----------|-----------|
| A1 | **대화만으로** 신규 Work `create` | vault에 `.md` 생성 · 앱 그리드/서재에 표시 |
| A2 | 대화로 감상 **append** | 본문 `# 📝 메모` 또는 슬롯에 반영 · UI 미리보기 일치 |
| A3 | **rating** / **status** update | frontmatter 반영 · 3열 작품정보 동기화 |
| A4 | **tag** append | `tags:` YAML · 앱에서 표시 |
| A5 | **link** append | `[[pe_u_…\|이름]]` · wiki 칩·연결 패널 인식 |
| A6 | Agent 편집 → 앱 **watch reload** | 앱 재시작 없이 워크벤치 내용 갱신 |
| A7 | 앱 편집 → Agent **read** | Agent가 최신 본문·frontmatter 읽기 |
| A8 | 충돌 시 **bak + diff 확인** | 덮어쓰기 없이 사용자 확인 후 저장 |
| A9 | Collection / Library | **앱 UI**로 반영 확인 (Agent 직접 쓰기 아님) |
| A10 | 금지 준수 | F1–F8 위반 없음 (삭제·경로·registry·대량 catalog 없음) |

결과 기록: [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md) §3.4 (Agent 루프).

---

## 9. v1 vs post-v1 요약

| 영역 | v1 | post-v1 |
|------|----|---------|
| **범위** | 파일 프로토콜 + manual/Agent dogfood | SDK · HTTP API · 자동 operation layer |
| vault read | 전 Record | + ledger 분석 |
| vault write | 단일 Record operation (파일) | batch · 템플릿 · API |
| conflict | bak · diff · 사용자 확인 | merge UI · lock |
| catalog / akasha-db | 읽기만 · optional search | scale track · automation |
| Discovery / Wikidata | 앱 기능 유지 · **메시지 비핵심** | spine 확장 |
| Steam release | 무료 출시 진행 | Agent operation layer는 post-launch |

---

## 10. 관련 문서

| 문서 | 역할 |
|------|------|
| [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md) | 경로·ID·예시 (현장 레시피) |
| [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) | agent operation · index · taste signal · ID path hardening |
| [sanctum-md-customization.md](../history/product/sanctum-md-customization.md) | 슬롯·bodyRaw |
| [VISION.md](VISION.md) | v1 Personal Archive 북극성 |
| [PROJECT_STATUS.md](PROJECT_STATUS.md) | v1 blocking · M3 보류 |
| [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md) | 수동 dogfood SSOT |

---

## 11. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-30 | v1 초안 — 읽기/쓰기 범위 · operation · 충돌 · watcher · dogfood · post-v1 분리 |
| 2026-07-03 | Infinite Archive Hardening 연결 — v1 파일 프로토콜과 post-v1 structured operation layer 경계 명시 |
| 2026-06-30 | scope 정리 — v1 = 파일 프로토콜 + dogfood · post-v1 = SDK/API/operation layer · `timelineEntry` canonical |
| 2026-07-06 | **형식 명세 v3 동기화** — 불변 필드에 provenance 추가 · source 규약 §3.1a · 시간 규약 §3.1b · 관계 어휘 · create v3 계약 · `.akasha/spec` 읽기 범위 |
