# tool/archive

완료된 일회성 배치·스프린트 스크립트 보관용입니다. **새 작업에 사용하지 마세요.**

실행 예 (필요 시에만):

```bash
dart run tool/archive/seed_expansion_batch5.dart --help
dart run tool/archive/a5_scale_supply_batch.dart --batch 1
```

## 보관 파일

| 그룹 | 파일 |
|------|------|
| 시드 확장 | `seed_expansion_batch5.dart`, `seed_expansion_batch6.dart`, `seed_expansion_batch7.dart` |
| 커버리지 스프린트 | `coverage_sprint_01_gap_enrich.dart` … `coverage_sprint_04_high_risk_analyze.dart` (9개) |
| A5 스케일 | `a5_pilot_supply_batch.dart`, `a5_scale_*.dart` (8개) |
| 기타 | `fix_batch5_posters.dart`, `scale_5k_sim.dart` |

루트 `tool/` 유틸(`pre_insert_dedupe_gate.dart`, `coverage_quality.dart` 등)은 `../`로 import합니다.
