/// Payroll: money formatting and payslip parsing.
///
/// Money is the one place in this app where a rendering mistake is
/// immediately visible and immediately alarming, so the formatter gets the
/// most attention -- particularly the currency symbol, which is per-install
/// and must never be guessed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/features/payroll/data/payroll_models.dart';

void main() {
  group('money formatting', () {
    test('thousands are grouped', () {
      expect(const Money(86420).formatted, '86,420');
      expect(const Money(1234567).formatted, '1,234,567');
      expect(const Money(999).formatted, '999');
      expect(const Money(1000).formatted, '1,000');
    });

    test('whole amounts do not carry empty decimals', () {
      expect(const Money(4000).formatted, '4,000');
      expect(const Money(0).formatted, '0');
    });

    test('real decimals are kept', () {
      expect(const Money(1234.5).formatted, '1,234.50');
      expect(const Money(99.99).formatted, '99.99');
    });

    test('negatives keep their sign outside the digits', () {
      expect(const Money(-1500).formatted, '-1,500');
    });

    test('the symbol is used when the server provides one', () {
      expect(const Money(86420, symbol: r'$').formatted, r'$86,420');
      expect(const Money(86420, symbol: '₹').formatted, '₹86,420');
      expect(const Money(86420, symbol: '€').formatted, '€86,420');
    });

    test('an unknown currency renders the number alone, never a guess', () {
      // PayrollSettings.currency_symbol is per-install and defaults to '$'.
      // Showing a payslip in the wrong currency is worse than showing none.
      expect(const Money(86420).formatted, '86,420');
      expect(const Money(86420, symbol: '').formatted, '86,420');
    });
  });

  group('capabilities carry the currency', () {
    test('a symbol is read when present', () {
      final caps = Capabilities.fromJson({
        'role': 'employee',
        'permissions': const {},
        'features': const {},
        'currency_symbol': '₹',
      });
      expect(caps.currencySymbol, '₹');
    });

    test('absence stays null rather than defaulting', () {
      final caps = Capabilities.fromJson({
        'role': 'employee',
        'permissions': const {},
        'features': const {},
      });
      expect(caps.currencySymbol, isNull);
    });

    test('an empty string is treated as absent', () {
      final caps = Capabilities.fromJson({
        'role': 'employee',
        'permissions': const {},
        'features': const {},
        'currency_symbol': '',
      });
      expect(caps.currencySymbol, isNull);
    });
  });

  group('payslip parsing', () {
    Map<String, dynamic> body({Object? payHead}) => {
          'id': 7,
          'start_date': '2026-08-01',
          'end_date': '2026-08-31',
          'net_pay': 86420.0,
          'gross_pay': 102000.0,
          'deduction': 15580.0,
          'basic_pay': 60000.0,
          'pay_head_data': ?payHead,
        };

    test('a summary parses the money fields', () {
      final summary = PayslipSummary.fromJson(body())!;
      expect(summary.id, 7);
      expect(summary.netPay, 86420.0);
      expect(summary.grossPay, 102000.0);
    });

    test('a payslip without dates is discarded rather than half-rendered', () {
      expect(PayslipSummary.fromJson({'id': 7, 'net_pay': 100}), isNull);
    });

    test('earnings and deductions come out of pay_head_data', () {
      final detail = PayslipDetail.fromJson(
        body(
          payHead: {
            'allowances': [
              {'title': 'House rent', 'amount': 20000},
              {'title': 'Travel', 'amount': 5000},
            ],
            'deductions': [
              {'title': 'Provident fund', 'amount': 7200},
            ],
          },
        ),
      )!;

      expect(detail.earnings.length, 2);
      expect(detail.earnings.first.title, 'House rent');
      expect(detail.deductions.length, 1);
    });

    test('the several deduction buckets are merged into one list', () {
      // The server splits these by when they apply; the payslip shows one
      // list, because that is what the printed payslip shows.
      final detail = PayslipDetail.fromJson(
        body(
          payHead: {
            'deductions': [
              {'title': 'A', 'amount': 1},
            ],
            'basic_pay_deductions': [
              {'title': 'B', 'amount': 2},
            ],
            'post_tax_deductions': [
              {'title': 'C', 'amount': 3},
            ],
          },
        ),
      )!;

      expect(detail.deductions.map((d) => d.title), ['A', 'B', 'C']);
    });

    test('a missing pay_head_data yields empty lists, not a crash', () {
      final detail = PayslipDetail.fromJson(body())!;
      expect(detail.earnings, isEmpty);
      expect(detail.deductions, isEmpty);
      expect(detail.summary.netPay, 86420.0);
    });

    test('paid days, LOP and the bank mask come from the payload', () {
      final summary = PayslipSummary.fromJson(
        body(
          payHead: {'paid_days': 21, 'unpaid_days': 0},
        )..['bank_account_check_number'] = 'HDFC00004821',
      )!;

      expect(summary.daysLine, 'Paid days 21 · LOP 0');
      expect(summary.bankLast4, '4821');
    });

    test('a short account number is not masked into a guess', () {
      final summary = PayslipSummary.fromJson(
        body()..['bank_account_check_number'] = '12',
      )!;
      expect(summary.bankLast4, isNull);
      expect(summary.daysLine, isNull);
    });

    test('tax and net deduction buckets are part of the one list', () {
      final detail = PayslipDetail.fromJson(
        body(
          payHead: {
            'tax_deductions': [
              {'title': 'Federal tax', 'amount': 9260},
            ],
            'net_deductions': [
              {'title': 'Loan', 'amount': 1000},
            ],
          },
        ),
      )!;

      expect(detail.deductions.map((d) => d.title), ['Federal tax', 'Loan']);
    });

    test('a malformed component is skipped, not rendered blank', () {
      final detail = PayslipDetail.fromJson(
        body(
          payHead: {
            'allowances': [
              {'title': 'Good', 'amount': 100},
              {'amount': 50},
              {'title': 'No amount'},
              'nonsense',
            ],
          },
        ),
      )!;

      expect(detail.earnings.length, 1);
      expect(detail.earnings.single.title, 'Good');
    });
  });
}
