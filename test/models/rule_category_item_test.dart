import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner_flutter/screens/rules_screen.dart';

void main() {
  group('RuleCategoryItem Model & Math Tests', () {
    test('Calculates nominal and percentage amounts correctly', () {
      final netSalary = 2713.74;

      final fixedItem = RuleCategoryItem(
        id: 'fix-1',
        name: 'Loyer',
        amount: 850.0,
        isPercentage: false,
        iconType: 'home',
        iconBgColor: Colors.blue,
      );

      expect(fixedItem.getEffectiveAmount(netSalary), 850.0);
      expect(fixedItem.getEffectivePercent(netSalary), closeTo(31.32, 0.05));

      final percentItem = RuleCategoryItem(
        id: 'sav-1',
        name: 'PEA',
        amount: 15.0,
        isPercentage: true,
        iconType: 'chart',
        iconBgColor: Colors.green,
      );

      expect(percentItem.getEffectivePercent(netSalary), 15.0);
      expect(percentItem.getEffectiveAmount(netSalary), closeTo(407.06, 0.05));
    });

    test('JSON Serialization and Deserialization preserve note and fields', () {
      final item = RuleCategoryItem(
        id: 'fix-sub',
        name: 'Abonnements',
        amount: 51.99,
        isPercentage: false,
        isLocked: true,
        iconType: 'card',
        iconBgColor: const Color(0xFF1E88E5),
        note: 'Bouygues (41.00 €) • Spotify (10.99 €)',
      );

      final json = item.toJson();
      expect(json['id'], 'fix-sub');
      expect(json['name'], 'Abonnements');
      expect(json['amount'], 51.99);
      expect(json['note'], 'Bouygues (41.00 €) • Spotify (10.99 €)');

      final restored = RuleCategoryItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.amount, item.amount);
      expect(restored.note, item.note);
      expect(restored.iconBgColor.value, item.iconBgColor.value);
    });

    test('Accumulation / Cumul preserves exact decimal additions', () {
      final netSalary = 2713.74;
      final subItem = RuleCategoryItem(
        id: 'fix-sub',
        name: 'Abonnements',
        amount: 41.00,
        isPercentage: false,
        iconType: 'card',
        iconBgColor: Colors.purple,
        note: 'Bouygues',
      );

      final detectedExpenseAmt = 10.99;
      final detectedMerchant = 'Spotify';

      final newTotal = subItem.getEffectiveAmount(netSalary) + detectedExpenseAmt;
      subItem.amount = double.parse(newTotal.toStringAsFixed(2));
      subItem.note = '${subItem.note} • $detectedMerchant';

      expect(subItem.amount, 51.99);
      expect(subItem.note, 'Bouygues • Spotify');
    });
  });
}
