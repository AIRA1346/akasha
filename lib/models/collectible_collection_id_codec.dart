import 'dart:math';

/// User-local CollectibleCollection IDs — `col_u_{8}`.
abstract final class CollectibleCollectionIdCodec {
  static const String _alphabet = '0123456789abcdefghijklmnopqrstuv';

  static String buildUserLocal({String? suffix}) {
    if (suffix != null && suffix.length == 8) {
      return 'col_u_$suffix';
    }
    final rng = Random.secure();
    final buf = StringBuffer('col_u_');
    for (var i = 0; i < 8; i++) {
      buf.write(_alphabet[rng.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }

  static bool isUserLocalId(String id) =>
      RegExp(r'^col_u_[a-z0-9]{8}$').hasMatch(id.trim());
}
