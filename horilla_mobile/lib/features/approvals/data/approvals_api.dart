/// Fetching and deciding a manager's approvals.
///
/// Six endpoints, each with its own conventions. The ones that bite:
///
/// * Shift and attendance-request routes have no trailing slash; leave and
///   work-type routes do. Dio does not add or strip slashes, so the paths
///   below are exact.
/// * Shift reject is POST; every other decision is PUT, except
///   reimbursements, which are POST with a `status` body.
/// * Several decisions answer 200 with `{"error": ...}` or
///   `{"status": "failed"}` on refusal, so a 2xx is not proof of success.
/// * Work-type approve can save and *then* answer 400 when its notification
///   fails -- re-read before reporting a failure.
/// * The API's own permission decorator answers 401 for "no permission",
///   which would otherwise surface as "Please sign in again".
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'approval_models.dart';

typedef _Parse = ApprovalItem? Function(Object?);

class ApprovalsApi {
  ApprovalsApi(this._dio);

  final Dio _dio;

  /// ponytail: pages capped at 5 x 100 per source. A manager with more than
  /// 500 open requests of one kind has a problem this screen can't fix;
  /// raise the cap or add server-side "pending only" filters if it happens.
  static const _pageSize = 100;
  static const _maxPages = 5;

  Future<ApprovalInbox> fetchInbox({
    required int selfId,
    String? currencySymbol,
  }) async {
    final sources = <(String, Map<String, dynamic>, _Parse)>[
      (
        '/leave/request/',
        {'status': 'requested'},
        (v) => ApprovalItem.fromLeave(v, selfId: selfId),
      ),
      (
        '/leave/allocation-request/',
        const {},
        (v) => ApprovalItem.fromAllocation(v, selfId: selfId),
      ),
      (
        '/attendance/attendance-request/',
        const {},
        (v) => ApprovalItem.fromAttendanceRequest(v, selfId: selfId),
      ),
      (
        '/base/shift-requests/',
        const {},
        (v) => ApprovalItem.fromShift(v, selfId: selfId),
      ),
      (
        '/base/worktype-requests/',
        const {},
        (v) => ApprovalItem.fromWorkType(v, selfId: selfId),
      ),
      (
        // The server's spelling.
        '/payroll/reimbusement/',
        const {},
        (v) => ApprovalItem.fromReimbursement(
          v,
          selfId: selfId,
          currencySymbol: currencySymbol,
        ),
      ),
    ];

    // One unavailable source must not blank the others -- but if every one
    // failed, "All caught up" would be a lie, so that surfaces as an error.
    final failures = <ApiFailure>[];
    final results = await Future.wait(
      sources.map((s) async {
        try {
          return await _allPages(s.$1, s.$2, s.$3);
        } on ApiFailure catch (f) {
          failures.add(f);
          return const <ApprovalItem>[];
        }
      }),
    );
    if (failures.length == sources.length) throw failures.first;

    final items = results.expand((r) => r).toList()
      ..sort((a, b) {
        if (a.submitted == null && b.submitted == null) return 0;
        if (a.submitted == null) return 1;
        if (b.submitted == null) return -1;
        return b.submitted!.compareTo(a.submitted!);
      });
    return ApprovalInbox(items);
  }

  Future<List<ApprovalItem>> _allPages(
    String path,
    Map<String, dynamic> query,
    _Parse parse,
  ) async {
    final items = <ApprovalItem>[];
    for (var page = 1; page <= _maxPages; page++) {
      final body = await _get(path, {
        ...query,
        'page_size': _pageSize,
        'page': page,
      });
      final raw = switch (body) {
        final Map<String, dynamic> map => map['results'],
        final List list => list,
        _ => null,
      };
      if (raw is! List) break;
      items.addAll(raw.map(parse).whereType<ApprovalItem>());
      // A bare list, or a last page, ends it.
      if (body is! Map<String, dynamic> || body['next'] == null) break;
    }
    return items;
  }

  Future<Object?> _get(String path, Map<String, dynamic> query) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Sends one decision. Throws [ApiFailure] with a message fit to show.
  Future<void> decide(ApprovalItem item, {required bool approve}) async {
    if (!approve && !item.canReject) {
      throw const ApiUnknown("This request can't be rejected from the app.");
    }
    final id = item.id;
    try {
      switch (item.kind) {
        case ApprovalKind.leave:
          await _send('PUT', '/leave/${approve ? 'approve' : 'reject'}/$id/');
        case ApprovalKind.allocation:
          await _send(
            'PUT',
            '/leave/allocation-${approve ? 'approve' : 'reject'}/$id/',
          );
        case ApprovalKind.attendance:
          await _send('PUT', '/attendance/attendance-request-approve/$id');
        case ApprovalKind.shift:
          await (approve
              ? _send('PUT', '/base/shift-request-approve/$id')
              : _send('POST', '/base/shift-request-cancel/$id'));
        case ApprovalKind.workType:
          await _decideWorkType(id, approve: approve);
        case ApprovalKind.reimbursement:
          await _send(
            'POST',
            '/payroll/reimbusement-approve-reject/$id',
            data: {
              'status': approve ? 'approved' : 'rejected',
              if (item.encashAmount != null) 'amount': item.encashAmount,
            },
          );
      }
    } on ApiFailure catch (f) {
      throw _explain(f);
    }
  }

  Future<void> _decideWorkType(int id, {required bool approve}) async {
    if (!approve) {
      // ponytail: this endpoint answers 200 whether or not it did anything,
      // so there is no failure to detect here. A refresh shows the truth.
      await _send('PUT', '/base/worktype-requests-cancel/$id/');
      return;
    }
    try {
      await _send('PUT', '/base/worktype-requests-approve/$id/');
    } on ApiFailure {
      // Approve can save and then fail on its notification. Re-read before
      // telling a manager their approval did not go through.
      final current = await _get('/base/worktype-requests/$id/', const {});
      if (current is Map && current['approved'] == true) return;
      rethrow;
    }
  }

  Future<void> _send(String method, String path, {Object? data}) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
    // A 2xx that is really a refusal.
    final body = response.data;
    if (body is Map) {
      final error = body['error'];
      if (error is String && error.trim().isNotEmpty) {
        throw ApiUnknown(error.trim());
      }
      if (body['status'] == 'failed') {
        throw const ApiUnknown('The server did not accept that decision.');
      }
    }
  }

  static ApiFailure _explain(ApiFailure f) {
    // The API's own permission decorator answers 401, not 403, for a caller
    // who lacks the permission. The session is fine; the right is missing.
    if (f is ApiUnauthenticated) {
      return const ApiForbidden(
        "You don't have permission to decide this request.",
      );
    }
    return f;
  }
}

final approvalsApiProvider = Provider<ApprovalsApi>(
  (ref) => ApprovalsApi(ref.watch(apiClientProvider).dio),
);
