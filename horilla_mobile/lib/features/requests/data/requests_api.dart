import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'request_models.dart';

class RequestsApi {
  RequestsApi(this._dio);

  final Dio _dio;

  /// Four endpoints, one list.
  ///
  /// They are fetched concurrently, and a failure in any one does not take
  /// the screen down: a person with three shift requests should still see
  /// them when the asset service is unhappy. A partial list is far more
  /// useful than an error page, and the alternative -- all-or-nothing --
  /// makes the whole tab hostage to the least reliable endpoint.
  Future<RequestInbox> fetchInbox() async {
    final results = await Future.wait([
      _collect('/base/shift-requests/',
          (v) => WorkRequest.fromShiftLike(v, RequestKind.shift)),
      _collect('/base/worktype-requests/',
          (v) => WorkRequest.fromShiftLike(v, RequestKind.workType)),
      _collect('/asset/asset-requests/', WorkRequest.fromAssetRequest),
      // Note the spelling: the server's route really is "reimbusement".
      _collect('/payroll/reimbusement/', WorkRequest.fromReimbursement),
    ]);

    final merged = results.expand((r) => r).toList()
      // Newest first, and anything undated last rather than pinned to the top
      // by a null sorting as epoch.
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

    return RequestInbox(requests: merged);
  }

  Future<List<WorkRequest>> _collect(
    String path,
    WorkRequest? Function(Object?) parse,
  ) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return _items(response.data, parse);
    } on DioException {
      // Deliberately swallowed -- see fetchInbox. One unavailable request
      // type must not blank the others.
      return const [];
    }
  }

  // --- lookups for the create screens ---------------------------------

  Future<List<RequestOption>> fetchShifts() =>
      _list('/base/employee-shift/', RequestOption.fromShift);

  Future<List<RequestOption>> fetchWorkTypes() =>
      _list('/base/worktypes/', RequestOption.fromWorkType);

  Future<List<AssetCategoryOption>> fetchAssetCategories() => _list(
    '/asset/asset-categories/',
    AssetCategoryOption.fromJson,
  );

  Future<List<T>> _list<T>(String path, T? Function(Object?) parse) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return _items(response.data, parse);
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  List<T> _items<T>(Object? body, T? Function(Object?) parse) {
    final raw = switch (body) {
      final Map<String, dynamic> map => map['results'],
      final List list => list,
      _ => null,
    };
    if (raw is! List) return const [];
    return raw.map(parse).whereType<T>().toList();
  }

  // --- creating a request ------------------------------------------------

  // employeeId is always sent explicitly: the server only auto-fills it for
  // callers without add-permission on the request, so a manager or HR user
  // (who has that permission for everyone) submitting for themselves would
  // otherwise create an orphaned request with employee_id null. Verified
  // live: without it the created record had employee_id: null; with it,
  // correctly attributed.
  Future<void> submitShiftOrWorkType(
    ShiftOrWorkTypeRequest draft,
    int employeeId,
  ) async {
    try {
      await _dio.post<dynamic>(draft.path, data: draft.toJson(employeeId));
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<void> submitAssetRequest(
    AssetRequestDraft draft,
    int employeeId,
  ) async {
    try {
      await _dio.post<dynamic>(
        '/asset/asset-requests/',
        data: draft.toJson(employeeId),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<void> submitReimbursement(
    ReimbursementDraft draft,
    int employeeId,
  ) async {
    try {
      await _dio.post<dynamic>(
        '/payroll/reimbusement/',
        data: draft.toJson(employeeId),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final requestsApiProvider = Provider<RequestsApi>(
  (ref) => RequestsApi(ref.watch(apiClientProvider).dio),
);

final requestInboxProvider = FutureProvider<RequestInbox>((ref) {
  return ref.watch(requestsApiProvider).fetchInbox();
});

final shiftOptionsProvider = FutureProvider<List<RequestOption>>((ref) {
  return ref.watch(requestsApiProvider).fetchShifts();
});

final workTypeOptionsProvider = FutureProvider<List<RequestOption>>((ref) {
  return ref.watch(requestsApiProvider).fetchWorkTypes();
});

final assetCategoryOptionsProvider =
    FutureProvider<List<AssetCategoryOption>>((ref) {
      return ref.watch(requestsApiProvider).fetchAssetCategories();
    });
