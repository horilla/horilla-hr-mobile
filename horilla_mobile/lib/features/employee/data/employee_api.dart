import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'employee_models.dart';

class EmployeeApi {
  EmployeeApi(this._dio);

  final Dio _dio;

  /// The directory.
  ///
  /// What comes back depends on what the server lets this person see: an
  /// admin gets everyone, a manager their reports, and an ordinary employee
  /// whatever the `employee_view` accessibility setting allows -- possibly
  /// only themselves. The app does not try to predict which; it renders what
  /// it is given, and says so when that is just one row.
  Future<List<DirectoryEntry>> fetchDirectory({String? search}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/employee/list/employees/',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page_size': 50,
        },
      );

      final body = response.data;
      final raw = switch (body) {
        final Map<String, dynamic> map => map['results'],
        final List list => list,
        _ => null,
      };
      if (raw is! List) return const [];

      return raw
          .map(DirectoryEntry.fromJson)
          .whereType<DirectoryEntry>()
          .toList()
        ..sort((a, b) => a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            ));
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<WorkInformation> fetchWorkInformation(int workInfoId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/employee/employee-work-information/$workInfoId/',
      );
      return WorkInformation.fromJson(response.data);
    } on DioException catch (e) {
      // Work info is gated to self, manager and permission holders, so a
      // colleague's is often simply not visible. That is a normal outcome
      // rather than an error: the profile shows what it has.
      final failure = e.error;
      if (failure is ApiForbidden || failure is ApiNotFound) {
        return WorkInformation.empty;
      }
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final employeeApiProvider = Provider<EmployeeApi>(
  (ref) => EmployeeApi(ref.watch(apiClientProvider).dio),
);

/// What the directory search box currently holds.
///
/// A Notifier rather than StateProvider, which Riverpod 3 removed.
class DirectorySearch extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final directorySearchProvider =
    NotifierProvider<DirectorySearch, String>(DirectorySearch.new);

final directoryProvider = FutureProvider<List<DirectoryEntry>>((ref) async {
  final search = ref.watch(directorySearchProvider);
  return ref.watch(employeeApiProvider).fetchDirectory(search: search);
});
