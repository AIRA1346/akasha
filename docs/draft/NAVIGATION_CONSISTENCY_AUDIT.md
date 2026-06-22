# Navigation Consistency Audit — P6

> **갱신:** 2026-06-22 (P4–P7 구현 반영)  
> **기준:** `lib/` 코드 실측  
> **목표 규칙:** 탐험 = Preview · 편집 = Workbench

---

## 터미널 함수

| 함수 | 파일 | 결과 |
|------|------|------|
| `openWorkPreview` | `home_shell_controller.dart` | Work Preview 패널 |
| `openWorkFromPreview` | `home_shell_controller.dart` | Work Workbench |
| `openEntityPreview` | `home_shell_controller.dart` | Entity Preview 패널 |
| `openEntityFromPreview` | `home_shell_controller.dart` | Entity Workbench |
| `openEntity` | `home_shell_controller.dart` | Entity Workbench (직행) |
| `openBrowseItem` | `home_workbench_coordinator.dart` | Work Workbench |

---

## 전수 조사표 (P4 구현 후)

### Search (Fusion)

| 대상 | 현재 | 목표 | 파일 |
|------|------|------|------|
| 로컬 Work | **Preview** ✅ | Preview | `home_dialogs_coordinator.dart` |
| 원격 Work | **Preview** ✅ | Preview | 동일 |
| 로컬 Entity | **Preview** ✅ | Preview | `_openEntityFromSearch` → `onPreviewEntity` |
| 원격 Entity | **Preview** ✅ | Preview | 동일 |
| promote 후 Entity | **Workbench** (의도적) | Workbench | `_promoteCatalogOnlyToArchive` |

### Home Dashboard

| 섹션 | Work | Entity | 파일 |
|------|------|--------|------|
| 계속 탐험하기 | Preview ✅ | **Preview** ✅ | `home_dashboard_view.dart` |
| 오늘의 연결 | Preview ✅ | **Preview** ✅ | `home_dashboard_todays_links_section.dart` |
| 최근 발견 | Preview ✅ | **Preview** ✅ | `home_dashboard_recent_discovery_section.dart` |
| 최근 기록 | Preview ✅ | — | `home_dashboard_recent_records_section.dart` |
| Preview 이웃 탭 | Preview ✅ | **Preview** ✅ | `dashboard_preview_panel.dart` / `entity_dashboard_preview_panel.dart` |

### Browse Grid

| 모드 | Work | Entity |
|------|------|--------|
| 탐색/대시보드 | Preview ✅ | **Preview** ✅ |
| Entity-only scope | Preview ✅ | **Preview** ✅ |
| Entity discovery strip (compact) | Preview ✅ | **Preview** ✅ |
| 나만의 서재 Work 그리드 | **Workbench** (큐레이션) | — |

### Collection

| 대상 | Work | Entity |
|------|------|--------|
| 컬렉션 갤러리 | Preview ✅ | **Preview** ✅ |

### Library (Personal)

| 대상 | Work | Entity |
|------|------|--------|
| 서재 Work 그리드 | **Workbench** (큐레이션) | — |
| Entity-only scope | Preview ✅ | **Preview** ✅ |

### Knowledge Graph

| 액션 | Work | Entity |
|------|------|--------|
| 열기 / 이웃 | Preview ✅ | **Preview** ✅ |

### Records / Timeline

| 액션 | Work | Entity |
|------|------|--------|
| 링크 탭 | **Workbench** (의도적) | **Workbench** (의도적) |

*기록 뷰 내 링크는 편집 맥락 유지 — 별도 스프린트 검토*

### Sidebar 최근 탐색

| 타입 | 현재 | 목표 |
|------|------|------|
| Work | Preview ✅ | Preview |
| Entity | **Preview** ✅ | Preview |

### Wiki 링크 (Sanctum)

| 출처 | Work | Entity |
|------|------|--------|
| Workbench Sanctum | Workbench | Workbench |

*탐험 규칙과 불일치 — P7+ 후보*

---

## 불일치 요약 (P4 후)

| 패턴 | Work | Entity |
|------|------|--------|
| 홈·탐색·그래프·검색·컬렉션 | Preview ✅ | **Preview** ✅ |
| 서재 Work 그리드 | Workbench (큐레이션) | — |
| Records·타임라인·위키·promote 직후 | Workbench (의도적) | Workbench (의도적) |

**탐험 경로 Entity = Work 3층 구조 통일 완료.**

---

## P5 홈 IA — 삭제 완료

| 블록 | 파일 | 판정 | 상태 |
|------|------|------|------|
| 환영 헤더 | `home_dashboard_welcome_header.dart` | 제거 | ✅ `home_dashboard_view.dart`에서 미사용 |
| 빠른 액션 | `home_dashboard_quick_actions_section.dart` | 제거 | ✅ 동일 |
| TopBar 검색 | `home_dashboard_top_bar.dart` | 유지 | ✅ |
| 지식 우주 궤도 | `home_dashboard_universe_section.dart` | 제거 | ✅ (R3-A) |
| 발견의 여정 | `home_dashboard_discovery_section.dart` | 제거 | ✅ (R3-A) |

**홈 4섹션:** 계속 탐험하기 → 오늘의 연결 → 최근 발견 → 최근 기록
