import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/budget_provider.dart';
import '../core/providers/salary_provider.dart';
import '../core/providers/settings_provider.dart';
import '../widgets/banking_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final budget = ref.watch(budgetProvider);
    final salary = ref.watch(salaryProvider);
    final settings = ref.watch(settingsProvider);

    final activeBaselineNet = salary.activeBaseline?.netSalary ?? 3850.0;
    final availableBudget = activeBaselineNet - budget.totalSpent;
    final savingsRate = activeBaselineNet > 0 ? (salary.activeBaseline?.investableAmount ?? 1200.0) / activeBaselineNet * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Utilisateur Gmail & Status Banque
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentCyan.withValues(alpha: 0.2),
                      child: Text(
                        (authState.user?.displayName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.displayName ?? 'AuraBudget Pro',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authState.user?.email ?? 'Base : ${salary.activeBaseline?.periodLabel ?? 'Juin 2026'}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const BankingModalContent(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: settings.bankConnected ? AppColors.accentEmerald.withValues(alpha: 0.15) : AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: settings.bankConnected ? AppColors.accentEmerald : AppColors.accentCyan),
                    ),
                    child: Row(
                      children: [
                        Icon(settings.bankConnected ? Icons.check_circle_rounded : Icons.account_balance_rounded, color: settings.bankConnected ? AppColors.accentEmerald : AppColors.accentCyan, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          settings.bankConnected ? settings.connectedBankName : 'Connecter banque',
                          style: TextStyle(color: settings.bankConnected ? AppColors.accentEmerald : AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main KPI Card — Budget Disponible
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.cardBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BUDGET MENSUEL DISPONIBLE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Text('⭐ Référent Actif', style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${availableBudget.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Sur un salaire référent net de ${activeBaselineNet.toStringAsFixed(0)} € / mois', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: activeBaselineNet > 0 ? (budget.totalSpent / activeBaselineNet).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.accentCyan,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Secondary KPI Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ÉPARGNE & DCA', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${(salary.activeBaseline?.investableAmount ?? 1200).toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.accentEmerald, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${savingsRate.toStringAsFixed(1)}% du salaire net', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MOYENNE LISSÉE 2025-26', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${salary.analytics.overallAverageNet.toStringAsFixed(0)} € / m', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('Indicatif analytique', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Répartition des Catégories
            const Text('Répartition des Dépenses', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budget.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final cat = budget.categories[idx];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSubtle)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.pie_chart_rounded, color: AppColors.accentCyan, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${cat.spentAmount.toStringAsFixed(0)} € engagés / ${cat.allocatedAmount.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Text('${cat.remaining.toStringAsFixed(0)} € restants', style: TextStyle(color: cat.remaining >= 0 ? AppColors.accentEmerald : AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Transactions Récentes
            const Text('Transactions Récentes', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budget.transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final tx = budget.transactions[idx];
                return ListTile(
                  tileColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: tx.isIncome ? AppColors.accentEmerald : AppColors.accentRose),
                  title: Text(tx.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  trailing: Text('${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} €', style: TextStyle(color: tx.isIncome ? AppColors.accentEmerald : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
