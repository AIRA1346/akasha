# ADR-001: Dual-layer Entity Model (Work + Franchise)

| 항목 | 내용 |
|------|------|
| **상태** | **승인** (2026-06-08) |
| **범위** | Universal Works Registry 전체 |
| **선행** | `data-architecture-redesign.md` (당시 선행 문서 · 현재 문서: [ARCHITECTURE.md](../../active/ARCHITECTURE.md)) v4 |

---

## 맥락

AKASHA 장기 목표는 **인류의 모든 작품** 레지스트리이다.  
제품은 IP 1카드 그리드를 약속하고, 저장은 v4 `wk_` 불변 ID에 의존한다.

## 결정

**Dual-layer**를 채택한다.

| 계층 | 엔티티 | 역할 |
|------|--------|------|
| **저장 원자** | **Work** (`wk_`) | shard · search_index · 볼트 · dedupe survivor |
| **문화적 정체성** | **Franchise** (`franchise_*`) | IP 1카드 · `displayNames` · 다매체 묶음 |

- 볼트·Contribution·`retire_work_ids`는 **Work**를 가리킨다.
- 홈 그리드 1카드·IP 검색의 기본 대상은 **Franchise**이다.
- Work-only UI 회귀는 하지 않는다.

## 결과

- ADR-002~004는 Dual-layer 위에서 매체별·출처별 규칙을 정의한다.
- Franchise 독립 ID (`fr_`) 도입 여부는 별도 ADR로 연기한다.
