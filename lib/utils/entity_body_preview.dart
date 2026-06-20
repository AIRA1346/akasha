/// Entity journal body → gallery card preview (120 chars).
abstract final class EntityBodyPreview {
  static String format(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}…';
  }
}
