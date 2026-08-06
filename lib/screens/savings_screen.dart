import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/liquid_tank.dart';
import '../widgets/notification_header.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  double _livretABalance = 1600;
  double _livretATarget = 8000;

  double _lddsBalance = 0;
  double _lddsTarget = 0;

  double _monthlySavingsRate = 200;

  void _showEditTankDialog(String title, double currentBalance, double currentTarget, Function(double, double) onSave) {
    final balanceCtrl = TextEditingController(text: currentBalance.toStringAsFixed(0));
    final targetCtrl = TextEditingController(text: currentTarget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.accentGold),
              const SizedBox(width: 10),
              Text('Ajuster $title', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Solde actuel (€)',
                  suffixText: '€',
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Plafond / Cible (€)',
                  suffixText: '€',
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final newBal = double.tryParse(balanceCtrl.text.trim()) ?? currentBalance;
                final newTarget = double.tryParse(targetCtrl.text.trim()) ?? currentTarget;
                onSave(newBal, newTarget);
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalSaved = _livretABalance + _lddsBalance;
    final double totalTarget = _livretATarget + _lddsTarget;

    final double remainingTarget = (15000 - totalSaved).clamp(0, 15000);
    final double monthsToTarget = _monthlySavingsRate > 0 ? remainingTarget / _monthlySavingsRate : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Entonnoir d\'épargne'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title: ARCHITECTURE DE SÉCURITÉ (Matching Screenshots 1 & 8)
            const Text(
              'ARCHITECTURE DE SÉCURITÉ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),

            // Liquid Tanks Grid / Stack
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: LiquidTankWidget(
                          title: 'Livret A',
                          currentAmount: _livretABalance,
                          targetAmount: _livretATarget,
                          liquidColor: AppColors.accentGold,
                          onEdit: () => _showEditTankDialog('Livret A', _livretABalance, _livretATarget, (b, t) {
                            setState(() {
                              _livretABalance = b;
                              _livretATarget = t;
                            });
                          }),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: LiquidTankWidget(
                          title: 'LDDS',
                          currentAmount: _lddsBalance,
                          targetAmount: _lddsTarget,
                          liquidColor: AppColors.accentCyan,
                          onEdit: () => _showEditTankDialog('LDDS', _lddsBalance, _lddsTarget, (b, t) {
                            setState(() {
                              _lddsBalance = b;
                              _lddsTarget = t;
                            });
                          }),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      LiquidTankWidget(
                        title: 'Livret A',
                        currentAmount: _livretABalance,
                        targetAmount: _livretATarget,
                        liquidColor: AppColors.accentGold,
                        onEdit: () => _showEditTankDialog('Livret A', _livretABalance, _livretATarget, (b, t) {
                          setState(() {
                            _livretABalance = b;
                            _livretATarget = t;
                          });
                        }),
                      ),
                      const SizedBox(height: 14),
                      LiquidTankWidget(
                        title: 'LDDS',
                        currentAmount: _lddsBalance,
                        targetAmount: _lddsTarget,
                        liquidColor: AppColors.accentCyan,
                        onEdit: () => _showEditTankDialog('LDDS', _lddsBalance, _lddsTarget, (b, t) {
                          setState(() {
                            _lddsBalance = b;
                            _lddsTarget = t;
                          });
                        }),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Card: Accumulateur Sécurité & Stepper (Matching Screenshot 1)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, color: AppColors.accentGold, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Accumulateur séquentiel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nous remplissons vos filets de sécurité séquentiellement : d\'abord le Livret A, puis le LDDS. Sûr et optimal.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ajuster le taux d\'épargne',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider Control
                  Slider(
                    value: _monthlySavingsRate,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    activeColor: AppColors.accentCyan,
                    onChanged: (val) => setState(() => _monthlySavingsRate = val),
                  ),
                  const SizedBox(height: 8),

                  // Stepper Buttons [-] [ 200 € ] [+] (Matching Screenshot 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        icon: const Icon(Icons.remove_rounded, color: AppColors.accentCyan),
                        onPressed: () {
                          if (_monthlySavingsRate > 50) {
                            setState(() => _monthlySavingsRate -= 50);
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          '${_monthlySavingsRate.toStringAsFixed(0)}   €',
                          style: const TextStyle(
                            color: AppColors.accentCyan,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        icon: const Icon(Icons.add_rounded, color: AppColors.accentCyan),
                        onPressed: () {
                          if (_monthlySavingsRate < 2000) {
                            setState(() => _monthlySavingsRate += 50);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 18),

                  // Stats List (Matching Screenshot 1)
                  _buildStatRow(
                    icon: Icons.show_chart_rounded,
                    label: 'Taux d\'épargne mensuel :',
                    value: '${_monthlySavingsRate.toStringAsFixed(0)} €/mo',
                    valueColor: AppColors.accentEmerald,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    icon: Icons.wallet_outlined,
                    label: 'Total épargné :',
                    value: '${totalSaved.toStringAsFixed(0)} € / ${totalTarget > 0 ? totalTarget.toStringAsFixed(0) : "8000"} €',
                    valueColor: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    icon: Icons.timer_outlined,
                    label: 'Temps pour la cible (15k) :',
                    value: '${monthsToTarget.toStringAsFixed(1)} mois',
                    valueColor: AppColors.accentGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer Tip Card (Matching Screenshot 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: AppColors.accentCyan, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💡 Astuce : Cliquez sur un réservoir ci-dessus pour modifier directement son solde et son plafond.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Épargne Salariale (PEE / PERCO / Intéressement & Participation) Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.business_center_rounded, color: AppColors.accentGold, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Épargne Salariale (PEE / PERCO)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Exonéré IR',
                          style: TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'L\'intéressement et la participation versés directement sur votre PEE ne transitent pas par votre compte bancaire mais constituent une réserve de valeur majeure.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Cumul Intéressement & Participation PEE :', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Suivi automatique via Fiches Paie', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
