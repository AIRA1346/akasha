/// Vault 디스크 reload 공통 try/catch 래퍼.
abstract final class WorkbenchVaultReloadFlow {
  static Future<void> run<T>({
    required Future<T?> Function() reload,
    required void Function(T value) onReloaded,
    required void Function(String message) showSuccess,
    required void Function(String message) showFailure,
    required String Function() successMessage,
    required String Function(Object error) failureMessage,
    required bool silent,
    required bool Function() isMounted,
  }) async {
    try {
      final value = await reload();
      if (value == null) {
        throw StateError('reload failed');
      }
      if (!isMounted()) return;
      onReloaded(value);
      if (!silent && isMounted()) {
        showSuccess(successMessage());
      }
    } catch (e) {
      if (!silent && isMounted()) {
        showFailure(failureMessage(e));
      }
    }
  }
}
