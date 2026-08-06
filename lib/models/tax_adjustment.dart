class TaxAdjustment {
  final String id;
  final String label;
  final int taxYear;
  final double grossAmount;
  final double deductionAmount;
  final String startPeriod; // YYYY-MM e.g. "2026-09"
  final int monthsCount; // e.g. 4 (Sept-Dec)

  TaxAdjustment({
    required this.id,
    required this.label,
    required this.taxYear,
    required this.grossAmount,
    required this.deductionAmount,
    required this.startPeriod,
    required this.monthsCount,
  });

  double get netTaxDue => (grossAmount - deductionAmount).clamp(0.0, 100000.0);

  double get monthlyInstallment => monthsCount > 0 ? netTaxDue / monthsCount : netTaxDue;

  bool isActiveForPeriod(String period) {
    try {
      final parts = startPeriod.split('-');
      final startY = int.parse(parts[0]);
      final startM = int.parse(parts[1]);

      final curParts = period.split('-');
      final curY = int.parse(curParts[0]);
      final curM = int.parse(curParts[1]);

      final startTotalMonths = startY * 12 + startM;
      final curTotalMonths = curY * 12 + curM;
      final endTotalMonths = startTotalMonths + monthsCount - 1;

      return curTotalMonths >= startTotalMonths && curTotalMonths <= endTotalMonths;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'taxYear': taxYear,
        'grossAmount': grossAmount,
        'deductionAmount': deductionAmount,
        'startPeriod': startPeriod,
        'monthsCount': monthsCount,
      };

  factory TaxAdjustment.fromJson(Map<String, dynamic> json) => TaxAdjustment(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        label: json['label'] as String? ?? 'Avis d\'imposition',
        taxYear: json['taxYear'] as int? ?? 2025,
        grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
        deductionAmount: (json['deductionAmount'] as num?)?.toDouble() ?? 0.0,
        startPeriod: json['startPeriod'] as String? ?? '2026-09',
        monthsCount: json['monthsCount'] as int? ?? 4,
      );

  TaxAdjustment copyWith({
    String? id,
    String? label,
    int? taxYear,
    double? grossAmount,
    double? deductionAmount,
    String? startPeriod,
    int? monthsCount,
  }) {
    return TaxAdjustment(
      id: id ?? this.id,
      label: label ?? this.label,
      taxYear: taxYear ?? this.taxYear,
      grossAmount: grossAmount ?? this.grossAmount,
      deductionAmount: deductionAmount ?? this.deductionAmount,
      startPeriod: startPeriod ?? this.startPeriod,
      monthsCount: monthsCount ?? this.monthsCount,
    );
  }
}
