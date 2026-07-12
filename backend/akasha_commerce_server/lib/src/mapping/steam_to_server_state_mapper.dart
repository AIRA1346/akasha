import '../server_order_state.dart';
import '../steam_txn_phase.dart';

/// Explicit mapping: Steam observations → internal order states.
///
/// Never treat Steam enums and [ServerOrderState] as the same type.
abstract final class SteamToServerStateMapper {
  static ServerOrderState mapPhase(
    SteamTxnPhase phase, {
    required ServerOrderState current,
  }) {
    return switch (phase) {
      SteamTxnPhase.initAccepted => ServerOrderState.authorizationPending,
      SteamTxnPhase.userAuthorized => ServerOrderState.authorized,
      SteamTxnPhase.finalizeSucceeded => ServerOrderState.completed,
      SteamTxnPhase.reportCompleted => ServerOrderState.completed,
      SteamTxnPhase.denied => ServerOrderState.denied,
      SteamTxnPhase.canceled => ServerOrderState.canceled,
      SteamTxnPhase.indeterminate => ServerOrderState.indeterminate,
      SteamTxnPhase.reportSettlement => current, // post-hoc; do not auto-complete
      SteamTxnPhase.reportChargeback => ServerOrderState.chargedBack,
    };
  }

  /// Unknown / unmapped Steam status → indeterminate (manual review).
  static ServerOrderState unknownSteamStatus(ServerOrderState current) =>
      ServerOrderState.indeterminate;
}
