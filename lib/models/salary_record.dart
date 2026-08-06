/// Modèle de données pour les bulletins de salaire et la répartition budgétaire AuraBudget Pro
class SalaryRecord {
  final String id;
  /// Format YYYY-MM (ex: "2026-07")
  final String period;
  /// Libellé affichable (ex: "Juillet 2026")
  final String periodLabel;
  /// Salaire net à payer en EUR (versé en banque après impôt)
  final double netSalary;
  /// Salaire brut mensuel
  final double? grossSalary;
  /// Montant Net Social / Net avant impôt sur le revenu
  final double netSocial;
  /// Cotisations sociales (négatif)
  final double socialContributions;
  /// Tickets resto déduits (négatif)
  final double mealTickets;
  /// Indemnité télétravail (positif)
  final double teleworkAllowance;
  /// Indemnités non soumises (positif)
  final double nonTaxableAllowances;
  /// Montant du prélèvement à la source (impôt IR, négatif ou 0.0)
  final double incomeTaxAmount;
  /// Taux effectif du prélèvement à la source (%)
  final double incomeTaxRatePercent;
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
  /// Montant d'épargne salariale placé sur PEE / PERCO (Intéressement & Participation non versés en banque)
  final double companySavingsPEE;

  /// Remarques additionnelles
  final String? notes;

  /// Nom de l'employeur
  String get employerName => "VESTAS FRANCE SAS PEROLS";
  /// Nom du salarié
  String get employeeName => "NEGEM RICHARD";

  /// Montant d'extra / rachat de congés / prime calculé dynamiquement
  double get calculatedExtraAmount {
    if (bonusAmount != null && bonusAmount! > 0) return bonusAmount!;
    if (netSocial > 3100) {
      return (netSocial - 2860.89).clamp(0.0, double.infinity);
    }
    if (netSalary > 3100) {
      return (netSalary - 2787.89).clamp(0.0, double.infinity);
    }
    return 0.0;
  }

  /// Mois contenant un extra (Prime, Rachat de Congés/RTT, Bonus)
  bool get isExtraOrBonusMonth =>
      hasExplicitBonus || (bonusAmount != null && bonusAmount! > 0) || calculatedExtraAmount > 10.0;

  /// Salaire net récurrent hors prime exceptionnel (calculé dynamiquement à partir des vraies fiches de paie!)
  double get regularNetSalary {
    if (bonusAmount != null && bonusAmount! > 0) {
      final ratio = (grossSalary != null && grossSalary! > 0) ? (netSalary / grossSalary!) : 0.77;
      final netBonus = bonusAmount! * ratio;
      return (netSalary - netBonus).clamp(0.0, double.infinity);
    }
    if (calculatedExtraAmount > 10.0) {
      final ratio = (grossSalary != null && grossSalary! > 0) ? (netSalary / grossSalary!) : 0.77;
      final netExtra = calculatedExtraAmount * ratio;
      return (netSalary - netExtra).clamp(0.0, double.infinity);
    }
    return netSalary;
  }

  /// Net social récurrent hors prime exceptionnel (calculé dynamiquement à partir des vraies fiches de paie!)
  double get regularNetSocial {
    if (bonusAmount != null && bonusAmount! > 0) {
      final ratio = (grossSalary != null && grossSalary! > 0) ? (netSocial / grossSalary!) : 0.78;
      final netBonus = bonusAmount! * ratio;
      return (netSocial - netBonus).clamp(0.0, double.infinity);
    }
    if (calculatedExtraAmount > 10.0) {
      final ratio = (grossSalary != null && grossSalary! > 0) ? (netSocial / grossSalary!) : 0.78;
      final netExtra = calculatedExtraAmount * ratio;
      return (netSocial - netExtra).clamp(0.0, double.infinity);
    }
    return netSocial;
  }

  /// Rémunération globale mensuelle équivalente (Net banque + Épargne Salariale PEE)
  double get totalGlobalComp => netSalary + companySavingsPEE;

  /// Année extraite de la période (ex: 2025)
  int get year {
    if (period.contains('-')) {
      final parts = period.split('-');
      return int.tryParse(parts[0]) ?? 2025;
    }
    final match = RegExp(r'20\d{2}').firstMatch(period);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 2025;
  }

