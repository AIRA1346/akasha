# AKASHA Constitution (프로젝트 헌법) — historical

> **Status:** historical — superseded on 2026-07-12
> **Current supreme SSOT:** [AKASHA Archive Constitution](../active/AKASHA_ARCHIVE_CONSTITUTION.md)
> **Active stub:** [docs/active/PROJECT_CONSTITUTION.md](closure-2026-07/PROJECT_CONSTITUTION_STUB.md)
> **원 지위 (폐기):** 프로젝트 최상위 헌법  
> **원 갱신:** 2026-07-03

이 문서는 읽기 전용 역사 기록이다. 원칙·거부 기준·기능 결정 필터는 더 이상 이 파일을 따르지 않는다.

---

## 1. 프로젝트 목표
> **세상의 모든 작품과 그 관계를 기록하고 탐색할 수 있는 지식 그래프 기반 문화 아카이브**

AKASHA는 단순한 독서 기록 앱, 노트 앱, 위키 클론, 혹은 오타쿠 DB가 아닙니다.  
작품에서 시작하여 인물, 사건, 장소, 개념으로 확장 및 연결되는 **문화 지식 그래프(Cultural Knowledge Graph) 기반의 개인 지식 우주(Personal Knowledge Universe)** 구축을 최종 목표로 합니다.

2026-07-03 기준 보정: AKASHA는 AI 서비스, 플레이어, 도구 오케스트레이터가 아니라 **궁극의 개인 아카이브 기반층**입니다. 외부 AI/도구는 AKASHA의 vault와 index를 읽고 agent write 계약으로 기록을 도울 수 있지만, AKASHA의 핵심 가치는 AI 없이도 사용자가 오래 보존하고 이해할 수 있는 아카이브입니다. 실행 계획은 [INFINITE_ARCHIVE_HARDENING_PLAN.md](../active/INFINITE_ARCHIVE_HARDENING_PLAN.md)를 따릅니다.

---

## 2. 핵심 엔티티 (Core Entities)
AKASHA가 기록하고 연결하는 5대 핵심 개념입니다:
- **Work (작품):** 지식 우주의 진입점이 되는 창작물
- **Person (인물):** 작가, 성우, 캐릭터, 실존/가상 인물
- **Event (사건):** 역사적 사건, 작품 내 타임라인 사건, 현실의 릴리즈
- **Place (장소):** 배경지, 실제 장소, 세계관 내의 가상 공간
- **Concept (개념):** 장르, 속성, 세부 설정, 고유 주제

---

## 3. 핵심 원칙 (Core Principles)

### Ⅰ. Entity ≠ Record
* **Entity(독립체)**는 식별 가능한 사실(Fact)의 핵심 닻(Anchor)입니다.
* **Record(기록)**는 사용자가 남긴 감상, 별점, 일기, 메모(`.md`)입니다.
* 시스템은 Fact 데이터와 개인의 기록을 엄격히 구분하여 관리합니다.

### Ⅱ. 검색 품질 > 성능 (Search Quality Over Performance)
* 사용자가 작품과 관계를 발견하고 연결하기 위해서는 정확한 검색 품질이 최우선입니다.
* 극단적인 성능 최적화나 인프라 캐싱보다 검색 결과의 신뢰도(Recall 및 Precision)가 언제나 우선합니다.

### Ⅲ. 기능 추가의 기준
모든 기능은 다음 4가지 핵심 가치 중 하나 이상을 개선해야 합니다:
1. **작품 발견 (Discovery)**
2. **기록 (Archive)**
3. **연결 (Link)**
4. **탐색 (Explore)**

---

## 4. 기능 감사 필터 (Feature Decision Filter)
새로운 기능을 제안하거나 개발할 때는 항상 다음 세 가지 질문을 던져야 합니다:

> [!IMPORTANT]
> 1. 이 기능이 **기록(Archive)**을 강화하는가?
> 2. 이 기능이 **연결(Link)**을 강화하는가?
> 3. 이 기능이 **발견(Discovery)**을 강화하는가?

**이 중 단 하나도 만족시키지 못하거나 답변할 수 없다면, 해당 기능은 구현하지 않습니다.**  
단순한 UI 미세 튜닝이나 부가 애니메이션 등은 우선순위의 가장 하단(나중)으로 밀려납니다.
