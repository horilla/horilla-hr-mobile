/// Editing your own record.
///
/// The server restricts this to an allowlist -- contact details, address,
/// date of birth, marital status, emergency contact and avatar -- and refuses
/// the rest, so a field like `is_active` or `badge_id` cannot be written from
/// here even if the app tried. It also honours an administrator's
/// profile-edit switch, which is why the app asks the capability payload
/// whether to offer the screen at all rather than discovering the refusal
/// after someone has typed.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';

@immutable
class PersonalInfo {
  const PersonalInfo({
    this.phone = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.emergencyContactName = '',
    this.emergencyContact = '',
    this.emergencyContactRelation = '',
  });

  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String emergencyContactName;
  final String emergencyContact;
  final String emergencyContactRelation;

  static PersonalInfo fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return const PersonalInfo();

    String read(String key) {
      final v = value[key];
      return v is String ? v : '';
    }

    return PersonalInfo(
      phone: read('phone'),
      address: read('address'),
      city: read('city'),
      state: read('state'),
      zip: read('zip'),
      emergencyContactName: read('emergency_contact_name'),
      emergencyContact: read('emergency_contact'),
      emergencyContactRelation: read('emergency_contact_relation'),
    );
  }

  /// Only what changed.
  ///
  /// The endpoint has no PATCH, so an update is a PUT with partial
  /// semantics -- sending only the edited fields keeps this from silently
  /// rewriting a field someone else changed between the read and the write.
  Map<String, dynamic> diffFrom(PersonalInfo original) {
    final changes = <String, dynamic>{};
    void compare(String key, String mine, String theirs) {
      if (mine.trim() != theirs.trim()) changes[key] = mine.trim();
    }

    compare('phone', phone, original.phone);
    compare('address', address, original.address);
    compare('city', city, original.city);
    compare('state', state, original.state);
    compare('zip', zip, original.zip);
    compare(
      'emergency_contact_name',
      emergencyContactName,
      original.emergencyContactName,
    );
    compare('emergency_contact', emergencyContact, original.emergencyContact);
    compare(
      'emergency_contact_relation',
      emergencyContactRelation,
      original.emergencyContactRelation,
    );
    return changes;
  }
}

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<PersonalInfo> fetch(int employeeId) async {
    try {
      final response =
          await _dio.get<dynamic>('/employee/employees/$employeeId/');
      return PersonalInfo.fromJson(response.data);
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Returns without sending anything when nothing changed.
  Future<void> update(int employeeId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    try {
      await _dio.put<dynamic>(
        '/employee/employees/$employeeId/',
        data: changes,
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final profileApiProvider =
    Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider).dio));

final personalInfoProvider = FutureProvider<PersonalInfo>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return const PersonalInfo();
  return ref.watch(profileApiProvider).fetch(session.user.id);
});

/// Whether this build should offer profile editing at all.
///
/// Read from the capability payload rather than assumed: an administrator can
/// switch self-service editing off, and the web UI honours that. Offering a
/// form that always fails would be worse than not offering one.
final canEditProfileProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider)?.capabilities.can('edit_own_profile') ??
      false;
});
