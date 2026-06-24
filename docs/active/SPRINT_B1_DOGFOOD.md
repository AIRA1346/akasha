# Sprint B1 — Dogfood

> **지위:** Sprint B 품질 다듬기의 **실사용 검증 SSOT**  
> **갱신:** 2026-06-24  
> **상위:** [PROJECT_STATUS.md](PROJECT_STATUS.md) · [release-readiness-checklist](../history/release-readiness-checklist.md)  
> **UX 참고:** [R14_UI_UX_AUDIT.md](../draft/R14_UI_UX_AUDIT.md) (Engine/Preview stack 변경 금지)

---

## 1. 목표

Release 빌드에서 **볼트 연결 → 검색·담기 → Work/Entity `.md` 편집·저장 → 연결 탐색** 루프를 실제 데이터로 반복하며 마찰(friction)을 수집한다. P0 회귀는 즉시 수정, P1은 백로그에 기록한다.

**금지 (B1):** Discovery Engine · Link/Search Index · Registry 스키마 · Preview stack / Save Return 정책 변경.

---

## 2. 자동 사전 검증

수동 dogfood **전에** 아래를 green으로 만든다.

```powershell
.\scripts\dogfood_precheck.ps1
# Release exe까지 확인할 때:
.\scripts\dogfood_precheck.ps1 -Build
```

| 단계 | 도구 | Pass 기준 |
|------|------|-----------|
| 1 | `flutter test` | 0 fail (**596**) |
| 2 | `ci_registry_check` | exit 0 (@10048) |
| 3 | `preflight_check` | 4 step OK |
| 4 | `sw1_a_validation` | recall@10 baseline |
| 5 | `quality_gate --release` | RB1·RB2 PASS |
| 6 (선택) | `build_release.ps1` | `akasha.exe` cold start |

추가 권장 (주간): `quality_gate --locale-minimum` · `flutter analyze lib/` (0 error).

### B1 자동 검증 로그

| 일자 | test | gates | build | 메모 |
|------|:----:|:-----:|:-----:|------|
| 2026-06-25 | **596** | ✅ 전부 PASS | analyze 0 issue | sw1_a 87/87 · quality_gate --release OK |

---

## 3. 수동 시나리오 (Release 빌드)

**환경:** 깨끗한 Windows · 볼트 미연결로 시작 · `build\windows\x64\runner\Release\akasha.exe`

### 3.1 P0 회귀 (release-readiness §3)

| ID | 시나리오 | B1 재확인 |
|----|----------|:---------:|
| Q01 | 첫 실행 CDN sync | ☐ |
| Q02 | 볼트 연동 → `.md` 생성 | ☐ |
| Q03 | 검색 → 담기 (md auto) | ☐ |
| Q04 | 우클릭 popover (ArchiveThenAdd 없음) | ☐ |
| Q05 | 카드 우클릭 메뉴 | ☐ |
| Q06 | DnD-A md 없음 | ☐ |
| Q07 | Case D IP tristate | ☐ |
| Q08 | E9 멤버 관리 | ☐ |
| Q09 | 외부 `.md` watch | ☐ |
| Q10 | IAP 테마 잠금 UI | ☐ |
| Q11 | v1 제외 UI 숨김 | ☐ |
| Q12 | 오프라인 번들 검색 | ☐ |

### 3.2 B1 핵심 루프 (신규·지속)

| # | 루프 | 관찰 포인트 |
|---|------|-------------|
| D1 | Registry 검색 → 프리뷰 → 워크벤치 열기 | Preview stack 복귀·닫기 (`onCloseAllPreviews`) |
| D2 | Work `.md` 본문·frontmatter 편집 → 저장 (Ctrl+S) | 저장 피드백·vault disk sync |
| D3 | Entity 추가·저장 → 연결 패널에서 이웃 탐색 | incoming/sameDay·link pick |
| D4 | Personal library 필터·테마 피커 | curated reorder·IAP 잠금 |
| D5 | 최근 탐색에서 이전 항목 복귀 | `HomeRecentExplorationCoordinator` |
| D6 | 볼트 설정·registry sync 다이얼로그 | sync 상태·auto-archive |

---

## 4. 마찰 기록 템플릿

| ID | 우선 | 화면 | 재현 | 기대 | 실제 | 조치 |
|----|:----:|------|------|------|------|------|
| F-001 | P1 | 탐색 필터 | domain 칩 혼란 | category만 | **제거됨** (DOMAIN Phase 1–2) | ✅ |

**R14에서 우선 관찰할 영역 (수정은 P1 unless P0):**

- Preview 320px 정보 밀도·계층
- Workbench 진입 시 컨텍스트 유지
- surface hex / spacing 불일치 (design token 부재)

---

## 5. 완료 기준

| 항목 | 기준 |
|------|------|
| 자동 | `dogfood_precheck.ps1` PASS (+ 주 1회 `-Build`) |
| P0 QA | §3.1 **12/12** Release 빌드 재확인 |
| B1 루프 | §3.2 **D1~D6** 각 1회 이상 무중단 |
| 마찰 | P0 즉시 수정 · P1 3건 이상이면 R14 백로그에 반영 |

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-24 | Sprint B1 dogfood SSOT 신규 |
