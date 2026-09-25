/// Attendance models.
///
/// The server returns durations as pre-formatted strings (`"160:00"`), not
/// seconds, so they are carried through as strings rather than parsed and
/// re-rendered -- that way the app and the web UI always agree, and a change
/// to the server's formatting does not silently disagree with the web.
library;

/// The monthly hour account, `AttendanceOverTime` server-side.
class HourAccount {
  const HourAccount({
    required this.month,
    required this.year,
    required this.workedHours,
    required this.pendingHours,
    required this.overtime,
  });

  final String month;
  final String year;

  /// Worked so far this month, `HH:MM`.
  final String workedHours;

  /// Still expected this month, `HH:MM`.
  final String pendingHours;

  final String overtime;

  static const empty = HourAccount(
    month: '',
    year: '',
    workedHours: '00:00',
    pendingHours: '00:00',
    overtime: '00:00',
  );

  bool get hasOvertime => !_isZero(overtime);

  /// Worked / (worked + pending), for the progress bar. Null when the numbers
  /// cannot be parsed -- the bar is then hidden rather than drawn at a
  /// guessed value.
  double? get progress {
    final worked = _minutes(workedHours);
    final pending = _minutes(pendingHours);
    if (worked == null || pending == null) return null;
    final total = worked + pending;
    if (total <= 0) return null;
    return (worked / total).clamp(0.0, 1.0);
  }

  /// Total expected this month, for the "of 160h" caption.
  String? get expectedHours {
    final worked = _minutes(workedHours);
    final pending = _minutes(pendingHours);
    if (worked == null || pending == null) return null;
    return '${((worked + pending) / 60).round()}h';
  }

  /// "142h 18m" -- v2's hero figure. Null when the server's value is not a
  /// real duration, so the card says so instead of printing it.
  String? get workedLabel => _label(workedHours);
  String? get overtimeLabel => _label(overtime);

  static String? _label(String value) {
    final m = _minutes(value);
    if (m == null) return null;
    return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  static bool _isZero(String value) =>
      RegExp(r'^0*:?0*(:0*)?$').hasMatch(value.trim());

  /// `"160:30"` -> 9630. Tolerant of `HH:MM:SS`; null for junk.
  ///
  /// Negative durations are junk too. The demo server returns
  /// `worked_hours: "-2:31"`, which this used to read as -2h *plus* 31m and
  /// then build "-2:31 of -1h" from. No month has negative hours worked.
  static int? _minutes(String value) {
    final parts = value.trim().split(':');
    if (parts.isEmpty) return null;
    final hours = int.tryParse(parts.first);
    if (hours == null || hours < 0 || parts.first.trim().startsWith('-')) {
      return null;
    }
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (minutes < 0) return null;
    return hours * 60 + minutes;
  }

  static HourAccount fromJson(Map<String, dynamic> json) {
    String read(String key, [String fallback = '00:00']) =>
        json[key] is String && (json[key] as String).isNotEmpty
        ? json[key] as String
        : fallback;
    return HourAccount(
      month: read('month', ''),
      year: read('year', ''),
      workedHours: read('worked_hours'),
      pendingHours: read('pending_hours'),
      overtime: read('overtime'),
    );
  }
}

/// One row of the activity log.
class AttendanceDay {
  const AttendanceDay({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.workedHour,
    this.workedSeconds,
    this.minimumHour,
    this.shiftName,
  });

  final int id;
  final DateTime date;

  /// `at_work_second`: the exact figure, for the week chart. The formatted
  /// [workedHour] is for display.
  final int? workedSeconds;

  /// The day's required hours from the shift, e.g. `"08:30"`.
  final String? minimumHour;
  final String? shiftName;

  /// Pre-formatted by the server, e.g. `"09:04"`.
  final String? clockIn;
  final String? clockOut;
  final String? workedHour;

  /// Still clocked in: an open row has a start and no end.
  bool get isOpen => clockIn != null && clockOut == null;

  static AttendanceDay? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final raw = value['attendance_date'];
    final date = raw is String ? DateTime.tryParse(raw) : null;
    if (date == null) return null;

    String? text(String key) {
      final v = value[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    return AttendanceDay(
      id: value['id'] is int ? value['id'] as int : 0,
      date: date,
      clockIn: text('attendance_clock_in'),
      clockOut: text('attendance_clock_out'),
      workedHour: text('attendance_worked_hour'),
      workedSeconds: value['at_work_second'] is int
          ? value['at_work_second'] as int
          : null,
      minimumHour: text('minimum_hour'),
      shiftName: text('shift_name'),
    );
  }
}

/// A page of results, in DRF's envelope.
class Paged<T> {
  const Paged({
    required this.results,
    required this.count,
    this.hasMore = false,
  });

  final List<T> results;
  final int count;
  final bool hasMore;

  static Paged<T> fromJson<T>(
    Map<String, dynamic> json,
    T? Function(Object?) item,
  ) {
    final raw = json['results'];
    return Paged<T>(
      results: raw is List ? raw.map(item).whereType<T>().toList() : const [],
      count: json['count'] is int ? json['count'] as int : 0,
      hasMore: json['next'] != null,
    );
  }
}

class AttendanceOverview {
  const AttendanceOverview({
    required this.hourAccount,
    required this.days,
    DateTime? month,
    this.lateIns,
    this.earlyOuts,
  }) : _month = month;

  final HourAccount hourAccount;

  /// The most recent days, newest first -- across months, because the
  /// server's list ignores date filters. [daysInMonth] narrows it.
  final Paged<AttendanceDay> days;
  final DateTime? _month;

  /// Null when the late/early-out lookup failed: an unknown count is shown
  /// as unknown, never as a reassuring zero.
  final int? lateIns;
  final int? earlyOuts;

  DateTime get month =>
      _month ?? DateTime(DateTime.now().year, DateTime.now().month);

  List<AttendanceDay> get daysInMonth => [
    for (final d in days.results)
      if (d.date.year == month.year && d.date.month == month.month) d,
  ];

  int get presentDays => daysInMonth.length;

  /// Months the loaded days cover, newest first; always includes the current
  /// one. The month picker offers exactly these, so it can never offer a
  /// month whose log would come back empty for want of data we never fetched.
  List<DateTime> get availableMonths {
    final now = DateTime.now();
    final seen = <DateTime>{DateTime(now.year, now.month)};
    for (final d in days.results) {
      seen.add(DateTime(d.date.year, d.date.month));
    }
    return seen.toList()..sort((a, b) => b.compareTo(a));
  }
}
