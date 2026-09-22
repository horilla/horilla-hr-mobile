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
