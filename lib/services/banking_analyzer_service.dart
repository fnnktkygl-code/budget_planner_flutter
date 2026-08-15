import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/budget_category.dart';
import '../models/temporary_expense.dart';

class DetectedRecurringExpense {
  final String id;
  final String canonicalGroupKey;
  final String merchant;
  final String rawTitle;
  final double amount;
  final String suggestedCategory;
  final int suggestedDurationMonths;
  final DateTime lastTransactionDate;
  final bool isSepaOrDebit;
  final String reason;
  final int occurrenceCount;
  final bool isAiCleaned;

  DetectedRecurringExpense({
    required this.id,
    required this.canonicalGroupKey,
    required this.merchant,
    required this.rawTitle,
    required this.amount,
    required this.suggestedCategory,
    this.suggestedDurationMonths = 12,
    required this.lastTransactionDate,
    this.isSepaOrDebit = false,
    required this.reason,
    this.occurrenceCount = 1,
    this.isAiCleaned = false,
  });

  DetectedRecurringExpense copyWith({
    String? id,
    String? canonicalGroupKey,
    String? merchant,
    String? rawTitle,
    double? amount,
    String? suggestedCategory,
    int? suggestedDurationMonths,
    DateTime? lastTransactionDate,
    bool? isSepaOrDebit,
    String? reason,
    int? occurrenceCount,
    bool? isAiCleaned,
  }) {
    return DetectedRecurringExpense(
      id: id ?? this.id,
      canonicalGroupKey: canonicalGroupKey ?? this.canonicalGroupKey,
      merchant: merchant ?? this.merchant,
      rawTitle: rawTitle ?? this.rawTitle,
      amount: amount ?? this.amount,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedDurationMonths: suggestedDurationMonths ?? this.suggestedDurationMonths,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      isSepaOrDebit: isSepaOrDebit ?? this.isSepaOrDebit,
      reason: reason ?? this.reason,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      isAiCleaned: isAiCleaned ?? this.isAiCleaned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'canonicalGroupKey': canonicalGroupKey,
        'merchant': merchant,
        'rawTitle': rawTitle,
        'amount': amount,
        'suggestedCategory': suggestedCategory,
        'suggestedDurationMonths': suggestedDurationMonths,
        'lastTransactionDate': lastTransactionDate.toIso8601String(),
        'isSepaOrDebit': isSepaOrDebit,
        'reason': reason,
        'occurrenceCount': occurrenceCount,
        'isAiCleaned': isAiCleaned,
      };
}

class BankingAnalyzerService {
  // In-memory cache for AI enhanced suggestions
  static final Map<String, DetectedRecurringExpense> _aiCacheByCanonicalKey = {};

