import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/app_vault.dart';
import '../core/ports/user_catalog_port.dart';
import '../core/archiving/entity_anchor.dart';
import '../models/entity_id_codec.dart';
import '../models/enums.dart';
import '../models/user_catalog_entity.dart';

/// Tier 1.5 user catalog — `{vault}/catalog/user_entities.json`.
class UserCatalogStore implements UserCatalogPort {
  UserCatalogStore._();
  static final UserCatalogStore instance = UserCatalogStore._();

  static const String catalogFileName = 'user_entities.json';
  static const int schemaVersion = 2;

  final List<UserCatalogEntity> _entities = [];
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  @visibleForTesting
  void resetForTesting() {
    _entities.clear();
  }

  @visibleForTesting
  void setEntitiesForTesting(List<UserCatalogEntity> items) {
    _entities
      ..clear()
      ..addAll(items);
  }

  @override
  List<UserCatalogEntity> get all => List.unmodifiable(_entities);

  @override
  Stream<void> get onChanged => _changeController.stream;

  @override
  Future<void> load() async {
    _entities.clear();
    final vault = AppVault.port.vaultPath;
    if (vault == null || vault.isEmpty) {
      return;
    }

    final file = _catalogFile(vault);
    if (!await file.exists()) {
      return;
    }

    try {
      final decoded = json.decode(await file.readAsString());
      if (decoded is Map) {
        final list = decoded['entities'];
        if (list is List) {
          for (final entry in list) {
            if (entry is Map) {
              final entity = UserCatalogEntity.fromJson(
                Map<String, dynamic>.from(entry),
              );
              if (entity.entityId.isNotEmpty &&
                  EntityIdCodec.isUserLocalAny(entity.entityId)) {
                _entities.add(entity);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[UserCatalogStore] load failed: $e');
    }
  }

  @override
  UserCatalogEntity? getById(String entityId) {
    for (final entity in _entities) {
      if (entity.entityId == entityId) return entity;
    }
    return null;
  }

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final q = trimmed.toLowerCase();
    return _entities.where((entity) {
      if (entityType != null && entity.anchorType != entityType) return false;
      if (subtype != null && entity.isWorkEntity && entity.subtype != subtype) {
        return false;
      }
      return entity.matchesQuery(q);
    }).toList();
  }

  @override
  Future<void> upsert(UserCatalogEntity entity) async {
    await load();
    final index = _entities.indexWhere((e) => e.entityId == entity.entityId);
    if (index >= 0) {
      _entities[index] = entity;
    } else {
      _entities.add(entity);
    }
    await _persist();
    _changeController.add(null);
  }

  @override
  Future<void> remove(String entityId) async {
    await load();
    _entities.removeWhere((e) => e.entityId == entityId);
    await _persist();
    _changeController.add(null);
  }

  Future<void> reloadFromVault() => load();

  Future<void> _persist() async {
    final vault = AppVault.port.vaultPath;
    if (vault == null || vault.isEmpty) return;

    final catalogDir = Directory(p.join(vault, 'catalog'));
    await catalogDir.create(recursive: true);
    final file = _catalogFile(vault);
    final payload = json.encode({
      'version': schemaVersion,
      'entities': _entities.map((e) => e.toJson()).toList(),
    });

    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload);
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
    await AppVault.port.signalVaultChanged();
  }

  File _catalogFile(String vaultPath) =>
      File(p.join(vaultPath, 'catalog', catalogFileName));
}
