import '../secure_commerce_models.dart';
import '../steam_adapter.dart';
import '../steam_txn_phase.dart';
import 'steam_api_types.dart';
import 'steam_publisher_credentials.dart';

/// Sandbox Steam microtxn adapter (ISteamMicroTxnSandbox).
///
/// Secrets come only from [SteamPublisherCredentials]. Never log the raw key.
class SandboxSteamMicroTxnAdapter implements SteamMicroTxnAdapter {
  SandboxSteamMicroTxnAdapter({
    required this.credentials,
    required this.transport,
    List<SteamApiResponseAudit>? auditLog,
    List<SteamReportRow>? reportQueue,
  }) : auditLog = auditLog ?? <SteamApiResponseAudit>[],
       reportQueue = reportQueue ?? <SteamReportRow>[];

  final SteamPublisherCredentials credentials;
  final SteamHttpTransport transport;
  final List<SteamApiResponseAudit> auditLog;
  final List<SteamReportRow> reportQueue;

  String get _iface =>
      credentials.useSandbox ? 'ISteamMicroTxnSandbox' : 'ISteamMicroTxn';

  Uri _uri(String method, Map<String, String> query) {
    return Uri.https('partner.steam-api.com', '/$_iface/$method/v2/', {
      'key': credentials.webApiKey,
      'appid': '${credentials.appId}',
      ...query,
    });
  }

  void _record(SteamApiResponseAudit audit) => auditLog.add(audit);

  static String redact(String body) => HttpSteamTicketAuthenticatorRedactor.redact(
        body,
      );

  SteamTxnPhase _parseResultBody(String body, {required SteamTxnPhase onOk}) {
    if (body.contains('Indeterminate') ||
        body.contains('"result":"Pending"') ||
        body.contains('"status":"Pending"')) {
      return SteamTxnPhase.indeterminate;
    }
    if (body.contains('Denied') || body.contains('"status":"Failed"')) {
      return SteamTxnPhase.denied;
    }
    if (body.contains('Canceled') || body.contains('Cancelled')) {
      return SteamTxnPhase.canceled;
    }
    if (body.contains('"result":"OK"') ||
        body.contains('"status":"Succeeded"') ||
        body.contains('OK')) {
      return onOk;
    }
    // Unknown Steam status → never auto-complete.
    return SteamTxnPhase.indeterminate;
  }

  @override
  Future<SteamAdapterResult> initTxn({
    required String steamId,
    required String orderId,
    required String productId,
    required int premiumGrantAmount,
  }) async {
    final uri = _uri('InitTxn', {
      'steamid': steamId,
      'orderid': orderId,
      'itemcount': '1',
      'amount[0]': '${premiumGrantAmount * 100}',
      'description[0]': productId,
    });
    final response = await transport.post(uri, {});
    _record(
      SteamApiResponseAudit(
        method: 'InitTxn',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
        orderId: orderId,
      ),
    );
    if (response.statusCode != 200) {
      return const SteamAdapterResult(phase: SteamTxnPhase.denied);
    }
    return SteamAdapterResult(
      phase: _parseResultBody(
        response.body,
        onOk: SteamTxnPhase.initAccepted,
      ),
    );
  }

  @override
  Future<SteamAdapterResult> finalizeTxn({
    required String steamId,
    required String orderId,
  }) async {
    final uri = _uri('FinalizeTxn', {
      'steamid': steamId,
      'orderid': orderId,
    });
    final response = await transport.post(uri, {});
    _record(
      SteamApiResponseAudit(
        method: 'FinalizeTxn',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
        orderId: orderId,
      ),
    );
    if (response.statusCode != 200) {
      return const SteamAdapterResult(phase: SteamTxnPhase.indeterminate);
    }
    return SteamAdapterResult(
      phase: _parseResultBody(
        response.body,
        onOk: SteamTxnPhase.finalizeSucceeded,
      ),
    );
  }

  @override
  Future<SteamAdapterResult> queryTxn({
    required String steamId,
    required String orderId,
  }) async {
    final uri = _uri('QueryTxn', {
      'steamid': steamId,
      'orderid': orderId,
    });
    final response = await transport.get(uri);
    _record(
      SteamApiResponseAudit(
        method: 'QueryTxn',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
        orderId: orderId,
      ),
    );
    if (response.body.contains('Succeeded') ||
        response.body.contains('"status":"Succeeded"')) {
      return const SteamAdapterResult(phase: SteamTxnPhase.reportCompleted);
    }
    if (response.body.contains('Failed') || response.body.contains('Denied')) {
      return const SteamAdapterResult(phase: SteamTxnPhase.denied);
    }
    return const SteamAdapterResult(phase: SteamTxnPhase.indeterminate);
  }

