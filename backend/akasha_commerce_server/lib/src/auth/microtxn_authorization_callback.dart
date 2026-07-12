import '../order_id64.dart';

/// Client → backend payload after Steam overlay MicroTxnAuthorizationResponse_t.
///
/// The backend must correlate AppID + OrderID + verified SteamID.
/// Any client-claimed SteamID string is ignored for authority.
class MicroTxnAuthorizationCallback {
  const MicroTxnAuthorizationCallback({
    required this.appId,
    required this.orderId,
    required this.authorized,
    this.clientClaimedSteamId,
  });

  final int appId;
  final OrderId64 orderId;
  final bool authorized;

  /// Informational only — never used as commerce account authority.
  final String? clientClaimedSteamId;
}
