// Discovery Contract Test KPI — 수집량이 아닌 계약 준수 지표.
library;

class DiscoveryContractKpi {
  final int fetched;
  final int policyRejected;
  final int dedupeCandidates;
  final int minimalCoreDrafts;
  final int missingTitle;
  final int missingYearOrExternalId;

  const DiscoveryContractKpi({
    this.fetched = 0,
    this.policyRejected = 0,
    this.dedupeCandidates = 0,
    this.minimalCoreDrafts = 0,
    this.missingTitle = 0,
    this.missingYearOrExternalId = 0,
  });

  bool get contractPassed =>
      policyRejected == 0 &&
      missingTitle == 0 &&
      missingYearOrExternalId == 0 &&
      minimalCoreDrafts + dedupeCandidates == fetched;

  Map<String, dynamic> toJson() => {
        'fetched': fetched,
        'policyRejected': policyRejected,
        'dedupeCandidates': dedupeCandidates,
        'minimalCoreDrafts': minimalCoreDrafts,
        'missingTitle': missingTitle,
        'missingYearOrExternalId': missingYearOrExternalId,
        'contractPassed': contractPassed,
      };
}
