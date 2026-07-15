enum SteamInventoryRewardStatus {
  granted,
  notEligible,
  rejected,
  failed,
  indeterminate,
}

class SteamInventoryRewardResult {
  const SteamInventoryRewardResult({
    required this.status,
    this.providerHandle,
    this.reportedGrantQuantity = 0,
    this.issueCode,
  });

  final SteamInventoryRewardStatus status;
  final String? providerHandle;
  final int reportedGrantQuantity;
  final String? issueCode;
}

/// Narrow Steam capability for provider-verified playtime reward evaluation.
abstract interface class SteamInventoryRewardPort {
  Future<SteamInventoryRewardResult> triggerPlaytimeReward({
    required int generatorItemDefId,
    required int expectedItemDefId,
  });
}
