# R3-H Dogfood Validation — R3-A ~ R3-G

> **일자:** 2026-06-22  
> **범위:** R3-A ~ R3-G 구현분 · 새 기능 구현 없음  
> **방법:** 시나리오별 사용 경로 재현(코드·UI 문자열 추적) + widget test + Windows 빌드 기동 확인

---

## 검증 방법 (한계 포함)

| 수단 | 내용 |
|------|------|
| 시나리오 재현 | `home_shell_controller`, Preview 패널, Workbench, Graph 뷰 호출 체인을 단계별로 따라감 |
| 자동 테스트 | `home_dashboard_view_test`, `entity_dashboard_preview_panel_test`, `work_detail_workspace_smoke_test` — **3/3 통과** |
| 앱 기동 | `build\windows\x64\runner\Release\akasha.exe` 실행 확인 |
| GUI 조작 | 에이전트 환경에서 **마우스로 전 시나리오 클릭 재현은 불가** — 관찰은 코드·카피·네비게이션 정책 기준 |

R3-E 이후 **R3-F**(Home·Graph Stack), **R3-G**(저장 후 Preview 복귀) 반영하여 재검증함.

---

## Scenario A — 빈 볼트

**프로필:** 새 볼트 폴더 연동, 로컬 작품 0, 엔티티 0.

### 실제 사용 과정

1. 앱 실행 → 볼트 미연동이면 상단 **노란 배너**: 「데모용 샘플 데이터」+ [폴더 연동]
2. 빈 볼트 연동 후 홈 → 네 섹션 모두 **빈 상태 카피**:
   - 계속 탐험하기: 「탐색 기록 없음」+ [검색으로 탐험 시작]
   - 오늘의 연결: 「[[wiki]] 링크로…」
   - 최근 발견 / 최근 기록: 각각 검색·Sanctum 안내
3. **다음 행동 후보가 4곳** — 검색(하단 중앙·홈 상단·섹션 CTA), 탐색 탭, 폴더 연동, Graph(사이드바)
4. 검색 → 글로벌 카탈로그(10k) → 작품 선택 → **Work Preview** (연결 0 → 빈 연결 CTA 블록)
5. [기록 열고 직접 작성하기] → Workbench — **Preview 사라짐**
6. 본문 작성 → **명시적 저장** → Preview 복귀(R3-G) — **최초 기록 전에는 Preview가 없었으므로 복귀 대상 없음**, Workbench에 머무름

### 막힌 지점

| 지점 | 내용 |
|------|------|
| 로컬 연결 0 | 오늘의 연결·Graph·홈 카드 **클릭할 대상 없음** — 검색/탐색 탭으로만 진입 |
| 첫 기록 전 | R3-G 복귀는 「Preview에서 기록하기로 들어온 경우」만 — cold start는 Workbench 체류 |
| 볼트 없이 커스텀 추가 | 「볼트를 먼저 연결」 스낵 — Preview만으로는 로컬 저장 불가 |

### 불필요한 클릭

- Graph 진입: **사이드바만** — 하단 탭에 없음 (홈 → 사이드바 열기 → 그래프)
- 빈 볼트에서 「탐험」 느낌을 내려면 최소 **홈 → 검색 → 작품 → Preview → Workbench** 4단계

### 혼란스러운 용어

| 표기 | 체감 |
|------|------|
| `[[wiki]]` | 개발자용 — 비개발자는 「링크」만 이해 |
| Sanctum / Vault | 홈 카피·배너에 혼재 |
| 「데모용 샘플」 | 빈 볼트와 **동시에** 이해되기 어려움 |
| Ctrl K (검색창) | **동작 안 함** — Tab만 사이드바 토글 |

### 예상과 다른 동작

- 「빈 볼트」라도 **탐색 탭**은 글로벌 카탈로그 그리드 — 로컬 0과 무관하게 작품이 보임 (탐험 vs 아카이브 구분이 약함)
- Graph 라벨 「그래프」 vs 화면 제목 「지식 연결 맵」 — **리스트 UI** (노드 그래프 아님)

### Scenario A 질문 답

| 질문 | 답 |
|------|-----|
| 첫 행동 명확? | **부분** — CTA는 많으나 **하나로 수렴하지 않음** |
| 어디 눌러야 하는지? | **검색**이 가장 분명, 나머지는 분산 |
| Dead End? | 로컬 연결·기록 **완전 0** 구간은 있음 — 검색 없으면 막힘 |

---

## Scenario B — 일반 사용자 (작품 10~30, 엔티티 5~20, 링크 일부)

**목표 루프:** Home → Preview → Entity Preview → Workbench → 저장 → Preview 복귀 → 연결 탐험

