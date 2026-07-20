# Sanctum `.md` 작품 페이지 커스터마이징

> **상태:** v1 P0~P3 ✅ · P2 watch ✅ (2026-06-14) · P4 block 확장 예정  
> **북극성:** [ultimate-archiving-vision.md](ultimate-archiving-vision.md) · `product-vision.md` §5 (당시 문서 · 현재 파일 없음 · 후계: [VISION.md](../../active/VISION.md))

---

## 1. 목표

유저 Sanctum vault의 `.md`로 **작품 상세 페이지를 꾸미되**, 앱 메타(별점·상태·포스터)와 공존한다.

**편집은 AKASHA 앱 안에서 완결** — 찾기 → 아카이빙 → 감상 기록까지 외부 Obsidian에 의존하지 않는다. (같은 볼트를 외부에서 열어도 되지만 필수 아님)

| 계층 | 역할 | 예 |
|------|------|-----|
| **YAML** | 앱이 읽는 구조화 메타 | `rating`, `status`, `poster` |
| **슬롯 섹션** | 앱 Quick edit ↔ md 동기화 | `# 📋 시놉시스`, `# 🎬 명대사`, `# 📝 메모` |
| **커스텀 섹션** | 유저 자유 작성·렌더만 | `# 🎵 OST`, 표, 이미지, 링크 |

---

## 2. 데이터 모델

```dart
AkashaItem.bodyRaw  // frontmatter 이후 마크다운 원문 (커스텀 섹션 보존)
```

- `description` / `memorableQuotes` / `review` — 슬롯 필드 (필터·Quick edit)
- `bodyRaw` — round-trip SSOT; 앱 저장 시 슬롯만 merge, 나머지 유지

---

## 3. 파이프라인

```
deserialize(md)
  → YAML → AkashaItem 메타
  → bodyRaw 저장
  → 슬롯 헤딩에서 필드 추출

serialize(item)
  → MarkdownBodyMerger.mergeBody(bodyRaw, slots)
  → YAML + merged body

상세 UI (워크벤치 4열)
  → SanctumPagePanel: 보기 | 본문 편집 | .md 파일 편집
  → VaultMarkdownBody(mergeBody(...))  ← 미리보기
  → 3열 md 저장 → vault 기록
```

---

## 4. 구현 단계

| Phase | 내용 | 상태 |
|-------|------|:----:|
| **P0** | `bodyRaw` + `MarkdownBodyMerger` round-trip | ✅ |
| **P1** | `VaultMarkdownBody` 상세 렌더 (이미지·링크) | ✅ |
| **P2** | 볼트 watch → 상세 live reload (폴링 보조) | ✅ |
| **P3** | 4열 본문·`.md` 파일 in-app 편집 | ✅ |
| **P4** | `::: block` 확장·layout YAML | ⏳ |

---

## 5. 슬롯 헤딩 규칙

| 슬롯 | 인식 키워드 (헤딩 `# …` 내) |
|------|---------------------------|
| 시놉시스 | `시놉`, `synopsis` |
| 명대사 | `명대사`, `명장면`, `quote` |
| 메모 | `📝`, `메모`, `memo`, `감상문`, `review` (단, `OST 메모` 등 커스텀 제목은 제외) |

슬롯이 파일에 없고 앱 필드만 채워져 있으면 저장 시 표준 헤딩으로 **append**.

---

## 6. 에셋 경로

| md 내 경로 | 해석 |
|------------|------|
| `posters/foo.jpg` | `{vault}/posters/foo.jpg` |
| `attachments/bar.png` | `{vault}/attachments/bar.png` |
| `https://…` | 네트워크 (User-Agent 헤더) |
| 절대 경로 (존재 시) | 로컬 파일 |

볼트 밖 경로는 렌더하지 않음.

---

## 7. 샘플

```markdown
---
work_id: "wk_frieren"
title: "장송의 프리렌"
rating: 5
status: "전부 봄"
poster: "posters/frieren.jpg"
---

# 📋 시놉시스
엘프 마법사 프리렌의 여행.

# 🎬 명장면 & 명대사
> "슬로우 라이프가 좋아."

# 🎵 OST 메모
- 1기 OP: **YOASOBI**

# 📝 메모
2기 기대 중.
```

`# 🎵 OST 메모`는 커스텀 섹션 — 앱 저장 후에도 유지되고 Sanctum 페이지에 렌더된다.
