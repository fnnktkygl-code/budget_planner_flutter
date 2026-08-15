import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/budget_provider.dart';
import '../services/banking_analyzer_service.dart';
import '../models/temporary_expense.dart';
import '../widgets/notification_header.dart';

class RuleCategoryItem {
  final String id;
  String name;
  double amount;
  bool isPercentage;
  bool isLocked;
  String iconType;
  Color iconBgColor;
  String? note;

  RuleCategoryItem({
    required this.id,
    required this.name,
    required this.amount,
    this.isPercentage = false,
    this.isLocked = true,
    required this.iconType,
    required this.iconBgColor,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'isPercentage': isPercentage,
    'isLocked': isLocked,
    'iconType': iconType,
    'iconBgColor': iconBgColor.value,
    'note': note,
  };

  factory RuleCategoryItem.fromJson(Map<String, dynamic> json) => RuleCategoryItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    isPercentage: json['isPercentage'] ?? false,
    isLocked: json['isLocked'] ?? false,
    iconType: json['iconType'] ?? 'default',
    iconBgColor: Color(json['iconBgColor'] ?? 0xFF000000),
    note: json['note'] as String?,
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
  ];

  Set<String> _ignoredDetectedTxIds = {};
  int _selectedForecastOffset = 0; // 0 = Mois en cours (M), 1 = M+1, 2 = M+2, 3 = M+3, 4 = M+4, 5 = M+5

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadIgnoredSuggestions();
  }

  DateTime _getDateForOffset(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + offset, 1);
  }

  String _getPeriodForOffset(int offset) {
    final d = _getDateForOffset(offset);
    final mStr = d.month < 10 ? '0${d.month}' : '${d.month}';
    return '${d.year}-$mStr';
  }

  String _getMonthName(int month) {
    const names = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return names[(month - 1) % 12];
  }

  String _getMonthShortName(int month) {
    const names = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
    return names[(month - 1) % 12];
  }

  String _getPeriodLabel(int offset) {
    final d = _getDateForOffset(offset);
    final name = _getMonthName(d.month);
    if (offset == 0) return '$name ${d.year} (Mois en cours)';
    return '$name ${d.year} (M+$offset)';
  }

  RuleCategoryItem? _findMatchingCategory(DetectedRecurringExpense sugg) {
    final m = sugg.merchant.toLowerCase();
    final all = [..._fixedChargesCategories, ..._savingsCategories, ..._dailyCategories];
    for (var c in all) {
      final cn = c.name.toLowerCase();
      if (m.contains('cdc') || m.contains('habitat') || m.contains('loyer')) {
        if (cn.contains('loyer') || cn.contains('habitat')) return c;
      }
      if (m.contains('bpce') || m.contains('assurance') || m.contains('macif') || m.contains('axa') || m.contains('allianz')) {
        if (cn.contains('assurance') || cn.contains('bpce')) return c;
      }
      if (m.contains('sendwave') || m.contains('transfer') || m.contains('remit')) {
        if (cn.contains('soutien') || cn.contains('sendwave') || cn.contains('famille')) return c;
      }
      if (m.contains('tontine')) {
        if (cn.contains('tontine')) return c;
      }
      if (m.contains('netflix') || m.contains('spotify') || m.contains('free') || m.contains('orange') || m.contains('sfr') || m.contains('bouygues')) {
        if (cn.contains('abonnement') || cn.contains('telecom') || cn.contains('internet')) return c;
      }
      if (cn.contains(m) || m.contains(cn)) return c;
    }
    return null;
  }

  Future<void> _loadIgnoredSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authProvider).user?.id ?? '';
    final key = userId.isEmpty ? 'aura_ignored_detected_txs' : '${userId}_aura_ignored_detected_txs';
    final rawList = prefs.getStringList(key);
    if (rawList != null) {
      setState(() {
        _ignoredDetectedTxIds = rawList.toSet();
      });
    }
  }

  Future<void> _saveIgnoredSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authProvider).user?.id ?? '';
    final key = userId.isEmpty ? 'aura_ignored_detected_txs' : '${userId}_aura_ignored_detected_txs';
    await prefs.setStringList(key, _ignoredDetectedTxIds.toList());
  }

  Future<void> _ignoreSuggestion(String id) async {
    setState(() {
      _ignoredDetectedTxIds.add(id);
    });
    await _saveIgnoredSuggestions();
  }

  Future<void> _addFixedChargeFromSuggestion(DetectedRecurringExpense sugg) async {
    setState(() {
      _fixedChargesCategories.add(
        RuleCategoryItem(
          id: 'fix-${DateTime.now().millisecondsSinceEpoch}',
          name: sugg.merchant,
          amount: sugg.amount,
          isPercentage: false,
          isLocked: false,
          iconType: 'card',
          iconBgColor: AppColors.accentRose,
        ),
      );
      _ignoredDetectedTxIds.add(sugg.id);
    });
    await _saveCategories();
    await _saveIgnoredSuggestions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sugg.merchant} (${sugg.amount.toStringAsFixed(2)} €/mois) ajouté aux Charges Fixes.'),
          backgroundColor: AppColors.accentEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAssignSuggestionModal(
    BuildContext parentContext,
    DetectedRecurringExpense sugg, {
    VoidCallback? onAssigned,
  }) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        int activeTab = 0; // 0 = Fusionner / Affecter, 1 = Nouveau poste dans pilier, 2 = Échéancier temporaire
        int linkMode = 0; // 0 = Cumuler / Additionner (+), 1 = Écraser / Remplacer (⚡)
        int selectedPillar = 0; // 0 = Charges Fixes, 1 = Épargne, 2 = Quotidien
        bool isPercentMode = false;
        bool renameOnOverwrite = false;
        bool appendNoteOnCumul = true;

        final matched = _findMatchingCategory(sugg);
        RuleCategoryItem? targetCategory = matched ?? (_fixedChargesCategories.isNotEmpty ? _fixedChargesCategories.first : null);

        final nameCtrl = TextEditingController(text: sugg.merchant);
        final amountCtrl = TextEditingController(text: sugg.amount.toStringAsFixed(2));
        final durationCtrl = TextEditingController(text: sugg.suggestedDurationMonths.toString());
        final now = DateTime.now();
        final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
        final startPeriodCtrl = TextEditingController(text: '${now.year}-$mStr');

        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(parentContext).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.accentCyan, width: 1.5),
                  left: BorderSide(color: AppColors.borderSubtle),
                  right: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Merchant & Detected Amount
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hub_rounded, color: AppColors.accentCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sugg.merchant,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Flux bancaire identifié : ${sugg.amount.toStringAsFixed(2)} €/mois',
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Selector: 1) Fusionner / Lier | 2) Nouveau Pilier | 3) Échéancier
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeTab == 0 ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🔗 Fusionner / Lier',
                                style: TextStyle(
                                  color: activeTab == 0 ? Colors.black : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeTab == 1 ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+ Nouveau Poste',
                                style: TextStyle(
                                  color: activeTab == 1 ? Colors.black : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => activeTab = 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeTab == 2 ? AppColors.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '📅 Échéancier',
                                style: TextStyle(
                                  color: activeTab == 2 ? Colors.black : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TAB CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      child: activeTab == 0
                          ? _buildLinkCategoryTab(
                              sheetCtx,
                              setSheetState,
                              sugg,
                              targetCategory,
                              linkMode,
                              renameOnOverwrite,
                              appendNoteOnCumul,
                              (newCat) => setSheetState(() => targetCategory = newCat),
                              (mode) => setSheetState(() => linkMode = mode),
                              (val) => setSheetState(() => renameOnOverwrite = val),
                              (val) => setSheetState(() => appendNoteOnCumul = val),
                              onAssigned,
                            )
                          : activeTab == 1
                              ? _buildNewPillarTab(
                                  sheetCtx,
                                  setSheetState,
                                  sugg,
                                  selectedPillar,
                                  isPercentMode,
                                  nameCtrl,
                                  amountCtrl,
                                  (p) => setSheetState(() => selectedPillar = p),
                                  (pct) => setSheetState(() => isPercentMode = pct),
                                  onAssigned,
                                )
                              : _buildTemporaryTab(
                                  sheetCtx,
                                  setSheetState,
                                  sugg,
                                  nameCtrl,
                                  amountCtrl,
                                  durationCtrl,
                                  startPeriodCtrl,
                                  onAssigned,
                                ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinkCategoryTab(
    BuildContext sheetCtx,
    StateSetter setSheetState,
    DetectedRecurringExpense sugg,
    RuleCategoryItem? targetCategory,
    int linkMode, // 0 = Cumuler (+), 1 = Écraser (⚡)
    bool renameOnOverwrite,
    bool appendNoteOnCumul,
    Function(RuleCategoryItem?) onSelectCategory,
    Function(int) onToggleMode,
    Function(bool) onToggleRename,
    Function(bool) onToggleAppendNote,
    VoidCallback? onAssigned,
  ) {
    final allPillars = [
      {'title': 'Charges Fixes Incompressibles', 'list': _fixedChargesCategories, 'icon': Icons.lock_clock_rounded, 'color': AppColors.accentRose},
      {'title': 'Allocations Mensuelles d\'Épargne', 'list': _savingsCategories, 'icon': Icons.shield_rounded, 'color': Colors.blue},
      {'title': 'Dépenses Quotidiennes', 'list': _dailyCategories, 'icon': Icons.credit_card_rounded, 'color': AppColors.accentCyan},
    ];

    final salary = ref.read(salaryProvider);
    final netSalary = salary.activeBaseline?.regularNetSalary ?? 2713.74;

    final curAmt = targetCategory != null ? targetCategory.getEffectiveAmount(netSalary) : 0.0;
    final newTotalCumul = curAmt + sugg.amount;
    final deltaOverwrite = sugg.amount - curAmt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector: Cumuler vs Écraser
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggleMode(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: linkMode == 0 ? AppColors.accentCyan.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: linkMode == 0 ? Border.all(color: AppColors.accentCyan) : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: linkMode == 0 ? AppColors.accentCyan : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '➕ Cumuler / Additionner',
                          style: TextStyle(
                            color: linkMode == 0 ? AppColors.accentCyan : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggleMode(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: linkMode == 1 ? AppColors.accentEmerald.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: linkMode == 1 ? Border.all(color: AppColors.accentEmerald) : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: linkMode == 1 ? AppColors.accentEmerald : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '⚡ Écraser / Remplacer',
                          style: TextStyle(
                            color: linkMode == 1 ? AppColors.accentEmerald : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
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
        const SizedBox(height: 12),

        Text(
          linkMode == 0
              ? 'Sélectionnez une catégorie existante à laquelle ajouter ${sugg.amount.toStringAsFixed(2)} €/mois (ex: Abonnements Bouygues + Spotify) :'
              : 'Sélectionnez une catégorie existante à mettre à jour et remplacer par ${sugg.amount.toStringAsFixed(2)} €/mois (ex: Loyer) :',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 14),

        for (var p in allPillars) ...[
          Text(
            (p['title'] as String).toUpperCase(),
            style: TextStyle(color: p['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: (p['list'] as List<RuleCategoryItem>).map((cat) {
                final isSelected = targetCategory?.id == cat.id;
                final catCurAmt = cat.getEffectiveAmount(netSalary);
                final catTotalCumul = catCurAmt + sugg.amount;
                final catDelta = sugg.amount - catCurAmt;

                return InkWell(
                  onTap: () => onSelectCategory(cat),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppColors.accentCyan) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.accentCyan : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Actuel : ${catCurAmt.toStringAsFixed(2)} €/mois (${cat.isPercentage ? "${cat.amount}%" : "Nominal"})',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                              if (cat.note != null && cat.note!.isNotEmpty)
                                Text(
                                  cat.note!,
                                  style: const TextStyle(color: AppColors.accentCyan, fontSize: 9, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (linkMode == 0) ...[
                              Text(
                                '➕ ${catTotalCumul.toStringAsFixed(2)} €',
                                style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '+${sugg.amount.toStringAsFixed(2)} €',
                                style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ] else ...[
                              Text(
                                '➔ ${sugg.amount.toStringAsFixed(2)} €',
                                style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                catDelta == 0 ? 'Identique' : (catDelta > 0 ? '+${catDelta.toStringAsFixed(2)} €' : '${catDelta.toStringAsFixed(2)} €'),
                                style: TextStyle(
                                  color: catDelta == 0 ? AppColors.textMuted : (catDelta > 0 ? AppColors.accentRose : AppColors.accentEmerald),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (targetCategory != null) ...[
          // Mathematical Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (linkMode == 0 ? AppColors.accentCyan : AppColors.accentEmerald).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (linkMode == 0 ? AppColors.accentCyan : AppColors.accentEmerald).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  linkMode == 0 ? Icons.calculate_rounded : Icons.bolt_rounded,
                  color: linkMode == 0 ? AppColors.accentCyan : AppColors.accentEmerald,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linkMode == 0 ? 'Calcul du cumul arithmétique :' : 'Aperçu du remplacement :',
                        style: TextStyle(
                          color: linkMode == 0 ? AppColors.accentCyan : AppColors.accentEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        linkMode == 0
                            ? '${curAmt.toStringAsFixed(2)} € (Actuel) + ${sugg.amount.toStringAsFixed(2)} € (${sugg.merchant}) = ${newTotalCumul.toStringAsFixed(2)} € / mois'
                            : '${curAmt.toStringAsFixed(2)} € (Actuel) ➔ ${sugg.amount.toStringAsFixed(2)} € (${sugg.merchant})  [Delta : ${deltaOverwrite >= 0 ? "+" : ""}${deltaOverwrite.toStringAsFixed(2)} €]',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (linkMode == 0) ...[
            CheckboxListTile(
              value: appendNoteOnCumul,
              onChanged: (val) => onToggleAppendNote(val ?? true),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.accentCyan,
              title: Text(
                'Consigner "${sugg.merchant}" dans la note de "${targetCategory.name}"',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ] else ...[
            CheckboxListTile(
              value: renameOnOverwrite,
              onChanged: (val) => onToggleRename(val ?? false),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.accentEmerald,
              title: Text(
                'Renommer également "${targetCategory.name}" en "${sugg.merchant}"',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: linkMode == 0 ? AppColors.accentCyan : AppColors.accentEmerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(linkMode == 0 ? Icons.add_circle_rounded : Icons.check_rounded, size: 18),
              label: Text(
                linkMode == 0
                    ? '➕ Cumuler et valider (${newTotalCumul.toStringAsFixed(2)} € / mois)'
                    : '⚡ Écraser "${targetCategory.name}" avec ${sugg.amount.toStringAsFixed(2)} €',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final oldAmount = targetCategory.amount;
                final oldName = targetCategory.name;
                final oldIsPct = targetCategory.isPercentage;
                final oldNote = targetCategory.note;

                setState(() {
                  if (linkMode == 0) {
                    // Cumuler / Additionner
                    if (targetCategory.isPercentage) {
                      targetCategory.amount = double.parse(((newTotalCumul / netSalary) * 100).toStringAsFixed(1));
                    } else {
                      targetCategory.amount = double.parse(newTotalCumul.toStringAsFixed(2));
                    }
                    if (appendNoteOnCumul) {
                      if (targetCategory.note == null || targetCategory.note!.isEmpty) {
                        targetCategory.note = sugg.merchant;
                      } else if (!targetCategory.note!.contains(sugg.merchant)) {
                        targetCategory.note = '${targetCategory.note} • ${sugg.merchant}';
                      }
                    }
                  } else {
                    // Écraser / Remplacer
                    targetCategory.amount = sugg.amount;
                    targetCategory.isPercentage = false;
                    if (renameOnOverwrite) {
                      targetCategory.name = sugg.merchant;
                    }
                  }
                  _ignoredDetectedTxIds.add(sugg.id);
                });

                await _saveCategories();
                await _saveIgnoredSuggestions();
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                onAssigned?.call();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        linkMode == 0
                            ? 'Catégorie "${targetCategory.name}" cumulée : ${curAmt.toStringAsFixed(2)} € + ${sugg.amount.toStringAsFixed(2)} € = ${targetCategory.getEffectiveAmount(netSalary).toStringAsFixed(2)} €/mois.'
                            : 'Catégorie "${targetCategory.name}" écrasée à ${sugg.amount.toStringAsFixed(2)} €/mois.',
                      ),
                      backgroundColor: AppColors.accentEmerald,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Annuler',
                        textColor: AppColors.accentGold,
                        onPressed: () async {
                          setState(() {
                            targetCategory.amount = oldAmount;
                            targetCategory.name = oldName;
                            targetCategory.isPercentage = oldIsPct;
                            targetCategory.note = oldNote;
                            _ignoredDetectedTxIds.remove(sugg.id);
                          });
                          await _saveCategories();
                          await _saveIgnoredSuggestions();
                          onAssigned?.call();
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewPillarTab(
    BuildContext sheetCtx,
    StateSetter setSheetState,
    DetectedRecurringExpense sugg,
    int selectedPillar,
    bool isPercentMode,
    TextEditingController nameCtrl,
    TextEditingController amountCtrl,
    Function(int) onSelectPillar,
    Function(bool) onTogglePercent,
    VoidCallback? onAssigned,
  ) {
    final pillars = [
      {'name': 'Charges Fixes', 'icon': Icons.lock_clock_rounded, 'color': AppColors.accentRose, 'prefix': 'fix'},
      {'name': 'Épargne & Invest.', 'icon': Icons.shield_rounded, 'color': Colors.blue, 'prefix': 'sav'},
      {'name': 'Dépenses Quotidiennes', 'icon': Icons.credit_card_rounded, 'color': AppColors.accentCyan, 'prefix': 'day'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choisissez le pilier de destination :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(pillars.length, (i) {
            final p = pillars[i];
            final isSel = selectedPillar == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelectPillar(i),
                child: Container(
                  margin: EdgeInsets.only(right: i < pillars.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSel ? (p['color'] as Color).withValues(alpha: 0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSel ? (p['color'] as Color) : AppColors.borderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(p['icon'] as IconData, color: isSel ? (p['color'] as Color) : AppColors.textMuted, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        p['name'] as String,
                        style: TextStyle(
                          color: isSel ? AppColors.textPrimary : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Intitulé de la catégorie', border: OutlineInputBorder()),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isPercentMode ? 'Pourcentage (%)' : 'Montant Mensuel (€)',
                  suffixText: isPercentMode ? '%' : '€',
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(isPercentMode ? Icons.percent_rounded : Icons.euro_rounded, color: AppColors.accentCyan),
              tooltip: 'Basculer % / €',
              onPressed: () => onTogglePercent(!isPercentMode),
            ),
          ],
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Ajouter à ${pillars[selectedPillar]["name"]}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? sugg.amount;
              final name = nameCtrl.text.trim().isEmpty ? sugg.merchant : nameCtrl.text.trim();
              final p = pillars[selectedPillar];

              final newItem = RuleCategoryItem(
                id: '${p["prefix"]}-${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                amount: amt,
                isPercentage: isPercentMode,
                iconType: 'card',
                iconBgColor: p['color'] as Color,
              );

              setState(() {
                if (selectedPillar == 0) {
                  _fixedChargesCategories.add(newItem);
                } else if (selectedPillar == 1) {
                  _savingsCategories.add(newItem);
                } else {
                  _dailyCategories.add(newItem);
                }
                _ignoredDetectedTxIds.add(sugg.id);
              });

              await _saveCategories();
              await _saveIgnoredSuggestions();
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              onAssigned?.call();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$name" (${amt.toStringAsFixed(2)} ${isPercentMode ? "%" : "€"}) ajouté avec succès !'),
                    backgroundColor: AppColors.accentEmerald,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Annuler',
                      textColor: AppColors.accentGold,
                      onPressed: () async {
                        setState(() {
                          if (selectedPillar == 0) {
                            _fixedChargesCategories.removeWhere((c) => c.id == newItem.id);
                          } else if (selectedPillar == 1) {
                            _savingsCategories.removeWhere((c) => c.id == newItem.id);
                          } else {
                            _dailyCategories.removeWhere((c) => c.id == newItem.id);
                          }
                          _ignoredDetectedTxIds.remove(sugg.id);
                        });
                        await _saveCategories();
                        await _saveIgnoredSuggestions();
                        onAssigned?.call();
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemporaryTab(
    BuildContext sheetCtx,
    StateSetter setSheetState,
    DetectedRecurringExpense sugg,
    TextEditingController nameCtrl,
    TextEditingController amountCtrl,
    TextEditingController durationCtrl,
    TextEditingController startPeriodCtrl,
    VoidCallback? onAssigned,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enregistrez ce flux comme dépense temporaire / échéancier à durée limitée (ex: régularisation Fisc, soins étalés) :',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: nameCtrl,
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
                decoration: const InputDecoration(labelText: 'Montant Mensuel (€)', suffixText: '€', border: OutlineInputBorder()),
                style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durée (Mois)', border: OutlineInputBorder()),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: startPeriodCtrl,
          decoration: const InputDecoration(labelText: 'Mois Début (AAAA-MM)', border: OutlineInputBorder(), hintText: 'ex: 2026-09'),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Créer l\'échéancier temporaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? sugg.amount;
              final dur = int.tryParse(durationCtrl.text.trim()) ?? sugg.suggestedDurationMonths;
              final name = nameCtrl.text.trim().isEmpty ? sugg.merchant : nameCtrl.text.trim();
              final start = startPeriodCtrl.text.trim().isEmpty ? _getPeriodForOffset(0) : startPeriodCtrl.text.trim();

              final exp = TemporaryExpense(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                label: name,
                monthlyAmount: amt,
                startPeriod: start,
                durationMonths: dur,
              );

              ref.read(salaryProvider.notifier).addTemporaryExpense(exp);
              setState(() {
                _ignoredDetectedTxIds.add(sugg.id);
              });
              await _saveIgnoredSuggestions();

              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              onAssigned?.call();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Échéancier "$name" (${amt.toStringAsFixed(2)} €/mois sur $dur mois) créé.'),
                    backgroundColor: AppColors.accentEmerald,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Annuler',
                      textColor: AppColors.accentGold,
                      onPressed: () async {
                        ref.read(salaryProvider.notifier).deleteTemporaryExpense(exp.id);
                        setState(() {
                          _ignoredDetectedTxIds.remove(sugg.id);
                        });
                        await _saveIgnoredSuggestions();
                        onAssigned?.call();
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showRadarModal(BuildContext context, List<DetectedRecurringExpense> initialSuggestions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isAiEnhancing = false;
        List<DetectedRecurringExpense> suggestions = List.from(initialSuggestions);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final activeSuggestions = suggestions.where((s) => !_ignoredDetectedTxIds.contains(s.id)).toList();

            void runAiEnhancement() async {
              if (isAiEnhancing) return;
              setModalState(() => isAiEnhancing = true);
              try {
                final enhanced = await BankingAnalyzerService.enhanceWithGeminiAi(
                  currentSuggestions: suggestions,
                );
                if (modalCtx.mounted) {
                  setModalState(() {
                    suggestions = enhanced;
                    isAiEnhancing = false;
                  });
                }
              } catch (_) {
                if (modalCtx.mounted) {
                  setModalState(() => isAiEnhancing = false);
                }
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.accentCyan, width: 1.5),
                  left: BorderSide(color: AppColors.borderSubtle),
                  right: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar_rounded, color: AppColors.accentCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Radar Open Banking',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.auto_awesome, size: 10, color: AppColors.accentCyan),
                                      SizedBox(width: 4),
                                      Text(
                                        'IA Propre',
                                        style: TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeSuggestions.isEmpty
                                  ? 'Toutes les suggestions sont traitées'
                                  : '${activeSuggestions.length} flux identifié${activeSuggestions.length > 1 ? "s" : ""} (doublons regroupés)',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (activeSuggestions.isNotEmpty && activeSuggestions.any((s) => !s.isAiCleaned))
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.accentCyan.withValues(alpha: 0.1),
                            foregroundColor: AppColors.accentCyan,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isAiEnhancing
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan))
                              : const Icon(Icons.auto_awesome, size: 13),
                          label: Text(isAiEnhancing ? 'IA...' : 'Affiner IA', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: isAiEnhancing ? null : runAiEnhancement,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aura analyse vos relevés bancaires pour détecter les flux récurrents. Vous pouvez les écraser sur une catégorie existante (ex: Loyer), les ajouter à un pilier de budget ou créer un échéancier.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (activeSuggestions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline_rounded, color: AppColors.accentEmerald, size: 44),
                          SizedBox(height: 12),
                          Text(
                            'Aucun autre flux en attente !',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toutes les suggestions bancaires ont été prises en compte.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: activeSuggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (c, idx) {
                          final sugg = activeSuggestions[idx];
                          final matchedCat = _findMatchingCategory(sugg);
                          final salary = ref.read(salaryProvider);
                          final netSalary = salary.activeBaseline?.regularNetSalary ?? 2713.74;

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sugg.merchant,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sugg.suggestedCategory,
                                                  style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              if (sugg.occurrenceCount > 1)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.cardBackground,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppColors.borderSubtle),
                                                  ),
                                                  child: Text(
                                                    '${sugg.occurrenceCount}x identifié',
                                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                                  ),
                                                ),
                                              if (sugg.isAiCleaned)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentPurple.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.auto_awesome, size: 10, color: AppColors.accentPurple),
                                                      SizedBox(width: 3),
                                                      Text('IA Certifiée', style: TextStyle(color: AppColors.accentPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            sugg.reason,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '-${sugg.amount.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            color: AppColors.accentRose,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          '/ mois',
                                          style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // ACTION BUTTONS
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // 1-Tap Cumuler shortcut if matching category exists
                                    if (matchedCat != null) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
                                          foregroundColor: AppColors.accentCyan,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                                        label: Text(
                                          '➕ Cumuler à "${matchedCat.name}" (+${sugg.amount.toStringAsFixed(2)}€ ➔ ${(matchedCat.getEffectiveAmount(netSalary) + sugg.amount).toStringAsFixed(2)}€)',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          final oldAmount = matchedCat.amount;
                                          final oldIsPct = matchedCat.isPercentage;
                                          final oldNote = matchedCat.note;
                                          final curAmt = matchedCat.getEffectiveAmount(netSalary);
                                          final newTotal = curAmt + sugg.amount;

                                          setState(() {
                                            if (matchedCat.isPercentage) {
                                              matchedCat.amount = double.parse(((newTotal / netSalary) * 100).toStringAsFixed(1));
                                            } else {
                                              matchedCat.amount = double.parse(newTotal.toStringAsFixed(2));
                                            }
                                            if (matchedCat.note == null || matchedCat.note!.isEmpty) {
                                              matchedCat.note = sugg.merchant;
                                            } else if (!matchedCat.note!.contains(sugg.merchant)) {
                                              matchedCat.note = '${matchedCat.note} • ${sugg.merchant}';
                                            }
                                            _ignoredDetectedTxIds.add(sugg.id);
                                          });

                                          await _saveCategories();
                                          await _saveIgnoredSuggestions();
                                          setModalState(() {});

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Catégorie "${matchedCat.name}" cumulée : ${curAmt.toStringAsFixed(2)} € + ${sugg.amount.toStringAsFixed(2)} € = ${newTotal.toStringAsFixed(2)} €/mois.'),
                                                backgroundColor: AppColors.accentEmerald,
                                                behavior: SnackBarBehavior.floating,
                                                action: SnackBarAction(
                                                  label: 'Annuler',
                                                  textColor: AppColors.accentGold,
                                                  onPressed: () async {
                                                    setState(() {
                                                      matchedCat.amount = oldAmount;
                                                      matchedCat.isPercentage = oldIsPct;
                                                      matchedCat.note = oldNote;
                                                      _ignoredDetectedTxIds.remove(sugg.id);
                                                    });
                                                    await _saveCategories();
                                                    await _saveIgnoredSuggestions();
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),

                                      // 1-Tap Overwrite shortcut
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.15),
                                          foregroundColor: AppColors.accentEmerald,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                                          ),
                                        ),
                                        icon: const Icon(Icons.bolt_rounded, size: 15),
                                        label: Text(
                                          '⚡ Écraser "${matchedCat.name}" (${matchedCat.getEffectiveAmount(netSalary).toStringAsFixed(0)}€ ➔ ${sugg.amount.toStringAsFixed(2)}€)',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          final oldAmount = matchedCat.amount;
                                          final oldIsPct = matchedCat.isPercentage;

                                          setState(() {
                                            matchedCat.amount = sugg.amount;
                                            matchedCat.isPercentage = false;
                                            _ignoredDetectedTxIds.add(sugg.id);
                                          });

                                          await _saveCategories();
                                          await _saveIgnoredSuggestions();
                                          setModalState(() {});

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Catégorie "${matchedCat.name}" écrasée à ${sugg.amount.toStringAsFixed(2)} €/mois.'),
                                                backgroundColor: AppColors.accentEmerald,
                                                behavior: SnackBarBehavior.floating,
                                                action: SnackBarAction(
                                                  label: 'Annuler',
                                                  textColor: AppColors.accentGold,
                                                  onPressed: () async {
                                                    setState(() {
                                                      matchedCat.amount = oldAmount;
                                                      matchedCat.isPercentage = oldIsPct;
                                                      _ignoredDetectedTxIds.remove(sugg.id);
                                                    });
                                                    await _saveCategories();
                                                    await _saveIgnoredSuggestions();
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],

                                    // Flexible Assignment Modal button
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surface,
                                        foregroundColor: AppColors.textPrimary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                      ),
                                      icon: const Icon(Icons.tune_rounded, size: 14),
                                      label: const Text('⚙️ Affecter / Autre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        _showAssignSuggestionModal(
                                          context,
                                          sugg,
                                          onAssigned: () => setModalState(() {}),
                                        );
                                      },
                                    ),

                                    // Staggered Schedule quick button
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.cardBackground,
                                        foregroundColor: AppColors.textSecondary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                      ),
                                      icon: const Icon(Icons.calendar_month_rounded, size: 14),
                                      label: Text('+ Échéancier (${sugg.suggestedDurationMonths}m)', style: const TextStyle(fontSize: 11)),
                                      onPressed: () async {
                                        final exp = TemporaryExpense(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          label: sugg.merchant,
                                          monthlyAmount: sugg.amount,
                                          startPeriod: _getPeriodForOffset(0),
                                          durationMonths: sugg.suggestedDurationMonths,
                                        );
                                        ref.read(salaryProvider.notifier).addTemporaryExpense(exp);

                                        setState(() {
                                          _ignoredDetectedTxIds.add(sugg.id);
                                        });
                                        await _saveIgnoredSuggestions();
                                        setModalState(() {});

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Échéancier "${sugg.merchant}" (${sugg.amount.toStringAsFixed(2)} €/mois sur ${sugg.suggestedDurationMonths} mois) créé.'),
                                              backgroundColor: AppColors.accentEmerald,
                                              behavior: SnackBarBehavior.floating,
                                              action: SnackBarAction(
                                                label: 'Annuler',
                                                textColor: AppColors.accentGold,
                                                onPressed: () async {
                                                  ref.read(salaryProvider.notifier).deleteTemporaryExpense(exp.id);
                                                  setState(() {
                                                    _ignoredDetectedTxIds.remove(sugg.id);
                                                  });
                                                  await _saveIgnoredSuggestions();
                                                  setModalState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),

                                    // Ignore button
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textMuted,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.visibility_off_outlined, size: 13),
                                      label: const Text('Ignorer', style: TextStyle(fontSize: 11)),
                                      onPressed: () async {
                                        setState(() {
                                          _ignoredDetectedTxIds.add(sugg.id);
                                        });
                                        await _saveIgnoredSuggestions();
                                        setModalState(() {});

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('"${sugg.merchant}" masqué du Radar.'),
                                              backgroundColor: AppColors.surface,
                                              behavior: SnackBarBehavior.floating,
                                              action: SnackBarAction(
                                                label: 'Annuler',
                                                textColor: AppColors.accentCyan,
                                                onPressed: () async {
                                                  setState(() {
                                                    _ignoredDetectedTxIds.remove(sugg.id);
                                                  });
                                                  await _saveIgnoredSuggestions();
                                                  setModalState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showForecastMatrixModal(BuildContext context, SalaryState salary, double netSalary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final totalSavings = _savingsCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));
        final baseFixed = _fixedChargesCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));
        final totalDaily = _dailyCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.accentCyan, width: 1.5),
              left: BorderSide(color: AppColors.borderSubtle),
              right: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppColors.accentCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Matrice Prévisionnelle (Horizon 6 Mois)',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Anticipez l\'impact des échéances futures et ajustez votre épargne.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (c, offset) {
                    final d = _getDateForOffset(offset);
                    final period = _getPeriodForOffset(offset);
                    final periodLabel = _getPeriodLabel(offset);
                    final isCurrentSelected = _selectedForecastOffset == offset;

                    final monthTax = salary.taxAdjustmentMonthlyForPeriod(period);
                    final monthTemp = salary.temporaryExpensesMonthlyForPeriod(period);
                    final activeTempList = salary.getActiveTemporaryExpensesForPeriod(period);
                    final activeTaxList = salary.getActiveTaxAdjustmentsForPeriod(period);

                    final monthTotalFixed = baseFixed + monthTax + monthTemp;
                    final monthReste = netSalary - totalSavings - monthTotalFixed - totalDaily;
                    final isDeficit = monthReste < 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentSelected ? AppColors.accentCyan.withValues(alpha: 0.08) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentSelected ? AppColors.accentCyan : AppColors.borderSubtle,
                          width: isCurrentSelected ? 1.5 : 1.0,
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
                                  Text(
                                    periodLabel,
                                    style: TextStyle(
                                      color: isCurrentSelected ? AppColors.accentCyan : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (offset == 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('En cours', style: TextStyle(color: AppColors.accentEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDeficit
                                      ? AppColors.accentRose.withValues(alpha: 0.15)
                                      : (monthReste < 150 ? Colors.amber.withValues(alpha: 0.15) : AppColors.accentEmerald.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Reste : ${monthReste.toStringAsFixed(2)} €',
                                  style: TextStyle(
                                    color: isDeficit ? AppColors.accentRose : (monthReste < 150 ? Colors.amber : AppColors.accentEmerald),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Breakdown rows
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Salaire net :', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text('${netSalary.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Charges fixes socle :', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text('-${baseFixed.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          if (monthTax > 0 || monthTemp > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Échéances actives : ', style: TextStyle(color: AppColors.accentRose, fontSize: 11, fontWeight: FontWeight.w600)),
                                    Text(
                                      activeTempList.map((e) => e.label).join(', '),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                                Text('-${(monthTax + monthTemp).toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Épargne & Quotidien :', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text('-${(totalSavings + totalDaily).toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isDeficit)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentRose.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.accentRose,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                                  label: const Text('Arbitrer ce déficit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showArbitrageDialog(context, monthReste.abs(), netSalary, periodLabel: periodLabel);
                                  },
                                )
                              else
                                const SizedBox.shrink(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accentCyan,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: Text(isCurrentSelected ? 'Sélectionné' : 'Voir ce mois ➔', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() => _selectedForecastOffset = offset);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showArbitrageDialog(BuildContext context, double deficitAmount, double netSalary, {String? periodLabel}) {
    final peaIndex = _savingsCategories.indexWhere((c) => c.name.toLowerCase().contains('pea'));
    final peaItem = peaIndex != -1 ? _savingsCategories[peaIndex] : null;
    final currentPeaAmount = peaItem?.getEffectiveAmount(netSalary) ?? 0.0;
    final recommendedPeaAmount = (currentPeaAmount - deficitAmount).clamp(0.0, currentPeaAmount);
    final recommendedPeaPercent = netSalary > 0 ? (recommendedPeaAmount / netSalary * 100) : 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, color: AppColors.accentCyan, size: 22),
              const SizedBox(width: 10),
              Text(periodLabel != null ? 'Arbitrage $periodLabel' : 'Arbitrage Anti-Découvert', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Un déficit de -${deficitAmount.toStringAsFixed(2)} € est calculé${periodLabel != null ? " pour $periodLabel" : ""}.\n\nPour préserver votre reste à vivre et éviter tout découvert, vous pouvez ajuster temporairement votre épargne PEA :',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Épargne PEA Actuelle :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${currentPeaAmount.toStringAsFixed(2)} € (${peaItem?.amount.toStringAsFixed(1)}%)', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Absorption Déficit :', style: TextStyle(color: AppColors.accentRose, fontSize: 12)),
                        Text('-${deficitAmount.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PEA Modulé Recommandé :', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${recommendedPeaAmount.toStringAsFixed(2)} € (${recommendedPeaPercent.toStringAsFixed(1)}%)', style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.pop(ctx),
            ),
            if (peaItem != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: Colors.black),
                child: const Text('Appliquer l\'arbitrage', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    if (peaItem.isPercentage) {
                      peaItem.amount = double.parse(recommendedPeaPercent.toStringAsFixed(1));
                    } else {
                      peaItem.amount = double.parse(recommendedPeaAmount.toStringAsFixed(0));
                    }
                  });
                  _saveCategories();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Modulation appliquée : Cible PEA ajustée à ${peaItem.isPercentage ? "${peaItem.amount}%" : "${peaItem.amount}€"}.'),
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
        
        // Permanent clean up of any legacy 'Tampon' / 'Marge' from daily categories
        final initialDailyCount = _dailyCategories.length;
        _dailyCategories = _dailyCategories.where((c) {
          final l = c.name.toLowerCase();
          return !l.contains('tampon') && !l.contains('marge');
        }).toList();
        if (_dailyCategories.length != initialDailyCount) {
          _saveCategories();
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
    final noteController = TextEditingController(text: item.note ?? '');
    bool isPercentage = item.isPercentage;
    String selectedIcon = item.iconType;
    Color selectedColor = item.iconBgColor;

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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la catégorie',
                      ),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Sous-postes / Notes (optionnel)',
                        hintText: 'ex: Bouygues • Spotify • Netflix',
                      ),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    
                    // Icon & Color Picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Icône & Couleur', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'chart', 'shield', 'home', 'video', 'people', 'heart', 'card', 'category'
                            ].map((type) {
                              final IconData iconData = {
                                'chart': Icons.show_chart_rounded,
                                'shield': Icons.shield_rounded,
                                'home': Icons.home_rounded,
                                'video': Icons.ondemand_video_rounded,
                                'people': Icons.people_alt_rounded,
                                'heart': Icons.favorite_rounded,
                                'card': Icons.credit_card_rounded,
                                'category': Icons.category_rounded,
                              }[type]!;
                              final isSelected = type == selectedIcon;
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedIcon = type),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : AppColors.cardBackground,
                                    border: Border.all(color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(iconData, color: isSelected ? AppColors.accentCyan : AppColors.textMuted, size: 20),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AppColors.accentCyan, AppColors.accentPurple, AppColors.accentRose, AppColors.accentGold, AppColors.accentEmerald
                            ].map((color) {
                              final isSelected = color.value == selectedColor.value;
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedColor = color),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
                              onTap: () => setDialogState(() {
                                if (isPercentage) {
                                  isPercentage = false;
                                  final currentAmt = double.tryParse(amountController.text) ?? 0.0;
                                  amountController.text = (netSalary * currentAmt / 100).toStringAsFixed(0);
                                }
                              }),
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
                              onTap: () => setDialogState(() {
                                if (!isPercentage) {
                                  isPercentage = true;
                                  final currentAmt = double.tryParse(amountController.text) ?? 0.0;
                                  amountController.text = (netSalary > 0 ? (currentAmt / netSalary * 100) : 0.0).toStringAsFixed(1);
                                }
                              }),
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
                            if (isPercentage) ...[
                              const SizedBox(height: 8),
                              Slider(
                                value: inputNum.clamp(0.0, 100.0),
                                min: 0,
                                max: 100,
                                activeColor: AppColors.accentCyan,
                                inactiveColor: AppColors.borderSubtle,
                                onChanged: (newVal) {
                                  amountController.text = newVal.toStringAsFixed(1);
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isPercentage
                                        ? 'Équivalence exacte := ${calcVal.toStringAsFixed(2)} € / mois'
                                        : 'Équivalence exacte := ${calcVal.toStringAsFixed(1)} % du net',
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
                    final newNote = noteController.text.trim().isEmpty ? null : noteController.text.trim();
                    setState(() {
                      item.name = newName;
                      item.amount = newAmount;
                      item.note = newNote;
                      item.isPercentage = isPercentage;
                      item.iconType = selectedIcon;
                      item.iconBgColor = selectedColor;
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

  void _showTemporaryExpenseDialog(
    BuildContext context, {
    TemporaryExpense? expense,
    String? initialLabel,
    double? initialAmount,
    int? initialDurationMonths,
    String? initialStartPeriod,
    String? initialSuggestionId,
  }) {
    final isEditing = expense != null;
    final now = DateTime.now();
    final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
    final currentPeriodStr = initialStartPeriod ?? '${now.year}-$mStr';

    final labelCtrl = TextEditingController(text: isEditing ? expense.label : (initialLabel ?? 'Dentiste Couronne'));
    final amountCtrl = TextEditingController(text: isEditing ? expense.monthlyAmount.toStringAsFixed(2) : (initialAmount != null ? initialAmount.toStringAsFixed(2) : '164.50'));
    final startCtrl = TextEditingController(text: isEditing ? expense.startPeriod : currentPeriodStr);
    final durationCtrl = TextEditingController(text: isEditing ? expense.durationMonths.toString() : (initialDurationMonths != null ? initialDurationMonths.toString() : '12'));

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
                    if (initialSuggestionId != null) {
                      _ignoreSuggestion(initialSuggestionId);
                    }
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
  void _showEditBufferMultiplierDialog(BuildContext context, double currentMultiplier) {
    final multCtrl = TextEditingController(text: currentMultiplier.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.security_rounded, color: AppColors.accentEmerald, size: 22),
              SizedBox(width: 10),
              Text('Logique du Seuil de Sécurité', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Le seuil de sécurité est le montant recommandé à conserver sur votre compte courant pour éviter tout découvert imprévu. Il est calculé en multipliant vos charges fixes incompressibles.\n\nPar défaut, il est de 1.0x (un mois complet de charges fixes d\'avance).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: multCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Multiplicateur', suffixText: 'x', border: OutlineInputBorder()),
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
              child: const Text('Enregistrer'),
              onPressed: () {
                final val = double.tryParse(multCtrl.text.replaceAll(',', '.')) ?? currentMultiplier;
                ref.read(salaryProvider.notifier).updateBufferMultiplier(val);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildForecastHorizonSelector(SalaryState salary, double netSalary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.timeline_rounded, color: AppColors.accentCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'HORIZON PRÉVISIONNEL & SIMULATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showForecastMatrixModal(context, salary, netSalary),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.table_chart_rounded, size: 13, color: AppColors.accentCyan),
                      SizedBox(width: 4),
                      Text(
                        'Matrice 6 Mois',
                        style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (offset) {
                final d = _getDateForOffset(offset);
                final period = _getPeriodForOffset(offset);
                final isSelected = _selectedForecastOffset == offset;
                final monthShort = _getMonthShortName(d.month);

                final extraTax = salary.taxAdjustmentMonthlyForPeriod(period);
                final extraTemp = salary.temporaryExpensesMonthlyForPeriod(period);
                final totalExtra = extraTax + extraTemp;

                return GestureDetector(
                  onTap: () => setState(() => _selectedForecastOffset = offset),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentCyan.withValues(alpha: 0.18)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              offset == 0 ? '$monthShort (En cours)' : '$monthShort (M+$offset)',
                              style: TextStyle(
                                color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (offset == 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentEmerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (totalExtra > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accentRose.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${totalExtra.toStringAsFixed(0)} € échéances',
                              style: const TextStyle(color: AppColors.accentRose, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          const Text(
                            'Socle standard',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveArbitrageBanner(SalaryState salary, double netSalary, double resteAVivre, List<TemporaryExpense> activeTempList, String selectedPeriodLabel) {
    if (resteAVivre >= 0 && _selectedForecastOffset == 0) {
      return const SizedBox.shrink();
    }

    final isDeficit = resteAVivre < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDeficit ? AppColors.accentRose.withValues(alpha: 0.1) : AppColors.accentCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeficit ? AppColors.accentRose.withValues(alpha: 0.4) : AppColors.accentCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDeficit ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
            color: isDeficit ? AppColors.accentRose : AppColors.accentCyan,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDeficit ? 'Alerte Tension Prévisionnelle • $selectedPeriodLabel' : 'Anticipation Budgétaire • $selectedPeriodLabel',
                      style: TextStyle(
                        color: isDeficit ? AppColors.accentRose : AppColors.accentCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isDeficit)
                      InkWell(
                        onTap: () => _showArbitrageDialog(context, resteAVivre.abs(), netSalary, periodLabel: selectedPeriodLabel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Arbitrer PEA', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDeficit
                      ? 'Avec les charges et échéances actives (${activeTempList.map((e) => "${e.label} ${e.monthlyAmount.toStringAsFixed(0)}€").join(", ")}), votre reste à vivre est en déficit de -${resteAVivre.abs().toStringAsFixed(2)} €. Nous vous conseillons de réallouer temporairement votre épargne PEA.'
                      : 'Vue simulée pour $selectedPeriodLabel : Vos flux et échéances actives (${activeTempList.isNotEmpty ? activeTempList.map((e) => e.label).join(", ") : "Socle fixe"}) sont pris en compte.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryProvider);
    final baseRecord = salary.activeBaseline;
    final netSalary = baseRecord?.regularNetSalary ?? baseRecord?.netSalary ?? 2713.74;
    final extraAmount = baseRecord?.calculatedExtraAmount ?? 0.0;
    final hasBonus = extraAmount > 0;

    final selectedPeriod = _getPeriodForOffset(_selectedForecastOffset);
    final selectedDate = _getDateForOffset(_selectedForecastOffset);
    final selectedPeriodLabel = _getPeriodLabel(_selectedForecastOffset);

    final taxMonthly = salary.taxAdjustmentMonthlyForPeriod(selectedPeriod);
    final tempMonthly = salary.temporaryExpensesMonthlyForPeriod(selectedPeriod);
    final activeTempList = salary.getActiveTemporaryExpensesForPeriod(selectedPeriod);
    final activeTaxList = salary.getActiveTaxAdjustmentsForPeriod(selectedPeriod);

    final totalSavings = _savingsCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));
    final baseFixed = _fixedChargesCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));
    final totalFixed = baseFixed + taxMonthly + tempMonthly;
    final totalDaily = _dailyCategories.fold(0.0, (sum, c) => sum + c.getEffectiveAmount(netSalary));

    final resteAVivre = netSalary - totalSavings - totalFixed - totalDaily;

    final allTransactions = ref.watch(budgetProvider).transactions;
    final detectedSuggestions = BankingAnalyzerService.analyzeTransactions(
      transactions: allTransactions,
      existingExpenses: salary.temporaryExpenses,
      existingLabels: [
        ..._fixedChargesCategories.map((c) => c.name),
        ..._savingsCategories.map((c) => c.name),
        ..._dailyCategories.map((c) => c.name),
      ],
      ignoredIds: _ignoredDetectedTxIds,
    );

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

            const SizedBox(height: 16),

            // FORECAST HORIZON SELECTOR
            _buildForecastHorizonSelector(salary, netSalary),

            // PREDICTIVE ARBITRAGE ADVISOR BANNER (if deficit or future period)
            _buildPredictiveArbitrageBanner(salary, netSalary, resteAVivre, activeTempList, selectedPeriodLabel),

            // Sleek Dark Theme Card — RESTE À VIVRE & ALLOCATION GAUGE
            LayoutBuilder(builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 700;
              final bal = salary.accountBalance;
              final seuilSecurite = totalFixed * salary.bufferMultiplier; // Dynamic buffer based on fixed charges
              final lowerBound = seuilSecurite * 0.8;
              final upperBound = seuilSecurite * 1.2;

              final heroA = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedForecastOffset == 0
                              ? 'RESTE À VIVRE THÉORIQUE — MODÈLE MENSUEL'
                              : 'RESTE À VIVRE PRÉVISIONNEL — ${selectedPeriodLabel.toUpperCase()}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Modèle 50/30/20', style: TextStyle(color: AppColors.accentEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${resteAVivre.toStringAsFixed(2)} €',
                          style: TextStyle(
                            color: resteAVivre < 0 ? AppColors.accentRose : AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            '${(netSalary > 0 ? (resteAVivre / netSalary * 100) : 0).toStringAsFixed(1)} % du net récurrent',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedForecastOffset == 0
                          ? 'Marge mensuelle non allouée issue de votre salaire net (${netSalary.toStringAsFixed(2)} €), après déduction des charges fixes (${totalFixed.toStringAsFixed(2)} €), de l\'épargne (${totalSavings.toStringAsFixed(2)} €) et du quotidien (${totalDaily.toStringAsFixed(2)} €).'
                          : 'Simulation prévisionnelle pour ${_getMonthName(selectedDate.month)} ${selectedDate.year} : Salaire net (${netSalary.toStringAsFixed(2)} €) - Charges fixes (${baseFixed.toStringAsFixed(2)} €) - Échéances actives (${(taxMonthly + tempMonthly).toStringAsFixed(2)} €) - Épargne (${totalSavings.toStringAsFixed(2)} €) - Quotidien (${totalDaily.toStringAsFixed(2)} €).',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
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
                              Expanded(flex: ((resteAVivre.clamp(0.0, netSalary) / netSalary) * 100).round().clamp(0, 100), child: Container(color: AppColors.accentEmerald)),
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
                  border: Border.all(
                    color: bal < 0
                        ? AppColors.accentRose
                        : (bal < lowerBound ? Colors.amber : (bal > upperBound ? AppColors.accentGold : AppColors.accentEmerald)),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bal < 0
                            ? AppColors.accentRose.withValues(alpha: 0.15)
                            : (bal < lowerBound
                                ? Colors.amber.withValues(alpha: 0.15)
                                : (bal > upperBound ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.accentEmerald.withValues(alpha: 0.15))),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: bal < 0
                              ? AppColors.accentRose.withValues(alpha: 0.3)
                              : (bal < lowerBound
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : (bal > upperBound ? AppColors.accentGold.withValues(alpha: 0.3) : AppColors.accentEmerald.withValues(alpha: 0.3))),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bal < 0
                                ? Icons.warning_amber_rounded
                                : (bal < lowerBound ? Icons.info_outline_rounded : (bal > upperBound ? Icons.savings_outlined : Icons.check_circle_outline_rounded)),
                            color: bal < 0
                                ? AppColors.accentRose
                                : (bal < lowerBound ? Colors.amber : (bal > upperBound ? AppColors.accentGold : AppColors.accentEmerald)),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bal < 0
                                ? 'Découvert bancaire actuel'
                                : (bal < lowerBound ? 'Sous le matelas de sécurité' : (bal > upperBound ? 'Excédent de trésorerie' : 'Trésorerie sécurisée')),
                            style: TextStyle(
                              color: bal < 0
                                  ? AppColors.accentRose
                                  : (bal < lowerBound ? Colors.amber : (bal > upperBound ? AppColors.accentGold : AppColors.accentEmerald)),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SOLDE BANCAIRE RÉEL',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            salary.syncBankName != null ? '${salary.syncBankName} • Live' : 'BoursoBank Live',
                            style: const TextStyle(color: AppColors.accentEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${bal.toStringAsFixed(2)} €',
                          style: TextStyle(
                            color: bal < 0 ? AppColors.accentRose : AppColors.accentEmerald,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showEditBufferMultiplierDialog(context, salary.bufferMultiplier),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.settings_outlined, size: 14, color: AppColors.accentCyan),
                                const SizedBox(width: 6),
                                Text(
                                  'Seuil cible : ${salary.bufferMultiplier}x (${seuilSecurite.toStringAsFixed(0)} €)',
                                  style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (bal < 0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, color: AppColors.accentCyan, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Découvert de ${bal.abs().toStringAsFixed(2)} € : Vous pouvez moduler l\'épargne PEA pour résorber ce découvert.',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _showArbitrageDialog(context, bal.abs(), netSalary),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Arbitrer', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        'Solde réel instantané disponible sur votre compte bancaire synchronisé.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderSubtle)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            onPressed: () => _showEditAccountBalanceDialog(context, salary.accountBalance),
                            label: const Text('Corriger', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
                              foregroundColor: AppColors.accentCyan,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.4))),
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 14),
                            onPressed: () async {
                              final success = await ref.read(settingsProvider.notifier).syncTrueLayerData(ref);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Solde bancaire synchronisé depuis TrueLayer !'
                                          : 'Synchronisation bancaire effectuée.',
                                    ),
                                    backgroundColor: success ? AppColors.accentEmerald : AppColors.accentCyan,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            label: const Text('Synchro Directe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            if (detectedSuggestions.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.05),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radar_rounded, color: AppColors.accentCyan, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Radar Open Banking',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${detectedSuggestions.length} flux',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Des dépenses récurrentes ou échéances non déclarées ont été identifiées sur votre compte.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Examiner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showRadarModal(context, detectedSuggestions),
                    ),
                  ],
                ),
              ),
            ],

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
                      if (salary.temporaryExpenses.isNotEmpty)
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
                        final isActiveOnSelected = exp.isActiveForPeriod(selectedPeriod);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActiveOnSelected ? AppColors.accentCyan.withValues(alpha: 0.4) : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(exp.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActiveOnSelected ? AppColors.accentEmerald.withValues(alpha: 0.15) : AppColors.surface,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isActiveOnSelected ? AppColors.accentEmerald.withValues(alpha: 0.3) : AppColors.borderSubtle),
                                          ),
                                          child: Text(
                                            isActiveOnSelected ? 'Actif sur $selectedPeriod' : 'Inactif sur $selectedPeriod',
                                            style: TextStyle(
                                              color: isActiveOnSelected ? AppColors.accentEmerald : AppColors.textSecondary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
              extraWidget: (taxMonthly > 0 || tempMonthly > 0)
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          if (taxMonthly > 0)
                            Row(
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
                          if (taxMonthly > 0 && tempMonthly > 0) const SizedBox(height: 8),
                          if (tempMonthly > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: AppColors.accentRose, size: 18),
                                    const SizedBox(width: 10),
                                    Text('Échéances actives (${activeTempList.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Text('-${tempMonthly.toStringAsFixed(2)} €/mois', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.isPercentage ? '% Ratio' : '€ Fixe',
                              style: const TextStyle(
                                color: AppColors.accentCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.accentCyan),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.note!.trim(),
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

