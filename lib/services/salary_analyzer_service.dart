import '../models/salary_record.dart';

const List<String> monthNamesFr = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
];

String formatPeriodLabel(String period) {
  if (!period.contains('-')) return period;
  final parts = period.split('-');
  final yearStr = parts[0];
  final monthIdx = (int.tryParse(parts[1]) ?? 1) - 1;
  final monthName = (monthIdx >= 0 && monthIdx < 12) ? monthNamesFr[monthIdx] : parts[1];
  return '$monthName $yearStr';
}

List<SalaryRecord> sortSalaryRecordsDescending(List<SalaryRecord> records) {
  final list = List<SalaryRecord>.from(records);
  list.sort((a, b) => b.period.compareTo(a.period));
  return list;
}

/// RÈGLE MÉTIER PRINCIPALE :
/// La répartition budgétaire active (base de calcul) se base EXCLUSIVEMENT
/// sur le bulletin le plus récent CHRONOLOGIQUEMENT en date (format YYYY-MM décroissant).
SalaryRecord? getActiveBaselineSalary(List<SalaryRecord> records) {
  if (records.isEmpty) return null;
  final sorted = sortSalaryRecordsDescending(records);
  final explicitActive = sorted.where((r) => r.isLatestActive).toList();
  if (explicitActive.isNotEmpty) {
    return explicitActive.first;
  }
  return sorted.first;
}

/// Calcul du lissage salarial sur les bulletins réels enregistrés par l'utilisateur.
SalaryAnalytics computeSalaryAnalytics(List<SalaryRecord> records) {
  if (records.isEmpty) {
    return SalaryAnalytics(
      activeBaseline: null,
      overallAverageNet: 0,
      overallAverageInvestable: 0,
      overallSavingsRate: 0,
      growthTrendPercent: 0,
      totalRecordsCount: 0,
      yearlySummaries: [],
    );
  }

  final activeBaseline = getActiveBaselineSalary(records);

  final double totalNet = records.fold(0.0, (sum, r) => sum + r.netSalary);
  final double totalInvestable = records.fold(0.0, (sum, r) => sum + r.investableAmount);
  final int count = records.length;

  final double overallAverageNet = totalNet / count;
  final double overallAverageInvestable = totalInvestable / count;
  final double overallSavingsRate = overallAverageNet > 0 ? (overallAverageInvestable / overallAverageNet) * 100 : 0;

  final sortedAsc = List<SalaryRecord>.from(records)..sort((a, b) => a.period.compareTo(b.period));
  double growthTrend = 0;
  if (sortedAsc.length >= 2) {
    final firstNet = sortedAsc.first.netSalary;
    final lastNet = sortedAsc.last.netSalary;
    if (firstNet > 0) {
      growthTrend = ((lastNet - firstNet) / firstNet) * 100;
    }
  }

  // Group by year
  final Map<int, List<SalaryRecord>> byYear = {};
  for (var r in records) {
    final y = int.tryParse(r.period.split('-')[0]) ?? r.updatedAt.year;
    byYear.putIfAbsent(y, () => []).add(r);
  }

  final List<YearlySalarySummary> yearlySummaries = [];
  final sortedYears = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

  for (var yr in sortedYears) {
    final listYr = byYear[yr]!;
    final yrTotalNet = listYr.fold(0.0, (sum, r) => sum + r.netSalary);
    final yrTotalInv = listYr.fold(0.0, (sum, r) => sum + r.investableAmount);
    final yrAvgNet = yrTotalNet / listYr.length;
    final yrAvgInv = yrTotalInv / listYr.length;
    final yrAvgSavings = yrAvgNet > 0 ? (yrAvgInv / yrAvgNet) * 100 : 0.0;

    yearlySummaries.add(
      YearlySalarySummary(
        year: yr,
        count: listYr.length,
        averageNet: yrAvgNet,
        averageInvestable: yrAvgInv,
        totalNet: yrTotalNet,
        totalInvestable: yrTotalInv,
        averageSavingsRate: yrAvgSavings,
      ),
    );
  }

  return SalaryAnalytics(
    activeBaseline: activeBaseline,
    overallAverageNet: overallAverageNet,
    overallAverageInvestable: overallAverageInvestable,
    overallSavingsRate: overallSavingsRate,
    growthTrendPercent: growthTrend,
    totalRecordsCount: count,
    yearlySummaries: yearlySummaries,
  );
}
