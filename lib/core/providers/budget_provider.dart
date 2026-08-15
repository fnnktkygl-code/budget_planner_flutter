import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/budget_category.dart';
import 'auth_provider.dart';

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
  final String userId;

  BudgetNotifier({required this.userId})
      : super(BudgetState(
          categories: defaultCategories,
          transactions: defaultTransactions,
          emergencyFundTargetMonths: 6,
          monthlyFixedExpenses: 1850,
        )) {
    if (userId.isNotEmpty) {
      init();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCat = prefs.getString('${userId}_aura_categories');
    final rawTx = prefs.getString('${userId}_aura_transactions');
    final months = prefs.getDouble('${userId}_aura_emergency_months') ?? 6.0;
    final fixed = prefs.getDouble('${userId}_aura_fixed_expenses') ?? 1850.0;

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
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('${userId}_aura_categories', jsonEncode(state.categories.map((c) => c.toJson()).toList()));
    prefs.setString('${userId}_aura_transactions', jsonEncode(state.transactions.map((t) => t.toJson()).toList()));
    prefs.setDouble('${userId}_aura_emergency_months', state.emergencyFundTargetMonths);
    prefs.setDouble('${userId}_aura_fixed_expenses', state.monthlyFixedExpenses);
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
  final authState = ref.watch(authProvider);
  return BudgetNotifier(userId: authState.user?.id ?? '');
});

final List<BudgetCategory> defaultCategories = [
  BudgetCategory(id: 'cat-1', name: 'Logement & Loyer', allocatedAmount: 0, spentAmount: 0, iconName: 'home', colorHex: '#06B6D4'),
  BudgetCategory(id: 'cat-2', name: 'Alimentation & Courses', allocatedAmount: 0, spentAmount: 0, iconName: 'shopping_cart', colorHex: '#10B981'),
  BudgetCategory(id: 'cat-3', name: 'Transports & Véhicule', allocatedAmount: 0, spentAmount: 0, iconName: 'directions_car', colorHex: '#F59E0B'),
  BudgetCategory(id: 'cat-4', name: 'Loisirs & Sorties', allocatedAmount: 0, spentAmount: 0, iconName: 'sports_esports', colorHex: '#EC4899'),
  BudgetCategory(id: 'cat-5', name: 'Épargne & Investissement (DCA)', allocatedAmount: 0, spentAmount: 0, iconName: 'savings', colorHex: '#8B5CF6'),
];

final List<TransactionItem> defaultTransactions = [];
