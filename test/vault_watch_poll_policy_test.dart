import 'package:akasha/services/vault_watch_poll_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultWatchPollPolicy.shouldRunPeriodicPoll', () {
    test('skips poll when directory watch is active', () {
      expect(
        VaultWatchPollPolicy.shouldRunPeriodicPoll(directoryWatchActive: true),
        isFalse,
      );
    });

    test('runs poll when directory watch is unavailable', () {
      expect(
        VaultWatchPollPolicy.shouldRunPeriodicPoll(directoryWatchActive: false),
        isTrue,
      );
    });
  });
}