  SalaryRecord({
    required this.id,
    required this.period,
    required this.periodLabel,
    required this.netSalary,
    this.grossSalary,
    this.netSocial = 2952.28,
    this.socialContributions = -840.78,
    this.mealTickets = -52.80,
    this.teleworkAllowance = 15.00,
    this.nonTaxableAllowances = 34.13,
    this.incomeTaxAmount = -238.54,
    this.incomeTaxRatePercent = 8.0,
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
    this.companySavingsPEE = 0.0,
    required this.updatedAt,
    this.notes,
  });

  SalaryRecord copyWith({
    String? id,
    String? period,
    String? periodLabel,
    double? netSalary,
    double? grossSalary,
    double? netSocial,
    double? socialContributions,
    double? mealTickets,
    double? teleworkAllowance,
    double? nonTaxableAllowances,
    double? incomeTaxAmount,
    double? incomeTaxRatePercent,
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
    double? companySavingsPEE,
    DateTime? updatedAt,
    String? notes,
  }) {
    return SalaryRecord(
      id: id ?? this.id,
      period: period ?? this.period,
      periodLabel: periodLabel ?? this.periodLabel,
      netSalary: netSalary ?? this.netSalary,
      grossSalary: grossSalary ?? this.grossSalary,
      netSocial: netSocial ?? this.netSocial,
      socialContributions: socialContributions ?? this.socialContributions,
      mealTickets: mealTickets ?? this.mealTickets,
      teleworkAllowance: teleworkAllowance ?? this.teleworkAllowance,
      nonTaxableAllowances: nonTaxableAllowances ?? this.nonTaxableAllowances,
      incomeTaxAmount: incomeTaxAmount ?? this.incomeTaxAmount,
      incomeTaxRatePercent: incomeTaxRatePercent ?? this.incomeTaxRatePercent,
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
      companySavingsPEE: companySavingsPEE ?? this.companySavingsPEE,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson({bool includeBinary = true}) => {
        'id': id,
        'period': period,
        'periodLabel': periodLabel,
        'netSalary': netSalary,
        'grossSalary': grossSalary,
        'netSocial': netSocial,
        'socialContributions': socialContributions,
        'mealTickets': mealTickets,
        'teleworkAllowance': teleworkAllowance,
        'nonTaxableAllowances': nonTaxableAllowances,
        'incomeTaxAmount': incomeTaxAmount,
        'incomeTaxRatePercent': incomeTaxRatePercent,
        'investableAmount': investableAmount,
        'savingsRate': savingsRate,
        'status': status,
        'documentName': documentName,
        if (includeBinary) 'renderedImageBase64': renderedImageBase64,
        if (includeBinary) 'rawFileBase64': rawFileBase64,
        'isLatestActive': isLatestActive,
        'hasExplicitBonus': hasExplicitBonus,
        'bonusDescription': bonusDescription,
        'bonusAmount': bonusAmount,
        'companySavingsPEE': companySavingsPEE,
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
      };

  factory SalaryRecord.fromJson(Map<String, dynamic> json) => SalaryRecord(
        id: json['id'],
        period: json['period'],
        periodLabel: json['periodLabel'],
        netSalary: (json['netSalary'] as num).toDouble(),
        grossSalary: json['grossSalary'] != null ? (json['grossSalary'] as num).toDouble() : null,
        netSocial: json['netSocial'] != null ? (json['netSocial'] as num).toDouble() : 2952.28,
        socialContributions: json['socialContributions'] != null ? (json['socialContributions'] as num).toDouble() : -840.78,
        mealTickets: json['mealTickets'] != null ? (json['mealTickets'] as num).toDouble() : -52.80,
        teleworkAllowance: json['teleworkAllowance'] != null ? (json['teleworkAllowance'] as num).toDouble() : 15.00,
        nonTaxableAllowances: json['nonTaxableAllowances'] != null ? (json['nonTaxableAllowances'] as num).toDouble() : 34.13,
        incomeTaxAmount: json['incomeTaxAmount'] != null ? (json['incomeTaxAmount'] as num).toDouble() : -238.54,
        incomeTaxRatePercent: json['incomeTaxRatePercent'] != null ? (json['incomeTaxRatePercent'] as num).toDouble() : 8.0,
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
        companySavingsPEE: json['companySavingsPEE'] != null ? (json['companySavingsPEE'] as num).toDouble() : 0.0,
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
