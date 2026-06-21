# Commerce Boundary Policy

> AKASHA 결제·권한 경계 — Steam IAP vs 제휴 콘텐츠  
> 목표: **코스메틱은 Steam**, **작품 구매·감상은 제휴 채널**

---

## 1. 왜 분리하는가

| 채널 | Valve 수수료 | 적합한 SKU |
|------|-------------|------------|
| **Steam microtxn** | ~30% | 서재 테마, 서포터 팩 |
| **제휴 웹/API** | 제휴사·PSP 조건 | eBook, 스트리밍, 게임 키, 구독 |

AKASHA의 장기 비전은 **플랫폼 제휴를 통한 인앱 구매·감상**입니다. Steam은 **런처·아카이브 허브**로 두고, 콘텐츠 거래는 별도 entitlement 레이어로 설계합니다.

⚠️ Steam 배포 약관: Steam 클라이언트 **내부에서** Steam 결제를 우회한 동일 카테고리 디지털 상품 판매는 제한될 수 있습니다. 콘텐츠 커머스는 **외부 결제 + entitlement 동기화** 또는 **딥링크** 패턴을 기본으로 하고, 출시 전 Steamworks 정책·법무 검토가 필요합니다.

---

## 2. 아키텍처 레이어

```
┌──────────────────────────────────────────────┐
│ Archive Layer     볼트 · 회상 · 나의 서재     │  v1
│ Catalog Layer     akasha-db · IP fusion      │  v1
│ Commerce Layer    SKU · entitlement · 제휴  │  v2+
│ Playback Layer    딥링크 · WebView · 뷰어    │  v2+
└──────────────────────────────────────────────┘
```

---

## 3. Entitlement 종류 (코드)

`EntitlementService` (`lib/services/entitlement_service.dart`):

| kind | 저장소 | 메서드 | 예시 SKU |
|------|--------|--------|----------|
| `cosmetic` | `akasha_entitlements` | `grantCosmeticEntitlement` | `akasha_library_theme_pack` |
| `content` | `akasha_content_entitlements` | `grantContentEntitlement` | `partner:bookwalker:workId` |

- **Cosmetic**: `purchaseCosmetic()` → Steamworks IAP 콜백
- **Content**: 제휴 OAuth / 웹결제 webhook → `grantContentEntitlement(key)`

두 집합은 **절대 혼합하지 않음**.

---

## 4. 제휴 플로우 (목표)

### 4.1 구매

1. 사용자가 작품 상세에서 「구매」 탭
2. 앱 → 제휴사 **웹 결제** (또는 제휴 앱 딥링크)
3. 제휴사 → AKASHA backend (또는 signed JWT) → `grantContentEntitlement`
4. 앱 UI: 「보유」 배지 + 감상 진입

### 4.2 이미 소유한 라이브러리

- Steam / Epic / Kindle 등 **OAuth read-only**
- 소유 여부만 동기화, 결제는 해당 플랫폼에서 이미 완료
- AKASHA는 **감상 진입·아카이브 연동**만 담당

### 4.3 감상 (단계)

| 단계 | 방식 |
|------|------|
| M2 | 외부 URL 딥링크 (`externalIds.steam` 등) |
| M3 | 제휴 WebView / 커스텀 뷰어 |
| M4 | 오프라인 DRM (제휴사 정책 따름) |

---

## 5. `externalIds` ↔ Commerce 연결

```json
{
  "workId": "sub_book_86-light-novel_2016",
  "externalIds": {
    "anilist": "116589",
    "partnerSku": "bookwalker:bn_12345"
  }
}
```

- 카탈로그: `externalIds`로 제휴 SKU 매핑
- Entitlement key: `partner:{provider}:{sku}` 또는 `workId:{workId}`

---

## 6. Steam v1 범위 (확정)

| 포함 | 제외 |
|------|------|
| 무료 앱 | 콘텐츠 IAP (Steam) |
| 서재 테마 IAP (스텁) | 인앱 스트리밍 재생 |
| 서포터 팩 IAP (스텁) | 제휴 실결제 (M2+) |

---

## 7. 구현 체크리스트 (백로그)

- [ ] `PartnerCommerceAdapter` 인터페이스 (OAuth, purchase URL, entitlement verify)
- [ ] 작품 상세 「구매·감상」 CTA (entitlement-aware)
- [ ] Backend webhook 또는 signed offline grant
- [ ] Steamworks 정책·EU DMA 결제 선택지 검토
- [ ] 환불·세금·MoR (제휴사별)

---

## 8. 관련 문서

- [locale-catalog-policy.md](locale-catalog-policy.md) — `externalIds`, `workId`
- [ROADMAP.md](../ROADMAP.md) — M2 Steam / M3+ 제휴