### 실제 사용 과정 (R3-F/G 반영)

| 단계 | 사용자 행동 | 관찰 |
|------|-------------|------|
| 1 | 홈 「계속 탐험하기」 카드 탭 | Work Preview (**replace**, stack `[]`) |
| 2 | Preview 「연결된 인물」 탭 | Entity Preview (**push**, stack `[Work]`) — **`← 이전` 표시** |
| 3 | 「기록하기 >」 | Preview·stack **스냅샷** → Workbench (Sanctum) |
| 4 | md 저장 (버튼/Ctrl+S) | **명시적 저장** → Preview+stack **복귀**, browse 모드 (R3-G) |
| 5 | `← 이전` | Work Preview 복귀 |
| 6 | 이웃 → 다른 Work | **push** — 체인 계속 |
| 7 | 사이드바 「그래프」 | Graph 뷰 — Preview **유지**(Workbench detail 아님) |
| 8 | Graph 「열기」/이웃 | Preview 열린 상태 → **push** (R3-F) |
| 9 | 하단 「홈」 | 홈 대시보드 — Preview **유지** (닫히지 않음) |
| 10 | 홈 다른 카드 | Preview 있음 → **push** (R3-F) |

### 확인 항목

| 항목 | 결과 |
|------|------|
| Preview Stack | ✅ 이웃·홈·Graph 연속 탭 시 push / `← 이전` 동작 |
| Save Return | ✅ Preview 진입 → 명시적 저장 → Preview+stack 복귀 |
| Graph 진입 | ✅ 사이드바 — Preview 병치 유지 |
| Home 진입 | ✅ Preview 유지 — 홈 카드 push |

### 막힌 지점

| 지점 | 내용 |
|------|------|
| **Autosave (2초)** | `silent: true` → Preview **복귀 안 함** — 저장 버튼과 **동작 다름** |
| **나의 서재** 그리드 | Workbench **직행** — Preview·Stack **우회** |
| Graph 「기록 열기」(전체 빈 연결) | 최근 작품 Workbench — Preview 루프 **밖** |
| Workbench 탭 레일 | 저장 후 Preview 복귀해도 **탭은 열린 채** — browse+Preview+탭 **3겹** |

### 불필요한 클릭

- Graph에서 이웃 보려면 작품 행 **펼치기** 1클릭 추가
- Preview → Workbench → 저장 → Preview: **의도된** 흐름이나, 저장 전 Preview가 **한 번 사라지는** 체감 (기록하기 클릭 시)

### 혼란스러운 용어

| 표기 | 체감 |
|------|------|
| 「기록하기 >」 vs 「md 저장」 | Preview는 가볍게, Workbench는 편집기 — **역할 차이는 맞으나 이름 불일치** |
| 「catalog only」 (Entity) | 아카이브 상태 — 일반 사용자에게 불투명 |
| 하단 「탐색」 vs 사이드바 대시보드 | **같은 공간, 다른 진입** |

### 예상과 다른 동작

- **탐색 탭** 그리드에서 포스터 탭 → Preview (OK)
- **검색**에서 Entity 선택 → Preview (OK)
- Preview에서 「연결 맵에서 보기」→ Graph — **Preview 유지** (예상 가능)
- 저장 후 neighbors **자동 갱신**은 Workbench 내부 — Preview 패널은 **복귀 시 FutureBuilder 재로드**로 갱신 (체감상 잠깐 로딩)

---

## Scenario C — 연결 밀집 볼트

**목표 루프:** Work → Entity → Work → Entity → Graph → `← 이전` 체인

### 실제 사용 과정

1. Home/Graph/Preview 이웃으로 **5~8단계** 체인 — stack depth 증가, 매 단계 `← 이전` **1클릭**으로 복귀 가능
2. 중간 「기록하기」→ 저장 → **해당 Preview+stack 복귀** — 체인 **끊기지 않음** (R3-G)
3. Graph: 작품 **연결 N개** 정렬, 펼침 시 neighbors — 탭하면 Preview **push**
4. `← 이전` 연속: Graph에서 추가 push 후 **역순** 복귀 가능

### 확인 항목

| 항목 | 결과 |
|------|------|
| Stack 체인 | ✅ 4~6 depth 코드상 문제 없음 |
| 성능 | ⚠️ Graph `_loadCounts` **전 작품 순회** — 50+ 작품 시 첫 로딩 **수 초** 가능 (체감 지연, UI freeze 아님) |
| 탐험 지속성 | ✅ Stack+Save Return으로 **긴 세션** 가능 |

### 막힌 지점

