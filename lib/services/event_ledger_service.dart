import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_vault.dart';
import '../core/archiving/vault_ledger_event.dart';
import '../core/ports/vault_port.dart';

/// Wave 6 W6-1 — `{vault}/.akasha/event_ledger.jsonl` append-only.
class EventLedgerService {
  EventLedgerService({
    VaultPort? vault,
    String? vaultPathOverride,
  })  : _vault = vault ?? AppVault.port,
        _vaultPathOverride = vaultPathOverride;

  static const String akashaDirName = '.akasha';
  static const String ledgerFileName = 'event_ledger.jsonl';

  final VaultPort _vault;
  final String? _vaultPathOverride;

  String? get _vaultPath => _vaultPathOverride ?? _vault.vaultPath;

  Future<void> append(VaultLedgerEvent event) async {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return;

    final dir = Directory(p.join(vaultPath, akashaDirName));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, ledgerFileName));
    await file.writeAsString(
      '${jsonEncode(event.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<VaultLedgerEvent>> readAll() async {
    final vaultPath = _vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return const [];

    final file = File(p.join(vaultPath, akashaDirName, ledgerFileName));
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
