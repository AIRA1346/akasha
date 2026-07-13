import 'dart:convert';
import 'dart:io';

import '../utils/app_log.dart';

/// Result of opening a derived locator index file for read.
enum DerivedIndexFileStatus {
  /// Target exists (or was restored) and passes validation.
  ready,

  /// No usable target or backup; stale `.tmp` is never promoted.
  missing,

  /// Target and backup are both unusable.
  corrupt,
}

class DerivedIndexFileOpenResult {
  const DerivedIndexFileOpenResult(this.status);

  final DerivedIndexFileStatus status;

  bool get isReady => status == DerivedIndexFileStatus.ready;
  bool get isMissing => status == DerivedIndexFileStatus.missing;
  bool get isCorrupt => status == DerivedIndexFileStatus.corrupt;
}

/// Minimal sibling-temp replace + restart recovery for locator index JSON.
///
/// Naming: `${target.path}.tmp`, `${target.path}.bak`.
class DerivedIndexAtomicWrite {
  const DerivedIndexAtomicWrite({
    this.beforeReplace,
    this.beforeBakRestore,
    this.beforeSidecarCleanup,
  });

  /// Test-only: after temp is verified, before live replace.
  final Future<void> Function(File target)? beforeReplace;

  /// Test-only: after bak is validated, before restore rename/promote.
  final Future<void> Function(File target, File bak)? beforeBakRestore;

  /// Test-only: before deleting stale `.tmp` / `.bak` sidecars.
  final Future<void> Function(File target)? beforeSidecarCleanup;

  static File tempSibling(File target) => File('${target.path}.tmp');

  static File bakSibling(File target) => File('${target.path}.bak');

  /// Opens [target] for read, restoring a valid `.bak` when needed.
  ///
  /// Never promotes `.tmp`. On success, removes stale sidecars.
  Future<DerivedIndexFileOpenResult> openForRead({
    required File target,
    required bool Function(String content) validateContent,
  }) async {
    final temp = tempSibling(target);
    final bak = bakSibling(target);

    final targetState = await _classify(target, validateContent);
    if (targetState == _ContentState.valid) {
      await _cleanupSidecarsBestEffort(
        target: target,
        temp: temp,
        bak: bak,
        deleteBak: true,
        deleteTemp: true,
      );
      return const DerivedIndexFileOpenResult(DerivedIndexFileStatus.ready);
    }

    final bakState = await _classify(bak, validateContent);
    if (bakState == _ContentState.valid) {
      try {
        await _restoreFromBak(
          target: target,
          bak: bak,
          targetState: targetState,
        );
        await _cleanupSidecarsBestEffort(
          target: target,
          temp: temp,
          bak: bak,
          deleteBak: true,
          deleteTemp: true,
        );
        return const DerivedIndexFileOpenResult(DerivedIndexFileStatus.ready);
      } on Object catch (error, stack) {
        appLog(
          '[DerivedIndexAtomicWrite] bak restore failed for ${target.path}: '
          '$error\n$stack',
        );
        // Leave bak in place when restore fails.
        if (targetState == _ContentState.missing &&
            bakState == _ContentState.valid) {
          return const DerivedIndexFileOpenResult(
            DerivedIndexFileStatus.missing,
          );
        }
        return const DerivedIndexFileOpenResult(DerivedIndexFileStatus.corrupt);
      }
    }

    // Do not promote .tmp — completeness cannot be proven.
    if (await temp.exists()) {
      appLog(
        '[DerivedIndexAtomicWrite] ignoring stale tmp for ${target.path}',
      );
      try {
        await temp.delete();
      } on Object catch (error, stack) {
        appLog(
          '[DerivedIndexAtomicWrite] stale tmp delete failed for '
          '${temp.path}: $error\n$stack',
        );
      }
    }

    if (targetState == _ContentState.missing &&
        bakState == _ContentState.missing) {
      return const DerivedIndexFileOpenResult(DerivedIndexFileStatus.missing);
    }
    return const DerivedIndexFileOpenResult(DerivedIndexFileStatus.corrupt);
  }

