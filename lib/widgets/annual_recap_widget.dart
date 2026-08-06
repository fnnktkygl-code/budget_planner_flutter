import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/salary_record.dart';

class AnnualRecapWidget extends StatelessWidget {
  final List<SalaryRecord> records;

  const AnnualRecapWidget({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    final double totalNetBanque = records.fold(0.0, (sum, r) => sum + r.netSalary);
    final double totalPrimes = records.fold(0.0, (sum, r) => sum + (r.bonusAmount ?? 0.0));
    final double totalPEE = records.fold(0.0, (sum, r) => sum + r.companySavingsPEE);
    final double totalPAS = records.fold(0.0, (sum, r) => sum + r.incomeTaxAmount.abs());
    final double totalNetSocial = records.fold(0.0, (sum, r) => sum + r.netSocial);
    final double totalGlobalComp = totalNetBanque + totalPEE;

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
                  Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Bilan Annuel de Rémunération Globale',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${records.length} mois suivis',
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Net Global Card Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL NET ENMAGASINÉ (Banque + PEE)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalGlobalComp.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Rétention Fiscale Impôt IR (PAS)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalPAS.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentRose, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detailed Breakdown Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            children: [
              _buildTableRow('Salaire Net de Base Cumulé', '${(totalNetBanque - totalPrimes).toStringAsFixed(2)} €', AppColors.textPrimary, isHeader: false),
              _buildTableRow('Primes & Variable Explicites', '${totalPrimes.toStringAsFixed(2)} €', AppColors.accentEmerald, isHeader: false),
              _buildTableRow('Épargne Salariale PEE (Intéressement)', '${totalPEE.toStringAsFixed(2)} €', AppColors.accentGold, isHeader: false),
              _buildTableRow('Net Social Avant Impôt (CSG/CRDS)', '${totalNetSocial.toStringAsFixed(2)} €', AppColors.accentPurple, isHeader: false),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String value, Color valueColor, {required bool isHeader}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: isHeader ? AppColors.textSecondary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
