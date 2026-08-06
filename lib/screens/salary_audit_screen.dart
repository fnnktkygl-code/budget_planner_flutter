import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../models/salary_record.dart';
import '../services/salary_analyzer_service.dart';

class SalaryAuditScreen extends ConsumerStatefulWidget {
  const SalaryAuditScreen({super.key});

  @override
  ConsumerState<SalaryAuditScreen> createState() => _SalaryAuditScreenState();
}

class _SalaryAuditScreenState extends ConsumerState<SalaryAuditScreen> {
  int _activeTab = 0; // 0 = Historique & Cartes, 1 = Synthèse par Année (2025-2026)
  String _selectedYearFilter = 'Tous'; // 'Tous', '2026', '2025'

  void _showAddEditBottomSheet(BuildContext context, {SalaryRecord? existingRecord}) {
    final salaryState = ref.read(salaryProvider);
    final active = salaryState.activeBaseline;

    final periodController = TextEditingController(
      text: existingRecord?.period ?? (active != null ? _suggestNextPeriod(active.period) : '2026-07'),
    );
    final netController = TextEditingController(
      text: existingRecord != null ? existingRecord.netSalary.toStringAsFixed(0) : '3850',
    );
    final grossController = TextEditingController(
      text: existingRecord?.grossSalary != null ? existingRecord!.grossSalary!.toStringAsFixed(0) : '4950',
    );
    final investableController = TextEditingController(
      text: existingRecord != null ? existingRecord.investableAmount.toStringAsFixed(0) : '1200',
    );
    final docController = TextEditingController(
      text: existingRecord?.documentName ?? (existingRecord != null ? '' : 'bulletin_paye_${periodController.text.replaceAll('-', '_')}.pdf'),
    );
    final notesController = TextEditingController(
      text: existingRecord?.notes ?? '',
    );

    bool setAsActiveRef = existingRecord?.isLatestActive ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingRecord != null ? '✏️ Modifier le bulletin' : '📥 Importer un bulletin de salaire',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentCyan, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Document PDF importé', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('Reconnaissance OCR & extraction des données', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: periodController,
                      decoration: const InputDecoration(labelText: 'Période (AAAA-MM)', hintText: 'ex: 2026-06', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: netController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Salaire Net (€)', border: OutlineInputBorder()),
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: investableController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Budget Épargne (€)', border: OutlineInputBorder()),
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: grossController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Salaire Brut (Optionnel €)', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: docController,
                      decoration: const InputDecoration(labelText: 'Nom du document', hintText: 'bulletin_2026_06.pdf', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes ou observations', hintText: 'Prime annuelle, augmentation, etc.', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Définir comme bulletin référent actif', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Utilise ce salaire net comme base exclusive pour la répartition budgétaire.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      value: setAsActiveRef,
                      activeThumbColor: AppColors.accentCyan,
                      onChanged: (val) {
                        setModalState(() {
                          setAsActiveRef = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(existingRecord != null ? 'Mettre à jour le bulletin' : 'Valider & Enregistrer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () {
                          final net = double.tryParse(netController.text) ?? 3850;
                          final gross = double.tryParse(grossController.text);
                          final invest = double.tryParse(investableController.text) ?? 1200;
                          final period = periodController.text.trim();
                          final savingsRate = net > 0 ? (invest / net) * 100 : 0.0;
                          final periodLabel = formatPeriodLabel(period);

                          final record = SalaryRecord(
                            id: existingRecord?.id ?? 'sal-${DateTime.now().millisecondsSinceEpoch}',
                            period: period,
                            periodLabel: periodLabel,
                            netSalary: net,
                            grossSalary: gross,
                            investableAmount: invest,
                            savingsRate: savingsRate,
                            status: '✓ Importé & Validé',
                            documentName: docController.text.trim().isNotEmpty ? docController.text.trim() : 'bulletin_$period.pdf',
                            isLatestActive: setAsActiveRef,
                            updatedAt: DateTime.now(),
                            notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                          );

                          if (existingRecord != null) {
                            ref.read(salaryProvider.notifier).updateRecord(record);
                          } else {
                            ref.read(salaryProvider.notifier).addRecord(record);
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bulletin de salaire $periodLabel enregistré avec succès !'), backgroundColor: AppColors.accentCyan, behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _suggestNextPeriod(String currentPeriod) {
    if (!currentPeriod.contains('-')) return '2026-07';
    final parts = currentPeriod.split('-');
    int year = int.tryParse(parts[0]) ?? 2026;
    int month = int.tryParse(parts[1]) ?? 6;
    month += 1;
    if (month > 12) {
      month = 1;
      year += 1;
    }
    final mStr = month < 10 ? '0$month' : '$month';
    return '$year-$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryProvider);
    final analytics = salaryState.analytics;
    final activeRecord = salaryState.activeBaseline;

    List<SalaryRecord> displayedRecords = sortSalaryRecordsDescending(salaryState.records);
    if (_selectedYearFilter != 'Tous') {
      displayedRecords = displayedRecords.where((r) => r.period.startsWith(_selectedYearFilter)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Audit Bulletins de Salaire', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('AuraBudget Pro — Lissage & Répartition', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.accentCyan),
            tooltip: 'Explication du calcul',
            onPressed: () => _showLogicExplanationDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter un bulletin', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditBottomSheet(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleExplanationBanner(context),
            const SizedBox(height: 16),
            _buildKpiGrid(analytics, activeRecord),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 16),

            if (_activeTab == 0) ...[
              _buildYearFilterChips(salaryState.records),
              const SizedBox(height: 14),
              if (displayedRecords.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final record = displayedRecords[idx];
                    final isBaseline = activeRecord?.id == record.id;
                    return _buildSalaryRecordCard(ctx, record, isBaseline);
                  },
                ),
            ] else ...[
              _buildYearlySummarySection(analytics),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleExplanationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.verified_user_rounded, color: AppColors.accentCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Répartition Budgétaire vs. Lissage Salarial', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 3),
                Text(
                  '• La Répartition (charges, épargne) est basée exclusivement sur le dernier bulletin référent.\n'
                  '• Le Lissage Salarial calcule la moyenne 2025-2026 à titre indicatif et n\'impacte pas votre budget actif.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(SalaryAnalytics analytics, SalaryRecord? activeRecord) {
    final activeNet = activeRecord?.netSalary ?? 0.0;
    final avgNet = analytics.overallAverageNet;
    final growth = analytics.growthTrendPercent;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'BASE RÉPARTITION',
                value: '${activeNet.toStringAsFixed(0)} €',
                subtitle: activeRecord != null ? 'Ref: ${activeRecord.periodLabel}' : 'Aucun bulletin',
                badgeText: '⭐ Actif',
                badgeColor: AppColors.accentCyan,
                icon: Icons.account_balance_wallet_rounded,
                isHighlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'MOYENNE LISSÉE',
                value: '${avgNet.toStringAsFixed(0)} € / m',
                subtitle: 'Sur ${analytics.totalRecordsCount} bulletins',
                badgeText: '📊 Indicatif',
                badgeColor: Colors.blueAccent,
                icon: Icons.stacked_line_chart_rounded,
                isHighlight: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKpiCard(
          title: 'TENDANCE DE CROISSANCE SALARIALE (2025 - 2026)',
          value: '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)} %',
          subtitle: 'Évolution du salaire net entre le 1er bulletin et le plus récent',
          badgeText: growth >= 0 ? '+ En hausse' : '📉 Ajusté',
          badgeColor: growth >= 0 ? AppColors.accentEmerald : Colors.orangeAccent,
          icon: Icons.trending_up_rounded,
          isHighlight: false,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required bool isHighlight,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.cardBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? AppColors.accentCyan.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: badgeColor, size: 18),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: isFullWidth ? 22 : 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _activeTab == 0 ? AppColors.accentCyan : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('📄 Bulletins & Historique', style: TextStyle(color: _activeTab == 0 ? AppColors.background : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _activeTab == 1 ? AppColors.accentCyan : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('📊 Synthèse Annuelle (2025-2026)', style: TextStyle(color: _activeTab == 1 ? AppColors.background : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilterChips(List<SalaryRecord> records) {
    final rawYears = records.map((r) => r.period.split('-')[0]).toSet();
    final years = ['Tous', ...rawYears];

    return Row(
      children: years.map((year) {
        final isSelected = _selectedYearFilter == year;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(year),
            selected: isSelected,
            selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(color: isSelected ? AppColors.accentCyan : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            side: BorderSide(color: isSelected ? AppColors.accentCyan : Colors.transparent),
            onSelected: (_) => setState(() => _selectedYearFilter = year),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSalaryRecordCard(BuildContext context, SalaryRecord record, bool isBaseline) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBaseline ? AppColors.accentCyan : AppColors.borderSubtle, width: isBaseline ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isBaseline ? AppColors.accentCyan.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded, color: AppColors.accentCyan, size: 20),
                    const SizedBox(width: 8),
                    Text(record.periodLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    if (isBaseline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accentCyan, borderRadius: BorderRadius.circular(8)),
                        child: const Text('⭐ Référent Actif', style: TextStyle(color: AppColors.background, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentEmerald.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4))),
                      child: Text(record.status, style: const TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SALAIRE NET À PAYER', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${record.netSalary.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('BUDGET ÉPARGNE ALLOUÉ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${record.investableAmount.toStringAsFixed(0)} € (${record.savingsRate.toStringAsFixed(1)}%)', style: const TextStyle(color: AppColors.accentCyan, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                if (record.grossSalary != null || record.documentName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (record.grossSalary != null)
                        Text('Brut : ${record.grossSalary!.toStringAsFixed(0)} €  •  ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      if (record.documentName != null)
                        Expanded(
                          child: Text('📄 ${record.documentName}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, overflow: TextOverflow.ellipsis)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isBaseline)
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.accentCyan),
                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                        label: const Text('Définir comme référent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          ref.read(salaryProvider.notifier).setActiveBaseline(record.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Le bulletin ${record.periodLabel} est désormais la base référente de répartition.'), backgroundColor: AppColors.accentCyan, behavior: SnackBarBehavior.floating),
                          );
                        },
                      )
                    else
                      const Text('✓ Base de répartition active', style: TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _showAddEditBottomSheet(context, existingRecord: record),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                          onPressed: () => _confirmDelete(context, record),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySummarySection(SalaryAnalytics analytics) {
    if (analytics.yearlySummaries.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible', style: TextStyle(color: AppColors.textSecondary)));
    }

    return Column(
      children: analytics.yearlySummaries.map((y) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Année ${y.year}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('${y.count} bulletins', style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Salaire Net Moyen', '${y.averageNet.toStringAsFixed(0)} € / m'),
                  _buildSummaryItem('Cumul Net Annuel', '${y.totalNet.toStringAsFixed(0)} €'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Épargne Moyenne', '${y.averageInvestable.toStringAsFixed(0)} € / m'),
                  _buildSummaryItem('Taux d\'Épargne Moyen', '${y.averageSavingsRate.toStringAsFixed(1)} %'),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          Icon(Icons.folder_open_rounded, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text('Aucun bulletin trouvé pour cette période', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SalaryRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer le bulletin', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Voulez-vous vraiment supprimer le bulletin de ${record.periodLabel} ?', style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            onPressed: () {
              ref.read(salaryProvider.notifier).deleteRecord(record.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showLogicExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('💡 Principes de Calcul Salarial', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('1. Base de Répartition Budgétaire (Active)', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text('Votre répartition budgétaire mensuelle se base STRICTEMENT sur votre dernier salaire net référent. L\'ajout de fiches de paie antérieures n\'altère pas votre répartition mensuelle actuelle.', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
              SizedBox(height: 14),
              Text('2. Lissage Salarial & Analyse (2025-2026)', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text('La moyenne lissée sert uniquement à l\'analyse patrimoniale à moyen terme pour lisser l\'impact des primes ou variations saisonnières.', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: AppColors.background),
            child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}
