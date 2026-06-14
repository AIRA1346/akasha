# ADR-007: App Layering and Architecture Guardrails

* **상태:** 승인 (Accepted)  
* **날짜:** 2026-06-13  
* **상위 계획:** [app-architecture-refactor-plan.md](../programs/app-architecture-refactor-plan.md)  
* **관련:** [data-architecture-redesign.md](../strategy/data-architecture-redesign.md) · [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md)

---

## 1. 맥락 (Context)

AKASHA v1 Steam 출시 준비 과정에서 `home_screen.dart`가 1,385줄의 거대 개체(God Object)로 성장하여 UI, 로컬 파일 I/O(Sanctum vault), 글로벌 작품 사전(WorksRegistry), 그리고 스팀웍스 API 호출의 비즈니스 로직들이 복잡하게 얽히는 결합도(D1) 문제가 발생했습니다.

특히 궁극적인 목표인 **「엔티티-저널(Entity-Journal) 아카이빙 모델」** (객관적 실체인 작품/인물/사건을 닻으로 삼고, 주관적 생각/장면/기억은 일기 형식 본문으로 서술)을 지탱하고, 사용자가 축적한 추억과 기록들을 **「시각적으로 예쁘게 감상하는 뷰(Timeline, Album, Carousel 등)」**를 기존 코드 훼손 없이 유연하게 교체 및 확장하기 위해서는 **레이어 경계를 강제하고 비즈니스 로직을 UI로부터 완벽하게 단절시키는 아키텍처적 가드레일**이 즉시 필요합니다.

> **제품 SSOT:** [ultimate-archiving-vision.md](../product/ultimate-archiving-vision.md) — Entity Archive(Phase 1) + Timeline(장기)

---

## 2. 아키텍처 결정 (Decision)

앱의 논리적 레이어를 아래 **4대 계층**으로 엄격히 분리하고, 의존성 방향은 오직 상단에서 하단으로만 흐르는 **단방향 의존성 규칙**을 정의합니다.

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Presentation  │  Thin Widgets, Screens, Dialogs (≤ 200줄)     │
└────────┬────────────────────────────────────────────────────────┘
         │ (호출)
┌────────▼────────────────────────────────────────────────────────┐
│ 2. Application   │  Coordinators, Use-cases, State Holders      │
└────────┬────────────────────────────────────────────────────────┘
         │ (의존/구독)
┌────────▼────────────────────────────────────────────────────────┐
│ 3. Domain        │  Pure Models (AkashaItem 등), Policy, Enums    │
└────────┬────────────────────────────────────────────────────────┘
         │ (DIP 구현)
┌────────▼────────────────────────────────────────────────────────┐
│ 4. Data          │  Port Interfaces & Adapters, API Clients     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.1 계층별 역할 및 가드레일

1. **Presentation (표현 계층)**:
   * **역할**: 사용자 화면 렌더링, 이벤트 감지, 입력 수집.
   * **제약**: 비즈니스 로직(예: 파일 쓰기 트랜잭션, 데이터 동기화 루프)을 직접 수행할 수 없습니다. 오직 **Application 계층(Coordinator)**의 메소드를 호출하거나 상태를 구독하기만 합니다.
   * **한계선**: 단일 위젯 및 다이얼로그 파일은 **200줄**, 스크린 단위 쉘은 **250줄**을 초과할 수 없습니다.

2. **Application (응용 계층)**:
   * **역할**: 행동(Use-case) 조율, 화면 독립적인 상태 홀더.
   * **제약**: UI 구성 요소(BuildContext, MediaQuery, Theme 등)에 직접 의존하거나 `import 'package:flutter/material.dart'`를 갖는 것을 엄격히 지양합니다.
   * **가드레일**: 하나의 클래스는 원칙적으로 하나의 오케스트레이션(예: `HomeMembershipCoordinator`)만 담당하며, 파일은 **150줄**을 초과할 수 없습니다.

3. **Domain (도메인 계층)**:
   * **역할**: 비즈니스 엔티티 모델(`AkashaItem`, `RegistryWork`), 핵심 도메인 규칙 및 에러 정의.
   * **제약**: 외부 I/O 패키지(`path_provider`, `shared_preferences`) 또는 Flutter UI Framework 패키지를 절대로 import 할 수 없는 **순수 Dart 패키지**여야 합니다.

4. **Data (데이터 계층)**:
   * **역할**: 데이터 영속성 처리, 네트워크 통신, 외부 API 어댑팅.
   * **제약**: `WorksRegistry` 또는 `AkashaFileService` 같은 무거운 싱글톤/스태틱 전역 객체들을 **Port 인터페이스 뒤에 숨겨 캡슐화**합니다.
   * **한계선**: 데이터 어댑터 파일은 **400줄**을 초과할 수 없습니다.

---

## 3. 포트와 어댑터 (Port-Adapter) 격리 규칙

미래의 AI 에이전트 연동 및 파일 스토리지 교체(예: SQLite 캐시 도입)에 대비하여, 데이터 통신 경계에 Port 인터페이스를 두어 의존성을 역전(DIP)시킵니다.

```
[Application: Coordinator] ──► [Domain: Port Interface (Abstract)]
                                          ▲
                                          │ (DIP 구현)
                               [Data: Adapter / Client]
```

* **인터페이스 선언**: `core/ports/` 폴더에 추상 클래스(Interface)를 배치합니다.
  ```dart
  abstract class VaultPort {
    Future<List<AkashaItem>> loadAll();
    Future<void> save(AkashaItem item);
  }
  ```
* **생성자 주입**: Coordinator는 데이터 어댑터의 실물 싱글톤을 직접 레퍼런스하지 않고, 생성자를 통해 주입(DI)받아 사용함으로써 유닛 테스트 시 모의 어댑터(`fake_vault_port.dart`) 주입을 용이하게 합니다.

---

## 4. 실행 효과 및 리팩토링 DoD (Definition of Done)

* **결합도 완화**: `home_screen.dart`는 얇은 화면 분할 쉘로 변모하여, 화면 내 코드 분석의 피로도를 대폭 낮춥니다.
* **유닛 테스트 용이성**: 파일 I/O를 모킹하기 위해 복잡한 환경 셋업을 요구하지 않고, 순수 메모리 가짜 포트(`FakeVaultPort`)만으로 비즈니스 시나리오를 0.1초 만에 테스트할 수 있습니다.
* **2단계 아카이빙 확장 확보**: Wikidata API 수집기와 로컬 마크다운 저장 구조가 Port 뒤로 완전히 숨어, 만화/애니 외에 인물/성우 등의 새 카테고리 도메인을 추가할 때 UI 코드가 다치지 않습니다.
