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
    id: 'sal-2026-06',
    period: '2026-06',
    periodLabel: 'Juin 2026',
    netSalary: 3850,
    grossSalary: 4950,
    investableAmount: 1200,
    savingsRate: 31.2,
    status: '✓ Importé & Validé',
    documentName: 'bulletin_paye_2026_06.pdf',
    isLatestActive: true,
    updatedAt: DateTime(2026, 6, 28),
    notes: 'Bulletin référent actuel — Base de la répartition budgétaire active',
  ),
  SalaryRecord(
    id: 'sal-2026-01',
    period: '2026-01',
    periodLabel: 'Janvier 2026',
    netSalary: 3700,
    grossSalary: 4750,
    investableAmount: 1100,
    savingsRate: 29.7,
    status: '✓ Importé & Validé',
    documentName: 'bulletin_paye_2026_01.pdf',
    isLatestActive: false,
    updatedAt: DateTime(2026, 1, 30),
    notes: 'Revalorisation annuelle 2026',
  ),
  SalaryRecord(
    id: 'sal-2025-09',
    period: '2025-09',
    periodLabel: 'Septembre 2025',
    netSalary: 3500,
    grossSalary: 4500,
    investableAmount: 1000,
    savingsRate: 28.6,
    status: '✓ Importé & Validé',
    documentName: 'bulletin_paye_2025_09.pdf',
    isLatestActive: false,
    updatedAt: DateTime(2025, 9, 28),
    notes: 'Bulletin d\'automne 2025',
  ),
  SalaryRecord(
    id: 'sal-2025-01',
    period: '2025-01',
    periodLabel: 'Janvier 2025',
    netSalary: 3400,
    grossSalary: 4350,
    investableAmount: 950,
    savingsRate: 27.9,
    status: '✓ Importé & Validé',
    documentName: 'bulletin_paye_2025_01.pdf',
    isLatestActive: false,
    updatedAt: DateTime(2025, 1, 29),
    notes: 'Premier bulletin importé 2025',
  ),
];
