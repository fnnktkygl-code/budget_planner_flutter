import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/budget_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final emergencyTarget = budget.monthlyFixedExpenses * budget.emergencyFundTargetMonths;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Architecture de Sécurité & Épargne', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matelas de Sécurité Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MATELAS DE SÉCURITÉ RECOMMANDÉ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accentEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('${budget.emergencyFundTargetMonths.toStringAsFixed(0)} Mois de charges', style: const TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${emergencyTarget.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Basé sur des charges fixes mensuelles de ${budget.monthlyFixedExpenses.toStringAsFixed(0)} € / mois', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Objectifs & Plans d\'Épargne DCA', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildSavingsTile(
              title: 'PEA (Plan d\'Épargne en Actions)',
              subtitle: 'Stratégie ETF World & S&P 500 — DCA 800 € / mois',
              amount: '15 400 €',
              target: '50 000 €',
              progress: 0.30,
              icon: Icons.show_chart_rounded,
              color: AppColors.accentCyan,
            ),
            const SizedBox(height: 12),
            _buildSavingsTile(
              title: 'Livret A (Épargne de Précaution)',
              subtitle: 'Fonds d\'urgence 6 mois immédiatement disponible',
              amount: '11 100 €',
              target: '11 100 €',
              progress: 1.0,
              icon: Icons.shield_rounded,
              color: AppColors.accentEmerald,
            ),
            const SizedBox(height: 12),
            _buildSavingsTile(
              title: 'PER (Plan Épargne Retraite)',
              subtitle: 'Défiscalisation & Versement Volontaire Annuel',
              amount: '6 800 €',
              target: '20 000 €',
              progress: 0.34,
              icon: Icons.lock_clock_rounded,
              color: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsTile({
    required String title,
    required String subtitle,
    required String amount,
    required String target,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$amount accumulés', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Cible: $target', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: AppColors.surfaceVariant, color: color, minHeight: 6),
        ],
      ),
    );
  }
}
