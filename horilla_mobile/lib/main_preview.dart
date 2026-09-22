/// Design-review entrypoint.
///
/// Runs the app against fixed sample data instead of a server, so the UI can
/// be looked at and judged without a Horilla instance to point at. Not part
/// of any shipped build -- run it explicitly:
///
///     flutter run -t lib/main_preview.dart
///
/// Deliberately a separate entrypoint rather than a flag inside the app: a
/// "preview mode" living in production code is a thing that eventually ships
/// by accident.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/session.dart';
import 'features/auth/data/auth_models.dart';
import 'features/home/data/home_api.dart';
import 'features/home/data/home_models.dart';

final _sampleHome = HomeData(
  user: const SignedInUser(id: 1, fullName: 'Nisha Prakash'),
  capabilities: const Capabilities(
    role: 'manager',
    permissions: {'view_team': true, 'approve_leave': true},
    features: {'leave': true, 'payroll': true, 'helpdesk': true},
  ),
  punch: PunchState(
    isClockedIn: true,
    clockInTime: '09:04',
    lastActivityAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  geofence: const GeofenceState(
    enabled: true,
    latitude: 12.9716,
    longitude: 77.5946,
    radiusInMeters: 150,
  ),
  today: const TodayTotals(
    worked: '03:12:40',
    breakTime: '00:30:00',
    overtime: '00:45:00',
  ),
  onLeaveToday: const [
    ColleagueOnLeave(id: 2, name: 'Arun Menon', leaveType: 'Casual'),
    ColleagueOnLeave(id: 3, name: 'Priya Nair', leaveType: 'Sick'),
    ColleagueOnLeave(id: 4, name: 'David Cole', leaveType: 'Earned'),
  ],
  unreadNotifications: 7,
  announcement: AnnouncementSummary(
    id: 1,
    title: 'Q3 review cycle opens on Monday',
    createdAt: DateTime.now(),
  ),
);

void main() {
  runApp(
    ProviderScope(
      overrides: [
        homeProvider.overrideWith((ref) async => _sampleHome),
        sessionRestoreProvider.overrideWith((ref) async {}),
        sessionProvider.overrideWith(_PreviewSession.new),
      ],
      child: const HorillaApp(),
    ),
  );
}

class _PreviewSession extends SessionController {
  @override
  Session? build() => Session(
        host: 'https://demo.horilla.com',
        user: _sampleHome.user,
        capabilities: _sampleHome.capabilities,
        isCleartext: false,
        geoFencingEnabled: true,
        faceDetectionEnabled: false,
      );
}
