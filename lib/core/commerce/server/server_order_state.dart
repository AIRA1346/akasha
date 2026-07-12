/// Internal commerce order lifecycle.
///
/// Do **not** merge these with [SteamTxnPhase] — Steam responses map into
/// transitions; they are not the same enum.
enum ServerOrderState {
  created,
  authorizationPending,
  authorized,
  finalizing,
  completed,
  denied,
  canceled,
  indeterminate,
  refunded,
  chargedBack,
}

extension ServerOrderStateX on ServerOrderState {
  bool get isTerminal => switch (this) {
    ServerOrderState.completed ||
    ServerOrderState.denied ||
    ServerOrderState.canceled ||
    ServerOrderState.refunded ||
    ServerOrderState.chargedBack => true,
    _ => false,
  };

  bool get allowsPremiumGrant => this == ServerOrderState.completed;
}
