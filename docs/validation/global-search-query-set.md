# Global Search Query Set (SW1)

> **95건** (recall 집계 **87건**, `NOT_IN_REGISTRY` 진단 8건 제외) · 402 Registry 기준  
> 자동화 러너 입력 형식으로도 사용 가능 (구현은 SW1.1)
>
> 계획: [global-search-validation-plan.md](global-search-validation-plan.md)

**필드 설명**

| 필드 | 설명 |
|------|------|
| `id` | GS001–GS095 |
| `query` | 사용자 입력 그대로 |
| `expectedWorkIds` | hit@K 성공으로 인정할 workId (복수 가능) |
| `acceptableWorkIds` | 시리즈 검색 시 추가 인정 (비어 있으면 expected만) |
| `tags` | 집계 카테고리 |
| `workload` | W1–W7 ([search-workload-profile](search-workload-profile.md)) |
| `persona` | JP / US / KR / CN |
| `hypothesis402` | Phase A 예상 — `PASS` · `FAIL` · `GAP` |

---

## A. 영어 → 일본어/한국어 작품 (EN cross) — 18건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS001 | `Your Lie in April` | wk_000000234 | EN_KO, ORIG_LOC | W1 | US | PASS |
| GS002 | `your lie in april` | wk_000000234 | EN_KO, ORIG_LOC | W1 | US | PASS |
| GS003 | `Goblin Slayer` | wk_000000329 | EN_KO, EN_JA | W1 | US | PASS |
| GS004 | `Golden Kamuy` | wk_000000196 | EN_KO, EN_JA | W1 | US | PASS |
| GS005 | `Kaiju No. 8` | wk_000000206 | EN_KO, EN_JA | W1 | US | PASS |
| GS006 | `Death Note` | wk_000000187 | EN_KO, EN_JA | W1 | US | PASS |
| GS007 | `Sword Art Online` | wk_000000241 | EN_KO, EN_JA | W1 | US | PASS |
| GS008 | `Naruto` | wk_000000218 | EN_KO, EN_JA | W1 | US | PASS |
| GS009 | `My Hero Academia` | wk_000000217 | EN_KO, EN_JA | W1 | US | PASS |
| GS010 | `Tokyo Ghoul` | wk_000000242 | EN_KO, EN_JA | W1 | US | PASS |
| GS011 | `Delicious in Dungeon` | wk_000000190, wk_000000318 | EN_KO, EN_JA | W1 | US | PASS |
| GS012 | `DanMachi` | wk_000000186 | EN_KO, ABBR | W4 | US | PASS |
| GS013 | `SAO` | wk_000000241 | EN_KO, ABBR | W4 | US | PASS |
| GS014 | `Demon Slayer` | wk_000000343, wk_000000188 | EN_KO, GAP | W1 | US | **GAP** |
| GS015 | `Kimetsu no Yaiba` | wk_000000343, wk_000000188 | EN_JA, GAP | W1 | US | **GAP** |
| GS016 | `Spy x Family` | wk_000000387, wk_000000239 | EN_KO, GAP | W1 | US | **GAP** |
| GS017 | `Fullmetal Alchemist` | wk_000000325, wk_000000194 | EN_KO, GAP | W1 | US | **GAP** |
| GS018 | `Mushoku Tensei` | wk_000000354, wk_000000257 | EN_KO, GAP | W1 | US | **GAP** |

---

