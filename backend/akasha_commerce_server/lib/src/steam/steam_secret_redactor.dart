/// Removes Steam publisher credentials from response bodies before auditing.
abstract final class SteamSecretRedactor {
  static String redact(String body) {
    return body
        .replaceAll(RegExp(r'(key|Key)=[^&\s"]+'), 'key=***')
        .replaceAll(RegExp(r'"key"\s*:\s*"[^"]+"'), '"key":"***"');
  }
}
