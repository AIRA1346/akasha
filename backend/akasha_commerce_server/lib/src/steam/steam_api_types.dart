import '../steam_txn_phase.dart';

/// Raw Steam Web API envelope preserved for audit (secrets stripped).
class SteamApiResponseAudit {
  const SteamApiResponseAudit({
    required this.method,
    required this.ok,
    required this.receivedAt,
    required this.redactedBody,
    this.httpStatus,
    this.orderId,
  });

  final String method;
  final bool ok;
  final DateTime receivedAt;
  final String redactedBody;
  final int? httpStatus;
  final String? orderId;
}

/// Parsed Steam microtxn / auth outcome before mapping to server state.
class SteamParsedOutcome {
  const SteamParsedOutcome({
    required this.phase,
    this.detail,
    this.audit,
  });

  final SteamTxnPhase phase;
  final String? detail;
  final SteamApiResponseAudit? audit;
}

class SteamHttpResponse {
  const SteamHttpResponse({required this.statusCode, required this.body});
  final int statusCode;
  final String body;
}

/// HTTP transport for Steam Web API calls (server-side only).
abstract class SteamHttpTransport {
  Future<SteamHttpResponse> get(Uri uri);
  Future<SteamHttpResponse> post(Uri uri, Map<String, String> fields);
}
