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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

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
import 'features/announcements/data/announcement_models.dart';
import 'features/announcements/data/announcements_api.dart';
import 'features/approvals/data/approval_models.dart';
import 'features/approvals/data/approvals_api.dart';
import 'features/team/data/team_api.dart';
import 'features/team/data/team_models.dart';

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

const _sampleShifts = [
  RequestOption(id: 1, name: 'Day shift'),
  RequestOption(id: 2, name: 'Night shift'),
  RequestOption(id: 3, name: 'Rotational'),
];

const _sampleWorkTypes = [
  RequestOption(id: 1, name: 'Work from office'),
  RequestOption(id: 2, name: 'Work from home'),
  RequestOption(id: 3, name: 'Hybrid'),
];

const _sampleAssetCategories = [
  AssetCategoryOption(id: 1, name: 'Laptops', available: 4),
  AssetCategoryOption(id: 2, name: 'Headphones', available: 12),
  AssetCategoryOption(id: 3, name: 'Monitors', available: 0),
];

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

/// Every sample-data override; shared with the README screenshot script.
final List<Override> previewOverrides = [
  homeProvider.overrideWith((ref) async => _sampleHome),
  attendanceOverviewProvider.overrideWith((ref) async => _sampleAttendance),
  leaveOverviewProvider.overrideWith((ref) async => _sampleLeave),
  directoryProvider.overrideWith((ref) async => _sampleDirectory),
  notificationInboxProvider.overrideWith((ref) async => _sampleNotifications),
  requestInboxProvider.overrideWith((ref) async => _sampleRequests),
  shiftOptionsProvider.overrideWith((ref) async => _sampleShifts),
  workTypeOptionsProvider.overrideWith((ref) async => _sampleWorkTypes),
  assetCategoryOptionsProvider.overrideWith(
    (ref) async => _sampleAssetCategories,
  ),
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
  approvalsApiProvider.overrideWithValue(_PreviewApprovalsApi()),
  teamTodayProvider.overrideWith((ref) async => _sampleTeam()),
  announcementsProvider.overrideWith((ref) async => _sampleAnnouncements),
  announcementProvider.overrideWith(
    (ref, id) async => _sampleAnnouncements.firstWhere(
      (a) => a.id == id,
      orElse: () => _sampleAnnouncements.first,
    ),
  ),
  sessionRestoreProvider.overrideWith((ref) async {}),
  sessionProvider.overrideWith(_PreviewSession.new),
];

void main() {
  runApp(ProviderScope(overrides: previewOverrides, child: const HorillaApp()));
}

final _sampleApprovals = ApprovalInbox([
  ApprovalItem(
    kind: ApprovalKind.leave,
    id: 1,
    employeeId: 2,
    name: 'Arun Menon',
    ask: 'Casual leave · 6 Oct – 8 Oct · 3 days',
    reason: 'Family function in Kochi.',
    submitted: DateTime.now().subtract(const Duration(hours: 3)),
    warning: 'Overlaps 1 approved leave in the team.',
  ),
  ApprovalItem(
    kind: ApprovalKind.shift,
    id: 2,
    employeeId: 3,
    name: 'Priya Nair',
    ask: 'Day shift → Night shift · 13 Oct – 24 Oct',
    reason: 'Covering the APAC release window.',
    submitted: DateTime.now().subtract(const Duration(days: 1)),
  ),
  ApprovalItem(
    kind: ApprovalKind.reimbursement,
    id: 3,
    employeeId: 4,
    name: 'David Cole',
    ask: 'Client visit taxi · ₹1,450',
    submitted: DateTime.now().subtract(const Duration(days: 2)),
  ),
  ApprovalItem(
    kind: ApprovalKind.attendance,
    id: 4,
    employeeId: 5,
    name: 'Meera Iyer',
    ask: 'Correction for 22 Sep · 09:10–18:05',
    canReject: false,
  ),
]);

class _PreviewApprovalsApi extends ApprovalsApi {
  _PreviewApprovalsApi() : super(Dio());

  @override
  Future<ApprovalInbox> fetchInbox({
    required int selfId,
    String? currencySymbol,
  }) async => _sampleApprovals;
}

TeamToday _sampleTeam() {
  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);
  return TeamToday.build(
    reports: {
      2: 'Senior engineer',
      3: 'Designer',
      4: 'QA engineer',
      5: 'Engineer',
      6: 'Engineer',
    },
    names: {
      2: 'Arun Menon',
      3: 'Priya Nair',
      4: 'David Cole',
      5: 'Meera Iyer',
      6: 'Rahul Das',
    },
    clockIns: {3: '09:02', 5: '08:55', 6: '09:20'},
    leaves: [
      TeamLeave(
        employeeId: 2,
        name: 'Arun Menon',
        start: day(0),
        end: day(1),
        type: 'Casual',
      ),
      TeamLeave(
        employeeId: 4,
        name: 'David Cole',
        start: day(0),
        end: day(0),
        type: 'Sick',
      ),
    ],
    today: today,
  );
}

final _sampleAnnouncements = [
  Announcement(
    id: 1,
    title: 'Q3 review cycle opens on Monday',
    createdAt: DateTime.now(),
    hasViewed: false,
    author: 'Nisha Prakash',
    content: const [
      ContentBlock(
        BlockType.paragraph,
        'Self reviews open on Monday and close on 10 October. Managers review from 13 October.',
      ),
      ContentBlock(BlockType.heading, 'Before you start'),
      ContentBlock(BlockType.bullet, 'Update your objectives in Performance'),
      ContentBlock(BlockType.bullet, 'Collect feedback from two peers'),
      ContentBlock(BlockType.bullet, 'Book a 1:1 with your manager'),
    ],
    expireDate: DateTime.now().add(const Duration(days: 21)),
  ),
  Announcement(
    id: 2,
    title: 'Office closed for Onam',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    content: const [
      ContentBlock(
        BlockType.paragraph,
        'Both Kochi and Bengaluru offices are closed on the 15th. Happy Onam!',
      ),
    ],
  ),
  Announcement(
    id: 3,
    title: 'New work-from-home policy',
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
    content: const [
      ContentBlock(
        BlockType.paragraph,
        'Up to three remote days a week, requested through the app.',
      ),
    ],
  ),
];

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
