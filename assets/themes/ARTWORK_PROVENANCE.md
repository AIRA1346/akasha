# AKASHA Theme Artwork Provenance

> **지위:** bundled theme artwork 생성·무결성 기록
> **생성일:** 2026-07-14
> **생성 방식:** OpenAI built-in image generation

## Assets

| Asset | 역할 | 크기 | SHA-256 |
|---|---|---:|---|
| `classicDark/hero.png` | Home Hero | 1672×941 | `8A49D678A2ADEDBE99FE1D20037612AA4DDC782A9807FE98D2E813DD246E797B` |
| `classicDark/backdrop.png` | app-root backdrop | 1672×941 | `DFB42618EDAB36E605B1EB32DB0685AA7006F552038D30766D6A967CD8E1B98B` |
| `midnightBlue/hero.png` | Home Hero | 1672×941 | `2FF4281F45B0608183988D38C1730F2066DACF0DB61A8185FA70D3DEC5600D74` |
| `midnightBlue/backdrop.png` | app-root backdrop | 1672×941 | `E3DD7412C73C0AB45176F5DFFB38A0A9BFFA406F5F159E20D17355FF87D5EF7F` |

총 원본 bundle 크기는 `6,282,701 bytes`다. 생성 원본을 그대로 사용했으며 별도 crop, 합성, 색 보정은 하지 않았다.

## Reference role

- `ChatGPT Image 2026년 7월 12일 오후 02_24_53.png`: Classic Dark의 mood, palette, Hero 배치 참고
- `ChatGPT Image 2026년 7월 13일 오전 11_42_19.png`: Midnight Blue의 mood, palette, Hero 배치 참고
- `ChatGPT Image 2026년 7월 13일 오전 11_42_12.png`: Midnight Blue의 천체 구도 참고

레퍼런스는 생성 입력의 시각 방향 자료로만 사용했다. 레퍼런스의 UI, 텍스트, poster, logo는 asset에 복제하지 않았다. 레퍼런스 파일 자체는 앱 bundle에 포함하지 않는다.

## Final prompt specifications

### Classic Dark Hero

- celestial knowledge-orbit scene suggesting records connected into a personal universe
- deep near-black/navy space, restrained violet/electric-blue paths, compass-like star nexus and connected nodes
- wide landscape with the left 45% dark and low-detail; focal structure on the right
- no UI, text, logo, watermark, people, buildings, or book covers

### Classic Dark Backdrop

- restrained celestial archive atmosphere behind a dense desktop interface
- near-black/deep navy field, faint violet-blue haze, sparse stars and connection arcs
- no central illustration; at least 85% very dark; slightly richer detail at the outer right edge
- no UI, text, logo, watermark, people, buildings, large planets, or bright focal object

### Midnight Blue Hero

- midnight celestial archive with a crescent moon, orbital rings, constellation threads and connected nodes
- deep blue-black sky, abstract reflective plane, cool moonlight and restrained blue glow
- wide landscape with the left 45% dark and low-detail; crescent/orbit focal structure on the right
- no UI, text, logo, watermark, people, dragons, city buildings, or book covers

### Midnight Blue Backdrop

- quiet midnight-blue celestial atmosphere behind a dense desktop interface
- deep blue-black sky, sparse stars, subtle cool-blue haze, faint constellation and orbital arcs
- no central illustration; at least 85% very dark; faint detail near outer edges
- no UI, text, logo, watermark, people, buildings, large moon/planet, or bright focal object

## Integration invariants

- artwork changes atmosphere only; geometry and feature availability remain shared.
- Hero copy area remains readable without relying on the source image's empty space alone.
- Backdrop is rendered under a preset-colored scrim.
- missing or corrupt assets fall back to code-rendered gradients and brand artwork.
- premium theme artwork must add its own provenance entry before integration.
