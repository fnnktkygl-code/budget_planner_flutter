import '../models/bank_config.dart';
import '../models/salary_record.dart';

class AllocationRecommendation {
  final double projectedBalance;
  final double ctoAllocation;
  final double peaAllocation;
  final double revolutDaily;
  final double revolutHolidays;
  final double unallocatedLazyMoney;
  final bool isWarningLowBalance;

  AllocationRecommendation({
    required this.projectedBalance,
    required this.ctoAllocation,
    required this.peaAllocation,
    required this.revolutDaily,
    required this.revolutHolidays,
    required this.unallocatedLazyMoney,
    this.isWarningLowBalance = false,
  });
}

class AllocationService {
  /// Computes the recommended allocation based on current balance, new salary, and config.
  static AllocationRecommendation computeAllocation({
    required double currentBalance,
    required SalaryRecord newSalaryRecord,
    required BankConfig config,
  }) {
    // 1. Calculate projected balance
    final projectedBalance = currentBalance + newSalaryRecord.actualBankFlow;

    // 2. Identify prime/bonus specifically bound for CTO (US convictions)
    double ctoAllocation = 0.0;
    if (newSalaryRecord.calculatedExtraAmount > 0) {
      ctoAllocation = newSalaryRecord.calculatedExtraAmount;
    }

    // 3. Subtract fixed rules (Revolut)
    final double revolutDaily = config.fixedRevolutDaily;
    final double revolutHolidays = config.fixedRevolutHolidays;

    // Projected after CTO and Fixed rules
    double balanceAfterFixed = projectedBalance - ctoAllocation - revolutDaily - revolutHolidays;

    // 4. Calculate Lazy Money (amount exceeding the max buffer)
    double lazyMoney = 0.0;
    if (balanceAfterFixed > config.maxBufferAmount) {
      lazyMoney = balanceAfterFixed - config.maxBufferAmount;
    }

    // 5. Warning if balance is too low
    bool isWarning = false;
    if (balanceAfterFixed < config.minBufferAmount) {
      isWarning = true;
    }

    // By default, the remaining lazy money could be proposed for PEA or kept unallocated for user choice.
    double peaAllocation = 0.0;
    // As per user, they have regular PEA transfers, but here we can suggest putting the rest of lazy money into PEA.
    if (lazyMoney > 0) {
      peaAllocation = lazyMoney; // Suggest all remaining lazy money to PEA.
    }

    return AllocationRecommendation(
      projectedBalance: projectedBalance,
      ctoAllocation: ctoAllocation,
      peaAllocation: peaAllocation,
      revolutDaily: revolutDaily,
      revolutHolidays: revolutHolidays,
      unallocatedLazyMoney: lazyMoney - peaAllocation, // Will be 0 if all goes to PEA.
      isWarningLowBalance: isWarning,
    );
  }
}
