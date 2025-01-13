// lib/utils/debouncer.dart
// Utility class for optimizing UI performance by limiting the frequency of operations. Implements a timer-based debouncing mechanism to prevent excessive API calls or UI updates when user input changes rapidly.
import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}