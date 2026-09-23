import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds its builder once a second with the seconds worked so far today.
///
/// Worked time is the server's figure at fetch plus the time elapsed since,
/// and only while clocked in -- never a free-running local counter. A local
/// counter drifts every time the app is backgrounded, and this is exactly
/// the number people screenshot when they dispute their hours.
///
/// Only this subtree rebuilds each tick, and the timer stops while the app
/// is backgrounded: a clock nobody can see is not worth a wakeup a second.
class WorkedTicker extends StatefulWidget {
  const WorkedTicker({
    super.key,
    required this.workedAtFetch,
    required this.running,
    required this.builder,
  });

  /// Seconds worked when the data was fetched.
  final int workedAtFetch;

  /// Clocked in: the count advances. Clocked out: it holds.
  final bool running;
  final Widget Function(BuildContext context, int seconds) builder;

  @override
  State<WorkedTicker> createState() => _WorkedTickerState();
}

class _WorkedTickerState extends State<WorkedTicker>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(WorkedTicker old) {
    super.didUpdateWidget(old);
    // Fresh data from the server: count from it, not from the old anchor.
    if (old.workedAtFetch != widget.workedAtFetch ||
        old.running != widget.running) {
      _anchor = DateTime.now();
      _start();
    }
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
    _timer = null;
    if (!widget.running) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  int get _seconds => widget.running
      ? widget.workedAtFetch + DateTime.now().difference(_anchor).inSeconds
      : widget.workedAtFetch;

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}

/// "06:42:02"
String formatHms(int seconds) {
  String two(int v) => v.toString().padLeft(2, '0');
  final s = seconds < 0 ? 0 : seconds;
  return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
}

/// "6h 42m"
String formatHm(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 3600}h ${(s % 3600 ~/ 60).toString().padLeft(2, '0')}m';
}

/// "32m" / "1h 05m" / "0m" -- compact, for the hero's inset tiles.
String formatShort(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = s % 3600 ~/ 60;
  return h == 0 ? '${m}m' : '${h}h ${m.toString().padLeft(2, '0')}m';
}
