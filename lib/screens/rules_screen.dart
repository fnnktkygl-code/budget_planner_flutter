import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../models/temporary_expense.dart';
import '../widgets/notification_header.dart';

class RuleCategoryItem {
  final String id;
  String name;
  double amount;
  bool isPercentage;
  bool isLocked;
  final String iconType;
  final Color iconBgColor;

  RuleCategoryItem({
    required this.id,
    required this.name,
    required this.amount,
    this.isPercentage = false,
    this.isLocked = true,
    required this.iconType,
    required this.iconBgColor,
  });

  double getEffectiveAmount(double netSalary) {
    if (isPercentage) {
      return (netSalary * amount / 100);
    }
    return amount;
  }

  double getEffectivePercent(double netSalary) {
    if (isPercentage) return amount;
    if (netSalary <= 0) return 0.0;
    return (amount / netSalary) * 100;
  }
}

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  final List<RuleCategoryItem> _savingsCategories = [
    RuleCategoryItem(id: 'sav-1', name: 'Cible PEA', amount: 35.0, isPercentage: true, iconType: 'chart', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'sav-2', name: 'Livret A', amount: 7.0, isPercentage: true, iconType: 'shield', iconBgColor: AppColors.accentGold),
  ];

  final List<RuleCategoryItem> _fixedChargesCategories = [
    RuleCategoryItem(id: 'fix-1', name: 'Loyer', amount: 677, isPercentage: false, iconType: 'home', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-2', name: 'Abonnement', amount: 41, isPercentage: false, iconType: 'video', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-3', name: 'Tontine', amount: 300, isPercentage: false, iconType: 'people', iconBgColor: AppColors.accentPurple),
    RuleCategoryItem(id: 'fix-4', name: 'Soutien', amount: 231, isPercentage: false, iconType: 'heart', iconBgColor: AppColors.accentRose),
  ];

  final List<RuleCategoryItem> _dailyCategories = [
    RuleCategoryItem(id: 'day-1', name: 'Revolut (Reste à vivre)', amount: 7.0, isPercentage: true, iconType: 'card', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'day-2', name: 'Tampon / Marge €', amount: 0, isPercentage: false, iconType: 'basket', iconBgColor: AppColors.accentEmerald),
  ];

  Widget _buildGaugeLegend(String label, double amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${amount.toStringAsFixed(0)}€',
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(List<RuleCategoryItem> targetList, String defaultGroup, Color color) {
    final titleController = TextEditingController();
    final amountController = TextEditingController(text: '10');
    bool isPercentage = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.accentCyan),
                  SizedBox(width: 10),
                  Text('Nouvelle Catégorie', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                      hintText: 'ex: Assurance, Transports',
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mode Selector: Nominal € vs Percentage %
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isPercentage = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isPercentage ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Montant (€)',
                                style: TextStyle(
                                  color: !isPercentage ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isPercentage = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isPercentage ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pourcentage (%)',
                                style: TextStyle(
                                  color: isPercentage ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isPercentage ? 'Pourcentage du salaire (%)' : 'Montant mensuel (€)',
                      suffixText: isPercentage ? '%' : '€',
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim().isEmpty ? 'Nouvelle Catégorie' : titleController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 10.0;
                    setState(() {
                      targetList.add(
                        RuleCategoryItem(
                          id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
                          name: title,
                          amount: amount,
                          isPercentage: isPercentage,
                          iconType: 'default',
                          iconBgColor: color,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAmountDialog(RuleCategoryItem item, double netSalary) {
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(item.isPercentage ? 1 : 0));
    bool isPercentage = item.isPercentage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.edit_note_rounded, color: AppColors.accentCyan),
                  SizedBox(width: 10),
                  Text('Modifier la catégorie', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                    ),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mode Selector: Nominal € vs Percentage %
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isPercentage = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isPercentage ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Montant (€)',
                                style: TextStyle(
                                  color: !isPercentage ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isPercentage = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isPercentage ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pourcentage (%)',
                                style: TextStyle(
                                  color: isPercentage ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: amountController,
                    builder: (context, val, _) {
                      final inputNum = double.tryParse(val.text.trim()) ?? 0.0;
                      final calcVal = isPercentage
                          ? (netSalary * inputNum / 100)
                          : (netSalary > 0 ? (inputNum / netSalary * 100) : 0.0);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isPercentage ? 'Pourcentage (%)' : 'Montant mensuel (€)',
                              suffixText: isPercentage ? '%' : '€',
                            ),
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Équivalence exacte :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                Text(
                                  isPercentage
                                      ? '= ${calcVal.toStringAsFixed(2)} € / mois'
                                      : '= ${calcVal.toStringAsFixed(1)} % du salaire net',
                                  style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final newName = nameController.text.trim().isEmpty ? item.name : nameController.text.trim();
                    final newAmount = double.tryParse(amountController.text.trim()) ?? item.amount;
                    setState(() {
                      item.name = newName;
                      item.amount = newAmount;
                      item.isPercentage = isPercentage;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(RuleCategoryItem item, List<RuleCategoryItem> targetList) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 22),
              SizedBox(width: 8),
              Text('Supprimer la règle', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer "${item.name}" ?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  targetList.removeWhere((i) => i.id == item.id);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTemporaryExpense(TemporaryExpense exp) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 22),
              SizedBox(width: 8),
              Text('Supprimer l\'échéancier', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment supprimer l\'échéancier "${exp.label}" (-${exp.monthlyAmount.toStringAsFixed(2)} €/mois) ?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ref.read(salaryProvider.notifier).deleteTemporaryExpense(exp.id);
                Navigator.pop(ctx);
              },
              child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTemporaryExpenseDialog(BuildContext context) {
    final now = DateTime.now();
    final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
    final currentPeriodStr = '${now.year}-$mStr';

    final labelCtrl = TextEditingController(text: 'Dentiste Couronne');
    final amountCtrl = TextEditingController(text: '164.50');
    final startCtrl = TextEditingController(text: currentPeriodStr);
    final durationCtrl = TextEditingController(text: '12');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final amt = double.tryParse(amountCtrl.text) ?? 0.0;
            final dur = int.tryParse(durationCtrl.text) ?? 12;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.calendar_month_rounded, color: AppColors.accentCyan, size: 22),
                  SizedBox(width: 10),
                  Text('Dépense Échéancée / Temporaire', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajoutez une dépense à durée limitée (ex: soins dentaires 164€/mois sur 12 mois, achat informatique en N fois).',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Intitulé', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(labelText: 'Montant Mensuel (€)', border: OutlineInputBorder(), suffixText: '€'),
                            style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(labelText: 'Durée (Mois)', border: OutlineInputBorder()),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Mois Début (AAAA-MM)', border: OutlineInputBorder()),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Échéancier :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('${(amt * dur).toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: Colors.white),
                  child: const Text('Ajouter l\'échéancier'),
                  onPressed: () {
                    final exp = TemporaryExpense(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: labelCtrl.text.isEmpty ? 'Dépense temporaire' : labelCtrl.text,
                      monthlyAmount: double.tryParse(amountCtrl.text) ?? 0.0,
                      startPeriod: startCtrl.text.isEmpty ? '2026-06' : startCtrl.text,
                      durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                    );
                    ref.read(salaryProvider.notifier).addTemporaryExpense(exp);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAccountBalanceDialog(BuildContext context, double currentBalance) {
    final balanceCtrl = TextEditingController(text: currentBalance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentCyan, size: 22),
              SizedBox(width: 10),
              Text('Solde Réel Compte Courant', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Indiquez le solde réel de votre compte bancaire principal pour calibrer le buffer de sécurité :',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Solde Réel Actuel (€)', suffixText: '€', border: OutlineInputBorder()),
                style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentEmerald, foregroundColor: Colors.white),
              child: const Text('Mettre à jour'),
              onPressed: () {
                final val = double.tryParse(balanceCtrl.text) ?? currentBalance;
                ref.read(salaryProvider.notifier).updateAccountBalance(val);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryProvider);
    final baseRecord = salary.activeBaseline;
    final netSalary = baseRecord?.regularNetSalary ?? baseRecord?.netSalary ?? 2713.74;
    final extraAmount = baseRecord?.calculatedExtraAmount ?? 0.0;
    final hasBonus = extraAmount > 0;

    final taxMonthly = salary.activeTaxAdjustmentMonthlyInstallment;
    final tempMonthly = salary.activeTemporaryExpensesMonthlyTotal;
    final totalSavings = _savingsCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));
    final totalFixed = _fixedChargesCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary)) + taxMonthly + tempMonthly;
    final totalDaily = _dailyCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));

    final resteAVivre = netSalary - totalSavings - totalFixed - totalDaily;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Règles de Répartition'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Status Banner (Section Header Notification)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasBonus 
                          ? 'Règles basées sur votre revenu récurrent de ${netSalary.toStringAsFixed(2)} € (hors primes)'
                          : 'Règles dynamiques (% & Nominal €) basées sur votre revenu net de ${netSalary.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (hasBonus)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bonus détecté : Les extras ou primes de ${extraAmount.toStringAsFixed(2)} € ne sont pas inclus ici. Ils sont gérés par le moteur proactif (CTO).',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Sleek Dark Theme Card — RESTE À VIVRE & ALLOCATION GAUGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentEmerald, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'RESTE À VIVRE ESTIMÉ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          'Revenu Net : ${netSalary.toStringAsFixed(2)} €',
                          style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${resteAVivre.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${(netSalary > 0 ? (resteAVivre / netSalary * 100) : 0).toStringAsFixed(1)} % du net',
                          style: const TextStyle(
                            color: AppColors.accentEmerald,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Visual Progress Gauge Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          if (netSalary > 0) ...[
                            Expanded(
                              flex: ((totalFixed / netSalary) * 100).round().clamp(1, 100),
                              child: Container(color: AppColors.chartRed),
                            ),
                            Expanded(
                              flex: ((totalSavings / netSalary) * 100).round().clamp(1, 100),
                              child: Container(color: AppColors.chartBlue),
                            ),
                            Expanded(
                              flex: ((totalDaily / netSalary) * 100).round().clamp(1, 100),
                              child: Container(color: AppColors.chartYellow),
                            ),
                            Expanded(
                              flex: ((resteAVivre / netSalary) * 100).round().clamp(0, 100),
                              child: Container(color: AppColors.accentEmerald),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGaugeLegend('Charges', totalFixed, AppColors.chartRed),
                      _buildGaugeLegend('Épargne PEA/LA', totalSavings, AppColors.chartBlue),
                      _buildGaugeLegend('Quotidien', totalDaily, AppColors.chartYellow),
                      _buildGaugeLegend('Reste', resteAVivre, AppColors.accentEmerald),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION BUFFER COMPTE COURANT & SANTÉ TRÉSORERIE (1500€ - 1800€)
            Container(
              padding: const EdgeInsets.all(18),
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
                          Icon(Icons.shield_outlined, color: AppColors.accentCyan, size: 20),
                          SizedBox(width: 8),
                          Text('Buffer Compte Courant & Santé Trésorerie', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.2),
                          foregroundColor: AppColors.accentEmerald,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: Text('${salary.accountBalance.toStringAsFixed(0)} € Réel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => _showEditAccountBalanceDialog(context, salary.accountBalance),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final bal = salary.accountBalance;
                      final projBal = bal + resteAVivre;
                      Color statusColor;
                      String statusText;
                      String adviceText;

                      if (bal < 1200) {
                        statusColor = AppColors.accentRose;
                        statusText = '🚨 Danger de Découvert (< 1 200 €)';
                        adviceText = 'Votre buffer est sous le seuil de sécurité. Il est recommandé de réduire temporairement vos allocations PEA pour renflouer le compte courant à 1 500 €.';
                      } else if (bal < 1500) {
                        statusColor = Colors.orange;
                        statusText = '🟧 Absorption de Choc (1 200 € - 1 500 €)';
                        adviceText = 'Votre buffer absorbe les variations. Maintenez vos charges sous contrôle pour remonter progressivement vers la cible de 1 500 €.';
                      } else if (bal <= 1800) {
                        statusColor = AppColors.accentEmerald;
                        statusText = '🟩 Cible Idéale (1 500 € - 1 800 €)';
                        adviceText = 'Trésorerie optimale ! Votre solde est parfaitement équilibré entre sécurité et investissement.';
                      } else {
                        statusColor = AppColors.accentCyan;
                        statusText = '💡 Cash Dormant Détecté (> 1 800 €)';
                        adviceText = 'Vous avez +${(bal - 1800).toStringAsFixed(0)} € d\'excédent sur votre compte courant. Pensez à l\'arbitrer vers votre PEA ou votre Livret A !';
                      }

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Projeté Fin de Mois : ${projBal.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(adviceText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION DÉPENSES TEMPORAIRES ÉCHÉANCÉES (Dentiste 12 mois, Crédits N fois...)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_month_rounded, color: AppColors.accentCyan, size: 20),
                          SizedBox(width: 8),
                          Text('Dépenses Échéancées & Temporaires', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Déclarer un Échéancier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddTemporaryExpenseDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (salary.temporaryExpenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Text(
                        'Aucune dépense temporaire enregistrée. Déclarez vos soins dentaires (ex: 164€/mois sur 12 mois) ou achats étalés N fois.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    )
                  else
                    Column(
                      children: salary.temporaryExpenses.map((exp) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(exp.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Début ${exp.startPeriod} • Durée : ${exp.durationMonths} mois (Fin ${exp.endPeriod})',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${exp.monthlyAmount.toStringAsFixed(2)} €/mois',
                                style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () => _confirmDeleteTemporaryExpense(exp),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: ALLOCATION MENSUELLE D'ÉPARGNE
            _buildSectionHeader('ALLOCATION MENSUELLE D\'ÉPARGNE', totalSavings, netSalary, AppColors.chartBlue),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_savingsCategories, netSalary, allowDelete: false, onAdd: () => _showAddCategoryDialog(_savingsCategories, 'Épargne', AppColors.accentCyan)),

            const SizedBox(height: 24),

            // Section 2: CHARGES FIXES INCOMPRESSIBLES
            _buildSectionHeader('CHARGES FIXES INCOMPRESSIBLES', totalFixed, netSalary, AppColors.chartRed),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(
              _fixedChargesCategories,
              netSalary,
              allowDelete: true,
              onAdd: () => _showAddCategoryDialog(_fixedChargesCategories, 'Charge', AppColors.accentRose),
              extraWidget: taxMonthly > 0
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.account_balance_rounded, color: AppColors.accentRose, size: 18),
                              SizedBox(width: 10),
                              Text('Impôts DGFiP (Régularisation Étalée)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Text('-${taxMonthly.toStringAsFixed(2)} €/mois', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 24),

            // Section 3: DÉPENSES QUOTIDIENNES
            _buildSectionHeader('DÉPENSES QUOTIDIENNES', totalDaily, netSalary, AppColors.chartYellow),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_dailyCategories, netSalary, allowDelete: true, onAdd: () => _showAddCategoryDialog(_dailyCategories, 'Dépense', AppColors.accentEmerald)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double totalAmount, double netSalary, Color accentColor) {
    final pct = netSalary > 0 ? (totalAmount / netSalary * 100) : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Total : ${totalAmount.toStringAsFixed(2)} €  •  ${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGroupCard(
    List<RuleCategoryItem> categories,
    double netSalary, {
    required bool allowDelete,
    required VoidCallback onAdd,
    Widget? extraWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          if (extraWidget != null) extraWidget,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              return _buildCategoryRow(cat, netSalary, allowDelete: allowDelete, onDelete: () => _confirmDeleteCategory(cat, categories));
            },
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Add Category Button
          InkWell(
            onTap: onAdd,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.accentCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter une catégorie',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    RuleCategoryItem item,
    double netSalary, {
    required bool allowDelete,
    required VoidCallback onDelete,
  }) {
    final effectiveAmt = item.getEffectiveAmount(netSalary);
    final effectivePct = item.getEffectivePercent(netSalary);

    IconData getIcon(String type) {
      switch (type) {
        case 'chart':
          return Icons.show_chart_rounded;
        case 'shield':
          return Icons.shield_rounded;
        case 'home':
          return Icons.home_rounded;
        case 'video':
          return Icons.ondemand_video_rounded;
        case 'people':
          return Icons.people_alt_rounded;
        case 'heart':
          return Icons.favorite_rounded;
        case 'card':
          return Icons.credit_card_rounded;
        case 'basket':
          return Icons.shopping_basket_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.iconBgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(getIcon(item.iconType), color: item.iconBgColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Name & Mode Switcher Chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Interactive Mode Toggle Chip (% vs €)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (item.isPercentage) {
                            // Switch from % to Nominal €
                            item.amount = double.parse(effectiveAmt.toStringAsFixed(2));
                            item.isPercentage = false;
                          } else {
                            // Switch from Nominal € to %
                            item.amount = double.parse(effectivePct.toStringAsFixed(1));
                            item.isPercentage = true;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isPercentage ? AppColors.accentCyan.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.isPercentage ? AppColors.accentCyan.withValues(alpha: 0.5) : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.isPercentage ? '% Ratio' : '€ Fixe',
                              style: TextStyle(
                                color: item.isPercentage ? AppColors.accentCyan : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.swap_horiz_rounded, size: 12, color: item.isPercentage ? AppColors.accentCyan : AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Calculated Secondary Value Badge (Equal Font Size & High Contrast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              item.isPercentage
                  ? '= ${effectiveAmt.toStringAsFixed(2)} €'
                  : '= ${effectivePct.toStringAsFixed(1)} %',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Primary Value Button Box (Tap to edit)
          GestureDetector(
            onTap: () => _showEditAmountDialog(item, netSalary),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.isPercentage ? '${item.amount.toStringAsFixed(1)} %' : '${item.amount.toStringAsFixed(0)} €',
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_rounded, color: AppColors.accentCyan, size: 14),
                ],
              ),
            ),
          ),

          if (allowDelete) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