## B. 일본어 → 작품 (JA cross) — 14건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS019 | `四月は君の嘘` | wk_000000234 | JA_EN, ORIG_LOC | W3 | JP | PASS |
| GS020 | `ゴブリンスレイヤー` | wk_000000329 | JA_EN, EN_JA | W3 | JP | PASS |
| GS021 | `ゴールデンカムイ` | wk_000000196 | JA_EN, EN_JA | W3 | JP | PASS |
| GS022 | `怪獣8号` | wk_000000206 | JA_EN, EN_JA | W3 | JP | PASS |
| GS023 | `DEATH NOTE` | wk_000000187 | JA_EN | W1 | JP | PASS |
| GS024 | `ソードアート・オンライン` | wk_000000241 | JA_EN, EN_JA | W3 | JP | PASS |
| GS025 | `進撃` | — (402에 進撃の巨人 없음) | JA_EN, PARTIAL | W2 | JP | FAIL* |
| GS026 | `鬼滅の刃` | wk_000000343, wk_000000188 | JA_EN, GAP | W3 | JP | **GAP** |
| GS027 | `呪術廻戦` | — (미수록) | JA_EN, GAP | W1 | JP | FAIL* |
| GS028 | `ダンジョンに出会いを求めるのは間違っているだろうか` | wk_000000186 | JA_EN, ORIG_LOC | W1 | JP | PASS |
| GS029 | `僕のヒーローアカデミア` | wk_000000217 | JA_EN | W3 | JP | PASS |
| GS030 | `東京喰種` | wk_000000242 | JA_EN | W3 | JP | PASS |
| GS031 | `ガチアクタ` | wk_000000327 | JA_EN, EN_JA | W3 | JP | PASS |
| GS032 | `葬送のフリーレン` | — (미수록) | JA_EN, GAP | W1 | JP | FAIL* |

\* `NOT_IN_REGISTRY` — 스위트에 유지(미수록 시나리오). recall 집계 시 **평가 제외** 또는 별도 버킷.

---

## C. 한국어 → 영어/일본어 메타 (KO cross) — 14건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS033 | `데스노트` | wk_000000187 | KO_EN, ORIG_LOC | W1 | KR | PASS |
| GS034 | `소드 아트 온라인` | wk_000000241 | KO_EN, ORIG_LOC | W1 | KR | PASS |
| GS035 | `나루토` | wk_000000218 | KO_EN | W1 | KR | PASS |
| GS036 | `고블린 슬레이어` | wk_000000329 | KO_EN, ORIG_LOC | W1 | KR | PASS |
| GS037 | `던전에서 만남을 추구하면 안 되는걸까` | wk_000000186 | KO_EN, ORIG_LOC | W1 | KR | PASS |
| GS038 | `귀멸의 칼날` | wk_000000343, wk_000000188 | KO_EN, SERIES | W1 | KR | PASS |
| GS039 | `스파이 패밀리` | wk_000000387, wk_000000239 | KO_EN, SERIES | W1 | KR | PASS |
| GS040 | `강철의 연금술사` | wk_000000325, wk_000000194 | KO_EN, SERIES | W1 | KR | PASS |
| GS041 | `4월은 너의 거짓말` | wk_000000234, wk_000000380 | KO_EN, SERIES | W1 | KR | PASS |
| GS042 | `Re:제로` | wk_000000230 | KO_EN, ABBR | W4 | KR | PASS |
| GS043 | `Re:Zero` | wk_000000230, wk_000000375 | EN_KO, GAP | W4 | US | **GAP** |
| GS044 | `20세기 소년` | wk_000000291 | KO_EN | W1 | KR | PASS |
| GS045 | `20th Century Boys` | wk_000000291 | EN_KO, GAP | W1 | US | **GAP** |
| GS046 | `우라사와 나오키` | wk_000000291 (+기타 우라사와 작품) | KO_EN | W5 | KR | PASS† |

† creator 매칭 — expected는 **우라사와 나오키 대표작** wk_000000291, acceptable: 동일 creator 다른 작품.

---