  Future<SteamAdapterResult> refundTxn({
    required String steamId,
    required String orderId,
  }) async {
    final uri = _uri('RefundTxn', {
      'steamid': steamId,
      'orderid': orderId,
    });
    final response = await transport.post(uri, {});
    _record(
      SteamApiResponseAudit(
        method: 'RefundTxn',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
        orderId: orderId,
      ),
    );
    if (response.body.contains('OK')) {
      return const SteamAdapterResult(phase: SteamTxnPhase.reportChargeback);
    }
    return const SteamAdapterResult(phase: SteamTxnPhase.indeterminate);
  }

  Future<SteamAdapterResult> getUserInfo({required String steamId}) async {
    final uri = _uri('GetUserInfo', {'steamid': steamId});
    final response = await transport.get(uri);
    _record(
      SteamApiResponseAudit(
        method: 'GetUserInfo',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
      ),
    );
    if (response.statusCode == 200 &&
        (response.body.contains('OK') || response.body.contains('"result":"OK"'))) {
      return const SteamAdapterResult(phase: SteamTxnPhase.userAuthorized);
    }
    return const SteamAdapterResult(phase: SteamTxnPhase.denied);
  }

  @override
  Future<List<SteamReportRow>> getReport({
    required String cursorHighWater,
  }) async {
    final uri = _uri('GetReport', {
      'type': 'GAMESALES',
      'time': cursorHighWater,
    });
    final response = await transport.get(uri);
    _record(
      SteamApiResponseAudit(
        method: 'GetReport',
        ok: response.statusCode == 200,
        receivedAt: DateTime.now().toUtc(),
        redactedBody: redact(response.body),
        httpStatus: response.statusCode,
      ),
    );
    // Harness / tests enqueue rows; production JSON parse lands later.
    final rows = List<SteamReportRow>.from(reportQueue);
    reportQueue.clear();
    return rows;
  }
}

/// Shared redactor (avoid importing auth from steam adapter cyclically).
abstract final class HttpSteamTicketAuthenticatorRedactor {
  static String redact(String body) {
    return body
        .replaceAll(RegExp(r'(key|Key)=[^&\s"]+'), 'key=***')
        .replaceAll(RegExp(r'"key"\s*:\s*"[^"]+"'), '"key":"***"');
  }
}

/// In-memory Steam sandbox transport (no network, no real key required).
class InMemorySteamSandboxTransport implements SteamHttpTransport {
  InMemorySteamSandboxTransport();

  final Map<String, String> orderStatus = {};
  bool nextFinalizeIndeterminate = false;
  int getReportCalls = 0;

  @override
  Future<SteamHttpResponse> get(Uri uri) async {
    final path = uri.path;
    if (path.contains('QueryTxn')) {
      final orderId = uri.queryParameters['orderid'] ?? '';
      final status = orderStatus[orderId] ?? 'Pending';
      return SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK","params":{"status":"$status"}}}',
      );
    }
    if (path.contains('GetUserInfo')) {
      return const SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK"}}',
      );
    }
    if (path.contains('GetReport')) {
      getReportCalls++;
      return const SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK","params":{"orders":[]}}}',
      );
    }
    if (path.contains('AuthenticateUserTicket')) {
      return const SteamHttpResponse(statusCode: 403, body: '{}');
    }
    return const SteamHttpResponse(statusCode: 404, body: '{}');
  }

  @override
  Future<SteamHttpResponse> post(Uri uri, Map<String, String> fields) async {
    final path = uri.path;
    final orderId = uri.queryParameters['orderid'] ?? '';
    if (path.contains('InitTxn')) {
      orderStatus[orderId] = 'Init';
      return const SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK"}}',
      );
    }
    if (path.contains('FinalizeTxn')) {
      if (nextFinalizeIndeterminate) {
        nextFinalizeIndeterminate = false;
        return const SteamHttpResponse(
          statusCode: 200,
          body: '{"response":{"result":"Pending"}}',
        );
      }
      orderStatus[orderId] = 'Succeeded';
      return const SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK"}}',
      );
    }
    if (path.contains('RefundTxn')) {
      orderStatus[orderId] = 'Refunded';
      return const SteamHttpResponse(
        statusCode: 200,
        body: '{"response":{"result":"OK"}}',
      );
    }
    return const SteamHttpResponse(statusCode: 404, body: '{}');
  }
}
