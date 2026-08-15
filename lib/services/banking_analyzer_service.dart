import '../models/budget_category.dart';
import '../models/temporary_expense.dart';

class DetectedRecurringExpense {
  final String id;
  final String merchant;
  final String rawTitle;
  final double amount;
  final String suggestedCategory;
  final int suggestedDurationMonths;
  final DateTime lastTransactionDate;
  final bool isSepaOrDebit;
  final String reason;

  DetectedRecurringExpense({
    required this.id,
    required this.merchant,
    required this.rawTitle,
    required this.amount,
    required this.suggestedCategory,
    this.suggestedDurationMonths = 3,
    required this.lastTransactionDate,
    this.isSepaOrDebit = false,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'rawTitle': rawTitle,
        'amount': amount,
        'suggestedCategory': suggestedCategory,
        'suggestedDurationMonths': suggestedDurationMonths,
        'lastTransactionDate': lastTransactionDate.toIso8601String(),
        'isSepaOrDebit': isSepaOrDebit,
        'reason': reason,
      };
}

class BankingAnalyzerService {
  /// Clean up French banking descriptions (BoursoBank / STET prefixes)
  static String cleanMerchantName(String raw) {
    String name = raw.toUpperCase();
    name = name.replaceAll(RegExp(r'^(PRLV|VIR|CB|PAIEMENT|FACTURE|RETRAIT)\s*(SEPA|CARTE)?\s*'), '');
    name = name.replaceAll(RegExp(r'^(DU|LE|POUR)\s+\d{2}/\d{2}(/\d{2,4})?\s*'), '');
    name = name.replaceAll(RegExp(r'REF\s*:\s*\S+'), '');
    name = name.replaceAll(RegExp(r'EMETTEUR\s*:\s*'), '');
    name = name.replaceAll(RegExp(r'ID\s*:\s*\S+'), '');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.contains('DGFIP') || name.contains('DIRECTION GENERALE DES FINANCES') || name.contains('TRESOR PUBLIC')) {
      return 'DGFIP (Impôts)';
    }
    if (name.contains('KLARNA')) return 'Klarna (Paiement étalé)';
    if (name.contains('ALMA')) return 'Alma (Paiement étalé)';
    if (name.contains('FLOA')) return 'Floa Bank (Échéancier)';
    if (name.contains('PAYPAL')) return 'PayPal';
    if (name.contains('EDF')) return 'EDF Énergie';
    if (name.contains('ENGIE')) return 'Engie';
    if (name.contains('TOTALENERGIES')) return 'TotalEnergies';
    if (name.contains('FREE MOBILE') || name.contains('FREE TELECOM')) return 'Free Télécom';
    if (name.contains('ORANGE')) return 'Orange';
    if (name.contains('SFR')) return 'SFR';
    if (name.contains('BOUYGUES')) return 'Bouygues Telecom';
    if (name.contains('MUTUELLE') || name.contains('ALAN') || name.contains('HARMONIE')) return 'Mutuelle Santé';
    if (name.contains('DENTAIRE') || name.contains('ORTHODONTIE')) return 'Soins Dentaires';

    // Capitalize first letters
    final words = name.toLowerCase().split(' ');
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  /// Analyze transactions to find candidates for Temporary Obligations / Recurring Expenses
  static List<DetectedRecurringExpense> analyzeTransactions({
    required List<TransactionItem> transactions,
    required List<TemporaryExpense> existingExpenses,
    List<String> existingLabels = const [],
    Set<String> ignoredIds = const {},
  }) {
    final List<DetectedRecurringExpense> suggestions = [];
    final Map<String, List<TransactionItem>> groupedByMerchant = {};

    for (final tx in transactions) {
      if (tx.isIncome || tx.amount <= 0) continue;
      if (ignoredIds.contains(tx.id)) continue;

      final cleanName = cleanMerchantName(tx.title);
      groupedByMerchant.putIfAbsent(cleanName, () => []).add(tx);
    }

    final existingLabelsUpper = existingExpenses.map((e) => e.label.toUpperCase()).toSet();

    groupedByMerchant.forEach((merchantName, txList) {
      final sampleTx = txList.first;
      final upperTitle = sampleTx.title.toUpperCase();
      final upperMerchant = merchantName.toUpperCase();

      // Check if already declared in existing temporary expenses
      final alreadyDeclared = existingLabelsUpper.any((label) =>
          label.contains(upperMerchant) || upperMerchant.contains(label));
      if (alreadyDeclared) return;

      // 1. Tax / DGFIP detection
      if (upperTitle.contains('DGFIP') || upperTitle.contains('TRESOR') || upperTitle.contains('IMPOT')) {
        suggestions.add(DetectedRecurringExpense(
          id: 'sugg-${sampleTx.id}',
          merchant: 'DGFIP (Régularisation Fiscale)',
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Impôts',
          suggestedDurationMonths: 4,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Prélèvement fiscal / échéancier d\'impôts détecté sur votre compte.',
        ));
        return;
      }

      // 2. Split payment / BNPL detection (Klarna, Alma, Sofinco, 3x/4x)
      if (upperTitle.contains('KLARNA') ||
          upperTitle.contains('ALMA') ||
          upperTitle.contains('FLOA') ||
          upperTitle.contains('SOFINCO') ||
          upperTitle.contains('3X') ||
          upperTitle.contains('4X') ||
          upperTitle.contains('3 FOIS') ||
          upperTitle.contains('4 FOIS')) {
        suggestions.add(DetectedRecurringExpense(
          id: 'sugg-${sampleTx.id}',
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Échéancier / Crédit',
          suggestedDurationMonths: 3,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: sampleTx.title.toUpperCase().contains('PRLV'),
          reason: 'Paiement échelonné (3x/4x) ou financement détecté.',
        ));
        return;
      }

      // 3. Healthcare / Dental treatments
      if (upperTitle.contains('DENT') ||
          upperTitle.contains('ORTHO') ||
          upperTitle.contains('CLINIQUE') ||
          upperTitle.contains('HOPITAL')) {
        if (sampleTx.amount >= 50.0) {
          suggestions.add(DetectedRecurringExpense(
            id: 'sugg-${sampleTx.id}',
            merchant: merchantName,
            rawTitle: sampleTx.title,
            amount: sampleTx.amount,
            suggestedCategory: 'Santé',
            suggestedDurationMonths: 2,
            lastTransactionDate: sampleTx.date,
            isSepaOrDebit: false,
            reason: 'Dépense de santé significative pouvant faire l\'objet d\'un étalement.',
          ));
          return;
        }
      }

      // 4. Repeated direct debits (SEPA) not in fixed charges
      if (upperTitle.contains('PRLV') || upperTitle.contains('SEPA') || txList.length >= 2) {
        // If amount is significant (> 15€)
        if (sampleTx.amount >= 15.0) {
          suggestions.add(DetectedRecurringExpense(
            id: 'sugg-${sampleTx.id}',
            merchant: merchantName,
            rawTitle: sampleTx.title,
            amount: sampleTx.amount,
            suggestedCategory: 'Abonnement / Prélèvement',
            suggestedDurationMonths: 12,
            lastTransactionDate: sampleTx.date,
            isSepaOrDebit: true,
            reason: 'Prélèvement automatique récurrent identifié.',
          ));
        }
      }
    });

    // Sort by most recent first
    suggestions.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));
    return suggestions;
  }
}
