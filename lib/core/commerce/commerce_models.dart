import 'currency_kind.dart';

enum ProductKind {
  /// Steam-settled pack that grants [CurrencyKind.premium].
  premiumPack,

  /// Spend currency → permanent theme entitlement.
  themeUnlock,

  /// Spend [CurrencyKind.premium] only; no entitlement / no gameplay advantage.
  donation,
}

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
}

class CommerceProduct {
  const CommerceProduct({
    required this.id,
    required this.kind,
    required this.payment,
    this.grantPremiumAmount,
    this.entitlementKey,
  });

  final String id;
  final ProductKind kind;
  final PaymentOption payment;

  /// For [ProductKind.premiumPack] — amount of Astra granted after settlement.
  final int? grantPremiumAmount;

  /// For [ProductKind.themeUnlock] — stable entitlement id (not a display name).
  final String? entitlementKey;
}

enum OrderStatus {
  pendingPayment,
  settled,
  refunded,
  failed,
}

class CommerceOrder {
  const CommerceOrder({
    required this.id,
    required this.userId,
    required this.productId,
    required this.status,
    required this.idempotencyKey,
    this.settledPremiumGrant,
    this.externalPaymentId,
  });

  final String id;
  final String userId;
  final String productId;
  final OrderStatus status;
  final String idempotencyKey;
  final int? settledPremiumGrant;
  final String? externalPaymentId;

  CommerceOrder copyWith({
    OrderStatus? status,
    int? settledPremiumGrant,
    String? externalPaymentId,
  }) => CommerceOrder(
    id: id,
    userId: userId,
    productId: productId,
    status: status ?? this.status,
    idempotencyKey: idempotencyKey,
    settledPremiumGrant: settledPremiumGrant ?? this.settledPremiumGrant,
    externalPaymentId: externalPaymentId ?? this.externalPaymentId,
  );
}

enum LedgerEntryType {
  /// Credit after settled payment or earned grant.
  credit,

  /// Debit for theme unlock / donation.
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
  final int premium;
  final int earned;

  int of(CurrencyKind kind) => switch (kind) {
    CurrencyKind.premium => premium,
    CurrencyKind.earned => earned,
  };
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

class PaymentSettlement {
  const PaymentSettlement({
    required this.externalPaymentId,
    required this.orderId,
    required this.succeeded,
  });

  final String externalPaymentId;
  final String orderId;
  final bool succeeded;
}