## D. 중국어 · 영어 혼용 (EN_ZH / MIXED) — 8건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS047 | `鬼灭之刃` | wk_000000343, wk_000000188 | EN_ZH, GAP | W3 | CN | **GAP** |
| GS048 | `进击的巨人` | — | EN_ZH, GAP | W1 | CN | FAIL* |
| GS049 | `你的名字` | — | EN_ZH, GAP | W1 | CN | FAIL* |
| GS050 | `死亡笔记` | wk_000000187 | EN_ZH, GAP | W3 | CN | **GAP** |
| GS051 | `火影忍者` | wk_000000218 | EN_ZH, GAP | W3 | CN | **GAP** |
| GS052 | `Dr.STONE` | wk_000000189 | MIXED, EN_JA | W1 | CN | PASS |
| GS053 | `BLEACH` | wk_000000176 | MIXED, EN_JA | W1 | US | PASS |
| GS054 | `ONE PIECE` | — (402 미수록) | EN_ZH, GAP | W1 | CN | FAIL* |

---

## E. 원제 ↔ 현지화 (ORIG_LOC) — 10건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS055 | `Great Teacher Onizuka` | wk_000000333 | ORIG_LOC | W1 | US | PASS |
| GS056 | `GTO` | wk_000000333 | ORIG_LOC, ABBR | W4 | JP | PASS |
| GS057 | `Parasyte` | wk_000000226 | ORIG_LOC | W2 | US | PASS |
| GS058 | `寄生獣` | wk_000000226 | ORIG_LOC | W3 | JP | PASS |
| GS059 | `Vinland Saga` | wk_000000247 | ORIG_LOC | W1 | US | PASS |
| GS060 | `ヴィンランド・サガ` | wk_000000247 | ORIG_LOC | W3 | JP | PASS |
| GS061 | `Barakamon` | wk_000000297 | ORIG_LOC | W1 | US | PASS |
| GS062 | `ばらかもん` | wk_000000297 | ORIG_LOC | W3 | JP | PASS |
| GS063 | `Made in Abyss` | wk_000000348 | ORIG_LOC | W1 | US | PASS |
| GS064 | `メイドインアビス` | wk_000000348 | ORIG_LOC | W3 | JP | PASS |

---

## F. 별칭 · 약칭 (ALIAS / ABBR) — 10건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS065 | `SAO` | wk_000000241 | ABBR | W4 | US | PASS |
| GS066 | `DanMachi` | wk_000000186 | ABBR | W4 | US | PASS |
| GS067 | `GTO` | wk_000000333 | ABBR | W4 | JP | PASS |
| GS068 | `Dr. Stone` | wk_000000189 | ALIAS | W1 | US | PASS |
| GS069 | `Shokugeki` | wk_000000382 | PARTIAL, ABBR | W2 | US | PASS |
| GS070 | `食戟` | wk_000000382 | PARTIAL, JA_EN | W2 | JP | PASS |
| GS071 | `Re:ゼロ` | wk_000000230 | MIXED, ABBR | W4 | JP | **GAP** |
| GS072 | `FMA` | wk_000000194, wk_000000325 | ABBR, GAP | W4 | US | **GAP** |
| GS073 | `NGE` | — (미수록) | ABBR, GAP | W4 | US | FAIL* |
| GS074 | `Eva` | — (미수록) | ABBR, GAP | W4 | US | FAIL* |

---

## G. 시리즈명 ↔ 개별 작품 (SERIES) — 10건

| id | query | expectedWorkIds | acceptableWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|---------------------|------|---|---------|--------|
| GS075 | `귀멸의 칼날` | wk_000000343 | wk_000000188, wk_000000404, wk_000000405 | SERIES | W1 | KR | PASS |
| GS076 | `무한열차` | wk_000000404, wk_000000405 | wk_000000343, wk_000000188 | SERIES, PARTIAL | W2 | KR | PASS |
| GS077 | `스파이 패밀리` | wk_000000387 | wk_000000239 | SERIES | W1 | KR | PASS |
| GS078 | `86` | wk_000000292, wk_000000253 | — | SERIES, PARTIAL | W2 | JP | PASS |
| GS079 | `무직전생` | wk_000000354 | wk_000000257, wk_000000216 | SERIES | W1 | KR | PASS |
| GS080 | `반지의 제왕` | wk_000000010 | wk_000000158 | SERIES, PARTIAL | W2 | KR | PASS |
| GS081 | `Lord of the Rings` | wk_000000010, wk_000000158 | — | SERIES, GAP | W1 | US | **GAP** |
| GS082 | `The Fellowship of the Ring` | wk_000000010 | wk_000000158 | SERIES, GAP | W1 | US | **GAP** |
| GS083 | `단다단` | wk_000000310, wk_000000185 | — | SERIES | W1 | KR | PASS |
| GS084 | `Dandadan` | wk_000000310, wk_000000185 | — | SERIES, GAP | W1 | US | **GAP** |

