import 'secure_commerce_models.dart';
import 'steam_txn_phase.dart';

/// Steam microtxn port. Implementations must run on a secure server —
/// never embed Publisher Web API keys in the Flutter client.
abstract class SteamMicroTxnAdapter {
  Future<SteamAdapterResult> initTxn({
    required String steamId,
    required String orderId,
    required String productId,
    required int premiumGrantAmount,
  });

  Future<SteamAdapterResult> finalizeTxn({
    required String steamId,
    required String orderId,
  });

  Future<SteamAdapterResult> queryTxn({
    required String steamId,
    required String orderId,
  });

  /// Pull GetReport rows after [cursorHighWater].
  Future<List<SteamReportRow>> getReport({
    required String cursorHighWater,
  });
}

class SteamReportRow {
  const SteamReportRow({
    required this.orderId,
    required this.steamId,
    required this.phase,
    required this.reportId,
  });

  final String orderId;
  final String steamId;
  final SteamTxnPhase phase;
  final String reportId;
}
