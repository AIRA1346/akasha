import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/ports/entity_registry_port.dart';
import '../models/entity_fact.dart';

/// Bundled Person MVP seed ([wave4-entity-types-spec §6]).
class PersonSeedRegistry implements EntityRegistryPort {
  PersonSeedRegistry._();
  static final PersonSeedRegistry instance = PersonSeedRegistry._();

  static const String assetPath = 'assets/entities/person_seed.json';

  final List<EntityFact> _entities = [];
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _entities.clear();

    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final list = decoded['entities'];
        if (list is List) {
          for (final entry in list) {
            if (entry is Map) {
              final fact = EntityFact.fromJson(Map<String, dynamic>.from(entry));
              if (fact.entityId.isNotEmpty) {
                _entities.add(fact);
              }
            }
          }
        }
      }
    } catch (_) {
      // offline / missing asset — empty registry OK
    }

    _initialized = true;
  }

  @visibleForTesting
  void resetForTesting() {
    _entities.clear();
    _initialized = false;
  }

  @visibleForTesting
  void seedForTesting(List<EntityFact> facts) {
    _entities
      ..clear()
      ..addAll(facts);
    _initialized = true;
  }

  @override
  EntityFact? getById(String entityId) {
    for (final entity in _entities) {
      if (entity.entityId == entityId) return entity;
    }
    return null;
  }

  @override
  List<EntityFact> search(String query, {EntityAnchorType? type}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final q = trimmed.toLowerCase();
    return _entities.where((entity) {
      if (type != null && entity.entityType != type) return false;
      return entity.matchesQuery(q);
    }).toList();
  }

  /// 전체 seed 목록 (Entity Link Picker Cold Graph용).
  List<EntityFact> listFacts({EntityAnchorType? type}) {
    if (!_initialized) return const [];
    return _entities
        .where((entity) => type == null || entity.entityType == type)
        .toList();
  }
}