---

## H. 부분 검색 · 혼합 스크립트 · 지역 패턴 — 11건

| id | query | expectedWorkIds | tags | W | persona | hyp402 |
|----|-------|-----------------|------|---|---------|--------|
| GS085 | `death` | wk_000000187 | PARTIAL | W2 | US | PASS |
| GS086 | `goblin` | wk_000000329 | PARTIAL | W2 | US | PASS |
| GS087 | `東京` | wk_000000242, wk_000000243 | PARTIAL, MIXED | W2 | JP | PASS |
| GS088 | `Re:` | wk_000000230, wk_000000260, wk_000000375 | PARTIAL, MIXED | W2 | KR | PASS |
| GS089 | `소년` | wk_000000291 (+다수) | PARTIAL | W2 | KR | PASS‡ |
| GS090 | `BLEACH` | wk_000000176 | MIXED | W1 | US | PASS |
| GS091 | `블리치` | wk_000000176 | KO_EN, ORIG_LOC | W1 | KR | PASS |
| GS092 | `Blue Lock` | wk_000000177 | EN_JA | W1 | US | PASS |
| GS093 | `ブルーロック` | wk_000000177 | JA_EN | W3 | JP | PASS |
| GS094 | `Assassination Classroom` | wk_000000296 | EN_KO | W1 | US | PASS |
| GS095 | `暗殺教室` | wk_000000296 | JA_EN | W3 | JP | PASS |

‡ 다건 매칭 — recall은 hit@K만 보며, RANKING/AMBIGUITY 태그로 순위 품질 별도 기록.

> **건수:** `NOT_IN_REGISTRY` 8건 (GS025, GS027, GS032, GS048, GS049, GS054, GS073, GS074)은 recall 집계 **제외** · **유효 87건**.

---

## I. 집계용 요약

| 태그 | 건수 | GAP/FAIL 예상 (402) |
|------|------|---------------------|
| EN_JA / JA_EN | 28 | ~10 GAP |
| EN_KO / KO_EN | 32 | ~8 GAP |
| EN_ZH | 8 | ~7 GAP |
| ORIG_LOC | 24 | ~4 GAP |
| ALIAS / ABBR | 14 | ~5 GAP |
| SERIES | 10 | ~3 GAP |
| PARTIAL / MIXED | 15 | ~1 AMBIGUITY |
| NOT_IN_REGISTRY (제외) | 8 | — |

**402 baseline 예상:** 유효 87건 중 **PASS ~58–68 · GAP/FAIL ~19–29** (메타 누락 위주).

---

## J. 기계 판독용 JSON 스키마 (SW1.1)

```json
{
  "version": 1,
  "registrySnapshot": "402@2026-06-08",
  "queries": [
    {
      "id": "GS001",
      "query": "Your Lie in April",
      "expectedWorkIds": ["wk_000000234"],
      "acceptableWorkIds": [],
      "tags": ["EN_KO", "ORIG_LOC"],
      "workload": "W1",
      "persona": "US",
      "hypothesis402": "PASS",
      "excludeFromRecall": false
    }
  ]
}
```

전체 JSON export는 SW1-A 착수 시 `docs/global-search-query-set.json`으로 분리 가능.
