class AIAnalysisService {
  static Future<String> generateFinancialAdvice({
    required double monthlySalary,
    required double monthlySavings,
    required double fixedExpenses,
  }) async {
    final savingsRate = monthlySalary > 0 ? (monthlySavings / monthlySalary) * 100 : 0.0;

    if (savingsRate >= 30) {
      return "Excellente discipline financière ! Votre taux d'épargne de ${savingsRate.toStringAsFixed(1)}% dépasse la règle recommandée 50/30/20. Vous pouvez sereinement accélérer vos investissements long terme (PEA, DCA).";
    } else if (savingsRate >= 20) {
      return "Très bon profil financier (${savingsRate.toStringAsFixed(1)}% d'épargne). Votre matelas de sécurité se consolide régulièrement. Pensez à diversifier vos supports.";
    } else {
      return "Taux d'épargne actuel : ${savingsRate.toStringAsFixed(1)}%. Il est recommandé d'optimiser vos abonnements ou charges fixes pour atteindre le cap des 20% d'épargne mensuelle.";
    }
  }
}
