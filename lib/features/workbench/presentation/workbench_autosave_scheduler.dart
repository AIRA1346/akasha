import 'dart:async';

import '../../../services/file_service.dart';

/// Workbench 탭 공통 자동 저장 타이머 (Work·Entity).
class WorkbenchAutosaveScheduler {
  WorkbenchAutosaveScheduler({this.delay = const Duration(seconds: 2)});

  final Duration delay;
  Timer? _timer;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();

  bool get hasVault {
    final path = AkashaFileService().vaultPath;
    return path != null && path.isNotEmpty;
  }

  void schedule({
    required bool persistEnabled,
    required bool Function() isDirty,
    required bool Function() isActive,
    required Future<void> Function() save,
    bool blockOnExternalChange = false,
    bool Function()? externalChangePending,
  }) {
    cancel();
    if (!persistEnabled || !hasVault) return;
    if (blockOnExternalChange && (externalChangePending?.call() ?? false)) {
      return;
    }
    _timer = Timer(delay, () async {
      if (!isActive()) return;
      if (!isDirty()) return;
      if (blockOnExternalChange && (externalChangePending?.call() ?? false)) {
        return;
      }
      await save();
    });
  }

  void flushIfNeeded({
    required bool persistEnabled,
    required bool Function() isDirty,
    required bool isSaving,
    required Future<void> Function() save,
    bool blockOnExternalChange = false,
    bool Function()? externalChangePending,
  }) {
    if (!persistEnabled || !isDirty() || !hasVault || isSaving) return;
    if (blockOnExternalChange && (externalChangePending?.call() ?? false)) {
      return;
    }
    unawaited(save());
  }
}
