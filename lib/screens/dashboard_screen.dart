import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/auth_provider.dart';
import '../models/salary_record.dart';
import '../widgets/donut_chart.dart';
import '../widgets/notification_header.dart';
import '../widgets/banking_modal.dart';
import 'allocation_recommendation_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? "Utilisateur";
    
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

    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Tableau de bord'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Interactive Payslip Selector Dropdown Banner
            InkWell(
              onTap: () => _showPayslipSelectorDialog(context, salaryState.records, activeBaseline),
              borderRadius: BorderRadius.circular(14),
              child: Container(
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
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${activeBaseline?.employerName ?? "Entreprise Exemple"} | Salarié : ${(activeBaseline?.employeeName == null || activeBaseline?.employeeName == "John Doe") ? userName : activeBaseline!.employeeName} (${activeBaseline?.periodLabel ?? "Juillet 2026"})',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentCyan, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.swap_horiz_rounded, color: AppColors.accentEmerald, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Changer de Bulletin',
                            style: TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live TrueLayer Open Banking Balance Card
            _buildLiveBankBalanceCard(salaryState, settingsState),
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
                      Expanded(child: _buildAllocationCard(segments, netSalary, activeBaseline, salaryState.accountBalance)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNetIncomeCard(activeBaseline, grossSalary, netSalary, socialContrib, mealTickets, telework, nonTaxable)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAllocationCard(segments, netSalary, activeBaseline, salaryState.accountBalance),
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

  Widget _buildLiveBankBalanceCard(SalaryState salaryState, SettingsState settingsState) {
    final isConnected = settingsState.bankConnected || settingsState.truelayerAccessToken.isNotEmpty;
    final bankName = settingsState.connectedBankName.isNotEmpty
        ? settingsState.connectedBankName
        : (salaryState.syncBankName ?? 'BoursoBank');
    final lastSyncStr = salaryState.lastBankSync != null
        ? DateFormat('dd/MM à HH:mm').format(salaryState.lastBankSync!)
        : (settingsState.lastSyncTimestamp != null
            ? DateFormat('dd/MM à HH:mm').format(settingsState.lastSyncTimestamp!)
            : 'En direct');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected
              ? AppColors.accentEmerald.withValues(alpha: 0.35)
              : AppColors.accentCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isConnected ? AppColors.accentEmerald : AppColors.accentCyan).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: isConnected ? AppColors.accentEmerald : AppColors.accentCyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Solde Compte Courant',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isConnected ? AppColors.accentEmerald : AppColors.accentGold).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isConnected ? 'TrueLayer Live' : 'Non Connecté',
                        style: TextStyle(
                          color: isConnected ? AppColors.accentEmerald : AppColors.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${salaryState.accountBalance.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: salaryState.accountBalance >= 0 ? AppColors.textPrimary : AppColors.danger,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$bankName • Synchro : $lastSyncStr',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (settingsState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentCyan),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: AppColors.accentCyan, size: 22),
              tooltip: 'Rafraîchir le solde en direct',
              onPressed: () async {
                final success = await ref.read(settingsProvider.notifier).syncTrueLayerData(ref);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Solde mis à jour avec succès depuis votre banque !'
                            : 'Synchronisation bancaire effectuée.',
                      ),
                      backgroundColor: success ? AppColors.accentEmerald : AppColors.accentCyan,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
              tooltip: 'Gérer les banques',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BankingModalContent(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationCard(List<AllocationSegment> segments, double netSalary, SalaryRecord? activeBaseline, double currentBalance) {
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
                  Tooltip(
                    message: 'En savoir plus sur l\'Allocation d\'actifs',
                    decoration: BoxDecoration(
                      color: const Color(0xFF151D2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: AppColors.accentCyan, size: 18),
                      onPressed: () {
                        _showExplanationModal(
                          context,
                          title: '📊 Allocation d\'Actifs & Répartition',
                          content: 'Cette roue présente la ventilation stratégique de votre salaire net en banque selon vos règles budgétaires configurées (Charges fixes, Cible d\'investissement PEA, Épargne liquide Livret A et Reste à vivre).\n\nVous pouvez cliquer sur chaque segment ou élément de légende pour afficher la décomposition exacte des sous-postes.',
                        );
                      },
                    ),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (activeBaseline != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllocationRecommendationScreen(
                        salaryRecord: activeBaseline,
                        currentBalance: currentBalance, // Solde dynamique TrueLayer
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.insights, size: 18),
              label: const Text('Voir la Recommandation Proactive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentEmerald,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
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

  void _showPayslipSelectorDialog(BuildContext context, List<SalaryRecord> records, SalaryRecord? activeBaseline) {
    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredRecords = records.where((r) {
              final q = searchQuery.toLowerCase();
              return r.periodLabel.toLowerCase().contains(q) ||
                     r.employerName.toLowerCase().contains(q) ||
                     r.employeeName.toLowerCase().contains(q) ||
                     r.period.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.description_rounded, color: AppColors.accentCyan, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Sélectionner un Bulletin',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar Field
                    TextField(
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un mois, année (ex: 2026, Juillet)...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentCyan, size: 20),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentCyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: records.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                'Aucun bulletin enregistré. Importez votre premier bulletin depuis l\'onglet Bulletins & Salaires !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredRecords.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final record = filteredRecords[index];
                                final isActive = record.id == activeBaseline?.id || record.isLatestActive;

                                return InkWell(
                                  onTap: () {
                                    ref.read(salaryProvider.notifier).setActiveBaseline(record.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('⚡ Bulletin actif basculé sur : ${record.periodLabel} (${record.netSalary.toStringAsFixed(2)} € Net)'),
                                        backgroundColor: AppColors.accentEmerald,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.accentCyan.withValues(alpha: 0.15) : AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive ? AppColors.accentCyan : AppColors.borderSubtle,
                                        width: isActive ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive ? Icons.check_circle_rounded : Icons.insert_drive_file_outlined,
                                          color: isActive ? AppColors.accentCyan : AppColors.textMuted,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    record.periodLabel,
                                                    style: TextStyle(
                                                      color: isActive ? AppColors.accentCyan : AppColors.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (record.hasExplicitBonus) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.accentGold.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text('⚡ Bonus', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${record.employerName} • ${record.employeeName}',
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${record.netSalary.toStringAsFixed(2)} €',
                                              style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (isActive)
                                              const Text('ACTIF', style: TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
    final rttBuyback = activeRecord?.rttBuybackAmount ?? 0.0;
    final regularNet = activeRecord?.regularNetSalary ?? netSalary;
    final purchasingPower = activeRecord?.purchasingPower ?? netSalary;

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
                  Tooltip(
                    message: 'Détails du Revenu Net Mensuel',
                    decoration: BoxDecoration(
                      color: const Color(0xFF151D2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.5)),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: AppColors.accentEmerald, size: 18),
                      onPressed: () {
                        _showExplanationModal(
                          context,
                          title: '🧾 Décomposition du Revenu Net Mensuel',
                          content: 'Cette carte restitue l\'analyse financière exacte extraite de votre bulletin de salaire actif (${activeRecord?.periodLabel ?? "Juillet 2026"}) par l\'IA Gemini.\n\nElle présente le passage rigoureux du Salaire Brut aux cotisations sociales, au Net Social (Net avant impôt) puis au Prélèvement à la source (Impôt IR) jusqu\'au montant net final crédité sur votre compte bancaire.',
                        );
                      },
                    ),
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
          
          if (telework != 0.0 || nonTaxable != 0.0 || (activeRecord?.expenseReimbursement ?? 0.0) != 0.0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('Indemnités & Frais (Télétravail, Non-imposable, etc.)', '+ ${(telework + nonTaxable + (activeRecord?.expenseReimbursement ?? 0.0)).toStringAsFixed(2)} €', isPositive: true),
          ],
          
          if (hasBonus || bonusAmt > 0 || rttBuyback > 0) ...[
            const SizedBox(height: 14),
            _buildSalaryLine('Primes & Extra (Bonus, Rachat RTT)', '+ ${(bonusAmt + rttBuyback).toStringAsFixed(2)} €', isPositive: true),
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
                  if (activeRecord?.isExtraOrBonusMonth == true)
                    Text(
                      'Net Récurrent : ${regularNet.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 11),
                    ),
                  if ((activeRecord?.mealTicketsEmployer ?? 0.0) > 0)
                    Text(
                      'Pouvoir d\'achat : ${purchasingPower.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 11),
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
