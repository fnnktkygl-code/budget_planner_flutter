import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = ref.watch(salaryProvider);
    final activeSalary = salary.activeBaseline?.netSalary ?? 3850.0;

    final needs = activeSalary * 0.50; // 50% Charges Fixes
    final wants = activeSalary * 0.30; // 30% Plaisirs & Envie
    final savings = activeSalary * 0.20; // 20% Épargne

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Règles Budgétaires 50/30/20', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, color: AppColors.accentCyan, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Calculé sur votre salaire net référent actuel de ${activeSalary.toStringAsFixed(0)} € / mois.',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildRuleCard('50% — Besoins Essentiels & Fixes', '${needs.toStringAsFixed(0)} €', 'Loyer, factures, alimentation de base, transports', AppColors.accentCyan),
            const SizedBox(height: 12),
            _buildRuleCard('30% — Envies & Loisirs', '${wants.toStringAsFixed(0)} €', 'Restaurants, voyages, loisirs, vêtements', AppColors.accentGold),
            const SizedBox(height: 12),
            _buildRuleCard('20% — Épargne & Investissement', '${savings.toStringAsFixed(0)} €', 'DCA, matelas d\'urgence, bourse', AppColors.accentEmerald),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String amount, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
