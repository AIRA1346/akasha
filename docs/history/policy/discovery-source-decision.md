# Discovery 소스 결정 — 요약

> **법무 SSOT:** [policy/discovery-legal-baseline.md](policy/discovery-legal-baseline.md) — **코드·ToS 직접 검토 (2026-06-10 확정)**  
> **운영:** [programs/catalog-growth-charter.md](programs/catalog-growth-charter.md)

---

## 확정 스택 (법무 리스크 최소)

| 순위 | 경로 |
|:----:|------|
| 1 | **수동 PR / Maintainer Fact** |
| 2 | **Wikidata CC0 Facts** (Q-id·title·year·creator) — UA·rate limit·대량은 덤프 |
| 3 | **Open Library 월간 덤프** (예정) |
| ❌ | AniList·MAL·트래커 API bulk · description·이미지·raw JSON Git |

상세 근거·코드 감사·운영 수치: **legal-baseline 문서만** 본다.

---

## 구현 포인터

| 항목 | 경로 |
|------|------|
| **Wikidata spine 전략** | [strategy/wikidata-spine-plan.md](strategy/wikidata-spine-plan.md) |
| Manifest | `akasha-db/pipeline/discovery/manifest.json` |
| Wikidata | `tool/discovery/wikidata_client.dart` |
| Gate | `tool/discovery/signal_gate.dart` |