  Future<void> writeText({
    required File target,
    required String content,
  }) async {
    jsonDecode(content);

    await target.parent.create(recursive: true);
    final temp = tempSibling(target);
    final backup = bakSibling(target);

    if (await temp.exists()) await temp.delete();
    await temp.writeAsString(content, flush: true);
    final written = await temp.readAsString();
    if (written != content) {
      await temp.delete();
      throw StateError('Derived index staged content failed read-back verify.');
    }

    final beforeReplaceHook = beforeReplace;
    if (beforeReplaceHook != null) {
      await beforeReplaceHook(target);
    }

    if (!await target.exists()) {
      await temp.rename(target.path);
      await _cleanupSidecarsBestEffort(
        target: target,
        temp: temp,
        bak: backup,
        deleteBak: true,
        deleteTemp: true,
      );
      return;
    }

    // Keep an existing .bak until the new backup rename succeeds: move it aside
    // only when we must free the .bak path for the current target.
    File? previousBakQuarantine;
    if (await backup.exists()) {
      previousBakQuarantine = File('${backup.path}.old');
      if (await previousBakQuarantine.exists()) {
        await previousBakQuarantine.delete();
      }
      await backup.rename(previousBakQuarantine.path);
    }

    try {
      await target.rename(backup.path);
    } on Object {
      if (previousBakQuarantine != null &&
          await previousBakQuarantine.exists() &&
          !await backup.exists()) {
        await previousBakQuarantine.rename(backup.path);
      }
      if (await temp.exists()) {
        try {
          await temp.delete();
        } on Object catch (error, stack) {
          appLog(
            '[DerivedIndexAtomicWrite] temp cleanup after rename fail: '
            '$error\n$stack',
          );
        }
      }
      rethrow;
    }

    try {
      await temp.rename(target.path);
    } catch (error) {
      if (await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      if (previousBakQuarantine != null &&
          await previousBakQuarantine.exists() &&
          !await backup.exists()) {
        await previousBakQuarantine.rename(backup.path);
      }
      if (await temp.exists()) {
        try {
          await temp.delete();
        } on Object catch (cleanupError, stack) {
          appLog(
            '[DerivedIndexAtomicWrite] temp cleanup after promote fail: '
            '$cleanupError\n$stack',
          );
        }
      }
      Error.throwWithStackTrace(error, StackTrace.current);
    }

    if (await backup.exists()) await backup.delete();
    if (previousBakQuarantine != null &&
        await previousBakQuarantine.exists()) {
      await previousBakQuarantine.delete();
    }
    if (await temp.exists()) await temp.delete();
  }

  Future<_ContentState> _classify(
    File file,
    bool Function(String content) validateContent,
  ) async {
    if (!await file.exists()) return _ContentState.missing;
    try {
      final content = await file.readAsString();
      if (!validateContent(content)) return _ContentState.invalid;
      return _ContentState.valid;
    } on Object {
      return _ContentState.invalid;
    }
  }

  Future<void> _restoreFromBak({
    required File target,
    required File bak,
    required _ContentState targetState,
  }) async {
    final beforeRestore = beforeBakRestore;
    if (beforeRestore != null) {
      await beforeRestore(target, bak);
    }

    if (targetState == _ContentState.missing) {
      await bak.rename(target.path);
      return;
    }

    // Corrupt/invalid target: quarantine without deleting bak first.
    final quarantine = File('${target.path}.stale');
    if (await quarantine.exists()) await quarantine.delete();
    await target.rename(quarantine.path);
    try {
      await bak.rename(target.path);
    } on Object {
      if (await quarantine.exists() && !await target.exists()) {
        await quarantine.rename(target.path);
      }
      rethrow;
    }
    if (await quarantine.exists()) await quarantine.delete();
  }

  Future<void> _cleanupSidecarsBestEffort({
    required File target,
    required File temp,
    required File bak,
    required bool deleteBak,
    required bool deleteTemp,
  }) async {
    try {
      final beforeCleanup = beforeSidecarCleanup;
      if (beforeCleanup != null) {
        await beforeCleanup(target);
      }
      if (deleteTemp && await temp.exists()) {
        await temp.delete();
      }
      if (deleteBak && await bak.exists()) {
        await bak.delete();
      }
    } on Object catch (error, stack) {
      appLog(
        '[DerivedIndexAtomicWrite] sidecar cleanup failed for ${target.path}: '
        '$error\n$stack',
      );
    }
  }
}

enum _ContentState { missing, valid, invalid }

/// Thrown when a derived index file exists but cannot be parsed safely.
class DerivedIndexCorruptException implements Exception {
  DerivedIndexCorruptException(this.path, [this.cause]);

  final String path;
  final Object? cause;

  @override
  String toString() => 'Derived index corrupt at $path';
}
