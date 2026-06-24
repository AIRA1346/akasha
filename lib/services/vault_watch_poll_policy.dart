/// Vault 외부 변경 감지 — directory watch vs fingerprint 폴링.
abstract final class VaultWatchPollPolicy {
  /// 주기적 전체 vault fingerprint 스캔 여부.
  ///
  /// Native directory watch가 활성일 때는 이벤트+debounce로 충분하므로
  /// 2초 폴링을 생략합니다. watch 실패·종료 시에만 폴링 fallback.
  static bool shouldRunPeriodicPoll({required bool directoryWatchActive}) =>
      !directoryWatchActive;
}
