# AppDomain (서브컬처 / 일반 문화) 폐기 계획

> **지위:** `AppDomain` 제거 로드맵 SSOT  
> **갱신:** 2026-06-24  
> **배경:** Registry 98.4% `subculture` · VISION은 PKU(작품→Entity) · category가 1차 축

---

## 목표

사용자 IA에서 **domain 분기를 제거**하고, `category` + 큐레이션만 남긴다.  
스키마·레거시 ID는 단계적으로 정리하되 **호환은 유지**한다.

---

## 단계

| Phase | 내용 | 상태 |
|:-----:|------|:----:|
| **1** | UI — browse 필터·작품 추가·서재/대시보드 설정·기여 다이얼로그에서 domain 선택 제거 | ✅ |
| **2** | 런타임 — 필터 스냅샷·서재 `normalizeLibraries`에서 domain 무시·제거 | ✅ |
| **3** | Registry — ingest 기본 `subculture` · `generalCulture` 신규 금지 · `migrate_domain_normalize.dart` | ✅ |
| **4** | 스키마 — `fromStorage` 정규화 · config domain 필드 제거 · 문서 갱신 · `sub_`/`gen_` 파싱 유지 | ✅ |

---

## 유지 (레거시 호환)

| 항목 | 이유 |
|------|------|
| `AkashaItem.domain` · YAML `domain:` | 읽기 시 `AppDomain.fromStorage` → subculture |
| `WorkIdCodec` `sub_`/`gen_` | 레거시 마스터 ID |
| `RegistryWork.domain` | Tier 1 필드 — 값은 항상 subculture |

## 제거됨

- Browse·서재·대시보드 **domain 필터 UI·저장**
- `generalCulture` Registry ingest (162건 → subculture 마이그레이션)
- `PersonalLibraryConfig.domain` · `DashboardConfig.domain`
- `BrowseFilterState.domain`

---

## 검증

```powershell
flutter test
.\scripts\dogfood_precheck.ps1
```

수동: 탐색 필터 행에 domain 없음 · 서재 필터가 category만으로 동작 · 커스텀 작품 추가 정상.

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-24 | Phase 3–4 — Registry 162건 정규화 · fromStorage · config domain 제거 |
