/// Steam microtxn / report phase as observed by the adapter.
/// Kept separate from [ServerOrderState].
enum SteamTxnPhase {
  /// InitTxn accepted; awaiting user authorization.
  initAccepted,

  /// User approved in Steam overlay / checkout.
  userAuthorized,

  /// FinalizeTxn succeeded.
  finalizeSucceeded,

  /// FinalizeTxn / InitTxn denied.
  denied,

  /// User or system canceled before completion.
  canceled,

  /// Network / ambiguous response — needs QueryTxn or GetReport.
  indeterminate,

  /// GetReport (or QueryTxn) confirms completed after ambiguity.
  reportCompleted,

  /// GetReport SETTLEMENT row (post-hoc reconciliation).
  reportSettlement,

  /// GetReport CHARGEBACK / refund row.
  reportChargeback,
}
