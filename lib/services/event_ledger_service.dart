import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_vault.dart';
import '../core/archiving/vault_ledger_event.dart';
import '../core/ports/vault_port.dart';

/// W6-1 — `{vault}/system/logs/event_ledger.jsonl` append-only operational ledger.
///
/// Data boundary: operational audit log (not rebuildable from Markdown).
/// Previously stored at `.akasha/event_ledger.jsonl` — migrated to
/// `system/logs/` to keep `.akasha/` 100% disposable.
class EventLedgerService {
  EventLedgerService({
    VaultPort? vault,
    String? vaultPathOverride,
  })  : _vault = vault ?? AppVault.port,
        _vaultPathOverride = vaultPathOverride;

  static const String systemDirName = 'system';
  static const String logsDirName = 'logs';
  static const String ledgerFileName = 'event_ledger.jsonl';
  // Legacy path kept for migration only.
  static const String _legacyDirName = '.akasha';

  final VaultPort _vault;
  final String? _vaultPathOverride;

  String? get _vaultPath => _vaultPathOverride ?? _vault.vaultPath;

  File _ledgerFile(String vaultPath) => File(
        p.join(vaultPath, systemDirName, logsDirName, ledgerFileName),
      );

  File _legacyFile(String vaultPath) =>
      File(p.join(vaultPath, _legacyDirName, ledgerFileName));

  /// Copies old `.akasha/event_ledger.jsonl` to `system/logs/` without deleting original.
  Future<void> _migrateIfNeeded(String vaultPath) async {
    final newFile = _ledgerFile(vaultPath);
    final oldFile = _legacyFile(vaultPath);

    if (await newFile.exists()) return; // already migrated
    if (!await oldFile.exists()) return; // no legacy file

    // copy → verify → leave old in place
    await newFile.parent.create(recursive: true);
    await oldFile.copy(newFile.path);
    if (!await newFile.exists()) {
      await newFile.delete().catchError((_) => newFile as FileSystemEntity);
    }
    // Old file intentionally left at .akasha/ (not deleted).
  }

  Future<void> append(VaultLedgerEvent event) async {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return;

    await _migrateIfNeeded(vaultPath);
    final file = _ledgerFile(vaultPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(event.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<VaultLedgerEvent>> readAll() async {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    await _migrateIfNeeded(vaultPath);
    final file = _ledgerFile(vaultPath);
    if (!await file.exists()) return const [];

    final lines = await file.readAsLines();
    final events = <VaultLedgerEvent>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        events.add(
          VaultLedgerEvent.fromJson(
            jsonDecode(trimmed) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // skip malformed lines
      }
    }
    return events;
  }
}

