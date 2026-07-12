import 'steam_txn_phase.dart';

class CommerceAuditRecord {
  const CommerceAuditRecord({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.steamId,
    this.orderId,
    this.steamPhase,
    this.detail,
  });

  final String id;
  final DateTime createdAt;
  final String action;
  final String steamId;
  final String? orderId;
  final SteamTxnPhase? steamPhase;
  final String? detail;
}
