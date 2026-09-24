/// Which modules this build ships.
///
/// Scope was deliberately narrowed (2026-09) to the three modules the product
/// needs solid first: **attendance, leave and employee management**. Payroll
/// and the requests inbox widened back in once their remaining screens were
/// built: payslips are opened from Home, and the requests tab now has all
/// three of its create screens (shift/work-type, asset, reimbursement).
/// Helpdesk and performance stay off -- neither is built.
///
/// This is a flag rather than commented-out code on purpose. Commented code
/// stops compiling, drifts from the APIs around it and is miserable to
/// restore; the screens behind these flags still build, still run their
/// tests, and come back by flipping one constant.
///
/// To bring a module back: set its flag true. Nothing else needs editing --
/// the tab bar, the router and the home screen's quick actions all read from
/// here.
library;

abstract final class Modules {
  /// Punch, hour account, activity log.
  static const attendance = true;

  /// Balances, requests, applying.
  static const leave = true;

  /// Directory, colleague profiles, own profile and settings.
  static const employee = true;

  /// Payslips and payslip detail. Opened from Home.
  static const payroll = true;

  /// The merged shift / work-type / asset / reimbursement inbox, with
  /// create screens for all three request types.
  static const requests = true;

  // --- deferred -----------------------------------------------------------

  /// Helpdesk tickets and the ticket thread. Not built.
  static const helpdesk = false;

  /// Objectives, feedback, meetings. Not built.
  static const performance = false;

  /// Comp-off (encashing extra hours worked). `CompensatoryLeaveRequest`
  /// exists server-side but has no REST endpoint at all -- unlike the
  /// others above, this shows up as a real card in the Leave screen,
  /// visibly disabled, rather than being hidden entirely. Flip once the
  /// backend actually has a route to call.
  static const compOff = false;
}
