import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../widgets/donut_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = ref.watch(salaryProvider);
    final activeBaseline = salary.activeBaseline;

    final grossSalary = activeBaseline?.grossSalary ?? 3776.67;
    final netSalary = activeBaseline?.netSalary ?? 2861.26;

    final segments = [
      AllocationSegment(label: 'Charges', percentage: 51, color: AppColors.chartRed),
      AllocationSegment(label: 'Cible PEA', percentage: 35, color: AppColors.chartBlue),
      AllocationSegment(label: 'Livret A', percentage: 7, color: AppColors.chartYellow),
      AllocationSegment(label: 'Reste à vivre', percentage: 7, color: AppColors.chartGreen),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: const [
            Text(
              'Tableau de bord',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Exporter PDF Action Button (Matching Screenshot 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Exporter PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Génération du rapport PDF en cours...'),
                        backgroundColor: AppColors.accentCyan,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Responsive Layout: Grid on Desktop (width >= 900), Stack on Mobile
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAllocationCard(segments)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNetIncomeCard(grossSalary, netSalary)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAllocationCard(segments),
                      const SizedBox(height: 16),
                      _buildNetIncomeCard(grossSalary, netSalary),
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
          const SizedBox(height: 20),
          DonutChartWidget(segments: segments),
        ],
      ),
    );
  }

  Widget _buildNetIncomeCard(double grossSalary, double netSalary) {
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

          // Items Table (Matching Screenshot 1)
          _buildSalaryLine('Salaire de base (Brut)', '${grossSalary.toStringAsFixed(2)} €', isPositive: null),
          const SizedBox(height: 14),
          _buildSalaryLine('Cotisations sociales', '- 860.78 €', isPositive: false),
          const SizedBox(height: 14),
          _buildSalaryLine('Tickets resto déduits', '- 3.90 €', isPositive: false),
          const SizedBox(height: 14),
          _buildSalaryLine('IND. TELETRAVAIL', '+ 15.00 €', isPositive: true),
          const SizedBox(height: 14),
          _buildSalaryLine('INDEM. NON SOUMISES', '+ 34.13 €', isPositive: true),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET À PAYER EFFECTIF',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
