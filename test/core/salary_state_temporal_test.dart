import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner_flutter/core/providers/salary_provider.dart';

void main() {
  group('SalaryState & TemporaryExpense Temporal Forecast Calculation Tests', () {
    test('TemporaryExpense isActiveForPeriod works across boundary months', () {
      final exp = TemporaryExpense(
        id: 'tax-1',
        label: 'Impôts Fisc',
        monthlyAmount: 600.0,
        startPeriod: '2026-09',
        durationMonths: 4, // 2026-09, 2026-10, 2026-11, 2026-12
      );

      expect(exp.isActiveForPeriod('2026-08'), isFalse);
      expect(exp.isActiveForPeriod('2026-09'), isTrue);
      expect(exp.isActiveForPeriod('2026-10'), isTrue);
      expect(exp.isActiveForPeriod('2026-11'), isTrue);
      expect(exp.isActiveForPeriod('2026-12'), isTrue);
      expect(exp.isActiveForPeriod('2027-01'), isFalse);
    });

    test('SalaryState calculates temporary expenses dynamically for any period', () {
      final state = SalaryState(
        temporaryExpenses: [
          TemporaryExpense(
            id: 'fisc',
            label: 'Fisc',
            monthlyAmount: 600.0,
            startPeriod: '2026-09',
            durationMonths: 6,
          ),
          TemporaryExpense(
            id: 'ortho',
            label: 'Orthodontie',
            monthlyAmount: 150.0,
            startPeriod: '2026-08',
            durationMonths: 3, // 2026-08, 2026-09, 2026-10
          ),
        ],
      );

      // In 2026-08: Only ortho (150.0)
      expect(state.temporaryExpensesMonthlyForPeriod('2026-08'), equals(150.0));
      expect(state.getActiveTemporaryExpensesForPeriod('2026-08').length, equals(1));

      // In 2026-09: Both fisc (600) + ortho (150) = 750.0
      expect(state.temporaryExpensesMonthlyForPeriod('2026-09'), equals(750.0));
      expect(state.getActiveTemporaryExpensesForPeriod('2026-09').length, equals(2));

      // In 2026-11: Only fisc (600)
      expect(state.temporaryExpensesMonthlyForPeriod('2026-11'), equals(600.0));
      expect(state.getActiveTemporaryExpensesForPeriod('2026-11').length, equals(1));

      // In 2027-04: None active
      expect(state.temporaryExpensesMonthlyForPeriod('2027-04'), equals(0.0));
    });

    test('SalaryState taxAdjustmentMonthlyForPeriod calculates staggered tax correctly', () {
      final state = SalaryState(
        taxAdjustment: const TaxAdjustment(
          netTaxAmount: 400.0,
          adjustmentType: TaxAdjustmentType.owed,
          staggerInstallments: 4,
          firstInstallmentPeriod: '2026-09',
        ),
      );

      expect(state.taxAdjustmentMonthlyForPeriod('2026-08'), equals(0.0));
      expect(state.taxAdjustmentMonthlyForPeriod('2026-09'), equals(100.0));
      expect(state.taxAdjustmentMonthlyForPeriod('2026-10'), equals(100.0));
      expect(state.taxAdjustmentMonthlyForPeriod('2026-11'), equals(100.0));
      expect(state.taxAdjustmentMonthlyForPeriod('2026-12'), equals(100.0));
      expect(state.taxAdjustmentMonthlyForPeriod('2027-01'), equals(0.0));
    });
  });
}
