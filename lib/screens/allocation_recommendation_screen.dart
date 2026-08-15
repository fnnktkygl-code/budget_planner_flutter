import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/bank_config.dart';
import '../models/salary_record.dart';
import '../services/allocation_service.dart';

class AllocationRecommendationScreen extends StatelessWidget {
  final SalaryRecord salaryRecord;
  final double currentBalance;

  const AllocationRecommendationScreen({
    super.key,
    required this.salaryRecord,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    const config = BankConfig(
      mainAccountId: 'main_checking',
      fixedMonthlyExpenses: 1400.0,
      safetyMarginPercent: 0.15,
    );

    final recommendation = AllocationService.computeAllocation(
      currentBalance: currentBalance,
      newSalaryRecord: salaryRecord,
      config: config,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recommandation Bancaire Proactive'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(recommendation, config),
            const SizedBox(height: 16),
            _buildAllocationList(recommendation),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AllocationRecommendation reco, BankConfig config) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Text(
            'Solde Projeté (Après virement salaire)',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${reco.projectedBalance.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: reco.isWarningLowBalance ? AppColors.accentRose : AppColors.accentEmerald,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoStat('Solde Réel Actuel', '${currentBalance.toStringAsFixed(2)} €'),
              _infoStat('Tampon Min', '${config.minBufferAmount.toStringAsFixed(0)} €'),
              _infoStat('Tampon Max', '${config.maxBufferAmount.toStringAsFixed(0)} €'),
            ],
          ),
          if (reco.isWarningLowBalance)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.accentRose),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attention : Votre solde risque d\'être inférieur à votre seuil de sécurité après les charges.',
                      style: TextStyle(color: AppColors.accentRose, fontSize: 12),
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _infoStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildAllocationList(AllocationRecommendation reco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Virements Recommandés',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.trending_up,
          color: AppColors.accentPurple,
          title: 'CTO (Actions US / Convictions)',
          subtitle: 'Allocation des primes & bonus',
          amount: reco.ctoAllocation,
        ),
        _buildActionTile(
          icon: Icons.flight_takeoff,
          color: AppColors.accentGold,
          title: 'Revolut - Vacances',
          subtitle: 'Budget mensuel fixe',
          amount: reco.revolutHolidays,
        ),
        _buildActionTile(
          icon: Icons.shopping_cart,
          color: AppColors.accentCyan,
          title: 'Revolut - Dépenses Courantes',
          subtitle: 'Budget mensuel fixe',
          amount: reco.revolutDaily,
        ),
        _buildActionTile(
          icon: Icons.account_balance,
          color: AppColors.accentEmerald,
          title: 'PEA',
          subtitle: 'Épargne passive (Lazy Money)',
          amount: reco.peaAllocation,
        ),
        if (reco.unallocatedLazyMoney > 0)
          _buildActionTile(
            icon: Icons.savings,
            color: Colors.teal,
            title: 'À Placer (Livrets, etc.)',
            subtitle: 'Surplus non alloué',
            amount: reco.unallocatedLazyMoney,
          ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required double amount,
  }) {
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Text(
          '${amount.toStringAsFixed(2)} €',
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
