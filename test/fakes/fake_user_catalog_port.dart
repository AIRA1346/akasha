import 'dart:async';

import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';

class FakeUserCatalogPort implements UserCatalogPort {
  final List<UserCatalogEntity> _entities = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void seed(List<UserCatalogEntity> entities) {
    _entities
      ..clear()
      ..addAll(entities);
  }

  @override
  Future<void> load() async {}

  @override
  List<UserCatalogEntity> get all => List.unmodifiable(_entities);

  @override
  List<UserCatalogEntity> search(String query, {MediaCategory? subtype}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _entities.where((entity) {
      if (subtype != null && entity.subtype != subtype) return false;
      return entity.matchesQuery(q);
    }).toList();
  }

  @override
  UserCatalogEntity? getById(String entityId) {
    for (final entity in _entities) {
      if (entity.entityId == entityId) return entity;
    }
    return null;
  }

  @override
  Future<void> upsert(UserCatalogEntity entity) async {
    final index = _entities.indexWhere((e) => e.entityId == entity.entityId);
    if (index >= 0) {
      _entities[index] = entity;
    } else {
      _entities.add(entity);
    }
    _changes.add(null);
  }

  @override
  Future<void> remove(String entityId) async {
    _entities.removeWhere((e) => e.entityId == entityId);
    _changes.add(null);
  }

  @override
  Stream<void> get onChanged => _changes.stream;
}
