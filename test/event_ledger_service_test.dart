import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/vault_ledger_event.dart';
import 'package:akasha/services/event_ledger_service.dart';

void main() {
  group('EventLedgerService', () {
    late Directory vaultDir;
    late EventLedgerService ledger;

    setUp(() async {
      vaultDir = await Directory.systemTemp.createTemp('akasha_ledger_test_');
      ledger = EventLedgerService(vaultPathOverride: vaultDir.path);
    });

    tearDown(() async {
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('append writes jsonl lines', () async {
      await ledger.append(
        VaultLedgerEvent(
          type: VaultLedgerEventType.vaultReloaded,
          at: DateTime.utc(2026, 6, 19, 12),
          meta: {'itemCount': 3},
        ),
      );
      await ledger.append(
        VaultLedgerEvent(
          type: VaultLedgerEventType.linkIndexRebuilt,
          at: DateTime.utc(2026, 6, 19, 12, 1),
          meta: {'incomingEntities': 2},
        ),
      );

      final events = await ledger.readAll();
      expect(events.length, 2);
      expect(events.first.type, VaultLedgerEventType.vaultReloaded);
      expect(events.last.type, VaultLedgerEventType.linkIndexRebuilt);
      expect(events.first.meta['itemCount'], 3);
    });
  });
}
