class TaxAdjustment {
  final String id;
  final String label;
  final int taxYear;
  final double totalTaxNetDue; // Impôt net total dû pour l'année (ex: 3310 €)
  final double alreadyPaidPas; // Retenue à la source déjà prélevée (ex: 844 €)
  final String startPeriod; // YYYY-MM e.g. "2026-09"
  final int monthsCount; // e.g. 4 (Sept-Dec)

  TaxAdjustment({
    required this.id,
    required this.label,
    required this.taxYear,
    required this.totalTaxNetDue,
    required this.alreadyPaidPas,
    required this.startPeriod,
    required this.monthsCount,
  });

  /// Solde d'impôt net restant à payer (ex: 3310 - 844 = 2466 €)
  double get netTaxDue => (totalTaxNetDue - alreadyPaidPas).clamp(0.0, 100000.0);

  /// Mensualité étalée à prélever sur le budget (ex: 2466 / 4 = 616.50 €/mois)
  double get monthlyInstallment => monthsCount > 0 ? netTaxDue / monthsCount : netTaxDue;

  /// Impôt mensuel réel ajusté pour l'année de référence (ex: 3310 / 12 = 275.83 €/mois)
  double get monthlyRealTaxForYear => totalTaxNetDue / 12.0;

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
        'totalTaxNetDue': totalTaxNetDue,
        'alreadyPaidPas': alreadyPaidPas,
        'startPeriod': startPeriod,
        'monthsCount': monthsCount,
      };

  factory TaxAdjustment.fromJson(Map<String, dynamic> json) => TaxAdjustment(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        label: json['label'] as String? ?? 'Avis d\'imposition',
        taxYear: json['taxYear'] as int? ?? 2025,
        totalTaxNetDue: (json['totalTaxNetDue'] as num?)?.toDouble() ??
            (json['grossAmount'] as num?)?.toDouble() ??
            3310.0,
        alreadyPaidPas: (json['alreadyPaidPas'] as num?)?.toDouble() ??
            (json['deductionAmount'] as num?)?.toDouble() ??
            844.0,
        startPeriod: json['startPeriod'] as String? ?? '2026-09',
        monthsCount: json['monthsCount'] as int? ?? 4,
      );

  TaxAdjustment copyWith({
    String? id,
    String? label,
    int? taxYear,
    double? totalTaxNetDue,
    double? alreadyPaidPas,
    String? startPeriod,
    int? monthsCount,
  }) {
    return TaxAdjustment(
      id: id ?? this.id,
      label: label ?? this.label,
      taxYear: taxYear ?? this.taxYear,
      totalTaxNetDue: totalTaxNetDue ?? this.totalTaxNetDue,
      alreadyPaidPas: alreadyPaidPas ?? this.alreadyPaidPas,
      startPeriod: startPeriod ?? this.startPeriod,
      monthsCount: monthsCount ?? this.monthsCount,
    );
  }
}
