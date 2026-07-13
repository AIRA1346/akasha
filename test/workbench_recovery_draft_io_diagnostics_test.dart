import 'dart:io';

import 'package:akasha/features/workbench/presentation/workbench_recovery_draft_io_diagnostics.dart';
import 'package:akasha/services/workbench_recovery_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> logs;
  late WorkbenchRecoveryDraftIoDiagnostics diagnostics;

  setUp(() {
    logs = <String>[];
    diagnostics = WorkbenchRecoveryDraftIoDiagnostics(
      kind: WorkbenchRecoveryRecordKind.work,
      log: logs.add,
    );
  });

  test('first save failure logs once', () {
    diagnostics.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    expect(logs, hasLength(1));
    expect(logs.single, contains('operation=save'));
    expect(logs.single, contains('status=failed'));
    expect(logs.single, contains('kind=work'));
    expect(logs.single, contains('recordId=wk_u_draft01'));
  });

  test('repeated identical save failures stay at one log', () {
    final error = const FileSystemException('disk');
    for (var i = 0; i < 5; i++) {
      diagnostics.noteSaveFailure(error, recordId: 'wk_u_draft01');
    }
    expect(logs, hasLength(1));
  });

  test('changed save failure code logs again', () {
    diagnostics.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteSaveFailure(
      const PathAccessException('x', OSError('denied', 5), 'path'),
      recordId: 'wk_u_draft01',
    );
    expect(logs, hasLength(2));
    expect(logs.last, contains('status=failed'));
    expect(logs[0], isNot(equals(logs[1])));
  });

  test('save success after failure logs recovered once', () {
    diagnostics.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    expect(logs, hasLength(2));
    expect(logs.last, contains('operation=save'));
    expect(logs.last, contains('status=recovered'));
  });

  test('continued save success after recovery does not log', () {
    diagnostics.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    expect(logs, hasLength(2));
  });

  test('delete failures follow the same transition rules', () {
    diagnostics.noteDeleteFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteDeleteFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteDeleteFailure(
      const PathNotFoundException('gone', OSError(), 'path'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteDeleteSuccess(recordId: 'wk_u_draft01');
    diagnostics.noteDeleteSuccess(recordId: 'wk_u_draft01');

    expect(logs, hasLength(3));
    expect(logs[0], contains('operation=delete'));
    expect(logs[0], contains('status=failed'));
    expect(logs[1], contains('operation=delete'));
    expect(logs[1], contains('status=failed'));
    expect(logs[2], contains('operation=delete'));
    expect(logs[2], contains('status=recovered'));
  });

  test('save and delete failure states are independent', () {
    diagnostics.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'wk_u_draft01',
    );
    diagnostics.noteDeleteSuccess(recordId: 'wk_u_draft01');
    expect(logs, hasLength(1));
    expect(logs.single, contains('operation=save'));
    expect(logs.single, isNot(contains('status=recovered')));

    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    expect(logs, hasLength(2));
    expect(logs.last, contains('operation=save'));
    expect(logs.last, contains('status=recovered'));
  });

  test('entity kind uses the same policy', () {
    final entityLogs = <String>[];
    final entity = WorkbenchRecoveryDraftIoDiagnostics(
      kind: WorkbenchRecoveryRecordKind.entity,
      log: entityLogs.add,
    );
    entity.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'pe_u_draft01',
    );
    entity.noteSaveFailure(
      const FileSystemException('disk'),
      recordId: 'pe_u_draft01',
    );
    entity.noteSaveSuccess(recordId: 'pe_u_draft01');
    expect(entityLogs, hasLength(2));
    expect(entityLogs.first, contains('kind=entity'));
    expect(entityLogs.last, contains('status=recovered'));
  });

  test('happy path success never logs', () {
    diagnostics.noteSaveSuccess(recordId: 'wk_u_draft01');
    diagnostics.noteDeleteSuccess(recordId: 'wk_u_draft01');
    expect(logs, isEmpty);
  });

  test('logs omit body title absolute path and long exception text', () {
    const secretBody = 'SECRET_DRAFT_BODY_CONTENT';
    const secretTitle = 'Secret Title Should Not Appear';
    const absPath = r'C:\Users\secret\vault\system\drafts\work_x.json';
    diagnostics.noteSaveFailure(
      FileSystemException('cannot write $secretBody $secretTitle at $absPath'),
      recordId: 'wk_u_draft01',
    );
    final line = logs.single;
    expect(line, isNot(contains(secretBody)));
    expect(line, isNot(contains(secretTitle)));
    expect(line, isNot(contains(r'C:\Users')));
    expect(line, isNot(contains(absPath)));
    expect(line, isNot(contains('cannot write')));
    expect(line, contains('errorCode='));
  });

  test('classifyRecoveryDraftIoError uses stable exception classes', () {
    expect(
      classifyRecoveryDraftIoError(const PathAccessException('', OSError(), '')),
      'permission_denied',
    );
    expect(
      classifyRecoveryDraftIoError(const PathNotFoundException('', OSError(), '')),
      'path_unavailable',
    );
    expect(
      classifyRecoveryDraftIoError(const FileSystemException('x')),
      'file_system_error',
    );
    expect(classifyRecoveryDraftIoError(StateError('x')), 'unknown_io_error');
  });

  test('runSave and runDelete never throw to the caller', () async {
    final store = _ThrowingRecoveryDraftStore();
    await expectLater(
      diagnostics.runSave(
        store: store,
        vaultPath: r'C:\vault',
        draft: WorkbenchRecoveryDraft(
          kind: WorkbenchRecoveryRecordKind.work,
          recordId: 'wk_u_draft01',
          updatedAt: DateTime.utc(2026, 7, 13),
          bodyText: 'SECRET_BODY',
          fileText: 'SECRET_FILE',
          title: 'SECRET_TITLE',
        ),
      ),
      completes,
    );
    await expectLater(
      diagnostics.runDelete(
        store: store,
        vaultPath: r'C:\vault',
        recordId: 'wk_u_draft01',
      ),
      completes,
    );
    expect(logs, hasLength(2));
    for (final line in logs) {
      expect(line, isNot(contains('SECRET_')));
      expect(line, isNot(contains(r'C:\vault')));
    }
  });

  test('logging failures do not propagate from runSave or runDelete', () async {
    final throwingLog = WorkbenchRecoveryDraftIoDiagnostics(
      kind: WorkbenchRecoveryRecordKind.work,
      log: (_) => throw StateError('log sink failed'),
    );
    final store = _ThrowingRecoveryDraftStore();
    await expectLater(
      throwingLog.runSave(
        store: store,
        vaultPath: r'C:\vault',
        draft: WorkbenchRecoveryDraft(
          kind: WorkbenchRecoveryRecordKind.work,
          recordId: 'wk_u_draft01',
          updatedAt: DateTime.utc(2026, 7, 13),
          bodyText: 'body',
          fileText: 'file',
        ),
      ),
      completes,
    );
    await expectLater(
      throwingLog.runDelete(
        store: store,
        vaultPath: r'C:\vault',
        recordId: 'wk_u_draft01',
      ),
      completes,
    );
  });
}

class _ThrowingRecoveryDraftStore extends WorkbenchRecoveryDraftStore {
  @override
  Future<File> save({
    required String vaultPath,
    required WorkbenchRecoveryDraft draft,
  }) async {
    throw const FileSystemException('injected save failure');
  }

  @override
  Future<void> delete({
    required String vaultPath,
    required WorkbenchRecoveryRecordKind kind,
    required String recordId,
  }) async {
    throw const FileSystemException('injected delete failure');
  }
}
