import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/salary_record.dart';
import '../models/tax_adjustment.dart';

class AnnualRecapWidget extends StatefulWidget {
  final List<SalaryRecord> records;
  final List<TaxAdjustment>? taxAdjustments;

  const AnnualRecapWidget({
    super.key,
    required this.records,
    this.taxAdjustments,
  });

  @override
  State<AnnualRecapWidget> createState() => _AnnualRecapWidgetState();
}

class _AnnualRecapWidgetState extends State<AnnualRecapWidget> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    final years = widget.records.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));

    final filteredRecords = _selectedYear == null
        ? widget.records
        : widget.records.where((r) => r.year == _selectedYear).toList();

    if (filteredRecords.isEmpty) return const SizedBox.shrink();

    final double totalGross = filteredRecords.fold(0.0, (sum, r) => sum + (r.grossSalary ?? 0.0));
    final double totalNetBanque = filteredRecords.fold(0.0, (sum, r) => sum + r.netSalary);
    final double totalPrimes = filteredRecords.fold(0.0, (sum, r) => sum + (r.bonusAmount ?? 0.0));
    final double totalPEE = filteredRecords.fold(0.0, (sum, r) => sum + r.companySavingsPEE);
    final double totalPAS = filteredRecords.fold(0.0, (sum, r) => sum + r.incomeTaxAmount.abs());
    final double totalNetSocial = filteredRecords.fold(0.0, (sum, r) => sum + r.netSocial);
    final double totalGlobalComp = totalNetBanque + totalPEE;
    final double totalBaseNet = totalNetBanque - totalPrimes;
    final double totalCotisations = totalGross > totalNetSocial ? (totalGross - totalNetSocial) : 0.0;

    final double netPctOfGross = totalGross > 0 ? (totalNetBanque / totalGross * 100) : 0.0;
    final double basePctOfNet = totalNetBanque > 0 ? (totalBaseNet / totalNetBanque * 100) : 0.0;
    final double primePctOfNet = totalNetBanque > 0 ? (totalPrimes / totalNetBanque * 100) : 0.0;
    final double pasPctOfNetSocial = totalNetSocial > 0 ? (totalPAS / totalNetSocial * 100) : 0.0;
    final double pasPctOfGross = totalGross > 0 ? (totalPAS / totalGross * 100) : 0.0;
    final double cotiPctOfGross = totalGross > 0 ? (totalCotisations / totalGross * 100) : 0.0;

    final bool hasTaxAdj = widget.taxAdjustments != null && widget.taxAdjustments!.isNotEmpty;
    final activeTaxAdj = (_selectedYear != null && hasTaxAdj)
        ? widget.taxAdjustments!.where((t) => t.taxYear == _selectedYear).firstOrNull
        : widget.taxAdjustments?.firstOrNull;

    final double totalRealTaxDgfip = activeTaxAdj?.totalTaxNetDue ?? (hasTaxAdj ? widget.taxAdjustments!.fold(0.0, (sum, t) => sum + t.totalTaxNetDue) : 0.0);
    final double totalRealMonthlyDgfip = activeTaxAdj?.monthlyRealTaxForYear ?? (hasTaxAdj ? widget.taxAdjustments!.fold(0.0, (sum, t) => sum + t.monthlyRealTaxForYear) : 0.0);

    final int monthCount = filteredRecords.length;
    final bool isFullYear = _selectedYear != null && monthCount == 12;
    final String completenessLabel = _selectedYear == null
        ? '$monthCount mois suivis (Cumul global)'
        : (isFullYear ? '$monthCount / 12 mois (Année complète ✓)' : '$monthCount / 12 mois (Année en cours ⏳)');

    final Color completenessColor = _selectedYear == null
        ? AppColors.accentGold
        : (isFullYear ? AppColors.accentEmerald : AppColors.accentCyan);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.accentGold, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Bilan Annuel de Rémunération Globale',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completenessColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: completenessColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  completenessLabel,
                  style: TextStyle(color: completenessColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildYearChip(null, 'Toutes les périodes (${widget.records.length} mois)'),
                for (int y in years) ...[
                  const SizedBox(width: 8),
                  _buildYearChip(y, '$y (${widget.records.where((r) => r.year == y).length}/12 m)'),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'TOTAL NET ENMAGASINÉ (Banque + PEE)',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            if (netPctOfGross > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${netPctOfGross.toStringAsFixed(1)}% du Brut',
                                  style: const TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]
                          ],
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
                        Text(
                          hasTaxAdj ? 'Impôt Réel DGFiP (Avis)' : 'Rétention Fiscale Impôt IR (PAS)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasTaxAdj ? '${totalRealTaxDgfip.toStringAsFixed(0)} € / an' : '${totalPAS.toStringAsFixed(2)} € (${pasPctOfNetSocial.toStringAsFixed(1)}%)',
                          style: const TextStyle(color: AppColors.accentRose, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (hasTaxAdj) ...[
                          const SizedBox(height: 2),
                          Text(
                            '(${totalRealMonthlyDgfip.toStringAsFixed(2)} €/mois • PAS Paie prov.: ${totalPAS.toStringAsFixed(0)} €)',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (totalGross > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (netPctOfGross * 10).round().clamp(1, 1000),
                            child: Container(color: AppColors.accentEmerald),
                          ),
                          if (cotiPctOfGross > 0)
                            Expanded(
                              flex: (cotiPctOfGross * 10).round().clamp(1, 1000),
                              child: Container(color: AppColors.accentPurple),
                            ),
                          if (pasPctOfNetSocial > 0)
                            Expanded(
                              flex: (pasPctOfNetSocial * 10).round().clamp(1, 1000),
                              child: Container(color: AppColors.accentRose),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.4),
            },
            children: [
              if (totalGross > 0)
                _buildTableRow(
                  'Salaire Brut Total Cumulé',
                  '${totalGross.toStringAsFixed(2)} €',
                  '100.0% du Brut',
                  AppColors.textPrimary,
                ),
              if (totalGross > 0)
                _buildTableRow(
                  'Cotisations & Charges Sociales',
                  '${totalCotisations.toStringAsFixed(2)} €',
                  '${cotiPctOfGross.toStringAsFixed(1)}% du Brut',
                  AppColors.accentPurple,
                ),
              _buildTableRow(
                'Net Social Avant Impôt (CSG/CRDS)',
                '${totalNetSocial.toStringAsFixed(2)} €',
                totalGross > 0 ? '${(totalNetSocial / totalGross * 100).toStringAsFixed(1)}% du Brut' : '100.0%',
                AppColors.textPrimary,
              ),
              _buildTableRow(
                'Retenue Impôt sur le Revenu (PAS Prélevé sur Paie)',
                '${totalPAS.toStringAsFixed(2)} €',
                '${pasPctOfNetSocial.toStringAsFixed(1)}% du Social • ${pasPctOfGross.toStringAsFixed(1)}% Brut',
                AppColors.accentRose,
              ),
              if (hasTaxAdj && totalRealTaxDgfip > 0)
                _buildTableRow(
                  'Impôt Réel DGFiP (Selon Avis d\'Imposition)',
                  '${totalRealTaxDgfip.toStringAsFixed(2)} €',
                  totalNetSocial > 0 ? '${(totalRealTaxDgfip / totalNetSocial * 100).toStringAsFixed(1)}% du Social' : '0.0%',
                  AppColors.accentRose,
                ),
              if (hasTaxAdj && (totalRealTaxDgfip - totalPAS).abs() > 1.0)
                _buildTableRow(
                  'Solde / Régularisation DGFiP (Écart à payer)',
                  '${(totalRealTaxDgfip - totalPAS) > 0 ? "+" : ""}${(totalRealTaxDgfip - totalPAS).toStringAsFixed(2)} €',
                  (totalRealTaxDgfip - totalPAS) > 0 ? 'Rattrapage DGFiP' : 'Remboursement DGFiP',
                  (totalRealTaxDgfip - totalPAS) > 0 ? AppColors.accentRose : AppColors.accentEmerald,
                ),
              _buildTableRow(
                'Salaire Net de Base Récurrent',
                '${totalBaseNet.toStringAsFixed(2)} €',
                '${basePctOfNet.toStringAsFixed(1)}% du Net Versé',
                AppColors.accentEmerald,
              ),
              _buildTableRow(
                'Primes & Variable Explicites',
                '${totalPrimes.toStringAsFixed(2)} €',
                '${primePctOfNet.toStringAsFixed(1)}% du Net Versé',
                AppColors.accentGold,
              ),
              if (totalPEE > 0)
                _buildTableRow(
                  'Épargne Salariale PEE (Intéressement)',
                  '${totalPEE.toStringAsFixed(2)} €',
                  '${(totalPEE / totalGlobalComp * 100).toStringAsFixed(1)}% Global',
                  AppColors.accentCyan,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearChip(int? year, String label) {
    final isSelected = _selectedYear == year;
    return InkWell(
      onTap: () => setState(() => _selectedYear = year),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String title, String value, String percentage, Color valueColor) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            percentage,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
