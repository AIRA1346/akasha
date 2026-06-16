# Sprint B — Friction Log

> **시작:** 2026-06-15 (@5181 · C2 ✅)  
> **SSOT:** [phase1-work-e2e-plan.md](phase1-work-e2e-plan.md) Sprint B  
> **빌드:** `build\windows\x64\runner\Release\akasha.exe` (eager-only @5181)

---

## B1 세션 체크리스트 (작품 1건 이상)

각 세션마다 ①~④를 **한 작품** 기준으로 끝까지 밟는다.

| # | 단계 | 확인 | 메모 |
|:-:|------|:----:|------|
| 1 | **① 발견** — 검색 또는 browse에서 작품 찾기 | ✅ | 대시보드 browse·느림 friction 기록 |
| 2 | **② 아카이브** — `.md` 생성 (수동 또는 auto-archive) | ✅ | |
| 3 | **③ 기록** — 워크벤치 저장 · 감상/인용 입력 | ✅ | |
| 4 | **④ 큐레이션** — 나만의 서재·라이브러리 멤버십 확인 | ✅ | 글로벌 854→1700 표시 이슈 별도 |

### 글로벌 사전 (대시보드) friction

| 일자 | friction | 심각도 | 조치 |
|------|----------|:------:|------|
| 2026-06-15 | 초기 로딩 느림 · `48/5181`과 실제 표시 수(854→1700) 불일치 | annoying | v1.1 표시 수 정합 |
| 2026-06-15 | 매체(만화·애니) 하위 접기 없음 | annoying | ✅ 카테고리 접기 구현 |
| 2026-06-15 | 대시보드에 감상 예정 보관함 — 글로벌 탐색과 역할 겹침 | annoying | ✅ 대시보드 숨김 |
| 2026-06-15 | 대시보드 스크롤바 thumb·휠 불안정 | annoying | ✅ sliver grid (`c28a5dd`) |

### @5181 특이 시나리오 (eager-only)

| 시나리오 | 기대 | 확인 |
|----------|------|:----:|
| 오프라인 cold start | eager 53 shard + search_index 로드 | ✅ | 2026-06-15 dogfood |
| 온라인 browse `더 불러오기` | CDN shard on-demand | ✅ | 2026-06-15 dogfood |
| franchise IP 카드 | 멤버 매체 칩 정상 | ✅ | 2026-06-15 dogfood |
| 매체(만화·애니) 접기 | 대시보드 하위 섹션 | ✅ | |
| 대시보드 watchlist 숨김 | 카탈로그·연도별만 | ✅ | |

---

## B2 Friction 기록

**규칙:** 체감 불편만 적는다. 확인·재현 후에만 코드 수정 ([phase1 §2](phase1-work-e2e-plan.md)).

| 일자 | 단계 | friction | 재현 | 심각도 | 조치 |
|------|------|----------|------|:------:|------|
| 2026-06-15 | ① 발견 | 대시보드 스크롤바 thumb 불일치 · 휠 튐 | ✅ | annoying | ✅ sliver grid (`c28a5dd`) |

심각도: `blocker` · `annoying` · `nit`

---

## B3 출시 품질 (원할 때)

[phase1-work-e2e-plan §9](phase1-work-e2e-plan.md) — 본인 Ready 시 M3.

| # | 질문 | 판단 |
|:-:|------|:----:|
| Q1 | ①~④ 매끄러운가? | |
| Q2 | 2주+ 실사용? | |
| Q3 | 남은 friction 출시 가능 수준? | |
| Q4 | 5181 · 검색 체감 OK? | ✅ |
| Q5 | 스토어 스크린샷 = 현재 앱? | — (보류) |
