import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner_flutter/services/banking_analyzer_service.dart';
import 'package:budget_planner_flutter/models/budget_category.dart';

void main() {
  group('BankingAnalyzerService Normalization & Deduplication', () {
    test('Cleans French banking merchant names without technical codes', () {
      expect(
        BankingAnalyzerService.cleanMerchantName('PRLV SEPA Turrel Baptiste, Cacp.322855169.4, Rum 7tmcm0596bdtw8'),
        'Turrel Baptiste',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('PRLV SEPA Cdc Habitat, 04375n2202670801689910, Rum'),
        'CDC Habitat (Loyer / Logement)',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('PRLV SEPA BPCE ASSURANCES IARD, BPCE ASSURANCE PRELEVEMENT HABITATION 01, 719754402zz'),
        'BPCE Assurances (Habitation)',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('CARTE 12/08 SENDWAVE CB*2753'),
        'Sendwave',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('CARTE 10/08 LATTES ORTHO CB*2753'),
        'Orthodontie Lattes',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('PRLV SEPA TOTALENERGIES SEPA'),
        'TotalEnergies',
      );
      expect(
        BankingAnalyzerService.cleanMerchantName('PRLV SEPA PAYPAL EUROPE'),
        'PayPal',
      );
    });

    test('Groups multi-month duplicates into single entries with correct occurrence counts', () {
      final List<TransactionItem> transactions = [
        TransactionItem(id: 'tx-1', title: 'PRLV SEPA Turrel Baptiste, Cacp.322855169.4, Rum 7tmcm0596bdtw8', amount: 145.0, date: DateTime(2026, 8, 1), category: 'Divers'),
        TransactionItem(id: 'tx-2', title: 'PRLV SEPA Turrel Baptiste, Cacp.320448670.1, Rum 7tmcm0596bdtw8', amount: 145.0, date: DateTime(2026, 7, 1), category: 'Divers'),
        TransactionItem(id: 'tx-3', title: 'PRLV SEPA Cdc Habitat, 04375n2202670801689910, Rum', amount: 612.09, date: DateTime(2026, 8, 5), category: 'Divers'),
        TransactionItem(id: 'tx-4', title: 'PRLV SEPA Cdc Habitat, 04375n2202667406695988, Rum', amount: 612.09, date: DateTime(2026, 7, 5), category: 'Divers'),
        TransactionItem(id: 'tx-5', title: 'PRLV SEPA Cdc Habitat, 04375n2202664222934244, Rum', amount: 612.09, date: DateTime(2026, 6, 5), category: 'Divers'),
        TransactionItem(id: 'tx-6', title: 'PRLV SEPA BPCE ASSURANCES IARD, BPCE ASSURANCE PRELEVEMENT HABITATION 01, 719754402zz', amount: 92.56, date: DateTime(2026, 8, 10), category: 'Divers'),
        TransactionItem(id: 'tx-7', title: 'PRLV SEPA BPCE ASSURANCES IARD, BPCE ASSURANCE PRELEVEMENT HABITATION 01, 719754402zz', amount: 92.56, date: DateTime(2026, 7, 10), category: 'Divers'),
        TransactionItem(id: 'tx-8', title: 'CARTE 12/08 SENDWAVE CB*2753', amount: 230.16, date: DateTime(2026, 8, 12), category: 'Divers'),
        TransactionItem(id: 'tx-9', title: 'CARTE 10/08 LATTES ORTHO CB*2753', amount: 990.0, date: DateTime(2026, 8, 10), category: 'Divers'),
      ];

      final suggestions = BankingAnalyzerService.analyzeTransactions(
        transactions: transactions,
        existingExpenses: [],
        existingLabels: [],
      );

      // Verify no duplicates
      final cdcList = suggestions.where((s) => s.canonicalGroupKey == 'cdc_habitat').toList();
      expect(cdcList.length, 1);
      expect(cdcList.first.occurrenceCount, 3);
      expect(cdcList.first.amount, 612.09);
      expect(cdcList.first.merchant, 'CDC Habitat (Loyer / Logement)');

      final turrelList = suggestions.where((s) => s.canonicalGroupKey == 'turrel_baptiste').toList();
      expect(turrelList.length, 1);
      expect(turrelList.first.occurrenceCount, 2);
      expect(turrelList.first.merchant, 'Turrel Baptiste');

      final bpceList = suggestions.where((s) => s.canonicalGroupKey == 'bpce_assurances').toList();
      expect(bpceList.length, 1);
      expect(bpceList.first.occurrenceCount, 2);
      expect(bpceList.first.merchant, 'BPCE Assurances (Habitation)');
    });
  });
}
