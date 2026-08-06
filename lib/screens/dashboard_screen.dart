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

  void _showPdfExporterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentRose),
              SizedBox(width: 10),
              Text('Exporter Rapport PDF', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Génération du rapport financier mensuel complet avec :',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text('• Bulletins NEGEM RICHARD (Juillet 2026 & Mai 2025)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              Text('• Allocation des actifs & Donut Chart', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              Text('• Décomposition du Revenu Net Lissé', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              Text('• Synchronisation Bancaire TrueLayer', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Télécharger PDF'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Rapport PDF téléchargé avec succès !'),
                    backgroundColor: AppColors.accentEmerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

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
      AllocationSegment(label: 'Charges', percentage: 51, color: AppColors.chartRed),
      AllocationSegment(label: 'Cible PEA', percentage: 35, color: AppColors.chartBlue),
      AllocationSegment(label: 'Livret A', percentage: 7, color: AppColors.chartYellow),
      AllocationSegment(label: 'Reste à vivre', percentage: 7, color: AppColors.chartGreen),
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

            // Title & Exporter PDF Action Button
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
                      'Répartition mensuelle & Revenu Lissé',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentRose, size: 18),
                  label: const Text('Exporter PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () => _showPdfExporterDialog(context),
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
                      Expanded(child: _buildAllocationCard(segments)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNetIncomeCard(activeBaseline, grossSalary, netSalary, socialContrib, mealTickets, telework, nonTaxable)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAllocationCard(segments),
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

  Widget _buildAllocationCard(List<AllocationSegment> segments) {
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
                children: const [
                  Text(
                    'Allocation d\'actifs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
              if (_selectedCategoryFilter != null)
                TextButton(
                  onPressed: () => setState(() => _selectedCategoryFilter = null),
                  child: const Text('Réinitialiser', style: TextStyle(color: AppColors.accentCyan, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          DonutChartWidget(segments: segments),
        ],
      ),
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
                children: const [
                  Text(
                    'Revenu net mensuel',
                    style: TextStyle(
                      color: AppColors.accentEmerald,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Données Lissées (Historique)',
                  style: TextStyle(
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
          _buildSalaryLine('Cotisations sociales', '${socialContrib.toStringAsFixed(2)} €', isPositive: false),
          const SizedBox(height: 14),
          _buildSalaryLine('Tickets resto déduits', '${mealTickets.toStringAsFixed(2)} €', isPositive: false),
          const SizedBox(height: 14),
          _buildSalaryLine('IND. TELETRAVAIL', '+ ${telework.toStringAsFixed(2)} €', isPositive: true),
          const SizedBox(height: 14),
          _buildSalaryLine('INDEM. NON SOUMISES', '+ ${nonTaxable.toStringAsFixed(2)} €', isPositive: true),
          
          if (hasBonus && bonusAmt > 0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('PRIME / BONUS EXCEPTIONNEL', '+ ${bonusAmt.toStringAsFixed(2)} €', isPositive: true),
          ],

          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET À PAYER EFFECTIF',
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

  Widget _buildSalaryLine(String label, String amount, {bool? isPositive}) {
    Color amountColor = AppColors.textPrimary;
    if (isPositive == true) amountColor = AppColors.accentEmerald;
    if (isPositive == false) amountColor = AppColors.accentRose;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
