/// One list, several very different sources.
///
/// The Requests tab shows shift changes, work-type changes, asset requests,
/// reimbursements and attendance corrections together. Server-side these
/// agree on almost nothing: shift and work-type requests carry two booleans
/// (`approved`, `canceled`), reimbursements a `status` string, asset requests
/// an `asset_request_status`, and attendance corrections a pair of
/// `is_validate_request*` flags. Each also names its date differently.
///
/// Normalising here rather than in the widgets means the screen has one shape
/// to render and one place to look when a status reads wrong.
library;

enum RequestKind {
  shift('Shift change'),
  workType('Work type'),
  asset('Asset'),
  reimbursement('Reimbursement'),
  attendance('Attendance fix');

  const RequestKind(this.label);

  final String label;
}

enum RequestState {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const RequestState(this.label);

  final String label;

  bool get isOpen => this == RequestState.pending;
}

class WorkRequest {
  const WorkRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.state,
    this.date,
    this.detail,
  });

  final int id;
  final RequestKind kind;
  final String title;
  final RequestState state;
  final DateTime? date;
  final String? detail;

  // --- adapters, one per source shape -------------------------------------

  /// Shift and work-type requests: two booleans, no status string.
  ///
  /// Order matters. `canceled` wins over `approved`, because a request that
  /// was approved and then cancelled is cancelled -- reading `approved` first
  /// would show it as live.
  static WorkRequest? fromShiftLike(Object? value, RequestKind kind) {
    if (value is! Map<String, dynamic>) return null;

    final title = switch (kind) {
      RequestKind.shift => value['shift_name'],
      _ => value['work_type_name'] ?? value['worktype_name'],
    };

    return WorkRequest(
      id: value['id'] is int ? value['id'] as int : 0,
      kind: kind,
      title: title is String && title.isNotEmpty ? title : kind.label,
      state: value['canceled'] == true
          ? RequestState.cancelled
          : value['approved'] == true
              ? RequestState.approved
              : RequestState.pending,
      date: _date(value['requested_date']),
      detail: value['previous_shift_name'] is String
          ? 'from ${value['previous_shift_name']}'
          : null,
    );
  }

  static WorkRequest? fromReimbursement(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final title = value['title'];
    return WorkRequest(
      id: value['id'] is int ? value['id'] as int : 0,
      kind: RequestKind.reimbursement,
      title: title is String && title.isNotEmpty
          ? title
          : RequestKind.reimbursement.label,
      state: _fromStatusString(value['status']),
      date: _date(value['allowance_on']),
    );
  }

  static WorkRequest? fromAssetRequest(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final description = value['description'];
    return WorkRequest(
      id: value['id'] is int ? value['id'] as int : 0,
      kind: RequestKind.asset,
      title: description is String && description.isNotEmpty
          ? description
          : RequestKind.asset.label,
      // Server-side these are Title-cased ("Requested"), unlike every other
      // status in this API.
      state: _fromStatusString(value['asset_request_status']),
      date: _date(value['asset_request_date']),
    );
  }

  static RequestState _fromStatusString(Object? value) {
    final text = value is String ? value.toLowerCase() : '';
    return switch (text) {
      'approved' => RequestState.approved,
      'rejected' => RequestState.rejected,
      'cancelled' || 'canceled' => RequestState.cancelled,
      _ => RequestState.pending,
    };
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Everything the Requests tab shows, already merged and ordered.
class RequestInbox {
  const RequestInbox({required this.requests});

  final List<WorkRequest> requests;

  static const empty = RequestInbox(requests: []);

  List<WorkRequest> get open =>
      requests.where((r) => r.state.isOpen).toList();

  List<WorkRequest> get closed =>
      requests.where((r) => !r.state.isOpen).toList();
}

// --- lookups the create screens pick from --------------------------------

/// A shift or work type an employee can request.
class RequestOption {
  const RequestOption({required this.id, required this.name});

  final int id;
  final String name;

  static RequestOption? fromShift(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['employee_shift'];
    final id = value['id'];
    if (id is! int || name is! String || name.isEmpty) return null;
    return RequestOption(id: id, name: name);
  }

  static RequestOption? fromWorkType(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['work_type'];
    final id = value['id'];
    if (id is! int || name is! String || name.isEmpty) return null;
    return RequestOption(id: id, name: name);
  }
}

/// An asset category, with how many are actually available -- shown so a
/// request for something with none in stock is a choice made knowingly.
class AssetCategoryOption {
  const AssetCategoryOption({
    required this.id,
    required this.name,
    required this.available,
  });

  final int id;
  final String name;
  final int available;

  static AssetCategoryOption? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final name = value['asset_category_name'];
    if (id is! int || name is! String || name.isEmpty) return null;
    final count = value['asset_count'];
    return AssetCategoryOption(
      id: id,
      name: name,
      available: count is int ? count : 0,
    );
  }
}