  /// Generate a unique canonical key for grouping across monthly invoices & varying references
  static String generateCanonicalKey(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('CDC HABITAT')) return 'cdc_habitat';
    if (upper.contains('TURREL')) return 'turrel_baptiste';
    if (upper.contains('BPCE')) return 'bpce_assurances';
    if (upper.contains('SENDWAVE')) return 'sendwave';
    if (upper.contains('ORTHO') || upper.contains('LATTES')) return 'lattes_ortho';
    if (upper.contains('BOUYGUES')) return 'bouygues_telecom';
    if (upper.contains('TOTALENERGIES')) return 'totalenergies';
    if (upper.contains('PAYPAL')) return 'paypal';
    if (upper.contains('DGFIP') || upper.contains('TRESOR') || upper.contains('IMPOT')) return 'dgfip';
    if (upper.contains('FREE')) return 'free_telecom';
    if (upper.contains('ORANGE')) return 'orange';
    if (upper.contains('SFR')) return 'sfr';
    if (upper.contains('EDF')) return 'edf';
    if (upper.contains('ENGIE')) return 'engie';
    if (upper.contains('NETFLIX')) return 'netflix';
    if (upper.contains('SPOTIFY')) return 'spotify';
    if (upper.contains('AMAZON')) return 'amazon';

    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Clean up French banking descriptions (BoursoBank / STET prefixes) to readable merchant names
  static String cleanMerchantName(String raw) {
    String name = raw.toUpperCase();

    // 1. Strip standard French banking transaction prefixes
    name = name.replaceAll(RegExp(r'^(PRLV\s+SEPA|VIR\s+SEPA|PRLV|VIR|CB|PAIEMENT|FACTURE|RETRAIT|CARTE)\s*(\d{2}/\d{2})?\s*'), '');
    name = name.replaceAll(RegExp(r'^(DU|LE|POUR)\s+\d{2}/\d{2}(/\d{2,4})?\s*'), '');

    // 2. Strip technical references trailing comma or keywords (CACP, RUM, REF, 04375..., etc.)
    name = name.replaceAll(RegExp(r',\s*(CACP|RUM|REF|EMETTEUR|ID|CONTRAT|FACTURE|TIERS|DOSSIER|\d{4,}).*$', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\b(CACP|RUM|REF|EMETTEUR|ID|NOT|CONTRAT|FACTURE|DOSSIER|TIERS)\s*[:.\s]\s*\S+.*$', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\b04375[A-Z0-9]+\b.*$', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\b719754[A-Z0-9]+\b.*$', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\bCB\*\d+\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\bCARTE\s+X+\d+\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\bX+\d+\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\d{2}/\d{2}(/\d{2,4})?'), '');
    name = name.replaceAll(RegExp(r'[-_/]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 3. Known French service & merchant recognition mapping
    if (name.contains('DGFIP') || name.contains('DIRECTION GENERALE DES FINANCES') || name.contains('TRESOR PUBLIC') || name.contains('IMPOT')) {
      return 'DGFIP (Impôts & Taxes)';
    }
    if (name.contains('CDC HABITAT')) return 'CDC Habitat (Loyer / Logement)';
    if (name.contains('TURREL')) return 'Turrel Baptiste';
    if (name.contains('BPCE')) return 'BPCE Assurances (Habitation)';
    if (name.contains('SENDWAVE')) return 'Sendwave';
    if (name.contains('LATTES') || name.contains('ORTHO') || name.contains('DENT')) return 'Orthodontie Lattes';
    if (name.contains('KLARNA')) return 'Klarna (Paiement 3x)';
    if (name.contains('ALMA')) return 'Alma (Paiement 3x/4x)';
    if (name.contains('FLOA')) return 'Floa Bank (Paiement 4x)';
    if (name.contains('SOFINCO')) return 'Sofinco (Crédit)';
    if (name.contains('COFIDIS')) return 'Cofidis (Crédit)';
    if (name.contains('PAYPAL')) return 'PayPal';
    if (name.contains('EDF')) return 'EDF Électricité';
    if (name.contains('ENGIE')) return 'Engie Gaz / Élec';
    if (name.contains('TOTALENERGIES')) return 'TotalEnergies';
    if (name.contains('FREE MOBILE') || name.contains('FREE TELECOM') || name.contains('FREEBOX') || name.contains('FREE ')) return 'Free Télécom';
    if (name.contains('ORANGE')) return 'Orange';
    if (name.contains('SFR')) return 'SFR';
    if (name.contains('BOUYGUES')) return 'Bouygues Telecom';
    if (name.contains('MUTUELLE') || name.contains('ALAN') || name.contains('HARMONIE') || name.contains('MGEN')) return 'Mutuelle Santé';
    if (name.contains('AMAZON') || name.contains('PRIME')) return 'Amazon';
    if (name.contains('NETFLIX')) return 'Netflix';
    if (name.contains('SPOTIFY')) return 'Spotify';
    if (name.contains('APPLE')) return 'Apple Services';
    if (name.contains('GOOGLE')) return 'Google Services';

    // Capitalize first letters and remove standalone numbers or stray punctuation
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
    final Map<String, List<TransactionItem>> groupedByCanonicalKey = {};

    // Exclude internal transfers, savings, and card top-ups
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

      final upperTitle = tx.title.toUpperCase();

      // 1. Exclude internal transfers & card top-ups (Revolut, Livrets, PEA, etc.)
      final isInternal = internalExclusions.any((ex) => upperTitle.contains(ex));
      if (isInternal) continue;

      // 2. Exclude anything already declared in user's fixed charges or categories
      final matchesExistingCategory = existingLabelsClean.any((cat) =>
          upperTitle.contains(cat) || cat.contains(upperTitle) || (cat.length >= 4 && upperTitle.contains(cat.substring(0, 4))));
      if (matchesExistingCategory) continue;

      final canonicalKey = generateCanonicalKey(tx.title);
      final suggId = 'sugg-$canonicalKey';
      if (ignoredIds.contains(suggId) || ignoredIds.contains(tx.id)) continue;

      groupedByCanonicalKey.putIfAbsent(canonicalKey, () => []).add(tx);
    }

    groupedByCanonicalKey.forEach((canonicalKey, txList) {
      // Sort txs to get most recent first
      txList.sort((a, b) => b.date.compareTo(a.date));
      final sampleTx = txList.first;
      final upperTitle = sampleTx.title.toUpperCase();
      final merchantName = cleanMerchantName(sampleTx.title);
      final upperMerchant = merchantName.toUpperCase();
      final suggId = 'sugg-$canonicalKey';

      // Check if already declared in existing temporary expenses
      final alreadyDeclared = existingExpensesUpper.any((label) =>
          label.contains(upperMerchant) || upperMerchant.contains(label));
      if (alreadyDeclared) return;

      // Use cached AI enrichment if available
      final cachedAi = _aiCacheByCanonicalKey[canonicalKey];
      if (cachedAi != null) {
        suggestions.add(cachedAi.copyWith(
          amount: sampleTx.amount,
          lastTransactionDate: sampleTx.date,
          occurrenceCount: txList.length,
        ));
        return;
      }

      // 1. Tax / DGFIP detection
      if (upperTitle.contains('DGFIP') || upperTitle.contains('TRESOR') || upperTitle.contains('IMPOT') || canonicalKey == 'dgfip') {
        suggestions.add(DetectedRecurringExpense(
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: 'DGFIP (Impôts & Taxes)',
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Impôts & Taxes',
          suggestedDurationMonths: 4,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Échéancier fiscal ou prélèvement d\'impôt identifié.',
          occurrenceCount: txList.length,
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
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Échéancier / Crédit',
          suggestedDurationMonths: 3,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: sampleTx.title.toUpperCase().contains('PRLV'),
          reason: 'Paiement fractionné (3x/4x) identifié.',
          occurrenceCount: txList.length,
        ));
        return;
      }

      // 3. Healthcare / Dental treatments
      if (upperTitle.contains('DENT') ||
          upperTitle.contains('ORTHO') ||
          upperTitle.contains('CLINIQUE') ||
          upperTitle.contains('HOPITAL') ||
          canonicalKey == 'lattes_ortho') {
        if (sampleTx.amount >= 50.0) {
          suggestions.add(DetectedRecurringExpense(
            id: suggId,
            canonicalGroupKey: canonicalKey,
            merchant: merchantName,
            rawTitle: sampleTx.title,
            amount: sampleTx.amount,
            suggestedCategory: 'Santé & Soins',
            suggestedDurationMonths: 3,
            lastTransactionDate: sampleTx.date,
            isSepaOrDebit: false,
            reason: 'Dépense de santé ou traitement étalable.',
            occurrenceCount: txList.length,
          ));
          return;
        }
      }

      // 4. Housing / Rent (CDC Habitat, etc.)
      if (canonicalKey == 'cdc_habitat' || upperTitle.contains('HABITAT') || upperTitle.contains('LOYER')) {
        suggestions.add(DetectedRecurringExpense(
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Logement / Loyer',
          suggestedDurationMonths: 12,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Prélèvement de loyer ou charges de logement.',
          occurrenceCount: txList.length,
        ));
        return;
      }

      // 5. Insurance (BPCE, etc.)
      if (canonicalKey == 'bpce_assurances' || upperTitle.contains('ASSUR') || upperTitle.contains('IARD')) {
        suggestions.add(DetectedRecurringExpense(
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Assurance Habitation',
          suggestedDurationMonths: 12,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Cotisation d\'assurance prélevée mensuellement.',
          occurrenceCount: txList.length,
        ));
        return;
      }

      // 6. Telecom & Utilities (Bouygues, TotalEnergies, Free, Orange, etc.)
      if (canonicalKey == 'bouygues_telecom' || canonicalKey == 'totalenergies' || canonicalKey == 'free_telecom' || canonicalKey == 'orange') {
        final cat = (canonicalKey == 'totalenergies' || upperTitle.contains('ENERGIE')) ? 'Énergie & Gaz' : 'Télécom & Internet';
        suggestions.add(DetectedRecurringExpense(
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: cat,
          suggestedDurationMonths: 12,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Abonnement mensuel régulier.',
          occurrenceCount: txList.length,
        ));
        return;
      }

      // 7. General Recurring SEPA or Repeated debits
      if (upperTitle.contains('PRLV') || upperTitle.contains('SEPA') || txList.length >= 2 || sampleTx.amount >= 20.0) {
        suggestions.add(DetectedRecurringExpense(
          id: suggId,
          canonicalGroupKey: canonicalKey,
          merchant: merchantName,
          rawTitle: sampleTx.title,
          amount: sampleTx.amount,
          suggestedCategory: 'Abonnement / Charge',
          suggestedDurationMonths: 12,
          lastTransactionDate: sampleTx.date,
          isSepaOrDebit: true,
          reason: 'Prélèvement automatique régulier identifié.',
          occurrenceCount: txList.length,
        ));
      }
    });

    // Sort by amount descending to put biggest impact first
    suggestions.sort((a, b) => b.amount.compareTo(a.amount));
    return suggestions;
  }

  /// AI Enhancement: Asynchronously clean and enrich suggestions via Gemini
  static Future<List<DetectedRecurringExpense>> enhanceWithGeminiAi({
    required List<DetectedRecurringExpense> currentSuggestions,
    String? clientApiKey,
  }) async {
    if (currentSuggestions.isEmpty) return currentSuggestions;

    final unenhanced = currentSuggestions.where((s) => !s.isAiCleaned).toList();
    if (unenhanced.isEmpty) return currentSuggestions;

    try {
      final backendUrl = Uri.parse('/api/clean-transactions');
      final response = await http.post(
        backendUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactions': unenhanced.map((s) => {
                'id': s.id,
                'title': s.rawTitle,
                'amount': s.amount,
                'date': s.lastTransactionDate.toIso8601String(),
              }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List cleanedList = data['cleanedTransactions'] ?? [];

        final Map<String, Map<String, dynamic>> cleanedById = {};
        for (final item in cleanedList) {
          if (item is Map && item['id'] != null) {
            cleanedById[item['id'].toString()] = Map<String, dynamic>.from(item);
          }
        }

        final List<DetectedRecurringExpense> enhanced = [];
        for (final sugg in currentSuggestions) {
          final aiInfo = cleanedById[sugg.id];
          if (aiInfo != null) {
            final updated = sugg.copyWith(
              merchant: aiInfo['cleanMerchant']?.toString() ?? sugg.merchant,
              suggestedCategory: aiInfo['category']?.toString() ?? sugg.suggestedCategory,
              suggestedDurationMonths: (aiInfo['suggestedDurationMonths'] as num?)?.toInt() ?? sugg.suggestedDurationMonths,
              reason: aiInfo['reason']?.toString() ?? sugg.reason,
              isAiCleaned: true,
            );
            _aiCacheByCanonicalKey[sugg.canonicalGroupKey] = updated;
            enhanced.add(updated);
          } else {
            enhanced.add(sugg);
          }
        }
        return enhanced;
      }
    } catch (e) {
      debugPrint('⚠️ [BankingAnalyzerService] AI enhancement error: $e');
    }

    return currentSuggestions;
  }
}
