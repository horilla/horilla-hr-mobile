/// The approvals queue, with the design's undo window.
///
/// A decision is not sent the moment it is made. The card disappears, a
/// toast offers Undo for as long as the toast is visible, and only when that
/// window closes does the request go to the server. That is the only way an
/// Undo can be honest here: none of these endpoints can take a decision back
/// once made, so "undo" after sending would mean a second, opposite decision
/// the employee may already have been notified about.
///
/// Each decision has its own timer. Deciding a second card while the first
/// is still in its window replaces the toast (one at a time) but does not
/// cancel the first decision -- it still commits when its own time is up.
///
/// ponytail: decisions still inside their window are lost if the app is
/// killed in those few seconds. Persist them if that turns out to matter.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../shared/widgets/toast.dart';
import 'approval_models.dart';
import 'approvals_api.dart';

class ApprovalsController extends AsyncNotifier<ApprovalInbox> {
  /// Overridable so tests need not wait out the real toast.
  Duration get undoWindow => ToastController.visibleFor;

  List<ApprovalItem> _fetched = const [];

  /// Decided but not yet confirmed by the server -- still inside the undo
  /// window, or in flight. Hidden from the queue either way.
  final Map<String, Timer?> _held = {};

  @override
  Future<ApprovalInbox> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.capabilities.isManager) {
      _fetched = const [];
      return ApprovalInbox.empty;
    }
    _fetched =
        (await ref
                .read(approvalsApiProvider)
                .fetchInbox(
                  selfId: session.user.id,
                  currencySymbol: session.capabilities.currencySymbol,
                ))
            .items;
    return _visible();
  }

  ApprovalInbox _visible() =>
      ApprovalInbox(_fetched.where((i) => !_held.containsKey(i.key)).toList());

  void _publish() => state = AsyncData(_visible());

  void decide(ApprovalItem item, {required bool approve}) {
    if (_held.containsKey(item.key)) return;
    _held[item.key] = Timer(undoWindow, () => _commit(item, approve));
    _publish();

    final verb = approve ? 'Approved' : 'Rejected';
    ref
        .read(toastProvider.notifier)
        .show(
          '$verb · ${_possessive(item.name)} ${item.kind.label.toLowerCase()}',
          onUndo: () => undo(item),
        );
  }

  void undo(ApprovalItem item) {
    final timer = _held[item.key];
    // Null means already in flight -- too late to take back.
    if (timer == null) return;
    timer.cancel();
    _held.remove(item.key);
    _publish();
  }

  Future<void> _commit(ApprovalItem item, bool approve) async {
    _held[item.key] = null;
    try {
      await ref.read(approvalsApiProvider).decide(item, approve: approve);
      _fetched = _fetched.where((i) => i.key != item.key).toList();
      _held.remove(item.key);
      _publish();
    } on ApiFailure catch (failure) {
      // Back in the queue, with the reason -- a decision that silently did
      // not happen is the worst outcome this screen can have.
      _held.remove(item.key);
      _publish();
      ref
          .read(toastProvider.notifier)
          .show(
            "Couldn't ${approve ? 'approve' : 'reject'} "
            '${_possessive(item.name)} ${item.kind.label.toLowerCase()}: '
            '${failure.message}',
          );
    }
  }

  static String _possessive(String name) {
    final first = name.split(' ').first;
    return first.endsWith('s') ? "$first'" : "$first's";
  }
}

final approvalsProvider =
    AsyncNotifierProvider<ApprovalsController, ApprovalInbox>(
      ApprovalsController.new,
    );
