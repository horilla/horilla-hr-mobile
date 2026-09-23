/// Editing your own record.
///
/// The endpoint has no PATCH, so an update is a PUT with partial semantics.
/// Sending only what actually changed is what stops this screen quietly
/// rewriting a field that someone else -- or HR -- changed between the read
/// and the write.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/employee/data/profile_api.dart';

void main() {
  const original = PersonalInfo(
    phone: '9999999999',
    address: '1 Old Street',
    city: 'Kochi',
    state: 'Kerala',
    zip: '682001',
    emergencyContactName: 'Arun',
    emergencyContact: '8888888888',
    emergencyContactRelation: 'Brother',
  );

  group('the diff', () {
    test('no edits means nothing is sent', () {
      // Which also means a PUT is never issued at all -- see ProfileApi.
      expect(original.diffFrom(original), isEmpty);
    });

    test('only the changed field is sent', () {
      const edited = PersonalInfo(
        phone: '7777777777',
        address: '1 Old Street',
        city: 'Kochi',
        state: 'Kerala',
        zip: '682001',
        emergencyContactName: 'Arun',
        emergencyContact: '8888888888',
        emergencyContactRelation: 'Brother',
      );

      expect(edited.diffFrom(original), {'phone': '7777777777'});
    });

    test('several changes are all sent', () {
      const edited = PersonalInfo(
        phone: '7777777777',
        address: '2 New Road',
        city: 'Kochi',
        state: 'Kerala',
        zip: '682001',
        emergencyContactName: 'Priya',
        emergencyContact: '8888888888',
        emergencyContactRelation: 'Brother',
      );

      expect(edited.diffFrom(original), {
        'phone': '7777777777',
        'address': '2 New Road',
        'emergency_contact_name': 'Priya',
      });
    });

    test('whitespace-only edits are not changes', () {
      // Tapping into a field and out again should not cause a write.
      const edited = PersonalInfo(
        phone: '  9999999999  ',
        address: '1 Old Street',
        city: 'Kochi',
        state: 'Kerala',
        zip: '682001',
        emergencyContactName: 'Arun',
        emergencyContact: '8888888888',
        emergencyContactRelation: 'Brother',
      );

      expect(edited.diffFrom(original), isEmpty);
    });

    test('values are trimmed before being sent', () {
      const edited = PersonalInfo(
        phone: '  7777777777  ',
        address: '1 Old Street',
        city: 'Kochi',
        state: 'Kerala',
        zip: '682001',
        emergencyContactName: 'Arun',
        emergencyContact: '8888888888',
        emergencyContactRelation: 'Brother',
      );

      expect(edited.diffFrom(original), {'phone': '7777777777'});
    });

    test('clearing a field is a change, not a no-op', () {
      // Removing an emergency contact has to reach the server; treating
      // empty as "unchanged" would make it impossible to delete one.
      const edited = PersonalInfo(
        phone: '9999999999',
        address: '1 Old Street',
        city: 'Kochi',
        state: 'Kerala',
        zip: '682001',
        emergencyContactName: '',
        emergencyContact: '8888888888',
        emergencyContactRelation: 'Brother',
      );

      expect(edited.diffFrom(original), {'emergency_contact_name': ''});
    });

    test('the diff never carries a field the server would refuse', () {
      const edited = PersonalInfo(phone: '1');
      final keys = edited.diffFrom(original).keys.toSet();

      // The self-service allowlist. Anything outside it is rejected
      // server-side; sending it would be a silent no-op at best.
      const allowed = {
        'phone',
        'address',
        'city',
        'state',
        'zip',
        'emergency_contact_name',
        'emergency_contact',
        'emergency_contact_relation',
      };
      expect(keys.difference(allowed), isEmpty);

      for (final forbidden in [
        'is_active',
        'badge_id',
        'email',
        'employee_first_name',
        'additional_info',
      ]) {
        expect(keys, isNot(contains(forbidden)));
      }
    });
  });

  group('parsing', () {
    test('missing fields become empty rather than null', () {
      final info = PersonalInfo.fromJson({'phone': '123'});
      expect(info.phone, '123');
      expect(info.address, '');
      expect(info.emergencyContact, '');
    });

    test('a non-map response yields empty values, not a crash', () {
      expect(PersonalInfo.fromJson('nonsense').phone, '');
      expect(PersonalInfo.fromJson(null).address, '');
    });

    test('non-string values are ignored rather than stringified', () {
      // A phone arriving as a number should not become "9999999999.0".
      final info = PersonalInfo.fromJson({'phone': 9999999999});
      expect(info.phone, '');
    });
  });
}
