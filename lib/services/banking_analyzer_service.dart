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
  /// Clean up French banking descriptions (BoursoBank / STET prefixes) to readable merchant names
  static String cleanMerchantName(String raw) {
    String name = raw.toUpperCase();
    name = name.replaceAll(RegExp(r'^(PRLV|VIR|CB|PAIEMENT|FACTURE|RETRAIT)\s*(SEPA|CARTE)?\s*'), '');
    name = name.replaceAll(RegExp(r'^(DU|LE|POUR)\s+\d{2}/\d{2}(/\d{2,4})?\s*'), '');
    name = name.replaceAll(RegExp(r'REF\s*:\s*\S+'), '');
    name = name.replaceAll(RegExp(r'EMETTEUR\s*:\s*'), '');
    name = name.replaceAll(RegExp(r'ID\s*:\s*\S+'), '');
    name = name.replaceAll(RegExp(r'CARTE\s+X+\d+'), '');
    name = name.replaceAll(RegExp(r'\d{2}/\d{2}(/\d{2,4})?'), '');
    name = name.replaceAll(RegExp(r'[-_/]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.contains('DGFIP') || name.contains('DIRECTION GENERALE DES FINANCES') || name.contains('TRESOR PUBLIC')) {
      return 'DGFIP (Impôts & Taxes)';
    }
    if (name.contains('KLARNA')) return 'Klarna (Paiement 3x)';
    if (name.contains('ALMA')) return 'Alma (Paiement 3x/4x)';
    if (name.contains('FLOA')) return 'Floa Bank (Paiement 4x)';
    if (name.contains('SOFINCO')) return 'Sofinco (Crédit/Échéancier)';
    if (name.contains('COFIDIS')) return 'Cofidis (Crédit/Échéancier)';
    if (name.contains('PAYPAL')) return 'PayPal';
    if (name.contains('EDF')) return 'EDF Électricité';
    if (name.contains('ENGIE')) return 'Engie Gaz/Élec';
    if (name.contains('TOTALENERGIES')) return 'TotalEnergies';
    if (name.contains('FREE MOBILE') || name.contains('FREE TELECOM') || name.contains('FREEBOX')) return 'Free Télécom';
    if (name.contains('ORANGE')) return 'Orange';
    if (name.contains('SFR')) return 'SFR';
    if (name.contains('BOUYGUES')) return 'Bouygues Telecom';
    if (name.contains('MUTUELLE') || name.contains('ALAN') || name.contains('HARMONIE') || name.contains('MGEN')) return 'Mutuelle Santé';
    if (name.contains('DENTAIRE') || name.contains('ORTHODONTIE') || name.contains('DENTISTE')) return 'Soins Dentaires';
    if (name.contains('AMAZON') || name.contains('PRIME')) return 'Amazon Prime';
    if (name.contains('NETFLIX')) return 'Netflix';
    if (name.contains('SPOTIFY')) return 'Spotify';
    if (name.contains('APPLE')) return 'Services Apple';
    if (name.contains('GOOGLE')) return 'Google Services';

    // Capitalize first letters and remove standalone numbers
    final words = name.toLowerCase().split(' ').where((w) => w.isNotEmpty && !RegExp(r'^\d+$').hasMatch(w)).toList();
    if (words.isEmpty) return 'Prélèvement Récurrent';
    return words.map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
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

    // Built-in exclusions for internal transfers, savings, and card top-ups
    final internalExclusions = [
      'REVOLUT',
      'BOURSO',
      'VIREMENT',
      'VIR ',
      'VIR.',
      'PEA',
      'COMPTE TITRES',
      'LIVRET',
      'EPARGNE',
      'CARTE BANCAIRE',
      'RETRAIT',
      'TRANSFERT',
      'SOLDE',
    ];

    final existingLabelsClean = existingLabels.map((l) => l.trim().toUpperCase()).where((l) => l.isNotEmpty).toList();
    final existingExpensesUpper = existingExpenses.map((e) => e.label.trim().toUpperCase()).toList();

    for (final tx in transactions) {
      if (tx.isIncome || tx.amount <= 0) continue;
      if (ignoredIds.contains(tx.id) || ignoredIds.contains('sugg-${tx.id}')) continue;

      final upperTitle = tx.title.toUpperCase();

      // 1. Exclude internal transfers & card top-ups (Revolut, Livrets, PEA, etc.)
      final isInternal = internalExclusions.any((ex) => upperTitle.contains(ex));
      if (isInternal) continue;

      // 2. Exclude anything already declared in user's fixed charges or categories
      final matchesExistingCategory = existingLabelsClean.any((cat) =>
          upperTitle.contains(cat) || cat.contains(upperTitle) || (cat.length >= 4 && upperTitle.contains(cat.substring(0, 4))));
      if (matchesExistingCategory) continue;

      final cleanName = cleanMerchantName(tx.title);
      groupedByMerchant.putIfAbsent(cleanName, () => []).add(tx);
    }

    groupedByMerchant.forEach((merchantName, txList) {
      final sampleTx = txList.first;
      final upperTitle = sampleTx.title.toUpperCase();
      final upperMerchant = merchantName.toUpperCase();

      // Check if already declared in existing temporary expenses
      final alreadyDeclared = existingExpensesUpper.any((label) =>
          label.contains(upperMerchant) || upperMerchant.contains(label));
      if (alreadyDeclared) return;

      // 1. Tax / DGFIP detection
      if (upperTitle.contains('DGFIP') || upperTitle.contains('TRESOR') || upperTitle.contains('IMPOT')) {
        suggestions.add(DetectedRecurringExpense(
          id: 'sugg-${sampleTx.id}',
          merchant: 'DGFIP (Impôts & Taxes)',
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Impôts',
          suggestedDurationMonths: 4,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Échéancier fiscal détecté.',
        ));
        return;
      }

      // 2. Split payment / BNPL detection (Klarna, Alma, Floa, Sofinco, 3x/4x)
      if (upperTitle.contains('KLARNA') ||
          upperTitle.contains('ALMA') ||
          upperTitle.contains('FLOA') ||
          upperTitle.contains('SOFINCO') ||
          upperTitle.contains('COFIDIS') ||
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
          reason: 'Paiement étalé (3x/4x) identifié.',
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
            suggestedDurationMonths: 3,
            lastTransactionDate: sampleTx.date,
            isSepaOrDebit: false,
            reason: 'Dépense de santé étalable.',
          ));
          return;
        }
      }

      // 4. Repeated direct debits (SEPA) not already in fixed charges (minimum 2 occurrences or explicit PRLV)
      if (upperTitle.contains('PRLV') || upperTitle.contains('SEPA') || txList.length >= 2) {
        if (sampleTx.amount >= 15.0) {
          suggestions.add(DetectedRecurringExpense(
            id: 'sugg-${sampleTx.id}',
            merchant: merchantName,
            rawTitle: sampleTx.title,
            amount: sampleTx.amount,
            suggestedCategory: 'Abonnement / Charge',
            suggestedDurationMonths: 12,
            lastTransactionDate: sampleTx.date,
            isSepaOrDebit: true,
            reason: 'Prélèvement automatique régulier.',
          ));
        }
      }
    });

    // Sort by most recent first
    suggestions.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));
    return suggestions;
  }
}
