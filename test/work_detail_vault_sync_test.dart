import 'package:akasha/features/workbench/presentation/work_detail_vault_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkbenchVaultDiskSync.resolveChange', () {
    final known = DateTime(2024, 1, 1, 12);

    test('noOp while saving', () {
      expect(
        WorkbenchVaultDiskSync.resolveChange(
          knownMtime: known,
          fileMtime: known.add(const Duration(hours: 1)),
          isSaving: true,
          isDirty: true,
        ),
        VaultDiskChangeAction.noOp,
      );
    });

    test('noOp when file not newer', () {
      expect(
        WorkbenchVaultDiskSync.resolveChange(
          knownMtime: known,
          fileMtime: known,
          isSaving: false,
          isDirty: false,
        ),
        VaultDiskChangeAction.noOp,
      );
    });

    test('promptReload when dirty and disk newer', () {
      expect(
        WorkbenchVaultDiskSync.resolveChange(
          knownMtime: known,
          fileMtime: known.add(const Duration(seconds: 1)),
          isSaving: false,
          isDirty: true,
        ),
        VaultDiskChangeAction.promptReload,
      );
    });

    test('reload when clean and disk newer', () {
      expect(
        WorkbenchVaultDiskSync.resolveChange(
          knownMtime: known,
          fileMtime: known.add(const Duration(seconds: 1)),
          isSaving: false,
          isDirty: false,
        ),
        VaultDiskChangeAction.reload,
      );
    });
  });

  test('evaluateFileChange sets externalChangePending on conflict', () {
    final sync = WorkbenchVaultDiskSync();
    sync.diskMtime = DateTime(2024, 1, 1);

    final action = sync.evaluateFileChange(
      filePath: null,
      isSaving: false,
      isDirty: true,
    );

    expect(action, VaultDiskChangeAction.noOp);
    expect(sync.externalChangePending, isFalse);
  });
}
