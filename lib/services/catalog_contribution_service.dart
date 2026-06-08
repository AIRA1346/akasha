import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/catalog_contribution_config.dart';
import '../models/catalog_contribution.dart';
import '../utils/catalog_contribution_export.dart';

/// 유저 카탈로그 제안 로컬 큐 (글로벌 DB 직접 쓰기 없음)
class CatalogContributionService {
  static final CatalogContributionService instance =
      CatalogContributionService._();
  CatalogContributionService._();

  static const String _fileName = 'catalog_contributions.json';

  final List<CatalogContribution> _pending = [];
  bool _loaded = false;

  List<CatalogContribution> get pending => List.unmodifiable(_pending);

  int get pendingCount => _pending.length;

  bool get isLoaded => _loaded;

  @visibleForTesting
  void resetForTesting() {
    _pending.clear();
    _loaded = false;
  }

  @visibleForTesting
  void setPendingForTesting(List<CatalogContribution> items) {
    _pending
      ..clear()
      ..addAll(items);
    _loaded = true;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _queueFile();
      if (await file.exists()) {
        final decoded = json.decode(await file.readAsString());
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is Map) {
              _pending.add(
                CatalogContribution.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[CatalogContributionService] load failed: $e');
    }
    _loaded = true;
  }

  Future<CatalogContribution> enqueue(CatalogContribution contribution) async {
    await load();
    _pending.insert(0, contribution);
    await _persist();
    return contribution;
  }

  Future<CatalogContribution> proposeAddWork(
    CatalogAddWorkProposal proposal, {
    String? note,
  }) {
    return enqueue(
      CatalogContribution(
        id: _newId(),
        kind: CatalogContributionKind.addWork,
        createdAt: DateTime.now().toUtc(),
        note: note,
        addWork: proposal,
      ),
    );
  }

  Future<CatalogContribution> proposeFixWork(
    CatalogFixWorkProposal proposal, {
    String? note,
  }) {
    return enqueue(
      CatalogContribution(
        id: _newId(),
        kind: CatalogContributionKind.fixWork,
        createdAt: DateTime.now().toUtc(),
        note: note,
        fixWork: proposal,
      ),
    );
  }

  Future<void> remove(String id) async {
    await load();
    _pending.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> clear() async {
    await load();
    _pending.clear();
    await _persist();
  }

  CatalogContributionBundle buildBundle({
    List<CatalogContribution>? items,
    String appVersion = '1.0.0',
  }) {
    final list = items ?? _pending;
    return CatalogContributionBundle(
      version: CatalogContributionConfig.bundleVersion,
      exportedAt: DateTime.now().toUtc(),
      appVersion: appVersion,
      contributions: List.from(list),
    );
  }

  String exportJson({List<CatalogContribution>? items}) {
    return CatalogContributionExport.bundleToJson(buildBundle(items: items));
  }

  Future<File> writeExportFile({List<CatalogContribution>? items}) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'catalog_exports'));
    await outDir.create(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(outDir.path, 'contributions_$stamp.json'));
    await file.writeAsString(exportJson(items: items));
    return file;
  }

  Future<void> _persist() async {
    final file = await _queueFile();
    await file.parent.create(recursive: true);
    final encoded = json.encode(_pending.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded);
  }

  Future<File> _queueFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  String _newId() {
    final n = Random().nextInt(0xFFFFFF);
    return 'contrib_${DateTime.now().millisecondsSinceEpoch}_${n.toRadixString(16).padLeft(6, '0')}';
  }
}
