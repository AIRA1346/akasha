import 'dart:async';

import 'commerce_controller.dart';

/// Periodically asks Steam to evaluate the playtime reward ItemDef.
///
/// This scheduler owns no eligibility clock, daily counter, or Echo balance.
/// It merely requests evaluation every ten minutes while AKASHA is running;
/// Steam remains the authority for eligible playtime and the six-per-window
/// cap, and the commerce gateway reconciles the resulting inventory.
class CommercePlaytimeRewardScheduler {
  CommercePlaytimeRewardScheduler({
    required CommerceController controller,
    this.interval = const Duration(minutes: 10),
  }) : _controller = controller;

  final CommerceController _controller;
  final Duration interval;
  Timer? _timer;
  bool _checkInFlight = false;
  bool _disposed = false;

  bool get isRunning => _timer?.isActive == true;

  void start() {
    if (_disposed || isRunning || interval <= Duration.zero) return;
    _timer = Timer.periodic(interval, (_) => unawaited(checkNow()));
  }

  Future<void> checkNow() async {
    if (_disposed || _checkInFlight) return;
    _checkInFlight = true;
    try {
      await _controller.claimEchoPlaytimeReward();
    } finally {
      _checkInFlight = false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
