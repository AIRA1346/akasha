/// Vault `.md` 파일명 — Windows 금지 문자 제거.
abstract final class VaultSafeFilename {
  static String fromTitle(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
