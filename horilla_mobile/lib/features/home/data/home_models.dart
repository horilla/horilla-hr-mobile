/// What the home screen draws, as returned by `GET /api/v1/mobile/home/`.
///
/// One request rather than the eight the resource endpoints would need -- the
/// previous version of this app made fourteen on this screen. Parsers are
/// deliberately tolerant: a field the server omits should cost one card, not
/// the whole screen.
library;

import '../../approvals/data/approval_models.dart';
import '../../auth/data/auth_models.dart';

class PunchState {
  const PunchState({
    required this.isClockedIn,
    this.clockInTime,
    this.lastActivityAt,
  });

  final bool isClockedIn;

  /// Already formatted by the server, e.g. `09:04`.
  final String? clockInTime;

  final DateTime? lastActivityAt;

  static PunchState fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PunchState(isClockedIn: false);
    final at = json['last_activity_at'];
    return PunchState(
      isClockedIn: json['is_clocked_in'] == true,
      clockInTime: json['clock_in_time'] is String
          ? json['clock_in_time'] as String
          : null,
      lastActivityAt: at is String ? DateTime.tryParse(at) : null,
    );
  }
}

class GeofenceState {
  const GeofenceState({
    required this.enabled,
    this.latitude,
    this.longitude,
    this.radiusInMeters,
  });

  final bool enabled;
  final double? latitude;
  final double? longitude;
  final int? radiusInMeters;

  static GeofenceState fromJson(Map<String, dynamic>? json) {
    if (json == null || json['enabled'] != true) {
      return const GeofenceState(enabled: false);
    }
    return GeofenceState(
      enabled: true,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      radiusInMeters: json['radius_in_meters'] is int
          ? json['radius_in_meters'] as int
          : null,
    );
  }

  static double? _toDouble(Object? value) => switch (value) {
    final double d => d,
    final int i => i.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };
}

/// Worked / Break / Overtime, each already formatted `HH:MM:SS`.
///
/// Break has no stored field on the server -- it is derived from the gaps
/// between activity pairs -- which is why it is computed there rather than
/// here: every client then agrees on the number.
class TodayTotals {
  const TodayTotals({
    required this.worked,
    required this.breakTime,
    required this.overtime,
    this.minimumHour,
  });

  final String worked;
  final String breakTime;
  final String overtime;

  /// Today's required hours from the shift, e.g. "08:30", when the server
  /// sends it. Horilla stores this per attendance row; the home aggregate
  /// does not return it yet, so the punch ring falls back to 8h and says so.
  final String? minimumHour;

  static const zero = TodayTotals(
    worked: '00:00:00',
    breakTime: '00:00:00',
    overtime: '00:00:00',
  );

  /// "HH:MM[:SS]" to seconds; null when it cannot be read.
  static int? secondsOf(String? value) {
    if (value == null) return null;
    final parts = value.trim().split(':').map(int.tryParse).toList();
    if (parts.isEmpty || parts.any((p) => p == null || p < 0)) return null;
    final h = parts[0]!;
    final m = parts.length > 1 ? parts[1]! : 0;
    final sec = parts.length > 2 ? parts[2]! : 0;
    return h * 3600 + m * 60 + sec;
  }

  int get workedSeconds => secondsOf(worked) ?? 0;
  int? get shiftSeconds {
    final s = secondsOf(minimumHour);
    return s == null || s == 0 ? null : s;
  }

  bool get hasOvertime =>
      overtime.isNotEmpty && !RegExp(r'^00:00:0?0?$').hasMatch(overtime);

  static TodayTotals fromJson(Map<String, dynamic>? json) {
    if (json == null) return zero;
    String read(String key) =>
        json[key] is String ? json[key] as String : '00:00:00';
    final minimum = json['minimum_hour'];
    return TodayTotals(
      worked: read('worked'),
      breakTime: read('break'),
      overtime: read('overtime'),
      minimumHour: minimum is String && minimum.isNotEmpty ? minimum : null,
    );
  }
}

class ColleagueOnLeave {
  const ColleagueOnLeave({
    required this.id,
    required this.name,
    this.leaveType,
  });

  final int id;
  final String name;
  final String? leaveType;

  static ColleagueOnLeave? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['name'];
    if (name is! String || name.isEmpty) return null;
    return ColleagueOnLeave(
      id: value['id'] is int ? value['id'] as int : 0,
      name: name,
      leaveType: value['leave_type'] is String
          ? value['leave_type'] as String
          : null,
    );
  }
}

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.id,
    required this.title,
    this.createdAt,
  });

  final int id;
  final String title;
  final DateTime? createdAt;

  static AnnouncementSummary? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final title = json['title'];
    if (title is! String || title.isEmpty) return null;
    final at = json['created_at'];
    return AnnouncementSummary(
      id: json['id'] is int ? json['id'] as int : 0,
      title: title,
      createdAt: at is String ? DateTime.tryParse(at) : null,
    );
  }
}

class HomeData {
  const HomeData({
    required this.user,
    required this.capabilities,
    required this.punch,
    required this.geofence,
    required this.today,
    required this.onLeaveToday,
    required this.unreadNotifications,
    this.announcement,
    this.pendingApprovals,
  });

  final SignedInUser user;
  final Capabilities capabilities;
  final PunchState punch;
  final GeofenceState geofence;
  final TodayTotals today;
  final List<ColleagueOnLeave> onLeaveToday;
  final int unreadNotifications;
  final AnnouncementSummary? announcement;

  /// Null on a server before PR #3407 -- the Home approvals band falls back
  /// to counting the full inbox client-side when this is absent.
  final PendingApprovals? pendingApprovals;

  static HomeData fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? sub(String key) => json[key] is Map<String, dynamic>
        ? json[key] as Map<String, dynamic>
        : null;

    return HomeData(
      user: SignedInUser.fromJson(sub('employee')),
      capabilities: Capabilities.fromJson(sub('capabilities')),
      punch: PunchState.fromJson(sub('punch')),
      geofence: GeofenceState.fromJson(sub('geofence')),
      today: TodayTotals.fromJson(sub('today')),
      onLeaveToday: json['on_leave_today'] is List
          ? (json['on_leave_today'] as List)
                .map(ColleagueOnLeave.fromJson)
                .whereType<ColleagueOnLeave>()
                .toList()
          : const [],
      unreadNotifications: json['unread_notifications'] is int
          ? json['unread_notifications'] as int
          : 0,
      announcement: AnnouncementSummary.fromJson(sub('announcement')),
      pendingApprovals: PendingApprovals.fromJson(json['pending_approvals']),
    );
  }
}
