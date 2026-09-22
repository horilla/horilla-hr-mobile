/// Which modules this build ships.
///
/// Scope was deliberately narrowed (2026-09) to the three modules the product
/// needs solid first: **attendance, leave and employee management**. Payroll
/// and the general requests inbox are built and tested but switched off,
/// because a half-attended module in the tab bar invites use before it is
/// ready.
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

  // --- deferred -----------------------------------------------------------

  /// Payslips and payslip detail. Built; see features/payroll.
  static const payroll = false;

  /// The merged shift / work-type / asset / reimbursement inbox.
  /// Built; see features/requests.
  static const requests = false;

  /// Helpdesk tickets and the ticket thread. Not built.
  static const helpdesk = false;

  /// Objectives, feedback, meetings. Not built.
  static const performance = false;
}
