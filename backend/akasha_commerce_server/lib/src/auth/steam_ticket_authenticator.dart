/// Verified Steam identity — only produced after AuthenticateUserTicket.
class VerifiedSteamIdentity {
  const VerifiedSteamIdentity({
    required this.steamId64,
    required this.appId,
  });

  final String steamId64;
  final int appId;
}

/// Port for Steam ISteamUserAuth/AuthenticateUserTicket.
abstract class SteamTicketAuthenticator {
  Future<VerifiedSteamIdentity> authenticateUserTicket({
    required String ticketHex,
    required int expectedAppId,
  });
}

/// Auth failures (ticket invalid/expired/reuse/AppID mismatch).
class SteamAuthException implements Exception {
  const SteamAuthException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'SteamAuthException($code): $message';
}