// --- what the create screens send -----------------------------------------

/// A shift-change or work-type-change request.
///
/// Same shape server-side down to the field names -- `shift_id` /
/// `previous_shift_id` for one kind, `work_type_id` / `previous_work_type_id`
/// for the other -- which is why one class with a `forShift` flag covers
/// both instead of two near-identical ones.
class ShiftOrWorkTypeRequest {
  const ShiftOrWorkTypeRequest({
    required this.forShift,
    required this.requestedId,
    required this.previousId,
    required this.requestedDate,
    this.requestedTill,
    required this.reason,
  });

  final bool forShift;
  final int requestedId;
  final int? previousId;
  final DateTime requestedDate;
  final DateTime? requestedTill;
  final String reason;

  String get path => forShift ? '/base/shift-requests/' : '/base/worktype-requests/';

  // employeeId is a parameter, not a field: the server only auto-fills it
  // for employees without add-permission on the request, so a manager or
  // HR user submitting for themselves must send it explicitly or the
  // request is created with employee_id null. Same pattern as
  // LeaveApplication.toJson in leave_models.dart.
  Map<String, dynamic> toJson(int employeeId) => {
    'employee_id': employeeId,
    if (forShift) ...{
      'shift_id': requestedId,
      if (previousId != null) 'previous_shift_id': previousId,
    } else ...{
      'work_type_id': requestedId,
      if (previousId != null) 'previous_work_type_id': previousId,
    },
    'requested_date': _isoDate(requestedDate),
    if (requestedTill != null) 'requested_till': _isoDate(requestedTill!),
    'description': reason,
  };
}

/// `2026-10-24`, the date shape every request endpoint here expects.
String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// A request for company-owned equipment.
class AssetRequestDraft {
  const AssetRequestDraft({required this.categoryId, required this.reason});

  final int categoryId;
  final String reason;

  // requested_employee_id, not employee_id -- the asset-request endpoint
  // names its subject differently from every other request type here.
  Map<String, dynamic> toJson(int employeeId) => {
    'asset_category_id': categoryId,
    'requested_employee_id': employeeId,
    'description': reason,
  };
}

/// An expense claim. Receipt capture is not built in this pass --
/// `attachment` is optional server-side, so a claim without one is a
/// complete, valid request, not a partial one.
class ReimbursementDraft {
  const ReimbursementDraft({
    required this.title,
    required this.amount,
    required this.incurredOn,
  });

  final String title;
  final double amount;
  final DateTime incurredOn;

  // `type`, `badge_id` and `employee_full_name` are required by the
  // serializer's validation despite being derived server-side from
  // employee_id -- confirmed live: any non-blank placeholder for the
  // latter two passes validation and is overwritten in the response with
  // the real employee's badge id and name, so what's sent here is
  // discarded rather than stored.
  Map<String, dynamic> toJson(int employeeId) => {
    'title': title,
    'employee_id': employeeId,
    'amount': amount,
    'allowance_on': _isoDate(incurredOn),
    'type': 'reimbursement',
    'badge_id': '-',
    'employee_full_name': '-',
  };
}
