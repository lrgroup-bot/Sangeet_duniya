import 'dart:async';

import 'package:flutter/foundation.dart';

class SleepTimerService extends ChangeNotifier {
  Timer? _endTimer;
  Timer? _ticker;
  DateTime? _endsAt;

  DateTime? get endsAt => _endsAt;
  bool get isActive => _endsAt != null;

  Duration get remaining {
    final end = _endsAt;
    if (end == null) return Duration.zero;
    final value = end.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  String get remainingLabel {
    if (!isActive) return 'Off';
    final value = remaining;
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return minutes.toString() + ':' + seconds.toString().padLeft(2, '0');
  }

  void start(
    Duration duration, {
    required Future<void> Function() onElapsed,
  }) {
    cancel();
    _endsAt = DateTime.now().add(duration);
    _endTimer = Timer(duration, () {
      unawaited(onElapsed());
      _finish();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining <= Duration.zero) {
        _finish();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void cancel() {
    _endTimer?.cancel();
    _ticker?.cancel();
    _endTimer = null;
    _ticker = null;
    _endsAt = null;
    notifyListeners();
  }

  void _finish() {
    _endTimer?.cancel();
    _ticker?.cancel();
    _endTimer = null;
    _ticker = null;
    _endsAt = null;
    notifyListeners();
  }
}

final sleepTimerService = SleepTimerService();
