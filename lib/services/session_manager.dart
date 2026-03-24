import 'dart:async';
import 'package:flutter/material.dart';

/// Tracks user inactivity. Call [onInteraction] on any tap/scroll.
/// After [timeoutDuration] of silence, fires [onTimeout].
class SessionManager {
  final Duration timeoutDuration;
  final VoidCallback onTimeout;

  Timer? _timer;

  SessionManager({
    this.timeoutDuration = const Duration(minutes: 5),
    required this.onTimeout,
  });

  /// Start or restart the inactivity countdown.
  void onInteraction() {
    _timer?.cancel();
    _timer = Timer(timeoutDuration, onTimeout);
  }

  /// Call this once to kick off the first timer.
  void start() => onInteraction();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
