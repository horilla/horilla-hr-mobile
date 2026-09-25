/// Employee directory and profile.
///
/// The assertions that matter most are about what does *not* come through.
/// The server's unrestricted employee serializer carries date of birth, home
/// address, marital status and emergency contacts, and its work-information
/// serializer carries salary. None of that belongs in a colleague directory,
/// and the surest way not to show it is not to parse it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/employee/data/employee_models.dart';

void main() {
  group('directory entries', () {
    test('a row parses the public fields', () {
      final entry = DirectoryEntry.fromJson({
        'id': 7,
        'employee_first_name': 'Nisha',
        'employee_last_name': 'Prakash',
        'job_position_name': 'Engineer',
        'email': 'nisha@example.com',
      })!;

      expect(entry.id, 7);
      expect(entry.fullName, 'Nisha Prakash');
      expect(entry.jobPosition, 'Engineer');
    });

    test('a missing surname does not leave a trailing space', () {
      final entry = DirectoryEntry.fromJson({
        'id': 7,
        'employee_first_name': 'Nisha',
      })!;
      expect(entry.fullName, 'Nisha');
    });

    test('a row without a first name is discarded', () {
      expect(DirectoryEntry.fromJson({'id': 7}), isNull);
      expect(DirectoryEntry.fromJson('nonsense'), isNull);
    });

    test('empty strings are treated as absent', () {
      final entry = DirectoryEntry.fromJson({
        'id': 7,
        'employee_first_name': 'Nisha',
        'job_position_name': '',
        'email': '',
      })!;
      expect(entry.jobPosition, isNull);
      expect(entry.email, isNull);
    });
  });

  group('work information', () {
    test('the public fields parse', () {
      final info = WorkInformation.fromJson({
        'department_name': 'Engineering',
        'job_position_name': 'Engineer',
        'shift_name': 'Day shift',
        'work_type_name': 'Hybrid',
        'location': 'Kochi',
        'reporting_manager_first_name': 'Arun',
        'reporting_manager_last_name': 'Menon',
        'date_joining': '2024-04-01',
      });

      expect(info.department, 'Engineering');
      expect(info.reportingManager, 'Arun Menon');
      expect(info.dateJoining, DateTime(2024, 4, 1));
    });

    test('salary is not parsed even when the server sends it', () {
      // EmployeeWorkInformationSerializer includes basic_salary and
      // salary_hour. A colleague's pay is not directory data, so this model
      // has nowhere to put it.
      final info = WorkInformation.fromJson({
        'department_name': 'Engineering',
        'basic_salary': 90000,
        'salary_hour': 500,
      });

      expect(info.department, 'Engineering');
      final labels = info.rows.map((r) => r.$1).toList();
      expect(labels, isNot(contains('Salary')));
      expect(labels, everyElement(isNot(contains('alary'))));
    });

    test('blank fields produce no row rather than an empty label', () {
      final info = WorkInformation.fromJson({
        'department_name': 'Engineering',
        'shift_name': '',
      });

      final labels = info.rows.map((r) => r.$1).toList();
      expect(labels, contains('Department'));
      expect(labels, isNot(contains('Shift')));
    });

    test('a manager with no surname still reads cleanly', () {
      final info = WorkInformation.fromJson({
        'reporting_manager_first_name': 'Arun',
      });
      expect(info.reportingManager, 'Arun');
    });

    test('nothing at all yields no rows, not a crash', () {
      expect(WorkInformation.fromJson(null).rows, isEmpty);
      expect(WorkInformation.fromJson('nonsense').rows, isEmpty);
      expect(WorkInformation.empty.rows, isEmpty);
    });
  });
}
