import 'package:akasha_commerce_server/akasha_commerce_server.dart';

/// Test-only Steam sandbox transport. It never performs network requests.
class InMemorySteamSandboxTransport implements SteamHttpTransport {
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
