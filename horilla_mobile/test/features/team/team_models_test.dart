/// Who is in, who is off, and which day this week is thin.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/team/data/team_models.dart';

// A Wednesday, so the week runs Mon 21 Sep -- Fri 25 Sep.
final today = DateTime(2026, 9, 23, 10);

TeamLeave off(int id, String name, int fromDay, int toDay) => TeamLeave(
  employeeId: id,
  name: name,
  start: DateTime(2026, 9, fromDay),
  end: DateTime(2026, 9, toDay),
  type: 'Casual Leave',
);

TeamToday build({
  Map<int, String> clockIns = const {},
  List<TeamLeave> leaves = const [],
}) => TeamToday.build(
  reports: {10: 'Designer', 11: 'Engineer', 12: null},
  names: {10: 'Priya Nair', 11: 'Arun Menon', 12: 'David Cole'},
  clockIns: clockIns,
  leaves: leaves,
  today: today,
);

void main() {
  test('each report gets exactly one state for today', () {
    final team = build(
      clockIns: {10: '09:04'},
      leaves: [off(11, 'Arun Menon', 22, 24)],
    );
    expect(team.count(TeamState.checkedIn), 1);
    expect(team.count(TeamState.onLeave), 1);
    expect(team.count(TeamState.notIn), 1);

    final arun = team.members.firstWhere((m) => m.id == 11);
    expect(arun.leaveType, 'Casual Leave');
  });

  test('checked in wins over on leave', () {
    final team = build(
      clockIns: {11: '09:30'},
      leaves: [off(11, 'Arun Menon', 23, 23)],
    );
    expect(team.members.firstWhere((m) => m.id == 11).state,
        TeamState.checkedIn);
  });

  test('the roster is in, then on leave, then not in', () {
    final team = build(
      clockIns: {12: '08:55'},
      leaves: [off(10, 'Priya Nair', 23, 23)],
    );
    expect(team.members.map((m) => m.state).toList(), [
      TeamState.checkedIn,
      TeamState.onLeave,
      TeamState.notIn,
    ]);
  });

  test('the week is Monday to Friday of the current week', () {
    final team = build();
    expect(team.week.map((d) => d.date.day).toList(), [21, 22, 23, 24, 25]);
  });

  test('two off on the same day is flagged; one is not', () {
    final quiet = build(leaves: [off(10, 'Priya Nair', 22, 22)]);
    expect(quiet.worstDay, isNull);

    final thin = build(
      leaves: [
        off(10, 'Priya Nair', 24, 25),
        off(11, 'Arun Menon', 24, 24),
      ],
    );
    expect(thin.worstDay?.date.day, 24);
    expect(thin.worstDay?.off, ['Priya', 'Arun']);
  });

  test('leave outside the team does not count toward a clash', () {
    final team = build(
      leaves: [
        off(10, 'Priya Nair', 24, 24),
        off(99, 'Someone Else', 24, 24),
      ],
    );
    expect(team.worstDay, isNull);
  });

  test('a report with no name on record still gets a row', () {
    final team = TeamToday.build(
      reports: {42: null},
      names: const {},
      clockIns: const {},
      leaves: const [],
      today: today,
    );
    expect(team.members.single.name, 'Employee #42');
  });
}
