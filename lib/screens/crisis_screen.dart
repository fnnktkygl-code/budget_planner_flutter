import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/budget_provider.dart';
import '../core/providers/salary_provider.dart';

class CrisisScreen extends ConsumerStatefulWidget {
  const CrisisScreen({super.key});

  @override
  ConsumerState<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends ConsumerState<CrisisScreen> {
  double _incomeDropPercent = 20.0;
  double _inflationPercent = 8.0;

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryProvider);
    final budget = ref.watch(budgetProvider);

    final baseSalary = salary.activeBaseline?.netSalary ?? 3850.0;
    final simulatedSalary = baseSalary * (1 - _incomeDropPercent / 100);
    final simulatedExpenses = budget.monthlyFixedExpenses * (1 + _inflationPercent / 100);
    final simulatedMargin = simulatedSalary - simulatedExpenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Simulation de Crise & Stress-Test', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warning)),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Testez la résistance de votre budget face à des chocs économiques (perte de revenu, hausse de l\'inflation).',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Paramètres de Choc Économique', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Text('Baisse de revenu : ${_incomeDropPercent.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Slider(
              value: _incomeDropPercent,
              min: 0,
              max: 50,
              divisions: 10,
              activeColor: AppColors.accentRose,
              onChanged: (val) => setState(() => _incomeDropPercent = val),
            ),

            const SizedBox(height: 12),
            Text('Hausse de l\'inflation / charges : ${_inflationPercent.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Slider(
              value: _inflationPercent,
              min: 0,
              max: 25,
              divisions: 25,
              activeColor: AppColors.accentGold,
              onChanged: (val) => setState(() => _inflationPercent = val),
            ),
            const SizedBox(height: 24),

            // Result Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: simulatedMargin >= 0 ? AppColors.accentEmerald : AppColors.danger, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RÉSULTAT DU STRESS-TEST', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('${simulatedMargin.toStringAsFixed(0)} € / mois', style: TextStyle(color: simulatedMargin >= 0 ? AppColors.accentEmerald : AppColors.danger, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    simulatedMargin >= 0
                        ? 'Votre budget reste résilient même en cas de crise majeure !'
                        : 'Attention : Déficit mensuel en cas de crise. Ajustez votre matelas de sécurité.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
