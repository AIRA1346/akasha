import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/franchise_group.dart';
import 'works_registry.dart';

/// 같은 IP의 여러 매체 workId를 묶어 관리합니다.
class FranchiseRegistry {
  static const String bundledAsset = 'assets/registry/franchise_groups.json';

  static final Map<String, FranchiseGroup> _groupsById = {};
  static final Map<String, String> _franchiseIdByWorkId = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final raw = await rootBundle.loadString(bundledAsset);
      final decoded = json.decode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (key.toString().startsWith('_')) return;
          if (value is! Map) return;
          final group = FranchiseGroup.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          );
          _groupsById[group.id] = group;
          for (final member in group.members) {
            _franchiseIdByWorkId[member] = group.id;
            final resolved = WorksRegistry.resolveWorkId(member);
            if (resolved.isNotEmpty) {
              _franchiseIdByWorkId[resolved] = group.id;
            }
          }
        });
      }
    } catch (e) {
      print('[FranchiseRegistry] Failed to load franchise groups: $e');
    }
    _initialized = true;
  }

  static FranchiseGroup? groupById(String franchiseId) =>
      _groupsById[franchiseId];

  static FranchiseGroup? groupFor(String workId) {
    if (workId.isEmpty) return null;
    final resolved = WorksRegistry.resolveWorkId(workId);
    final franchiseId =
        _franchiseIdByWorkId[resolved] ?? _franchiseIdByWorkId[workId];
    if (franchiseId == null) return null;
    return _groupsById[franchiseId];
  }

  static bool isSiblingCovered(String workId, Set<String> userWorkIds) {
    final group = groupFor(workId);
    if (group == null) return false;

    final userCanonical = <String>{
      for (final id in userWorkIds) ...{id, WorksRegistry.resolveWorkId(id)},
    };

    for (final member in group.members) {
      final memberResolved = WorksRegistry.resolveWorkId(member);
      if (userCanonical.contains(member) ||
          userCanonical.contains(memberResolved)) {
        return true;
      }
    }
    return false;
  }

  /// 같은 프랜차이즈의 다른 매체 workId (자신 제외)
  static List<String> siblingWorkIds(String workId) {
    final group = groupFor(workId);
    if (group == null) return const [];

    final resolved = WorksRegistry.resolveWorkId(workId);
    return group.members.where((member) {
      final memberResolved = WorksRegistry.resolveWorkId(member);
      return member != workId &&
          member != resolved &&
          memberResolved != workId &&
          memberResolved != resolved;
    }).toList();
  }
}
