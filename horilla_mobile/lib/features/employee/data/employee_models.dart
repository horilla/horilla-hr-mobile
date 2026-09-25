/// Employee directory and profile.
library;

/// A directory row.
///
/// Comes from `EmployeeListSerializer`, which is the safe payload: name, job
/// position, avatar, email. The unrestricted `EmployeeSerializer` carries date
/// of birth, home address, marital status and emergency contacts, and must
/// never back a directory.
class DirectoryEntry {
  const DirectoryEntry({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.jobPosition,
    this.email,
    this.avatarUrl,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? jobPosition;
  final String? email;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  static DirectoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final first = value['employee_first_name'];
    if (first is! String || first.isEmpty) return null;

    String? text(String key) {
      final v = value[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    return DirectoryEntry(
      id: value['id'] is int ? value['id'] as int : 0,
      firstName: first,
      lastName: text('employee_last_name') ?? '',
      jobPosition: text('job_position_name'),
      email: text('email'),
      avatarUrl: text('employee_profile'),
    );
  }
}

/// Work information for one person.
///
/// Deliberately does **not** carry `basic_salary` or `salary_hour`, which the
/// server's serializer does include. A colleague's pay is not directory data,
/// and the surest way not to show it is not to parse it.
class WorkInformation {
  const WorkInformation({
    this.jobPosition,
    this.department,
    this.shift,
    this.workType,
    this.employeeType,
    this.location,
    this.reportingManager,
    this.dateJoining,
  });

  final String? jobPosition;
  final String? department;
  final String? shift;
  final String? workType;
  final String? employeeType;
  final String? location;
  final String? reportingManager;
  final DateTime? dateJoining;

  static const empty = WorkInformation();

  static WorkInformation fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return empty;

    String? text(String key) {
      final v = value[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    final managerFirst = text('reporting_manager_first_name');
    final managerLast = text('reporting_manager_last_name');
    final joining = value['date_joining'];

    return WorkInformation(
      jobPosition: text('job_position_name'),
      department: text('department_name'),
      shift: text('shift_name'),
      workType: text('work_type_name'),
      employeeType: text('employee_type_name'),
      location: text('location'),
      reportingManager: managerFirst == null
          ? null
          : '$managerFirst ${managerLast ?? ''}'.trim(),
      dateJoining: joining is String ? DateTime.tryParse(joining) : null,
    );
  }

  /// Rows the profile screen shows, skipping anything the server left blank
  /// rather than printing a label with nothing after it.
  List<(String, String)> get rows => [
    if (department != null) ('Department', department!),
    if (jobPosition != null) ('Job position', jobPosition!),
    if (reportingManager != null) ('Reports to', reportingManager!),
    if (shift != null) ('Shift', shift!),
    if (workType != null) ('Work type', workType!),
    if (location != null) ('Work location', location!),
    if (employeeType != null) ('Employment', employeeType!),
  ];
}
