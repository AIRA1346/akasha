import '../steam/steam_api_types.dart';
import '../steam/steam_publisher_credentials.dart';
import 'steam_ticket_authenticator.dart';

/// Sandbox/test authenticator — never trusts client-supplied SteamID strings.
class SandboxSteamTicketAuthenticator implements SteamTicketAuthenticator {
  SandboxSteamTicketAuthenticator({
    required this.credentials,
    Map<String, VerifiedSteamIdentity>? ticketDirectory,
    Set<String>? usedTickets,
  }) : ticketDirectory = ticketDirectory ?? {},
       usedTickets = usedTickets ?? {};

  final SteamPublisherCredentials credentials;
  final Map<String, VerifiedSteamIdentity> ticketDirectory;
  final Set<String> usedTickets;

  /// Register a one-time ticket for sandbox E2E (tests / local harness only).
  void issueSandboxTicket(String ticketHex, VerifiedSteamIdentity identity) {
    ticketDirectory[ticketHex] = identity;
  }

  @override
  Future<VerifiedSteamIdentity> authenticateUserTicket({
    required String ticketHex,
    required int expectedAppId,
  }) async {
    if (ticketHex.trim().isEmpty) {
      throw const SteamAuthException('ticket_empty', 'Auth ticket is empty.');
    }
    if (usedTickets.contains(ticketHex)) {
      throw const SteamAuthException(
        'ticket_reuse',
        'Auth ticket was already consumed.',
      );
    }
    final identity = ticketDirectory[ticketHex];
    if (identity == null) {
      throw const SteamAuthException(
        'ticket_invalid',
        'AuthenticateUserTicket failed (unknown/expired ticket).',
      );
    }
    if (identity.appId != expectedAppId) {
      throw SteamAuthException(
        'appid_mismatch',
        'Ticket AppID ${identity.appId} != expected $expectedAppId.',
      );
    }
    if (expectedAppId != credentials.appId) {
      throw SteamAuthException(
        'appid_mismatch',
        'Expected AppID $expectedAppId != server AppID ${credentials.appId}.',
      );
    }
    usedTickets.add(ticketHex);
    return identity;
  }
}

/// HTTP-shaped authenticator that posts to Steam (key never logged).
class HttpSteamTicketAuthenticator implements SteamTicketAuthenticator {
  HttpSteamTicketAuthenticator({
    required this.credentials,
    required this.transport,
    List<SteamApiResponseAudit>? auditLog,
  }) : auditLog = auditLog ?? <SteamApiResponseAudit>[];

  final SteamPublisherCredentials credentials;
  final SteamHttpTransport transport;
  final List<SteamApiResponseAudit> auditLog;

  @override
  Future<VerifiedSteamIdentity> authenticateUserTicket({
    required String ticketHex,
    required int expectedAppId,
  }) async {
    final uri = Uri.https(
      'api.steampowered.com',
      '/ISteamUserAuth/AuthenticateUserTicket/v1/',
      {
        'key': credentials.webApiKey,
        'appid': '${credentials.appId}',
        'ticket': ticketHex,
      },
    );
    final response = await transport.get(uri);
    final audit = SteamApiResponseAudit(
      method: 'AuthenticateUserTicket',
      ok: response.statusCode == 200,
      receivedAt: DateTime.now().toUtc(),
      redactedBody: redactSecrets(response.body),
      httpStatus: response.statusCode,
    );
    auditLog.add(audit);
    if (response.statusCode != 200) {
      throw SteamAuthException(
        'ticket_http_error',
        'AuthenticateUserTicket HTTP ${response.statusCode}',
      );
    }
    final steamId = _extractSteamId(response.body);
    if (steamId == null) {
      throw const SteamAuthException(
        'ticket_invalid',
        'AuthenticateUserTicket did not return steamid.',
      );
    }
    final identity = VerifiedSteamIdentity(
      steamId64: steamId,
      appId: credentials.appId,
    );
    if (identity.appId != expectedAppId) {
      throw const SteamAuthException('appid_mismatch', 'AppID mismatch.');
    }
    return identity;
  }

  static String redactSecrets(String body) {
    return body
        .replaceAll(RegExp(r'(key|Key)=[^&\s"]+'), 'key=***')
        .replaceAll(RegExp(r'"key"\s*:\s*"[^"]+"'), '"key":"***"');
  }

  static String? _extractSteamId(String body) {
    final m = RegExp(r'"steamid"\s*:\s*"(\d+)"').firstMatch(body);
    return m?.group(1);
  }
}
