import 'order_id64.dart';
import 'server_order_state.dart';
import 'steam_txn_phase.dart';

class SecureCommerceOrder {
  const SecureCommerceOrder({
    required this.orderId,
    required this.steamId,
    required this.productId,
    required this.state,
    required this.idempotencyKey,
    required this.createdAt,
    this.premiumGrantAmount,
    this.lastSteamPhase,
    this.updatedAt,
  });

  final OrderId64 orderId;
  final String steamId;
  final String productId;
  final ServerOrderState state;
  final String idempotencyKey;
  final DateTime createdAt;
  final int? premiumGrantAmount;
  final SteamTxnPhase? lastSteamPhase;
  final DateTime? updatedAt;

  String get orderIdKey => orderId.toString();

  SecureCommerceOrder copyWith({
    ServerOrderState? state,
    SteamTxnPhase? lastSteamPhase,
    DateTime? updatedAt,
  }) => SecureCommerceOrder(
    orderId: orderId,
    steamId: steamId,
    productId: productId,
    state: state ?? this.state,
    idempotencyKey: idempotencyKey,
    createdAt: createdAt,
    premiumGrantAmount: premiumGrantAmount,
    lastSteamPhase: lastSteamPhase ?? this.lastSteamPhase,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class SteamAdapterResult {
  const SteamAdapterResult({
    required this.phase,
    this.detail,
  });

  final SteamTxnPhase phase;
  final String? detail;

  bool get isFinalizeSuccess => phase == SteamTxnPhase.finalizeSucceeded;
  bool get isCompletedConfirmation =>
      phase == SteamTxnPhase.finalizeSucceeded ||
      phase == SteamTxnPhase.reportCompleted;
}
