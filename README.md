# 🏛️ AKASHA (아카샤)
> **세상 모든 작품을 기억하고, 추억하며, 다음 여정을 찾아가는 개인 미디어 아카이브 공간**

AKASHA는 단순한 미디어 감상 기록(트래커) 앱을 넘어, 유저가 사랑하고 영접한 **세상의 모든 작품들(만화, 게임, 애니메이션, 책, 영화, 드라마 등)**을 옵시디언(Obsidian) 호환 로컬 마크다운 파일로 축적하고, 감동을 회상하며, 취향을 바탕으로 다음 여정을 발견하도록 돕는 **통합 미디어 아카이빙 플랫폼**입니다.

---

## 🌌 Core Philosophy (핵심 철학 및 비전)

우리가 작품을 보고 기록하는 진짜 이유는 데이터의 수집이 아닌 **'그때의 감동과 내 생각의 보존'**에 있습니다. AKASHA는 다음의 3대 핵심 사용자 경험을 토대로 움직이며, 어떤 개발이나 확장 중에도 이 방향성을 잃지 않습니다.

### 1. 📂 지능적인 다형성 기록 (Archive & Write)
* **모든 매체 수용**: 게임, 책, 영화, 애니메이션 등 매체 고유의 특성(출시 여부, 내 플레이 상태 등)을 완벽히 수용할 수 있는 유연한 다형성 데이터 구조를 지향합니다.
* **영구적인 개인 소유**: 모든 상세 리뷰, 평점, 태그, 명장면/명대사는 유저 로컬의 마크다운(`.md`) 파일에 Obsidian 양식으로 보존됩니다. 플랫폼 종속적이지 않은 100% 개인 소유 데이터입니다.

### 2. 👑 감동의 실시간 회상 (Remind & Relive)
* **묻히지 않는 기록**: 아카이브에 기록된 명대사와 감상문을 홈 화면에 무작위로 호출하는 **'오늘의 회상 카드'** 등을 통해, 잊고 있던 과거의 영감과 감동을 환기합니다.
* **성장과 여정의 기록**: 타임라인과 완성 캘린더를 통해 내가 걸어온 미디어 여정과 성장의 기록을 시각적으로 돌아봅니다.

### 3. 🗺️ 다음 여정으로의 인도 (Discover & Journey)
* **메타데이터 자동화**: 유저가 정보를 다 기입할 필요 없이 AI와 외부 API(TMDB, IGDB 등)가 작품의 장르, 포스터, 작가를 자동으로 연동하여 채워줍니다.
* **취향 기반 탐색**: 내가 작성한 아카이브 태그와 S-Tier 컬렉션(명예의 전당) 데이터를 유기적으로 연결하여, 아직 보지 않은 작품들 중에서 "내 취향에 맞는 최고의 다음 작품"을 정밀하게 추천하고 탐색할 수 있도록 돕습니다.

---

## 🛠️ Technology Stack
* **Core Framework**: Flutter (Windows Desktop 우선 검증 및 모바일 확장성 확보)
* **Storage**: Local Markdown Files (.md with YAML Front-matter)
* **State Management**: Provider / Riverpod (추후 고도화 예정)
* **Parser Engine**: Custom YAML & Markdown Parser for Obsidian Vault compatibility

---

## 📂 Obsidian Vault 연동 (볼트 구조)

앱에서 **폴더 연동** 시 아래 구조가 자동 생성됩니다.

```
{Vault}/
├── posters/          # 사용자 업로드 포스터 (상대경로 posters/...)
├── manga/
├── animation/
├── game/
├── book/
├── movie/
└── drama/
```

### YAML Front-matter (필수·권장 필드)

| 필드 | 설명 |
|------|------|
| `work_id` | 마스터 ID (`sub_manga_..._2011`). 비어 있으면 사전 매칭 후 자동 부여 |
| `title` | 작품 제목 (Obsidian 파일명과 동기화) |
| `category` | `manga` · `animation` · `game` · `book` · `movie` · `drama` |
| `domain` | `subculture` · `generalCulture` |
| `status` / `my_status` | 나의 상태 (볼 예정, 전부 봄 등) |
| `work_status` | 작품 상태 (완결, 출시됨 등) |
| `rating` | 0.0~5.0 |
| `is_hall_of_fame` | S-Tier 명예의 전당 여부 |
| `poster` | `posters/` 상대경로 또는 커스텀 URL만 저장 (Registry CDN URL은 생략) |

본문에는 **명대사·감상문**만 기록합니다. 작품 설명·포스터 기본값은 글로벌 사전에서 UI fusion 됩니다.

### 외부 편집

Obsidian에서 `.md`를 수정하면 앱이 **약 0.4초 후** 자동 반영합니다. 앱에서 저장 시 **원자적 쓰기**(임시 파일 → rename)로 파일 손상을 방지합니다.
