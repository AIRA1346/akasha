# Agent Vault Loop — Work Journal Vertical Slice

> **지위:** Agent Vault dogfood **A1~A6** Work journal 최소 사이클 기록
> **갱신:** 2026-06-30
> **상위:** [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md) · [SPRINT_B1_DOGFOOD.md](SPRINT_B1_DOGFOOD.md) §3.4

---

## 1. 목표

사용자 감상(대화·작성) → Agent가 vault `.md` 수정 → Flutter UI에 **예쁘게** 반영되는 **Work journal 1사이클** 검증.

| ID | operation | 이번 slice |
|----|-----------|:----------:|
| A1 | create | ✅ |
| A2 | append memo | ✅ |
| A3 | rating / status | ✅ |
| A4 | tag | ✅ |
| A5 | link | — (범위 밖) |
| A6 | watch reload | ✅ (앱 watch 기존 동작) |

**범위 밖:** Entity · Timeline · Collection Agent 편집 · registry manifest · catalog 대량 변경.

---

## 2. Fixture (테스트·재현용)

| 파일 | 단계 |
|------|------|
| [test/fixtures/vault_agent_slice_create.md](../../test/fixtures/vault_agent_slice_create.md) | A1 create — rating 0 · 태그 없음 · 짧은 메모 |
| [test/fixtures/vault_agent_slice_full.md](../../test/fixtures/vault_agent_slice_full.md) | A2~A4 반영 — rating 4.5 · status · tags · 긴 메모 |

경로 예: `{vault}/animation/Agent Slice 테스트 애니.md` (또는 `works/animation/`)

---

## 3. Agent operation 시나리오

### A1 — create

1. 사용자: 「○○ 애니 봤어, 기록해줘」
2. Agent: `wk_u_agnt0001` 발급 · frontmatter + `# 📝 메모` 최소 본문
3. Pass: 앱 그리드·서재·프리뷰에 작품 표시

### A2 — append memo

1. 사용자: 「2화부터 몰입됐고 엔딩이 좋았어」
2. Agent: `# 📝 메모` 슬롯 **append** (기존 줄 보존)
3. Pass: Sanctum **감상 카드**·Home 프리뷰 **내 감상**에 본문 반영

### A3 — rating / status

1. Agent: `rating: 4.5` · `status` / `my_status: "전부 봄"`
2. Pass: 포스터 카드·프리뷰 핵심 정보·**내 감상** 메타 행

### A4 — tag append

1. Agent: `tags: ["재미있음", "감동"]` dedupe append
2. Pass: 프리뷰 **내 감상** 태그 칩 · Workbench 태그

### A6 — watch reload

1. 앱 워크벤치·Sanctum 열린 상태에서 Agent가 atomic save
2. Pass: ~400ms 내 미리보기·본문 reload (재시작 불필요)

---

## 4. UI/UX 확인 포인트 (이번 slice 반영)

| 화면 | 확인 |
|------|------|
| **Home 프리뷰** | `PreviewJournalReflectionCard` — 평점·상태·태그·메모 발췌 |
| **Browse 그리드** | 포스터 카드 rating·status pill |
| **Workbench Sanctum** | `# 📝 메모` → `SanctumMemoCard` 카드 스타일 |
| **빈/최소 기록** | 평가 없음·빈 메모 안내 문구 (어색하지 않게) |
| **긴 메모** | 줄간격·카드 패딩·180자 발췌 (프리뷰) |

---

## 5. 수동 dogfood 체크리스트

**UI/UX 리뷰 (코드·fixture 기준):** [AGENT_VAULT_UI_DOGFOOD_REVIEW.md](../draft/AGENT_VAULT_UI_DOGFOOD_REVIEW.md) §7

| # | 항목 | Pass |
|---|------|:----:|
| 1 | Fixture create → 앱 표시 | ☐ |
| 2 | append 후 Sanctum·프리뷰 일치 | ☐ |
| 3 | rating/status UI | ☐ |
| 4 | tags 칩 | ☐ |
| 5 | Agent 저장 → watch reload | ☐ |
| 6 | registry manifest 미수정 | ☐ |

---

## 6. 자동 검증 (CI)

```powershell
.\scripts\flutter.ps1 test test/journal_reflection_preview_test.dart
.\scripts\flutter.ps1 test test/preview_journal_reflection_card_test.dart
.\scripts\flutter.ps1 test test/sanctum_preview_body_test.dart
.\scripts\flutter.ps1 test test/agent_vault_slice_fixture_test.dart
```

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-30 | Work journal vertical slice · fixture · UI 감상 카드 |
