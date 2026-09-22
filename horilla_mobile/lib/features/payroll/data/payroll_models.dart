/// Payroll models.
library;

/// How money is rendered.
///
/// The symbol is *not* hardcoded. `PayrollSettings.currency_symbol` defaults
/// to `$` server-side and is configured per install, so assuming any
/// particular currency would be wrong for most of them -- and a payslip
/// showing the wrong currency is worse than one showing none.
///
/// The payslip endpoints do not currently return it (only the PDF view's
/// context does), so until the API carries it this falls back to rendering
/// the number alone rather than guessing.
class Money {
  const Money(this.amount, {this.symbol});

  final double amount;
  final String? symbol;

  String get formatted {
    final value = _grouped(amount);
    return symbol == null || symbol!.isEmpty ? value : '$symbol$value';
  }

  /// Thousands separators, two decimals only when they carry information.
  static String _grouped(double value) {
    final negative = value < 0;
    final abs = value.abs();
    final whole = abs.truncate();
    final fraction = abs - whole;

    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }

    final text = fraction > 0.004
        ? '$buffer.${(fraction * 100).round().toString().padLeft(2, '0')}'
        : buffer.toString();
    return negative ? '-$text' : text;
  }
}

/// One line of the earnings or deductions breakdown.
class PayComponent {
  const PayComponent({required this.title, required this.amount});

  final String title;
  final double amount;

  static PayComponent? fromJson(Object? value) {
    if (value is! Map) return null;
    final title = value['title'] ?? value['name'];
    final amount = _toDouble(value['amount']);
    if (title is! String || title.isEmpty || amount == null) return null;
    return PayComponent(title: title, amount: amount);
  }
}

class PayslipSummary {
  const PayslipSummary({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.netPay,
    required this.grossPay,
    required this.deduction,
    this.status,
  });

  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final double netPay;
  final double grossPay;
  final double deduction;
  final String? status;

  static PayslipSummary? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final start = value['start_date'];
    final end = value['end_date'];
    final startDate = start is String ? DateTime.tryParse(start) : null;
    final endDate = end is String ? DateTime.tryParse(end) : null;
    if (startDate == null || endDate == null) return null;

    return PayslipSummary(
      id: value['id'] is int ? value['id'] as int : 0,
      startDate: startDate,
      endDate: endDate,
      netPay: _toDouble(value['net_pay']) ?? 0,
      grossPay: _toDouble(value['gross_pay']) ?? 0,
      deduction: _toDouble(value['deduction']) ?? 0,
      status: value['status'] is String ? value['status'] as String : null,
    );
  }
}

/// A payslip with its component breakdown, from `pay_head_data`.
class PayslipDetail {
  const PayslipDetail({
    required this.summary,
    required this.earnings,
    required this.deductions,
    this.basicPay,
    this.contractWage,
  });

  final PayslipSummary summary;
  final List<PayComponent> earnings;
  final List<PayComponent> deductions;
  final double? basicPay;
  final double? contractWage;

  static PayslipDetail? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final summary = PayslipSummary.fromJson(value);
    if (summary == null) return null;

    final head = value['pay_head_data'];
    final data = head is Map<String, dynamic> ? head : const {};

    return PayslipDetail(
      summary: summary,
      earnings: _components(data['allowances']),
      deductions: [
        ..._components(data['deductions']),
        ..._components(data['basic_pay_deductions']),
        ..._components(data['gross_pay_deductions']),
        ..._components(data['pretax_deductions']),
        ..._components(data['post_tax_deductions']),
      ],
      basicPay: _toDouble(value['basic_pay']),
      contractWage: _toDouble(value['contract_wage']),
    );
  }

  static List<PayComponent> _components(Object? value) {
    if (value is! List) return const [];
    return value.map(PayComponent.fromJson).whereType<PayComponent>().toList();
  }
}

double? _toDouble(Object? value) => switch (value) {
      final double d => d,
      final int i => i.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };
