/// Représente un instantané des règles de récapitulatif budgétaire appliqué à une période donnée (ex: 2026-01)
class BudgetHistoryRecord {
  final String period; // ex: "2026-01"
  final DateTime effectiveDate;
  final double netSalaryBaseline;
  final double fixedChargesTotal;
  final double savingsTotal;
  final double dailyTotal;
  final double resteAVivreTotal;
  final String? note;

  BudgetHistoryRecord({
    required this.period,
    required this.effectiveDate,
    required this.netSalaryBaseline,
    required this.fixedChargesTotal,
    required this.savingsTotal,
    required this.dailyTotal,
    required this.resteAVivreTotal,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'period': period,
        'effectiveDate': effectiveDate.toIso8601String(),
        'netSalaryBaseline': netSalaryBaseline,
        'fixedChargesTotal': fixedChargesTotal,
        'savingsTotal': savingsTotal,
        'dailyTotal': dailyTotal,
        'resteAVivreTotal': resteAVivreTotal,
        'note': note,
      };

  factory BudgetHistoryRecord.fromJson(Map<String, dynamic> json) => BudgetHistoryRecord(
        period: json['period'],
        effectiveDate: DateTime.parse(json['effectiveDate']),
        netSalaryBaseline: (json['netSalaryBaseline'] as num).toDouble(),
        fixedChargesTotal: (json['fixedChargesTotal'] as num).toDouble(),
        savingsTotal: (json['savingsTotal'] as num).toDouble(),
        dailyTotal: (json['dailyTotal'] as num).toDouble(),
        resteAVivreTotal: (json['resteAVivreTotal'] as num).toDouble(),
        note: json['note'],
      );
}
