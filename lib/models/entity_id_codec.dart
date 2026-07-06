import 'dart:math';

import '../core/archiving/entity_anchor.dart';
import 'work_id_codec.dart';

/// Cross-type entity ID rules — work branch delegates to [WorkIdCodec].
abstract final class EntityIdCodec {
  static const String _userLocalTokenAlphabet =
      '0123456789abcdefghijklmnopqrstuv';

  static const Map<EntityAnchorType, String> _prefixes = {
    EntityAnchorType.work: 'wk',
    EntityAnchorType.person: 'pe',
    EntityAnchorType.event: 'ev',
    EntityAnchorType.concept: 'co',
    EntityAnchorType.place: 'pl',
    EntityAnchorType.organization: 'or',
    EntityAnchorType.object: 'ob',
    // ignore: deprecated_member_use_from_same_package
    EntityAnchorType.custom: 'cu',
  };

  static EntityAnchorType? typeFromId(String entityId) {
    final id = entityId.trim();
    if (id.isEmpty) return null;

    if (WorkIdCodec.isGlobalWorkId(id) ||
        WorkIdCodec.isUserLocalWorkId(id) ||
        WorkIdCodec.isLegacyMasterId(id) ||
        id.startsWith('wk_')) {
      return EntityAnchorType.work;
    }

    if (id.startsWith('cu_')) {
      // Legacy cu_ IDs are treated as object for backward compatibility.
      return EntityAnchorType.object;
    }

    for (final entry in _prefixes.entries) {
      if (entry.key == EntityAnchorType.work) continue;
      // ignore: deprecated_member_use_from_same_package
      if (entry.key == EntityAnchorType.custom) continue;

      if (isGlobalId(id, entry.key) || isUserLocalId(id, entry.key)) {
        return entry.key;
      }
    }

    // Unrecognized ID format defaults to unknown (Spec §3).
    return EntityAnchorType.unknown;
  }

  static bool isUserLocalId(String entityId, EntityAnchorType type) {
    final prefix = _prefixes[type];
    if (prefix == null) return false;
    if (type == EntityAnchorType.work) {
      return WorkIdCodec.isUserLocalWorkId(entityId);
    }
    return RegExp('^${RegExp.escape(prefix)}_u_[a-z0-9]{8}\$').hasMatch(entityId);
  }

  static bool isGlobalId(String entityId, EntityAnchorType type) {
    final prefix = _prefixes[type];
    if (prefix == null) return false;
    if (type == EntityAnchorType.work) {
      return WorkIdCodec.isGlobalWorkId(entityId);
    }
    return RegExp('^${RegExp.escape(prefix)}_\\d{9}\$').hasMatch(entityId);
  }

  static bool isUserLocalAny(String entityId) {
    for (final type in _prefixes.keys) {
      if (isUserLocalId(entityId, type)) return true;
    }
    return false;
  }

  static bool isMasterFormat(String entityId) {
    final type = typeFromId(entityId);
    if (type == null) return false;
    if (type == EntityAnchorType.work) {
      return WorkIdCodec.isMasterFormat(entityId);
    }
    return isGlobalId(entityId, type) || isUserLocalId(entityId, type);
  }

  static String buildUserLocal(EntityAnchorType type, {String? suffix}) {
    if (type == EntityAnchorType.work) {
      return WorkIdCodec.buildUserLocal(suffix: suffix);
    }
    final prefix = _prefixes[type];
    if (prefix == null) {
      throw ArgumentError.value(type, 'type', 'unsupported for user local ID');
    }
    final token = suffix ?? _randomUserLocalToken();
    return '${prefix}_u_$token';
  }

  static String _randomUserLocalToken() {
    final rand = Random.secure();
    return List.generate(
      8,
      (_) => _userLocalTokenAlphabet[rand.nextInt(_userLocalTokenAlphabet.length)],
    ).join();
  }
}
