import 'currency_kind.dart';

enum ProductKind {
  /// Steam Inventory purchase that grants [CurrencyKind.premium].
  premiumPack,

  /// One complete visual theme package and its theme-specific effects.
  themePackage,

  /// Future standalone pointer/touch interaction effect.
  interactionEffect,

  /// Future standalone OST or audio package.
  audioPack,

  /// Spend [CurrencyKind.premium] only; no entitlement / no gameplay advantage.
  /// Display: EN "Support AKASHA" · KO "AKASHA 후원" (not "Donation").
  support,
}

/// Catalog publication state. This never implies that a local client can
/// transact; the live provider and feature flag must also be ready.
enum CommerceOfferState { planned, available, paused }

/// How a product may be paid.
enum PaymentPolicy {
  premiumOnly,
  earnedOnly,

  /// Buyer chooses exactly one of premium or earned at unlock time.
  chooseOne,
}

class PaymentOption {
  const PaymentOption({
    required this.policy,
    this.premiumPrice,
    this.earnedPrice,
  });

  final PaymentPolicy policy;
  final int? premiumPrice;
  final int? earnedPrice;

  int? priceFor(CurrencyKind kind) => switch (kind) {
    CurrencyKind.premium => premiumPrice,
    CurrencyKind.earned => earnedPrice,
  };

  bool allows(CurrencyKind kind) => switch (policy) {
    PaymentPolicy.premiumOnly => kind == CurrencyKind.premium,
    PaymentPolicy.earnedOnly => kind == CurrencyKind.earned,
    PaymentPolicy.chooseOne =>
      (kind == CurrencyKind.premium && premiumPrice != null) ||
          (kind == CurrencyKind.earned && earnedPrice != null),
  };

  List<CurrencyKind> get acceptedCurrencies => [
    for (final kind in CurrencyKind.values)
      if (allows(kind)) kind,
  ];

  /// Payment is always made with exactly one selected currency. A caller never
  /// supplies partial Astra plus partial Echo amounts.
  bool canPayEntirelyWith(CurrencyKind kind, int balance) {
    final price = priceFor(kind);
    return allows(kind) && price != null && price > 0 && balance >= price;
  }
}

class CommerceProduct {
  const CommerceProduct({
    required this.id,
    required this.kind,
    this.offerState = CommerceOfferState.planned,
    this.payment,
    this.grantPremiumAmount,
    this.entitlementKey,
    this.displayNameEn,
    this.displayNameKo,
  });

  final String id;
  final ProductKind kind;
  final CommerceOfferState offerState;

  /// In-app currency alternatives. `null` for real-money Astra packs.
  final PaymentOption? payment;

  /// For [ProductKind.premiumPack] — amount of Astra granted after finalization.
  final int? grantPremiumAmount;

  /// Stable entitlement id (not a display name or provider ItemDef id).
  final String? entitlementKey;

  /// Optional catalog display (UI). Never used as a storage key.
  final String? displayNameEn;
  final String? displayNameKo;
}

/// Domain order lifecycle for the pure commerce slice.
/// Steam adapter maps external txn states separately (see P4-B).
enum OrderStatus { pendingPayment, completed, refunded, failed }

class CommerceOrder {
  const CommerceOrder({
    required this.id,
    required this.userId,
    required this.productId,
    required this.status,
    required this.idempotencyKey,
    this.premiumGrantAmount,
    this.externalPaymentId,
  });

  final String id;
  final String userId;
  final String productId;
  final OrderStatus status;
  final String idempotencyKey;
  final int? premiumGrantAmount;
  final String? externalPaymentId;

  CommerceOrder copyWith({
    OrderStatus? status,
    int? premiumGrantAmount,
    String? externalPaymentId,
  }) => CommerceOrder(
    id: id,
    userId: userId,
    productId: productId,
    status: status ?? this.status,
    idempotencyKey: idempotencyKey,
    premiumGrantAmount: premiumGrantAmount ?? this.premiumGrantAmount,
    externalPaymentId: externalPaymentId ?? this.externalPaymentId,
  );
}

enum LedgerEntryType {
  /// Credit after finalized payment or earned grant.
  credit,

  /// Debit for theme unlock / support.
  debit,

  /// Refund / chargeback / cancel offset — never mutates prior rows.
  reversal,
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.userId,
    required this.currency,
    required this.type,
    required this.amount,
    required this.idempotencyKey,
    required this.createdAt,
    this.orderId,
    this.productId,
    this.reversesEntryId,
    this.note,
  });

  final String id;
  final String userId;
  final CurrencyKind currency;

  /// Magnitude rules:
  /// - [LedgerEntryType.credit] / [LedgerEntryType.debit]: positive amount
  /// - [LedgerEntryType.reversal]: signed adjustment (negative when reversing a credit)
  final int amount;
  final LedgerEntryType type;
  final String idempotencyKey;
  final DateTime createdAt;
  final String? orderId;
  final String? productId;
  final String? reversesEntryId;
  final String? note;

  int get signedDelta => switch (type) {
    LedgerEntryType.credit => amount,
    LedgerEntryType.debit => -amount,
    LedgerEntryType.reversal => amount,
  };
}

class WalletProjection {
  const WalletProjection({
    required this.userId,
    required this.premium,
    required this.earned,
  });

  final String userId;

  /// May be negative after refund reversal when Astra was already spent.
  final int premium;
  final int earned;

  int of(CurrencyKind kind) => switch (kind) {
    CurrencyKind.premium => premium,
    CurrencyKind.earned => earned,
  };

  /// Further Astra spend is blocked while premium cannot cover [price]
  /// (includes negative balance).
  bool canSpendPremium(int price) => premium >= price;
}

/// Permanent unlock (theme, etc.). Separate from currency spend rows.
class CommerceEntitlement {
  const CommerceEntitlement({
    required this.userId,
    required this.key,
    required this.grantedAt,
    required this.sourceProductId,
    required this.idempotencyKey,
  });

  final String userId;
  final String key;
  final DateTime grantedAt;
  final String sourceProductId;
  final String idempotencyKey;
}

/// Result of FinalizeTxn (or equivalent completed confirmation) — not a
/// GetReport SETTLEMENT row.
class PaymentFinalization {
  const PaymentFinalization({
    required this.externalPaymentId,
    required this.orderId,
    required this.succeeded,
  });

  final String externalPaymentId;
  final String orderId;
  final bool succeeded;
}
