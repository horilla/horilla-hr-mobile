import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'payroll_models.dart';

class PayrollApi {
  PayrollApi(this._dio);

  final Dio _dio;

  Future<List<PayslipSummary>> fetchPayslips() async {
    try {
      final response = await _dio.get<dynamic>('/payroll/payslip/');
      final body = response.data;
      final raw = switch (body) {
        final Map<String, dynamic> map => map['results'],
        final List list => list,
        _ => null,
      };
      if (raw is! List) return const [];

      final payslips =
          raw.map(PayslipSummary.fromJson).whereType<PayslipSummary>().toList()
            // Newest first: the one someone opens the screen for is the last one
            // they were paid.
            ..sort((a, b) => b.endDate.compareTo(a.endDate));
      return payslips;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<PayslipDetail> fetchPayslip(int id) async {
    try {
      final response = await _dio.get<dynamic>('/payroll/payslip/$id');
      final detail = PayslipDetail.fromJson(response.data);
      if (detail == null) throw const ApiIncompatibleServer();
      return detail;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final payrollApiProvider = Provider<PayrollApi>(
  (ref) => PayrollApi(ref.watch(apiClientProvider).dio),
);

final payslipsProvider = FutureProvider<List<PayslipSummary>>((ref) {
  return ref.watch(payrollApiProvider).fetchPayslips();
});

final payslipProvider = FutureProvider.family<PayslipDetail, int>((ref, id) {
  return ref.watch(payrollApiProvider).fetchPayslip(id);
});

/// The configured currency symbol, when the server tells us.
///
/// Not guessed. `PayrollSettings.currency_symbol` is per-install and defaults
/// to `$`, so rendering a payslip in an assumed currency would be wrong for
/// most deployments -- and a wrong currency on a payslip is worse than none.
final currencySymbolProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider)?.capabilities.currencySymbol;
});
