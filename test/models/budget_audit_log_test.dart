import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner_flutter/models/budget_audit_log.dart';

void main() {
  group('BudgetAuditLogEntry Unit Tests', () {
    test('Serialization and deserialization works seamlessly', () {
      final entry = BudgetAuditLogEntry(
        id: 'log-123',
        timestamp: DateTime(2026, 8, 15, 20, 30, 0),
        actionType: 'arbitrage',
        categoryName: 'Cible PEA',
        pillar: 'Épargne & Investissement',
        previousAmount: 1000.0,
        previousIsPercentage: false,
        newAmount: 475.0,
        newIsPercentage: false,
        effectiveDeltaEuro: -525.0,
        note: 'Absorption déficit Septembre 2026 avec marge de confort +50€',
        period: '2026-09',
      );

      final json = entry.toJson();
      expect(json['id'], 'log-123');
      expect(json['actionType'], 'arbitrage');
      expect(json['categoryName'], 'Cible PEA');
      expect(json['effectiveDeltaEuro'], -525.0);
      expect(json['period'], '2026-09');

      final reconstructed = BudgetAuditLogEntry.fromJson(json);
      expect(reconstructed.id, entry.id);
      expect(reconstructed.timestamp, entry.timestamp);
      expect(reconstructed.actionType, 'arbitrage');
      expect(reconstructed.actionLabel, 'Arbitrage Prévisionnel');
      expect(reconstructed.previousAmount, 1000.0);
      expect(reconstructed.newAmount, 475.0);
      expect(reconstructed.effectiveDeltaEuro, -525.0);
      expect(reconstructed.note, contains('Septembre 2026'));
    });

    test('Default values and fallback deserialization are safe', () {
      final minimal = BudgetAuditLogEntry.fromJson({});
      expect(minimal.id.isNotEmpty, true);
      expect(minimal.actionType, 'manual_edit');
      expect(minimal.effectiveDeltaEuro, 0.0);
      expect(minimal.actionLabel, 'Modification Manuelle');
    });
  });
}
