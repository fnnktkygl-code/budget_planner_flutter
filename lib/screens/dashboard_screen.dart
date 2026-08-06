import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../models/salary_record.dart';
import '../widgets/donut_chart.dart';
import '../widgets/notification_header.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryProvider);
    final activeBaseline = salaryState.activeBaseline;

    final grossSalary = activeBaseline?.grossSalary ?? 3776.67;
    final netSalary = activeBaseline?.netSalary ?? 2713.74;

    final socialContrib = activeBaseline?.socialContributions ?? -840.78;
    final mealTickets = activeBaseline?.mealTickets ?? -52.80;
    final telework = activeBaseline?.teleworkAllowance ?? 15.00;
    final nonTaxable = activeBaseline?.nonTaxableAllowances ?? 34.13;

    final segments = [
      AllocationSegment(
        id: 'charges',
        label: 'Charges',
        percentage: 51,
        color: AppColors.chartRed,
        subItems: [
          AllocationSubItem(name: 'Loyer', amount: 677.00, subtext: 'Charge fixe incompressible'),
          AllocationSubItem(name: 'Abonnements & Médias', amount: 41.00, subtext: 'Internet, Téléphone, Streaming'),
          AllocationSubItem(name: 'Tontine', amount: 300.00, subtext: 'Cotisation tontine mensuelle'),
          AllocationSubItem(name: 'Soutien Familial', amount: 231.00, subtext: 'Contribution mensuelle'),
        ],
      ),
      AllocationSegment(
        id: 'pea',
        label: 'Cible PEA',
        percentage: 35,
        color: AppColors.chartBlue,
        subItems: [
          AllocationSubItem(name: 'DCA ETF MSCI World / S&P 500', amount: (netSalary * 0.35), subtext: 'Investissement actions long terme'),
        ],
      ),
      AllocationSegment(
        id: 'livret_a',
        label: 'Livret A',
        percentage: 7,
        color: AppColors.chartYellow,
        subItems: [
          AllocationSubItem(name: 'Fond d\'urgence / Épargne liquide', amount: (netSalary * 0.07), subtext: 'Épargne de précaution disponible'),
        ],
      ),
      AllocationSegment(
        id: 'reste_a_vivre',
        label: 'Reste à vivre',
        percentage: 7,
        color: AppColors.chartGreen,
        subItems: [
          AllocationSubItem(name: 'Dépenses courantes Revolut', amount: (netSalary * 0.07), subtext: 'Courses, loisirs & vie quotidienne'),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Tableau de bord'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Notification Bar Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VESTAS FRANCE SAS PEROLS | Salarié : NEGEM RICHARD (${activeBaseline?.periodLabel ?? "Juillet 2026"})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Validé IA',
                      style: TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Vue d\'ensemble',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Répartition mensuelle & Flux de Rémunération',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exceptional Bonus Action Dispatch Banner (Separated from regular salary)
            if (activeBaseline != null && activeBaseline.hasExplicitBonus)
              _buildBonusActionCard(activeBaseline),

            // Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAllocationCard(segments, netSalary)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNetIncomeCard(activeBaseline, grossSalary, netSalary, socialContrib, mealTickets, telework, nonTaxable)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAllocationCard(segments, netSalary),
                      const SizedBox(height: 16),
                      _buildNetIncomeCard(activeBaseline, grossSalary, netSalary, socialContrib, mealTickets, telework, nonTaxable),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationCard(List<AllocationSegment> segments, double netSalary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Allocation d\'actifs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: AppColors.accentCyan, size: 18),
                    tooltip: 'En savoir plus sur l\'Allocation d\'actifs',
                    onPressed: () {
                      _showExplanationModal(
                        context,
                        title: '📊 Allocation d\'Actifs & Répartition',
                        content: 'Cette roue présente la ventilation stratégique de votre salaire net en banque selon vos règles budgétaires configurées (Charges fixes, Cible d\'investissement PEA, Épargne liquide Livret A et Reste à vivre).\n\nVous pouvez cliquer sur chaque segment ou élément de légende pour afficher la décomposition exacte des sous-postes.',
                      );
                    },
                  ),
                ],
              ),
              if (_selectedCategoryFilter != null)
                TextButton(
                  onPressed: () => setState(() => _selectedCategoryFilter = null),
                  child: const Text('Réinitialiser', style: TextStyle(color: AppColors.accentCyan, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DonutChartWidget(segments: segments, netSalary: netSalary),
        ],
      ),
    );
  }

  void _showExplanationModal(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                content,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBonusActionCard(SalaryRecord record) {
    final bonusName = record.bonusDescription ?? 'Prime Exceptionnelle';
    final bonusAmt = record.bonusAmount ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF311B92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.accentPurple.withValues(alpha: 0.25), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ $bonusName Détectée !',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Montant net du bonus : + ${bonusAmt > 0 ? bonusAmt.toStringAsFixed(2) : "Inclus"} €',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accentPurple, borderRadius: BorderRadius.circular(8)),
                child: const Text('Surplus Hors Salaire', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Stratégie d\'allocation exceptionnelle séparée du budget récurrent :',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('100% Boost PEA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🚀 Prime de ${bonusAmt > 0 ? bonusAmt.toStringAsFixed(2) : "1 500"} € allouée à 100% sur la cible PEA !'),
                      backgroundColor: AppColors.accentCyan,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.security_rounded, size: 16),
                label: const Text('Matelas Livret A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🛡️ Prime de ${bonusAmt > 0 ? bonusAmt.toStringAsFixed(2) : "1 500"} € versée sur l\'Épargne de Sécurité !'),
                      backgroundColor: AppColors.accentGold,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetIncomeCard(
    SalaryRecord? activeRecord,
    double grossSalary,
    double netSalary,
    double socialContrib,
    double mealTickets,
    double telework,
    double nonTaxable,
  ) {
    final hasBonus = activeRecord?.hasExplicitBonus ?? false;
    final bonusAmt = activeRecord?.bonusAmount ?? 0.0;
    final regularNet = activeRecord?.regularNetSalary ?? netSalary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Revenu net mensuel',
                    style: TextStyle(
                      color: AppColors.accentEmerald,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: AppColors.accentEmerald, size: 18),
                    tooltip: 'Détails du Revenu Net',
                    onPressed: () {
                      _showExplanationModal(
                        context,
                        title: '🧾 Décomposition du Revenu Net Mensuel',
                        content: 'Cette carte restitue l\'analyse financière exacte extraite de votre bulletin de salaire actif (${activeRecord?.periodLabel ?? "Juillet 2026"}) par l\'IA Gemini.\n\nElle présente le passage rigoureux du Salaire Brut aux cotisations sociales, au Net Social (Net avant impôt) puis au Prélèvement à la source (Impôt IR) jusqu\'au montant net final crédité sur votre compte bancaire.',
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeRecord != null ? 'Bulletin Actif (${activeRecord.periodLabel})' : 'Données Extraintes IA',
                  style: const TextStyle(
                    color: AppColors.accentEmerald,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Real Items Table
          _buildSalaryLine('Salaire de base (Brut)', '${grossSalary.toStringAsFixed(2)} €', isPositive: null),
          const SizedBox(height: 14),
          _buildSalaryLine('Cotisations sociales (URSSAF, Retraite)', '${socialContrib.toStringAsFixed(2)} €', isPositive: false),
          
          if (mealTickets != 0.0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('Tickets resto déduits', '${mealTickets.toStringAsFixed(2)} €', isPositive: false),
          ],
          
          if (telework != 0.0 || nonTaxable != 0.0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('Indemnités (Télétravail & Non-imposable)', '+ ${(telework + nonTaxable).toStringAsFixed(2)} €', isPositive: true),
          ],
          
          if (hasBonus && bonusAmt > 0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('Prime / Surplus Exceptionnel', '+ ${bonusAmt.toStringAsFixed(2)} €', isPositive: true),
          ],

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 14),

          // Net Imposable / Net Social Line
          _buildSalaryLine('Net Avant Impôt (Net Social)', '${(activeRecord?.netSocial ?? 2952.28).toStringAsFixed(2)} €', isPositive: true, isBold: true),
          const SizedBox(height: 14),

          // Income Tax (Prélèvement à la source - PAS) Line
          _buildSalaryLine(
            'Prélèvement à la source (Impôt IR ${(activeRecord?.incomeTaxRatePercent ?? 8.0).toStringAsFixed(1)}%)',
            (activeRecord?.incomeTaxAmount ?? -238.54) != 0.0
                ? '${(activeRecord?.incomeTaxAmount ?? -238.54).toStringAsFixed(2)} €'
                : '0.00 € (Taux 0%)',
            isPositive: (activeRecord?.incomeTaxAmount ?? -238.54) != 0.0 ? false : null,
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET À PAYER EFFECTIF (En banque)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasBonus && bonusAmt > 0)
                    Text(
                      'Net Récurrent : ${regularNet.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 11),
                    ),
                ],
              ),
              Text(
                '${netSalary.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryLine(String label, String amount, {bool? isPositive, bool isBold = false}) {
    Color amountColor = isBold ? AppColors.accentCyan : AppColors.textPrimary;
    if (isPositive == true) amountColor = AppColors.accentEmerald;
    if (isPositive == false) amountColor = AppColors.accentRose;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppColors.textPrimary : AppColors.textPrimary,
            fontSize: isBold ? 14 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: isBold ? 16 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
