import 'package:flutter/material.dart';
import '../models/bank_config.dart';
import '../models/salary_record.dart';
import '../services/allocation_service.dart';

class AllocationRecommendationScreen extends StatelessWidget {
  final SalaryRecord salaryRecord;
  final double currentBalance;

  const AllocationRecommendationScreen({
    Key? key,
    required this.salaryRecord,
    required this.currentBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock Config for UI presentation (In reality, this would come from a provider/local storage)
    const config = BankConfig(
      mainAccountId: 'mock_main_id',
      fixedMonthlyExpenses: 1400.0, // example
      safetyMarginPercent: 0.15, // 15% safety
    );

    final recommendation = AllocationService.computeAllocation(
      currentBalance: currentBalance,
      newSalaryRecord: salaryRecord,
      config: config,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandation Bancaire'),
        backgroundColor: Colors.indigo,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Solde Projeté (Après virement salaire)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${reco.projectedBalance.toStringAsFixed(2)} €',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: reco.isWarningLowBalance ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoStat('Tampon Min', '${config.minBufferAmount.toStringAsFixed(0)} €'),
                _infoStat('Tampon Max', '${config.maxBufferAmount.toStringAsFixed(0)} €'),
              ],
            ),
            if (reco.isWarningLowBalance)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention : Votre solde risque d\'être inférieur à votre seuil de sécurité après les charges.',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _infoStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildAllocationList(AllocationRecommendation reco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Virements Recommandés',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.trending_up,
          color: Colors.purple,
          title: 'CTO (Actions US / Convictions)',
          subtitle: 'Allocation des primes & bonus',
          amount: reco.ctoAllocation,
        ),
        _buildActionTile(
          icon: Icons.flight_takeoff,
          color: Colors.orange,
          title: 'Revolut - Vacances',
          subtitle: 'Budget mensuel fixe',
          amount: reco.revolutHolidays,
        ),
        _buildActionTile(
          icon: Icons.shopping_cart,
          color: Colors.blue,
          title: 'Revolut - Dépenses Courantes',
          subtitle: 'Budget mensuel fixe',
          amount: reco.revolutDaily,
        ),
        _buildActionTile(
          icon: Icons.account_balance,
          color: Colors.green,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          '${amount.toStringAsFixed(2)} €',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
