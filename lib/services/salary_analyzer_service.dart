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
/// sur le bulletin le plus récent en date ou désigné comme référent actif.
SalaryRecord? getActiveBaselineSalary(List<SalaryRecord> records) {
  if (records.isEmpty) return null;
  final explicitActive = records.where((r) => r.isLatestActive).toList();
  if (explicitActive.isNotEmpty) {
    return explicitActive.first;
  }
  final sorted = sortSalaryRecordsDescending(records);
  return sorted.first;
}

/// Calcul du lissage salarial sur la période 2025-2026 (à titre indicatif/analytique).
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
  final oldest = sortedAsc.first;
  final newest = sortedAsc.last;

  double growthTrendPercent = 0;
  if (oldest.id != newest.id && oldest.netSalary > 0) {
    growthTrendPercent = ((newest.netSalary - oldest.netSalary) / oldest.netSalary) * 100;
  }

  final Map<int, List<SalaryRecord>> byYear = {};
  for (var r in records) {
    final year = int.tryParse(r.period.split('-')[0]) ?? DateTime.now().year;
    byYear.putIfAbsent(year, () => []).add(r);
  }

  final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
  final List<YearlySalarySummary> yearlySummaries = years.map((year) {
    final yearRecords = byYear[year]!;
    final yCount = yearRecords.length;
    final yTotalNet = yearRecords.fold(0.0, (sum, r) => sum + r.netSalary);
    final yTotalInvestable = yearRecords.fold(0.0, (sum, r) => sum + r.investableAmount);
    final yAvgNet = yTotalNet / yCount;
    final yAvgInvestable = yTotalInvestable / yCount;
    final ySavingsRate = yAvgNet > 0 ? (yAvgInvestable / yAvgNet) * 100 : 0.0;

    return YearlySalarySummary(
      year: year,
      count: yCount,
      averageNet: yAvgNet,
      averageInvestable: yAvgInvestable,
      totalNet: yTotalNet,
      totalInvestable: yTotalInvestable,
      averageSavingsRate: ySavingsRate,
    );
  }).toList();

  return SalaryAnalytics(
    activeBaseline: activeBaseline,
    overallAverageNet: overallAverageNet,
    overallAverageInvestable: overallAverageInvestable,
    overallSavingsRate: overallSavingsRate,
    growthTrendPercent: growthTrendPercent,
    totalRecordsCount: count,
    yearlySummaries: yearlySummaries,
  );
}

final List<SalaryRecord> defaultSalaryRecords = [
  SalaryRecord(
    id: 'sal-2026-07',
    period: '2026-07',
    periodLabel: 'Juillet 2026',
    netSalary: 2713.74,
    grossSalary: 3776.67,
    investableAmount: 1200,
    savingsRate: 44.2,
    status: '✓ Bulletin Réel Validé (Gemini IA)',
    documentName: 'bulletin_negem_richard_juillet_2026.pdf',
    isLatestActive: true,
    updatedAt: DateTime(2026, 7, 31),
    notes: 'VESTAS FRANCE SAS PEROLS — Net Social: 2 952.28 € — IBAN: FR76 4061 8803 7300 0403 1180 429',
  ),
  SalaryRecord(
    id: 'sal-2025-05',
    period: '2025-05',
    periodLabel: 'Mai 2025',
    netSalary: 2684.46,
    grossSalary: 3666.67,
    investableAmount: 1000,
    savingsRate: 37.2,
    status: '✓ Bulletin Réel Validé (Gemini IA)',
    documentName: 'bulletin_negem_richard_mai_2025.pdf',
    isLatestActive: false,
    updatedAt: DateTime(2025, 5, 31),
    notes: 'VESTAS FRANCE SAS PEROLS — Net Social: 2 860.89 € — NIR: 193109934108822',
  ),
];
