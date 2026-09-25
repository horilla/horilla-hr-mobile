/// A manager's direct reports, today.
library;

enum TeamState {
  checkedIn('Checked in'),
  onLeave('On leave'),
  notIn('Not in');

  const TeamState(this.label);

  final String label;
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.state,
    this.jobPosition,
    this.clockIn,
    this.leaveType,
  });

  final int id;
  final String name;
  final TeamState state;
  final String? jobPosition;

  /// "09:04", when checked in.
  final String? clockIn;

  /// When on leave, the kind -- "Casual Leave".
  final String? leaveType;
}

/// One approved leave, reduced to what the week strip needs.
class TeamLeave {
  const TeamLeave({
    required this.employeeId,
    required this.name,
    required this.start,
    required this.end,
    this.type,
  });

  final int employeeId;
  final String name;
  final DateTime start;
  final DateTime end;
  final String? type;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_day(start)) && !d.isAfter(_day(end));
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
}

/// One weekday in the leave-clash strip.
class ClashDay {
  const ClashDay({required this.date, required this.off});

  final DateTime date;

  /// Names of reports on approved leave that day.
  final List<String> off;
}

class TeamToday {
  const TeamToday({required this.members, required this.week});

  final List<TeamMember> members;

  /// Monday to Friday of the current week.
  final List<ClashDay> week;

  static const empty = TeamToday(members: [], week: []);

  int count(TeamState state) => members.where((m) => m.state == state).length;

  /// Two or more of a team off on the same day is the design's "risk".
  ///
  /// ponytail: a fixed threshold of two, not a share of team size. A team of
  /// three losing two is worse than a team of twenty losing two; make it
  /// proportional if managers of large teams find it noisy.
  static const clashThreshold = 2;

  ClashDay? get worstDay {
    ClashDay? worst;
    for (final day in week) {
      if (day.off.length >= clashThreshold &&
          (worst == null || day.off.length > worst.off.length)) {
        worst = day;
      }
    }
    return worst;
  }

  /// Assemble from the raw pieces. Pure, so it is the part worth testing.
  static TeamToday build({
    required Map<int, String?> reports,
    required Map<int, String> names,
    required Map<int, String> clockIns,
    required List<TeamLeave> leaves,
    required DateTime today,
  }) {
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));

    final members = <TeamMember>[];
    for (final entry in reports.entries) {
      final id = entry.key;
      final leaveToday = leaves
          .where((l) => l.employeeId == id && l.covers(today))
          .firstOrNull;
      final clockIn = clockIns[id];
      final name = names[id];
      members.add(
        TeamMember(
          id: id,
          name: name == null || name.isEmpty ? 'Employee #$id' : name,
          jobPosition: entry.value,
          // Checked in wins over on leave: someone who came in on a leave
          // day is, as far as the manager needs to know today, in.
          state: clockIn != null
              ? TeamState.checkedIn
              : leaveToday != null
              ? TeamState.onLeave
              : TeamState.notIn,
          clockIn: clockIn,
          leaveType: leaveToday?.type,
        ),
      );
    }
    // In first, then on leave, then not in -- then by name.
    members.sort((a, b) {
      final byState = a.state.index.compareTo(b.state.index);
      return byState != 0 ? byState : a.name.compareTo(b.name);
    });

    final week = [
      for (var i = 0; i < 5; i++)
        ClashDay(
          date: monday.add(Duration(days: i)),
          off: leaves
              .where(
                (l) =>
                    reports.containsKey(l.employeeId) &&
                    l.covers(monday.add(Duration(days: i))),
              )
              .map((l) => l.name.split(' ').first)
              .toSet()
              .toList(),
        ),
    ];

    return TeamToday(members: members, week: week);
  }
}
