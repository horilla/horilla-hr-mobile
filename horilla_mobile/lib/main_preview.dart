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
import 'features/attendance/data/attendance_api.dart';
import 'features/attendance/data/attendance_models.dart';
import 'features/employee/data/employee_api.dart';
import 'features/employee/data/employee_models.dart';
import 'features/home/data/home_api.dart';
import 'features/leave/data/leave_api.dart';
import 'features/leave/data/leave_models.dart';
import 'features/notifications/data/notification_models.dart';
import 'features/notifications/data/notifications_api.dart';
import 'features/payroll/data/payroll_api.dart';
import 'features/payroll/data/payroll_models.dart';
import 'features/requests/data/request_models.dart';
import 'features/requests/data/requests_api.dart';
import 'features/home/data/home_models.dart';

final _sampleHome = HomeData(
  user: const SignedInUser(id: 1, fullName: 'Nisha Prakash'),
  capabilities: const Capabilities(
    role: 'manager',
    permissions: {'view_team': true, 'approve_leave': true},
    features: {'leave': true, 'payroll': true, 'helpdesk': true},
    currencySymbol: '₹',
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

final _sampleAttendance = AttendanceOverview(
  hourAccount: const HourAccount(
    month: 'September',
    year: '2026',
    workedHours: '142:30',
    pendingHours: '17:30',
    overtime: '04:15',
  ),
  days: Paged<AttendanceDay>(
    count: 6,
    results: [
      AttendanceDay(
        id: 1,
        date: DateTime.now(),
        clockIn: '09:04',
        workedHour: '03:12',
      ),
      for (var i = 1; i < 6; i++)
        AttendanceDay(
          id: i + 1,
          date: DateTime.now().subtract(Duration(days: i)),
          clockIn: '09:0$i',
          clockOut: '18:1$i',
          workedHour: '08:3$i',
        ),
    ],
  ),
);

final _sampleLeave = LeaveOverview(
  balances: const [
    LeaveBalance(
      id: 1,
      type: LeaveType(id: 1, name: 'Casual'),
      availableDays: 6.5,
      carryforwardDays: 2,
    ),
    LeaveBalance(
      id: 2,
      type: LeaveType(id: 2, name: 'Sick'),
      availableDays: 4,
      carryforwardDays: 0,
    ),
    LeaveBalance(
      id: 3,
      type: LeaveType(id: 3, name: 'Earned'),
      availableDays: 12,
      carryforwardDays: 0,
    ),
  ],
  requests: [
    LeaveRequestSummary(
      id: 1,
      type: const LeaveType(id: 1, name: 'Casual'),
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 11)),
      status: LeaveStatus.requested,
      requestedDays: 2,
    ),
    LeaveRequestSummary(
      id: 2,
      type: const LeaveType(id: 2, name: 'Sick'),
      startDate: DateTime.now().subtract(const Duration(days: 12)),
      status: LeaveStatus.approved,
      requestedDays: 1,
    ),
    LeaveRequestSummary(
      id: 3,
      type: const LeaveType(id: 3, name: 'Earned'),
      startDate: DateTime.now().subtract(const Duration(days: 40)),
      status: LeaveStatus.rejected,
      requestedDays: 3,
    ),
  ],
  holidays: [
    Holiday(
      id: 1,
      name: 'Onam',
      startDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Holiday(
      id: 2,
      name: 'Gandhi Jayanti',
      startDate: DateTime.now().add(const Duration(days: 10)),
    ),
  ],
);

final _samplePayslips = [
  for (var i = 0; i < 5; i++)
    PayslipSummary(
      id: i + 1,
      startDate: DateTime(2026, 8 - i, 1),
      endDate: DateTime(2026, 8 - i, 28),
      netPay: 86420.0 - i * 1500,
      grossPay: 102000.0 - i * 1500,
      deduction: 15580.0,
      status: 'paid',
    ),
];

final _sampleRequests = RequestInbox(
  requests: [
    WorkRequest(
      id: 1,
      kind: RequestKind.shift,
      title: 'Night shift',
      state: RequestState.pending,
      date: DateTime.now().subtract(const Duration(days: 1)),
      detail: 'from Day shift',
    ),
    WorkRequest(
      id: 2,
      kind: RequestKind.reimbursement,
      title: 'Client visit taxi',
      state: RequestState.pending,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    WorkRequest(
      id: 3,
      kind: RequestKind.asset,
      title: 'Replacement laptop charger',
      state: RequestState.approved,
      date: DateTime.now().subtract(const Duration(days: 9)),
    ),
    WorkRequest(
      id: 4,
      kind: RequestKind.workType,
      title: 'Work from home',
      state: RequestState.rejected,
      date: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ],
);

const _sampleDirectory = [
  DirectoryEntry(
    id: 1,
    firstName: 'Nisha',
    lastName: 'Prakash',
    jobPosition: 'Engineering manager',
    email: 'nisha@example.com',
  ),
  DirectoryEntry(
    id: 2,
    firstName: 'Arun',
    lastName: 'Menon',
    jobPosition: 'Senior engineer',
    email: 'arun@example.com',
  ),
  DirectoryEntry(
    id: 3,
    firstName: 'Priya',
    lastName: 'Nair',
    jobPosition: 'Designer',
    email: 'priya@example.com',
  ),
  DirectoryEntry(
    id: 4,
    firstName: 'David',
    lastName: 'Cole',
    jobPosition: 'QA engineer',
    email: 'david@example.com',
  ),
];

final _sampleNotifications = NotificationInbox(
  now: DateTime.now(),
  all: [
    AppNotification(
      id: 1,
      verb: 'Your leave request for 2 Oct was approved',
      unread: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      redirect: '/time/leave',
    ),
    AppNotification(
      id: 2,
      verb: 'Arun Menon requested 3 days of casual leave',
      unread: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 3,
      verb: 'September payslip is ready',
      unread: false,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppNotification(
      id: 4,
      verb: 'Onam holiday announced for 24 September',
      unread: false,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ],
);

void main() {
  runApp(
    ProviderScope(
      overrides: [
        homeProvider.overrideWith((ref) async => _sampleHome),
        attendanceOverviewProvider.overrideWith((ref) async => _sampleAttendance),
        leaveOverviewProvider.overrideWith((ref) async => _sampleLeave),
        directoryProvider.overrideWith((ref) async => _sampleDirectory),
        notificationInboxProvider
            .overrideWith((ref) async => _sampleNotifications),
        requestInboxProvider.overrideWith((ref) async => _sampleRequests),
        payslipsProvider.overrideWith((ref) async => _samplePayslips),
        payslipProvider.overrideWith(
          (ref, id) async => PayslipDetail(
            summary: _samplePayslips.firstWhere(
              (p) => p.id == id,
              orElse: () => _samplePayslips.first,
            ),
            earnings: const [
              PayComponent(title: 'Basic', amount: 60000),
              PayComponent(title: 'House rent allowance', amount: 24000),
              PayComponent(title: 'Travel allowance', amount: 18000),
            ],
            deductions: const [
              PayComponent(title: 'Provident fund', amount: 7200),
              PayComponent(title: 'Professional tax', amount: 200),
              PayComponent(title: 'Income tax', amount: 8180),
            ],
            basicPay: 60000,
          ),
        ),
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
