/// Server commerce account keyed by SteamID (authority lives on the server).
class CommerceAccount {
  const CommerceAccount({
    required this.steamId,
    required this.createdAt,
  });

  /// SteamID64 as decimal string (stable account key).
  final String steamId;
  final DateTime createdAt;
}
