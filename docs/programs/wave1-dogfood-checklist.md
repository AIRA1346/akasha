# Wave 1 Dogfood Checklist

> **목적:** Wave 1 Exit Gate · Wave 2 착수 전 실사용 검증  
> **갱신:** 2026-06-19  
> **상위:** [wave1-exit-review.md](wave1-exit-review.md)

---

## 환경

| 항목 | 값 |
|------|-----|
| 빌드 | `build\windows\x64\runner\Release\akasha.exe` |
| 커밋 | `d4f8503` |
| 볼트 | (테스트용 빈 폴더 또는 기존 Sanctum) |
| 네트워크 | (온/오프라인 각각 optional) |

---

## 시나리오 A — 직접 추가 → Fusion hit

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| A1 | 볼트 **미연결** → Fusion → 「직접 추가」 | SnackBar 「볼트 연결」 | ☐ | |
| A2 | 볼트 연결 | vault `catalog/` 생성 | ☐ | |
| A3 | Fusion → 「직접 추가」 → 제목 입력 · 저장 | `wk_u_*` · `.md` 생성 | ☐ | |
| A4 | Fusion 재검색 (동일 제목) | 「📋 내 catalog」 hit | ☐ | |
| A5 | catalog hit 탭 | 워크벤치 열림 | ☐ | |
| A6 | `catalog/user_entities.json` 확인 | entityId = workId | ☐ | |

---

## 시나리오 B — 글로벌 사전 작품 (회귀)

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| B1 | Fusion 검색 (akasha-db 작품) | 「🌐 글로벌 사전」 hit | ☐ | |
| B2 | Browse 그리드 | catalog-only **미표시** | ☐ | |
| B3 | 글로벌 작품 아카이브 | legacy `{category}/` path | ☐ | |

---

## 시나리오 C — Legacy 호환

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| C1 | 기존 `sub_*` `.md` 볼트 | loadAllItems 정상 | ☐ | |
| C2 | 저장 시 workId **유지** | custom → wk_u 덮어쓰기 ❌ | ☐ | |

---

## Friction log

| ID | 심각 | 관찰 | Wave 이관 |
|----|:----:|------|-----------|
| F1 | | | |
| F2 | | | |

---

## Exit

- [ ] A1~A6 Pass
- [ ] B1~B3 Pass
- [ ] C1~C2 Pass
- [ ] Friction 0건 **또는** wave2 spec / hotfix 티켓 생성

**실행일:** ___________ · **실행자:** ___________
