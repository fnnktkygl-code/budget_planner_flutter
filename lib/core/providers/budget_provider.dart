import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/budget_category.dart';

class BudgetState {
  final List<BudgetCategory> categories;
  final List<TransactionItem> transactions;
  final double emergencyFundTargetMonths;
  final double monthlyFixedExpenses;

  BudgetState({
    required this.categories,
    required this.transactions,
    required this.emergencyFundTargetMonths,
    required this.monthlyFixedExpenses,
  });

  BudgetState copyWith({
    List<BudgetCategory>? categories,
    List<TransactionItem>? transactions,
    double? emergencyFundTargetMonths,
    double? monthlyFixedExpenses,
  }) {
    return BudgetState(
      categories: categories ?? this.categories,
      transactions: transactions ?? this.transactions,
      emergencyFundTargetMonths: emergencyFundTargetMonths ?? this.emergencyFundTargetMonths,
      monthlyFixedExpenses: monthlyFixedExpenses ?? this.monthlyFixedExpenses,
    );
  }

  double get totalAllocated => categories.fold(0.0, (sum, c) => sum + c.allocatedAmount);
  double get totalSpent => categories.fold(0.0, (sum, c) => sum + c.spentAmount);
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier()
      : super(BudgetState(
          categories: defaultCategories,
          transactions: defaultTransactions,
          emergencyFundTargetMonths: 6,
          monthlyFixedExpenses: 1850,
        )) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCat = prefs.getString('aura_categories');
    final rawTx = prefs.getString('aura_transactions');
    final months = prefs.getDouble('aura_emergency_months') ?? 6.0;
    final fixed = prefs.getDouble('aura_fixed_expenses') ?? 1850.0;

    List<BudgetCategory> catList = defaultCategories;
    if (rawCat != null && rawCat.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawCat);
        catList = parsed.map((item) => BudgetCategory.fromJson(item)).toList();
      } catch (_) {}
    }

    List<TransactionItem> txList = defaultTransactions;
    if (rawTx != null && rawTx.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawTx);
        txList = parsed.map((item) => TransactionItem.fromJson(item)).toList();
      } catch (_) {}
    }

    state = BudgetState(
      categories: catList,
      transactions: txList,
      emergencyFundTargetMonths: months,
      monthlyFixedExpenses: fixed,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('aura_categories', jsonEncode(state.categories.map((c) => c.toJson()).toList()));
    prefs.setString('aura_transactions', jsonEncode(state.transactions.map((t) => t.toJson()).toList()));
    prefs.setDouble('aura_emergency_months', state.emergencyFundTargetMonths);
    prefs.setDouble('aura_fixed_expenses', state.monthlyFixedExpenses);
  }

  void addTransaction(TransactionItem item) {
    final updatedTx = [item, ...state.transactions];
    state = state.copyWith(transactions: updatedTx);
    _save();
  }

  void setTransactions(List<TransactionItem> items) {
    state = state.copyWith(transactions: items);
    _save();
  }

  void updateCategory(BudgetCategory category) {
    final idx = state.categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      final updated = List<BudgetCategory>.from(state.categories);
      updated[idx] = category;
      state = state.copyWith(categories: updated);
      _save();
    }
  }

  void setEmergencyMonths(double months) {
    state = state.copyWith(emergencyFundTargetMonths: months);
    _save();
  }

  void setFixedExpenses(double expenses) {
    state = state.copyWith(monthlyFixedExpenses: expenses);
    _save();
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier();
});

final List<BudgetCategory> defaultCategories = [
  BudgetCategory(id: 'cat-1', name: 'Logement & Loyer', allocatedAmount: 1100, spentAmount: 1100, iconName: 'home', colorHex: '#06B6D4'),
  BudgetCategory(id: 'cat-2', name: 'Alimentation & Courses', allocatedAmount: 500, spentAmount: 380, iconName: 'shopping_cart', colorHex: '#10B981'),
  BudgetCategory(id: 'cat-3', name: 'Transports & Véhicule', allocatedAmount: 250, spentAmount: 190, iconName: 'directions_car', colorHex: '#F59E0B'),
  BudgetCategory(id: 'cat-4', name: 'Loisirs & Sorties', allocatedAmount: 400, spentAmount: 280, iconName: 'sports_esports', colorHex: '#EC4899'),
  BudgetCategory(id: 'cat-5', name: 'Épargne & Investissement (DCA)', allocatedAmount: 1200, spentAmount: 1200, iconName: 'savings', colorHex: '#8B5CF6'),
];

final List<TransactionItem> defaultTransactions = [
  TransactionItem(id: 'tx-1', title: 'Virement Salaire Juin 2026', amount: 3850, date: DateTime(2026, 6, 28), category: 'Revenu', isIncome: true),
  TransactionItem(id: 'tx-2', title: 'Prélèvement Loyer Juin', amount: 1100, date: DateTime(2026, 6, 30), category: 'Logement', isIncome: false),
  TransactionItem(id: 'tx-3', title: 'Virement DCA PEA & ETF World', amount: 1200, date: DateTime(2026, 7, 1), category: 'Épargne', isIncome: false),
  TransactionItem(id: 'tx-4', title: 'Courses Carrefour', amount: 142.50, date: DateTime(2026, 7, 3), category: 'Alimentation', isIncome: false),
];
