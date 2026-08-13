import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../core/providers/auth_provider.dart';
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'isPercentage': isPercentage,
    'isLocked': isLocked,
    'iconType': iconType,
    'iconBgColor': iconBgColor.value,
  };

  factory RuleCategoryItem.fromJson(Map<String, dynamic> json) => RuleCategoryItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    isPercentage: json['isPercentage'] ?? false,
    isLocked: json['isLocked'] ?? false,
    iconType: json['iconType'] ?? 'default',
    iconBgColor: Color(json['iconBgColor'] ?? 0xFF000000),
  );

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
  List<RuleCategoryItem> _savingsCategories = [
    RuleCategoryItem(id: 'sav-1', name: 'Cible PEA', amount: 35.0, isPercentage: true, iconType: 'chart', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'sav-2', name: 'Livret A', amount: 7.0, isPercentage: true, iconType: 'shield', iconBgColor: Colors.blue),
  ];

  List<RuleCategoryItem> _fixedChargesCategories = [
    RuleCategoryItem(id: 'fix-1', name: 'Loyer', amount: 677, isPercentage: false, iconType: 'home', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-2', name: 'Abonnement', amount: 41, isPercentage: false, iconType: 'video', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-3', name: 'Tontine', amount: 300, isPercentage: false, iconType: 'people', iconBgColor: AppColors.accentPurple),
    RuleCategoryItem(id: 'fix-4', name: 'Soutien', amount: 231, isPercentage: false, iconType: 'heart', iconBgColor: AppColors.accentRose),
  ];

  List<RuleCategoryItem> _dailyCategories = [
    RuleCategoryItem(id: 'day-1', name: 'Revolut (Reste à vivre)', amount: 7.0, isPercentage: true, iconType: 'card', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'day-2', name: 'Tampon / Marge €', amount: 0, isPercentage: false, iconType: 'basket', iconBgColor: Colors.amber),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authProvider).user?.id ?? '';
    final key = userId.isEmpty ? 'aura_rules_categories' : '${userId}_aura_rules_categories';
    
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        if (data.containsKey('savings')) {
          _savingsCategories = (data['savings'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
        }
        if (data.containsKey('fixed')) {
          _fixedChargesCategories = (data['fixed'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
        }
        if (data.containsKey('daily')) {
          _dailyCategories = (data['daily'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
        }
        setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authProvider).user?.id ?? '';
    final key = userId.isEmpty ? 'aura_rules_categories' : '${userId}_aura_rules_categories';
    
    final data = {
      'savings': _savingsCategories.map((c) => c.toJson()).toList(),
      'fixed': _fixedChargesCategories.map((c) => c.toJson()).toList(),
      'daily': _dailyCategories.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(key, jsonEncode(data));
  }

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
                    _saveCategories();
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
                    _saveCategories();
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
                _saveCategories();
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

  void _showTemporaryExpenseDialog(BuildContext context, {TemporaryExpense? expense}) {
    final isEditing = expense != null;
    final now = DateTime.now();
    final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
    final currentPeriodStr = '${now.year}-$mStr';

    final labelCtrl = TextEditingController(text: isEditing ? expense.label : 'Dentiste Couronne');
    final amountCtrl = TextEditingController(text: isEditing ? expense.monthlyAmount.toStringAsFixed(2) : '164.50');
    final startCtrl = TextEditingController(text: isEditing ? expense.startPeriod : currentPeriodStr);
    final durationCtrl = TextEditingController(text: isEditing ? expense.durationMonths.toString() : '12');

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
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.accentCyan, size: 22),
                  const SizedBox(width: 10),
                  Text(isEditing ? 'Modifier l\'échéancier' : 'Dépense Échéancée / Temporaire', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  child: Text(isEditing ? 'Mettre à jour' : 'Ajouter l\'échéancier'),
                  onPressed: () {
                    final exp = TemporaryExpense(
                      id: isEditing ? expense.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      label: labelCtrl.text.isEmpty ? 'Dépense temporaire' : labelCtrl.text,
                      monthlyAmount: double.tryParse(amountCtrl.text) ?? 0.0,
                      startPeriod: startCtrl.text.isEmpty ? currentPeriodStr : startCtrl.text,
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
            LayoutBuilder(builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 700;
              final bal = salary.accountBalance;
              final projBal = bal + resteAVivre;
              final safe = projBal >= 0;
              
              final heroA = Container(
                padding: const EdgeInsets.all(24),
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
                        const Text('RESTE À VIVRE — CE MOIS-CI', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        Row(
                          children: const [
                            Icon(Icons.trending_up_rounded, color: AppColors.accentEmerald, size: 14),
                            SizedBox(width: 4),
                            Text('+68 % / 6 mois', style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${resteAVivre.toStringAsFixed(2)} €', style: TextStyle(color: resteAVivre < 0 ? AppColors.accentRose : AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.borderSubtle)),
                          child: Text('${(netSalary > 0 ? (resteAVivre / netSalary * 100) : 0).toStringAsFixed(1)} % du net', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.borderSubtle)),
                            child: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Un déficit reporté ramène votre trésorerie projetée à ${projBal.toStringAsFixed(0)} € fin de mois.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            if (netSalary > 0) ...[
                              Expanded(flex: ((totalFixed / netSalary) * 100).round().clamp(1, 100), child: Container(color: AppColors.accentRose)),
                              Expanded(flex: ((totalSavings / netSalary) * 100).round().clamp(1, 100), child: Container(color: Colors.blue)),
                              Expanded(flex: ((totalDaily / netSalary) * 100).round().clamp(1, 100), child: Container(color: Colors.amber)),
                              Expanded(flex: ((resteAVivre / netSalary) * 100).round().clamp(0, 100), child: Container(color: AppColors.accentEmerald)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildGaugeLegend('Charges', totalFixed, AppColors.accentRose),
                        _buildGaugeLegend('Épargne', totalSavings, Colors.blue),
                        _buildGaugeLegend('Quotidien', totalDaily, Colors.amber),
                        _buildGaugeLegend('Reste', resteAVivre, AppColors.accentEmerald),
                      ],
                    ),
                  ],
                ),
              );
              
              final heroB = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: safe ? AppColors.accentEmerald : AppColors.accentRose, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: safe ? AppColors.accentEmerald.withValues(alpha: 0.15) : AppColors.accentRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: safe ? AppColors.accentEmerald.withValues(alpha: 0.3) : AppColors.accentRose.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(safe ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, color: safe ? AppColors.accentEmerald : AppColors.accentRose, size: 14),
                          const SizedBox(width: 6),
                          Text(safe ? 'Trésorerie sécurisée' : 'Danger de découvert', style: TextStyle(color: safe ? AppColors.accentEmerald : AppColors.accentRose, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('${bal.toStringAsFixed(0)} €', style: TextStyle(color: bal < 0 ? AppColors.accentRose : AppColors.accentEmerald, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Déficit reporté du mois précédent (seuil de sécurité : 1 200 €)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
                      child: Row(
                        children: [
                          Text('${resteAVivre.toStringAsFixed(0)} € ', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text('théorique ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const Icon(Icons.arrow_right_alt_rounded, color: AppColors.textMuted, size: 14),
                          Text(' ${bal.abs().toStringAsFixed(0)} € ', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text('reporté ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const Icon(Icons.arrow_right_alt_rounded, color: AppColors.textMuted, size: 14),
                          Text(' ${projBal.toStringAsFixed(0)} € ', style: TextStyle(color: safe ? AppColors.accentEmerald : AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text('projeté', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      safe ? 'Votre trésorerie projetée est positive : aucune action nécessaire ce mois-ci.' : 'Votre trésorerie passera sous le seuil de sécurité. Il est recommandé de réduire temporairement vos allocations d\'épargne pour repasser à l\'équilibre.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderSubtle)),
                            ),
                            onPressed: () => _showEditAccountBalanceDialog(context, salary.accountBalance),
                            child: const Text('Corriger le solde réel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              
              if (isMobile) {
                return Column(
                  children: [
                    heroA,
                    const SizedBox(height: 16),
                    IntrinsicHeight(child: heroB),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: heroA),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: heroB),
                  ],
                ),
              );
            }),
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
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Déclarer un Échéancier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _showTemporaryExpenseDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (salary.temporaryExpenses.isEmpty)
                    InkWell(
                      onTap: () => _showTemporaryExpenseDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text('Aucune dépense temporaire enregistrée — soins dentaires, achats étalés N fois...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ),
                            Text('+ Déclarer', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
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
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 18),
                                    onPressed: () => _showTemporaryExpenseDialog(context, expense: exp),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                                    onPressed: () => _confirmDeleteTemporaryExpense(exp),
                                  ),
                                ],
                              )
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
            _buildSectionHeader('ALLOCATION MENSUELLE D\'ÉPARGNE', totalSavings, netSalary, Colors.blue),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_savingsCategories, netSalary, allowDelete: false, onAdd: () => _showAddCategoryDialog(_savingsCategories, 'Épargne', AppColors.accentCyan)),

            const SizedBox(height: 24),

            // Section 2: CHARGES FIXES INCOMPRESSIBLES
            _buildSectionHeader('CHARGES FIXES INCOMPRESSIBLES', totalFixed, netSalary, AppColors.accentRose),
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
            _buildSectionHeader('DÉPENSES QUOTIDIENNES', totalDaily, netSalary, Colors.amber),
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
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              item.isPercentage
                  ? '= ${effectiveAmt.toStringAsFixed(2)} €'
                  : '= ${effectivePct.toStringAsFixed(1)} %',
              style: const TextStyle(
                color: AppColors.textMuted,
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
                borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded, color: AppColors.accentCyan, size: 12),
                ],
              ),
            ),
          ),

          if (allowDelete) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
              onPressed: onDelete,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
