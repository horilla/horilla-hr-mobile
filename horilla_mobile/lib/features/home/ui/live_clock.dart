import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/theme/tokens.dart';

/// The ticking clock on the punch card.
///
/// Device local time, per the handoff -- a wall clock, not elapsed time, so
/// there is no server-drift question here. What matters is that this is the
/// *only* thing rebuilding each second: it owns its own timer and nothing
/// above it repaints, which keeps a once-a-second tick from re-laying-out the
/// whole screen.
///
/// The timer stops while the app is backgrounded. A clock nobody can see is
/// not worth a wakeup a second.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, this.style});

  final TextStyle? style;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _start() {
    _timer?.cancel();
    setState(() => _now = DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  static String format(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      format(_now),
      style: widget.style ??
          AppText.punchClock.copyWith(color: AppColors.surface),
    );
  }
}
