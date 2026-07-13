import 'dart:io';

import '../../../services/workbench_recovery_draft_store.dart';
import '../../../utils/app_log.dart';

/// Classifies recovery-draft I/O failures without OS message coupling.
String classifyRecoveryDraftIoError(Object error) {
  if (error is PathAccessException) return 'permission_denied';
  if (error is PathNotFoundException) return 'path_unavailable';
  if (error is FileSystemException) return 'file_system_error';
  return 'unknown_io_error';
}

/// Per-workspace transition logging for recovery draft save/delete.
///
/// Save and delete are tracked independently. Repeated identical failures do
/// not re-log; recovery after a failure logs once.
class WorkbenchRecoveryDraftIoDiagnostics {
  WorkbenchRecoveryDraftIoDiagnostics({
    required this.kind,
    void Function(String message)? log,
  }) : _log = log ?? appLog;

  final WorkbenchRecoveryRecordKind kind;
  final void Function(String message) _log;

  String? _saveLastErrorCode;
  String? _deleteLastErrorCode;
  bool _saveNeedsRecoveryLog = false;
  bool _deleteNeedsRecoveryLog = false;

  void noteSaveSuccess({required String recordId}) {
    if (!_saveNeedsRecoveryLog) {
      _saveLastErrorCode = null;
      return;
    }
    _saveNeedsRecoveryLog = false;
    _saveLastErrorCode = null;
    _emit(
      operation: 'save',
      recordId: recordId,
      status: 'recovered',
    );
  }

  void noteSaveFailure(Object error, {required String recordId}) {
    final code = classifyRecoveryDraftIoError(error);
    if (_saveNeedsRecoveryLog && _saveLastErrorCode == code) return;
    _saveNeedsRecoveryLog = true;
    _saveLastErrorCode = code;
    _emit(
      operation: 'save',
      recordId: recordId,
      status: 'failed',
      errorCode: code,
    );
  }

  void noteDeleteSuccess({required String recordId}) {
    if (!_deleteNeedsRecoveryLog) {
      _deleteLastErrorCode = null;
      return;
    }
    _deleteNeedsRecoveryLog = false;
    _deleteLastErrorCode = null;
    _emit(
      operation: 'delete',
      recordId: recordId,
      status: 'recovered',
    );
  }

  void noteDeleteFailure(Object error, {required String recordId}) {
    final code = classifyRecoveryDraftIoError(error);
    if (_deleteNeedsRecoveryLog && _deleteLastErrorCode == code) return;
    _deleteNeedsRecoveryLog = true;
    _deleteLastErrorCode = code;
    _emit(
      operation: 'delete',
      recordId: recordId,
      status: 'failed',
      errorCode: code,
    );
  }

  /// Runs [store.save] without propagating errors to the caller.
  Future<void> runSave({
    required WorkbenchRecoveryDraftStore store,
    required String vaultPath,
    required WorkbenchRecoveryDraft draft,
  }) async {
    try {
      await store.save(vaultPath: vaultPath, draft: draft);
      noteSaveSuccess(recordId: draft.recordId);
    } on Object catch (error) {
      noteSaveFailure(error, recordId: draft.recordId);
    }
  }

  /// Runs [store.delete] without propagating errors to the caller.
  Future<void> runDelete({
    required WorkbenchRecoveryDraftStore store,
    required String vaultPath,
    required String recordId,
  }) async {
    try {
      await store.delete(
        vaultPath: vaultPath,
        kind: kind,
        recordId: recordId,
      );
      noteDeleteSuccess(recordId: recordId);
    } on Object catch (error) {
      noteDeleteFailure(error, recordId: recordId);
    }
  }

  void _emit({
    required String operation,
    required String recordId,
    required String status,
    String? errorCode,
  }) {
    final safeId = sanitizeRecoveryDraftRecordIdForLog(recordId);
    final codePart = errorCode == null ? '' : ' errorCode=$errorCode';
    try {
      _log(
        '[WorkbenchRecoveryDraft] kind=${kind.name} operation=$operation '
        'recordId=$safeId status=$status$codePart',
      );
    } on Object {
      // Logging must never affect draft save/delete callers.
    }
  }
}

String sanitizeRecoveryDraftRecordIdForLog(String recordId) {
  final safe = recordId
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'\.{2,}'), '.')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
  if (safe.isEmpty) return 'unknown';
  if (safe.length > 64) return safe.substring(0, 64);
  return safe;
}
