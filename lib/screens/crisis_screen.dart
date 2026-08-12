import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/notification_header.dart';

class CrisisScreen extends ConsumerStatefulWidget {
  const CrisisScreen({super.key});

  @override
  ConsumerState<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends ConsumerState<CrisisScreen> {
  int _activeSubTab = 0; // 0 = Accident de la vie, 1 = Financement CLIC

  // Tab 0 State: Accident de la vie
  double _emergencyExpense = 0;
  double _cashPayment = 0;
  int _creditMonths = 12;

  // Tab 1 State: Financement CLIC
  double _clicTotalCost = 2900;
  double _clicInitialCash = 500;
  double _clicTaeg = 5.9;
  double _clicDurationMonths = 12;
  int _selectedOptionIndex = 0; // 0 = Fractionné sans frais, 1 = Crédit Personnel

  bool _isFinanceDetailsExpanded = true;
  bool _isOptimizerExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Simulateurs'),
      body: Column(
        children: [
          // Top Sub-Tabs Navigation Bar (Matching Screenshots 2 & 3)
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSubTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeSubTab == 0 ? AppColors.accentCyan : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ac_unit_rounded, color: _activeSubTab == 0 ? AppColors.accentCyan : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Accident de la vie',
                            style: TextStyle(
                              color: _activeSubTab == 0 ? AppColors.accentCyan : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSubTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeSubTab == 1 ? AppColors.accentCyan : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: _activeSubTab == 1 ? AppColors.accentCyan : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Financement CLIC',
                            style: TextStyle(
                              color: _activeSubTab == 1 ? AppColors.accentCyan : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Tab Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _activeSubTab == 0 ? _buildAccidentTabContent() : _buildClicTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB TAB 0: ACCIDENT DE LA VIE (Matching Screenshot 2) ---
  Widget _buildAccidentTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONFIGURER L\'URGENCE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),

        // Urgency Input Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildUrgencyInputRow(
                icon: Icons.ac_unit_rounded,
                iconColor: AppColors.accentRose,
                title: 'Dépense totale',
                amount: _emergencyExpense,
                unit: '€',
                onTap: () => _showEditValueDialog('Dépense totale', _emergencyExpense, (v) => setState(() => _emergencyExpense = v)),
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 14),

              _buildUrgencyInputRow(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.accentGold,
                title: 'Paiement comptant',
                amount: _cashPayment,
                unit: '€',
                onTap: () => _showEditValueDialog('Paiement comptant', _cashPayment, (v) => setState(() => _cashPayment = v)),
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 14),

              _buildUrgencyInputRow(
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.accentCyan,
                title: 'Durée du crédit',
                amount: _creditMonths.toDouble(),
                unit: 'mois',
                onTap: () => _showEditValueDialog('Durée du crédit', _creditMonths.toDouble(), (v) => setState(() => _creditMonths = v.toInt())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Big Red Action Button (Matching Screenshot 2)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Crise financière simulée ! Vos réserves sont recalculées.'),
                  backgroundColor: AppColors.accentRose,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Déclencher la crise financière',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyInputRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
    required String unit,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              '${amount.toStringAsFixed(0)} $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SUB TAB 1: FINANCEMENT CLIC (Matching Screenshots 3, 4, 5, 6) ---
  Widget _buildClicTabContent() {
    final netIncome = 2861.26;
    final remainingCost = (_clicTotalCost - _clicInitialCash).clamp(0, 500000);
    final incomePercent = netIncome > 0 ? (remainingCost / netIncome) * 100 : 0.0;

    final noFeeMonthly = _clicDurationMonths > 0 ? remainingCost / _clicDurationMonths : 0.0;

    // Credit math approximation
    final monthlyRate = (_clicTaeg / 100) / 12;
    final creditMonthly = monthlyRate > 0
        ? (remainingCost * monthlyRate) / (1 - (1 / ((1 + monthlyRate))))
        : noFeeMonthly;
    final creditTotalInterest = (creditMonthly * _clicDurationMonths) - remainingCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparateur de Modes de Financement',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Comparez les modes de financement et optimisez automatiquement vos allocations budgétaires.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Card 1: Dépense à optimiser (Matching Screenshot 3)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dépense à optimiser', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildLabeledInputField('Coût total de la dépense', _clicTotalCost, '€', (v) => setState(() => _clicTotalCost = v)),
              const SizedBox(height: 14),

              _buildLabeledInputField('Paiement comptant initial', _clicInitialCash, '€', (v) => setState(() => _clicInitialCash = v)),
              const SizedBox(height: 14),

              _buildLabeledInputField('Taux d\'intérêt annuel (TAEG)', _clicTaeg, '%', (v) => setState(() => _clicTaeg = v)),
              const SizedBox(height: 16),

              Text('Durée de remboursement globale : ${_clicDurationMonths.toStringAsFixed(0)} mois', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Slider(
                value: _clicDurationMonths,
                min: 3,
                max: 36,
                divisions: 11,
                activeColor: AppColors.accentCyan,
                onChanged: (val) => setState(() => _clicDurationMonths = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Impact Badges Bar (Matching Screenshot 3)
        Row(
          children: [
            _buildBadge('💼 ${incomePercent.toStringAsFixed(1)}% du revenu', AppColors.accentGold),
            const SizedBox(width: 8),
            _buildBadge('👝 Épargne : 1600 €', AppColors.accentRose),
            const SizedBox(width: 8),
            _buildBadge('👛 Pockets : 200 €', AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: 20),

        // Card 2: CONSEIL D'ANALYSE (Matching Screenshot 3 & 4)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF221A16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('CONSEIL D\'ANALYSE', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.accentGold, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Évitez le comptant — fractionnez ou crédit',
                      style: TextStyle(color: AppColors.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Payer cash épuiserait une part critique de votre épargne de sécurité. Un étalement sur plusieurs mois préserve votre filet de précaution.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text('‣ ${remainingCost.toStringAsFixed(0)} € = ${incomePercent.toStringAsFixed(1)}% de votre revenu mensuel.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('‣ Payer comptant consommerait +50% de votre épargne totale (1600 €).', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('‣ Le fractionné sans frais reste prioritaire si disponible (0 € d\'intérêts).', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card 3: Détails des options de financement Accordion (Matching Screenshot 4 & 5)
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              ListTile(
                onTap: () => setState(() => _isFinanceDetailsExpanded = !_isFinanceDetailsExpanded),
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.accentCyan),
                title: const Text('Détails des options de financement', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: Icon(_isFinanceDetailsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              ),

              if (_isFinanceDetailsExpanded) ...[
                const Divider(color: AppColors.borderSubtle, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Option A: Paiement Comptant
                      _buildOptionCard(
                        title: 'Paiement Comptant',
                        badgeText: null,
                        badgeColor: Colors.transparent,
                        warningText: 'Déconseillé : Payer comptant entame dangereusement votre réserve de précaution.',
                        lines: [
                          _buildLine('Débit immédiat', '${_clicTotalCost.toStringAsFixed(0)} €'),
                          _buildLine('Coût d\'intérêts', '0 €'),
                          _buildLine('Épargne totale restante', '0 €'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Option B: Fractionné sans frais
                      _buildOptionCard(
                        title: 'Fractionné sans frais',
                        badgeText: '0% INTÉRÊTS',
                        badgeColor: AppColors.accentEmerald,
                        subtitleText: 'Lissage parfait : Répartit la charge financière sur votre reste à vivre mensuel sans surcoût d\'intérêts.',
                        lines: [
                          _buildLine('Mensualité', '${noFeeMonthly.toStringAsFixed(2)} € / mois', valueColor: AppColors.accentEmerald),
                          _buildLine('Durée d\'étalement', '${_clicDurationMonths.toStringAsFixed(0)} mois'),
                          _buildLine('Intérêts totaux', '0 €'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Option C: Crédit Personnel
                      _buildOptionCard(
                        title: 'Crédit Personnel',
                        badgeText: 'TAEG ${_clicTaeg.toStringAsFixed(1)}%',
                        badgeColor: AppColors.accentCyan,
                        subtitleText: 'Simulateur d\'emprunt amortissable classique. Génère des frais d\'intérêts sur la durée de remboursement sélectionnée.',
                        lines: [
                          _buildLine('Mensualité', '${creditMonthly.toStringAsFixed(2)} € / mois', valueColor: AppColors.accentCyan),
                          _buildLine('Durée d\'étalement', '${_clicDurationMonths.toStringAsFixed(0)} mois'),
                          _buildLine('Intérêts totaux', '${creditTotalInterest.toStringAsFixed(2)} €', valueColor: AppColors.accentGold),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card 4: Optimiseur d'Impact Budgétaire Accordion (Matching Screenshot 5 & 6)
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              ListTile(
                onTap: () => setState(() => _isOptimizerExpanded = !_isOptimizerExpanded),
                leading: const Icon(Icons.tune_rounded, color: AppColors.accentCyan),
                title: const Text('Optimiseur d\'Impact Budgétaire', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: Icon(_isOptimizerExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              ),

              if (_isOptimizerExpanded) ...[
                const Divider(color: AppColors.borderSubtle, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sélectionnez l\'option de financement à répercuter sur vos enveloppes d\'épargne et d\'investissement :',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),

                      // Button Option 0
                      GestureDetector(
                        onTap: () => setState(() => _selectedOptionIndex = 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedOptionIndex == 0 ? AppColors.accentCyan : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedOptionIndex == 0 ? AppColors.accentCyan : AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(_selectedOptionIndex == 0 ? Icons.check_rounded : Icons.circle_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Fractionné sans frais (${noFeeMonthly.toStringAsFixed(0)} € / mois)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Button Option 1
                      GestureDetector(
                        onTap: () => setState(() => _selectedOptionIndex = 1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedOptionIndex == 1 ? AppColors.accentCyan : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedOptionIndex == 1 ? AppColors.accentCyan : AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(_selectedOptionIndex == 1 ? Icons.check_rounded : Icons.circle_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Crédit Personnel (${creditMonthly.toStringAsFixed(0)} € / mois)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'RÉORGANISATION RECOMMANDÉE DE VOS MENSUALITÉS D\'ÉPARGNE',
                        style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Livret A', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          Text(
                            '- ${_selectedOptionIndex == 0 ? noFeeMonthly.toStringAsFixed(0) : creditMonthly.toStringAsFixed(0)} €   (0 €)',
                            style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Main Action Button (Matching Screenshot 6)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Appliquer à mon budget mensuel', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔄 Plan de financement appliqué à votre budget mensuel avec succès !'),
                                backgroundColor: AppColors.accentEmerald,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLabeledInputField(String label, double value, String unit, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(unit, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String? badgeText,
    required Color badgeColor,
    String? warningText,
    String? subtitleText,
    required List<Widget> lines,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines,
          if (subtitleText != null) ...[
            const SizedBox(height: 12),
            Text(subtitleText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
          ],
          if (warningText != null) ...[
            const SizedBox(height: 12),
            Text(warningText, style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showEditValueDialog(String title, double currentVal, Function(double) onSave) {
    final ctrl = TextEditingController(text: currentVal.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Modifier $title', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan),
              onPressed: () {
                final val = double.tryParse(ctrl.text.trim()) ?? currentVal;
                onSave(val);
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
