/// Modèle de données pour les bulletins de salaire et la répartition budgétaire AuraBudget Pro
class SalaryRecord {
  final String id;
  /// Format YYYY-MM (ex: "2026-07")
  final String period;
  /// Libellé affichable (ex: "Juillet 2026")
  final String periodLabel;
  /// Salaire net à payer en EUR
  final double netSalary;
  /// Salaire brut mensuel
  final double? grossSalary;
  /// Cotisations sociales (négatif)
  final double socialContributions;
  /// Tickets resto déduits (négatif)
  final double mealTickets;
  /// Indemnité télétravail (positif)
  final double teleworkAllowance;
  /// Indemnités non soumises (positif)
  final double nonTaxableAllowances;
  /// Budget d'épargne mensuel / DCA alloué en EUR
  final double investableAmount;
  /// Taux d'épargne (% du salaire net)
  final double savingsRate;
  /// Statut d'importation validé
  final String status;
  /// Nom du fichier source PDF
  final String? documentName;
  /// Image encodée en base64 de la page visualisée
  final String? renderedImageBase64;
  /// Fichier brut encodé en base64
  final String? rawFileBase64;
  /// Indique s'il s'agit du bulletin référent d'allocation actif
  final bool isLatestActive;
  /// Présence d'une ligne de prime explicite sur le bulletin (ex: 13e mois, vacances, performance)
  final bool hasExplicitBonus;
  /// Libellé de la prime si détectée (ex: "Prime de Vacances", "13ème Mois")
  final String? bonusDescription;
  /// Montant de la prime si détectée
  final double? bonusAmount;
  /// Date de mise à jour
  final DateTime updatedAt;
  /// Remarques additionnelles
  final String? notes;

  /// Salaire net récurrent hors prime exceptionnel
  double get regularNetSalary => netSalary - (bonusAmount ?? 0.0);

  SalaryRecord({
    required this.id,
    required this.period,
    required this.periodLabel,
    required this.netSalary,
    this.grossSalary,
    this.socialContributions = -840.78,
    this.mealTickets = -52.80,
    this.teleworkAllowance = 15.00,
    this.nonTaxableAllowances = 34.13,
    required this.investableAmount,
    required this.savingsRate,
    required this.status,
    this.documentName,
    this.renderedImageBase64,
    this.rawFileBase64,
    this.isLatestActive = false,
    this.hasExplicitBonus = false,
    this.bonusDescription,
    this.bonusAmount,
    required this.updatedAt,
    this.notes,
  });

  SalaryRecord copyWith({
    String? id,
    String? period,
    String? periodLabel,
    double? netSalary,
    double? grossSalary,
    double? socialContributions,
    double? mealTickets,
    double? teleworkAllowance,
    double? nonTaxableAllowances,
    double? investableAmount,
    double? savingsRate,
    String? status,
    String? documentName,
    String? renderedImageBase64,
    String? rawFileBase64,
    bool? isLatestActive,
    bool? hasExplicitBonus,
    String? bonusDescription,
    double? bonusAmount,
    DateTime? updatedAt,
    String? notes,
  }) {
    return SalaryRecord(
      id: id ?? this.id,
      period: period ?? this.period,
      periodLabel: periodLabel ?? this.periodLabel,
      netSalary: netSalary ?? this.netSalary,
      grossSalary: grossSalary ?? this.grossSalary,
      socialContributions: socialContributions ?? this.socialContributions,
      mealTickets: mealTickets ?? this.mealTickets,
      teleworkAllowance: teleworkAllowance ?? this.teleworkAllowance,
      nonTaxableAllowances: nonTaxableAllowances ?? this.nonTaxableAllowances,
      investableAmount: investableAmount ?? this.investableAmount,
      savingsRate: savingsRate ?? this.savingsRate,
      status: status ?? this.status,
      documentName: documentName ?? this.documentName,
      renderedImageBase64: renderedImageBase64 ?? this.renderedImageBase64,
      rawFileBase64: rawFileBase64 ?? this.rawFileBase64,
      isLatestActive: isLatestActive ?? this.isLatestActive,
      hasExplicitBonus: hasExplicitBonus ?? this.hasExplicitBonus,
      bonusDescription: bonusDescription ?? this.bonusDescription,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'period': period,
        'periodLabel': periodLabel,
        'netSalary': netSalary,
        'grossSalary': grossSalary,
        'socialContributions': socialContributions,
        'mealTickets': mealTickets,
        'teleworkAllowance': teleworkAllowance,
        'nonTaxableAllowances': nonTaxableAllowances,
        'investableAmount': investableAmount,
        'savingsRate': savingsRate,
        'status': status,
        'documentName': documentName,
        'renderedImageBase64': renderedImageBase64,
        'rawFileBase64': rawFileBase64,
        'isLatestActive': isLatestActive,
        'hasExplicitBonus': hasExplicitBonus,
        'bonusDescription': bonusDescription,
        'bonusAmount': bonusAmount,
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
      };

  factory SalaryRecord.fromJson(Map<String, dynamic> json) => SalaryRecord(
        id: json['id'],
        period: json['period'],
        periodLabel: json['periodLabel'],
        netSalary: (json['netSalary'] as num).toDouble(),
        grossSalary: json['grossSalary'] != null ? (json['grossSalary'] as num).toDouble() : null,
        socialContributions: json['socialContributions'] != null ? (json['socialContributions'] as num).toDouble() : -840.78,
        mealTickets: json['mealTickets'] != null ? (json['mealTickets'] as num).toDouble() : -52.80,
        teleworkAllowance: json['teleworkAllowance'] != null ? (json['teleworkAllowance'] as num).toDouble() : 15.00,
        nonTaxableAllowances: json['nonTaxableAllowances'] != null ? (json['nonTaxableAllowances'] as num).toDouble() : 34.13,
        investableAmount: (json['investableAmount'] as num).toDouble(),
        savingsRate: (json['savingsRate'] as num).toDouble(),
        status: json['status'] ?? '✓ Importé & Validé',
        documentName: json['documentName'],
        renderedImageBase64: json['renderedImageBase64'],
        rawFileBase64: json['rawFileBase64'],
        isLatestActive: json['isLatestActive'] ?? false,
        hasExplicitBonus: json['hasExplicitBonus'] ?? false,
        bonusDescription: json['bonusDescription'],
        bonusAmount: json['bonusAmount'] != null ? (json['bonusAmount'] as num).toDouble() : null,
        updatedAt: DateTime.parse(json['updatedAt']),
        notes: json['notes'],
      );
}

class YearlySalarySummary {
  final int year;
  final int count;
  final double averageNet;
  final double averageInvestable;
  final double totalNet;
  final double totalInvestable;
  final double averageSavingsRate;

  YearlySalarySummary({
    required this.year,
    required this.count,
    required this.averageNet,
    required this.averageInvestable,
    required this.totalNet,
    required this.totalInvestable,
    required this.averageSavingsRate,
  });
}

class SalaryAnalytics {
  final SalaryRecord? activeBaseline;
  final double overallAverageNet;
  final double overallAverageInvestable;
  final double overallSavingsRate;
  final double growthTrendPercent;
  final int totalRecordsCount;
  final List<YearlySalarySummary> yearlySummaries;

  SalaryAnalytics({
    this.activeBaseline,
    required this.overallAverageNet,
    required this.overallAverageInvestable,
    required this.overallSavingsRate,
    required this.growthTrendPercent,
    required this.totalRecordsCount,
    required this.yearlySummaries,
  });
}