- Graph 리스트 **스크롤만** — 밀집 볼트에서 「어디부터」가 **연결 수 정렬**에 의존 — 의도는 맞으나 **탐색 fatigue**
- Wiki Sanctum에서 링크 탭 → **새 Preview replace** — stack **초기화** (기록 맥락과 탐험 맥락 충돌)

### 불필요한 클릭

- Graph: 작품마다 **펼치기** + 이웃 탭 — 밀집 환경에서 클릭 수 **누적**

### 혼란스러운 용어

- 「지식 연결 맵」= **아코디언 리스트** — 「맵」 기대와 다름
- incoming 「연결된 Record N개」 vs outgoing 「연결된 작품」 — **방향 개념** UI만으로는 학습 필요

### 예상과 다른 동작

- Preview 패널 **320px 고정** — 밀집 볼트에서 이웃 4섹션 **스크롤 길어짐** — 탐험은 되나 **한 화면에 안 들어옴**
- `RecentExploration` 사이드바와 Preview Stack **별개** — 둘 다 「최근」이지만 **관계 다름**

---

## 공통 — R3-A~G 이후에도 남는 마찰

| 유형 | 관찰 |
|------|------|
| 네비게이션 | 하단 5탭 + 사이드바 — **mental model 분산** |
| Preview 정책 | 탐색/검색=replace, 이웃/홈(Preview中)/Graph=push — **학습 후 자연** |
| 용어 | `[[wiki]]`, Sanctum, Vault, md, catalog only |
| 단축키 | Ctrl+K 표시만, Tab=사이드바 |
| Dead End | 서재 직행, 빈 볼트 로컬 0, autosave 후 Workbench 체류 |

---

## R3-E 대비 변화 (Dogfood 관점)

| R3-E 지적 | R3-H 재검증 |
|-----------|-------------|
| D3 저장 후 Preview 미복귀 | ✅ R3-G로 **해소** (명시적 저장) |
| D4 Home/Graph replace | ✅ R3-F로 **Preview中 push** |
| D1 Ctrl+K | ❌ **여전** |
| D2 서재 Preview 우회 | ❌ **여전** |
| D6 이중 네비 | ❌ **여전** |

**루프 완성도 (Dogfood 추정):**

| 프로필 | R3-E | R3-H |
|--------|------|------|
| 빈 볼트 | 60~65% | **62~68%** |
| 일반 | 82~85% | **88~91%** |
| 밀집 | 88~92% | **90~93%** |
| **이상 경로 (B/C)** | — | **~91%** |

---

## 성공 기준 답변

> 처음 사용하는 사람이 AKASHA를 문화 콘텐츠 관리 앱이 아니라  
> **기록 → 연결 → 발견** 시스템으로 이해할 수 있는가?

**조건부 아니오 (전체), 조건부 예 (안내된 경로).**

| 관점 | 판정 |
|------|------|
| **첫 10분 (cold start)** | **아니오에 가깝다** — 「검색·탐색·서재·컬렉션·볼트」가 먼저 보이고, 기록→연결→발견 **순환 narrative**는 홈 카피에 **분산** |
| **Scenario B 루프 1회 완주 후** | **예에 가깝다** — Preview·Stack·저장 복귀가 **체감상 하나의 탐험** |
| **헌법 4축 전달** | 발견·연결·탐색은 **Preview 중심**으로 전달됨 · **기록**은 Workbench로 **분리** — 통합 narrative는 **사용 후**에야 형성 |

**한 줄:** AKASHA는 R3-G까지 **「탐험가」 루프를 타는 사람**에게는 기록→연결→발견 시스템으로 읽히지만, **처음 열었을 때**는 여전히 **아카이브/탐색 앱**으로 보일 가능성이 크다.

---

## Dogfood 결론

R3-A ~ R3-G는 **Scenario B/C 이상 경로**에서 탐험 루프를 **실질적으로 닫았다.**  
Scenario A와 **앱 전체 첫인상**에서는 Dead End·용어·이중 네비가 **헌법 narrative**를 가린다.

**R4 계획 수립 전 권장:** Scenario B 루프를 **사람이 직접 1회** 클릭 재현(스크린샷·타이밍)하여 본 문서의 코드 기반 관찰을 **교차 검증**.

---

## 부록 — 검증 시 사용한 코드 앵커

| 기능 | 앵커 |
|------|------|
| Stack push/pop | `previewLinked*`, `navigate*Preview`, `popPreview` |
| Save return | `_previewReturnSnapshot`, `_maybeReturnToPreviewAfterSave` |
| Preview 표시 조건 | `!workbench.hasOpenDetail` |
| Home 4섹션 | `home_dashboard_view.dart` |
| Graph | `knowledge_graph_view.dart`, `navigate*Preview` 배선 |
