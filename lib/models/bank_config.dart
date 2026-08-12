class BankConfig {
  /// TrueLayer account ID for the main current account.
  final String mainAccountId;
  
  /// TrueLayer account ID for the PEA (Plan d'Épargne en Actions).
  final String? peaAccountId;
  
  /// TrueLayer account ID for the CTO (Compte Titres Ordinaire).
  final String? ctoAccountId;
  
  /// Fixed monthly expenses (e.g., rent, subscriptions, insurance).
  final double fixedMonthlyExpenses;
  
  /// Safety margin percentage (e.g., 0.20 for 20%).
  final double safetyMarginPercent;

  /// Allocations fixes manuelles (e.g., Revolut)
  final double fixedRevolutDaily;
  final double fixedRevolutHolidays;

  const BankConfig({
    required this.mainAccountId,
    this.peaAccountId,
    this.ctoAccountId,
    this.fixedMonthlyExpenses = 1000.0,
    this.safetyMarginPercent = 0.20,
    this.fixedRevolutDaily = 100.0,
    this.fixedRevolutHolidays = 100.0,
  });

  /// Dynamic lower bound for the buffer amount.
  double get minBufferAmount => fixedMonthlyExpenses * (1 + safetyMarginPercent);

  /// Dynamic upper bound for the buffer amount.
  double get maxBufferAmount => minBufferAmount + 300.0; // Flexible upper limit (+300 EUR).

  // TODO: Add JSON serialization if this needs to be saved locally (e.g., SharedPreferences).
}
