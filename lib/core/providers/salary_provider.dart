import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/salary_record.dart';
import '../../models/tax_adjustment.dart';
import '../../models/temporary_expense.dart';
import '../../services/salary_analyzer_service.dart';
import 'auth_provider.dart';

import '../../services/indexed_db_service.dart';

class SalaryState {
  final List<SalaryRecord> records;
  final List<TaxAdjustment> taxAdjustments;
  final List<TemporaryExpense> temporaryExpenses;
  final double accountBalance;

  SalaryState({
    required this.records,
    this.taxAdjustments = const [],
    this.temporaryExpenses = const [],
    this.accountBalance = 1740.0,
  });

  SalaryRecord? get activeBaseline => getActiveBaselineSalary(records);

  SalaryAnalytics get analytics => computeSalaryAnalytics(records);

  double get activeTaxAdjustmentMonthlyInstallment {
    double total = 0;
    final now = DateTime.now();
    final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
    final currentPeriod = '${now.year}-$mStr';

    for (var adj in taxAdjustments) {
      if (adj.isActiveForPeriod(currentPeriod)) {
        total += adj.monthlyInstallment;
      }
    }
    return total;
  }

  double get activeTemporaryExpensesMonthlyTotal {
    double total = 0;
    final now = DateTime.now();
    final mStr = now.month < 10 ? '0${now.month}' : '${now.month}';
    final currentPeriod = '${now.year}-$mStr';

    for (var exp in temporaryExpenses) {
      if (exp.isActiveForPeriod(currentPeriod)) {
        total += exp.monthlyAmount;
      }
    }
    return total;
  }

  SalaryState copyWith({
    List<SalaryRecord>? records,
    List<TaxAdjustment>? taxAdjustments,
    List<TemporaryExpense>? temporaryExpenses,
    double? accountBalance,
  }) {
    return SalaryState(
      records: records ?? this.records,
      taxAdjustments: taxAdjustments ?? this.taxAdjustments,
      temporaryExpenses: temporaryExpenses ?? this.temporaryExpenses,
      accountBalance: accountBalance ?? this.accountBalance,
    );
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  final String userId;
  Timer? _indexedDbDebounceTimer;

  SalaryNotifier({required this.userId}) : super(SalaryState(records: [], taxAdjustments: [], temporaryExpenses: [])) {
    if (userId.isNotEmpty) {
      init();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Multi-key Migration Fallback (v3 -> v2 -> v1 -> default)
    String? rawJson = prefs.getString('${userId}_aura_salary_records_v3');
    if (rawJson == null || rawJson.isEmpty) {
      rawJson = prefs.getString('${userId}_aura_salary_records_v2') ?? prefs.getString('${userId}_aura_salary_records');
    }

    final rawTaxJson = prefs.getString('${userId}_aura_tax_adjustments_v1');
    final rawTempJson = prefs.getString('${userId}_aura_temporary_expenses_v1');
    final savedBalance = prefs.getDouble('${userId}_aura_account_balance_v1') ?? 1740.0;

    List<SalaryRecord> list = [];
    List<TaxAdjustment> taxList = [];
    List<TemporaryExpense> tempList = [];

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawJson);
        list = parsed.map((item) => SalaryRecord.fromJson(item)).toList();
        list.sort((a, b) => b.period.compareTo(a.period));

        if (list.isNotEmpty && !list.any((r) => r.isLatestActive)) {
          list[0] = list[0].copyWith(isLatestActive: true);
        }
      } catch (_) {}
    }

    // Attempt to load full records with PDF images from Web IndexedDB
    if (kIsWeb) {
      try {
        final fullRecords = await IndexedDbService.loadFullRecords(userId);
        if (fullRecords != null && fullRecords.isNotEmpty) {
          list = fullRecords;
          list.sort((a, b) => b.period.compareTo(a.period));
        }
      } catch (e) {
        debugPrint('[SalaryNotifier] IndexedDB load exception: $e');
      }
    }

    if (rawTaxJson != null && rawTaxJson.isNotEmpty) {
      try {
        final List<dynamic> parsedTax = jsonDecode(rawTaxJson);
        final rawTaxList = parsedTax.map((item) => TaxAdjustment.fromJson(item)).toList();
        final Map<int, TaxAdjustment> uniqueByYear = {};
        for (var t in rawTaxList) {
          uniqueByYear[t.taxYear] = t;
        }
        taxList = uniqueByYear.values.toList();
      } catch (_) {}
    }

    if (rawTempJson != null && rawTempJson.isNotEmpty) {
      try {
        final List<dynamic> parsedTemp = jsonDecode(rawTempJson);
        tempList = parsedTemp.map((item) => TemporaryExpense.fromJson(item)).toList();
      } catch (_) {}
    }

    state = SalaryState(
      records: list,
      taxAdjustments: taxList,
      temporaryExpenses: tempList,
      accountBalance: savedBalance,
    );

    // Save to ensure v3 and IndexedDB are populated
    _save();
  }

  String exportAppDataJson() {
    final data = {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'accountBalance': state.accountBalance,
      'records': state.records.map((r) => r.toJson(includeBinary: true)).toList(),
      'taxAdjustments': state.taxAdjustments.map((t) => t.toJson()).toList(),
      'temporaryExpenses': state.temporaryExpenses.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  bool importAppDataJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<dynamic> rParsed = data['records'] ?? [];
      final List<dynamic> tParsed = data['taxAdjustments'] ?? [];
      final List<dynamic> eParsed = data['temporaryExpenses'] ?? [];
      final double balance = (data['accountBalance'] as num?)?.toDouble() ?? 1740.0;

      final rList = rParsed.map((item) => SalaryRecord.fromJson(item)).toList();
      final tList = tParsed.map((item) => TaxAdjustment.fromJson(item)).toList();
      final eList = eParsed.map((item) => TemporaryExpense.fromJson(item)).toList();

      rList.sort((a, b) => b.period.compareTo(a.period));

      if (rList.isNotEmpty && !rList.any((r) => r.isLatestActive)) {
        rList[0] = rList[0].copyWith(isLatestActive: true);
      }

      state = SalaryState(
        records: rList,
        taxAdjustments: tList,
        temporaryExpenses: eList,
        accountBalance: balance,
      );

      _save();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _save({bool saveHeavyBinaries = false}) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save lightweight financial JSON to SharedPreferences (Ultra-fast, < 1ms)
      final cleanJsonStr = jsonEncode(state.records.map((r) => r.toJson(includeBinary: false)).toList());
      await prefs.setString('${userId}_aura_salary_records_v3', cleanJsonStr);

      final taxJsonStr = jsonEncode(state.taxAdjustments.map((t) => t.toJson()).toList());
      await prefs.setString('${userId}_aura_tax_adjustments_v1', taxJsonStr);

      final tempJsonStr = jsonEncode(state.temporaryExpenses.map((e) => e.toJson()).toList());
      await prefs.setString('${userId}_aura_temporary_expenses_v1', tempJsonStr);

      await prefs.setDouble('${userId}_aura_account_balance_v1', state.accountBalance);

      // Heavy IndexedDB binary save: Debounced in background so UI thread NEVER freezes!
      if (kIsWeb && state.records.isNotEmpty && saveHeavyBinaries) {
        _indexedDbDebounceTimer?.cancel();
        _indexedDbDebounceTimer = Timer(const Duration(seconds: 2), () {
          IndexedDbService.saveFullRecords(state.records, userId);
        });
      }
    } catch (e) {
      debugPrint('[SalaryNotifier] Save exception: $e');
    }
  }

  void addRecord(SalaryRecord record) {
    List<SalaryRecord> updated = state.records.toList();

    updated.removeWhere((r) => r.id == record.id || r.period == record.period);
    updated.add(record);
    updated.sort((a, b) => b.period.compareTo(a.period));

    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(isLatestActive: i == 0);
    }

    state = state.copyWith(records: updated);
    _save(saveHeavyBinaries: true);
  }

  void addMultipleRecords(List<SalaryRecord> newRecords) {
    if (newRecords.isEmpty) return;

    List<SalaryRecord> updated = state.records.toList();

    for (var r in newRecords) {
      updated.removeWhere((existing) => existing.id == r.id || existing.period == r.period);
      updated.add(r);
    }

    updated.sort((a, b) => b.period.compareTo(a.period));

    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(isLatestActive: i == 0);
    }

    state = state.copyWith(records: updated);
    _save(saveHeavyBinaries: true);
  }

  void updateRecord(SalaryRecord record) {
    List<SalaryRecord> updated = List.from(state.records);
    if (record.isLatestActive) {
      updated = updated.map((r) => r.copyWith(isLatestActive: false)).toList();
    }
    final idx = updated.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      updated[idx] = record;
      updated.sort((a, b) => b.period.compareTo(a.period));
      state = state.copyWith(records: updated);
      _save(saveHeavyBinaries: true);
    }
  }

  void deleteRecord(String id) {
    final updated = state.records.where((r) => r.id != id).toList();
    updated.sort((a, b) => b.period.compareTo(a.period));

    if (updated.isNotEmpty && !updated.any((r) => r.isLatestActive)) {
      updated[0] = updated[0].copyWith(isLatestActive: true);
    }

    state = state.copyWith(records: updated);
    _save(saveHeavyBinaries: true);
  }

  void setActiveBaseline(String id) {
    final updated = state.records.map((r) => r.copyWith(isLatestActive: r.id == id)).toList();
    state = state.copyWith(records: updated);
    _save();
  }

  void addTaxAdjustment(TaxAdjustment adjustment) {
    final updated = state.taxAdjustments.where((t) => t.id != adjustment.id && t.taxYear != adjustment.taxYear).toList();
    updated.add(adjustment);
    state = state.copyWith(taxAdjustments: updated);
    _save();
  }

  void deleteTaxAdjustment(String id) {
    final updated = state.taxAdjustments.where((t) => t.id != id).toList();
    state = state.copyWith(taxAdjustments: updated);
    _save();
  }

  void clearTaxAdjustments() {
    state = state.copyWith(taxAdjustments: []);
    _save();
  }

  void addTemporaryExpense(TemporaryExpense expense) {
    final updated = state.temporaryExpenses.where((e) => e.id != expense.id).toList();
    updated.add(expense);
    state = state.copyWith(temporaryExpenses: updated);
    _save();
  }

  void deleteTemporaryExpense(String id) {
    final updated = state.temporaryExpenses.where((e) => e.id != id).toList();
    state = state.copyWith(temporaryExpenses: updated);
    _save();
  }

  void updateAccountBalance(double balance) {
    state = state.copyWith(accountBalance: balance);
    _save();
  }

  void clearAllRecords() async {
    state = SalaryState(records: [], taxAdjustments: [], temporaryExpenses: [], accountBalance: 1740.0);
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('${userId}_aura_salary_records_v3');
    prefs.remove('${userId}_aura_salary_records_v2');
    prefs.remove('${userId}_aura_salary_records');
    prefs.remove('${userId}_aura_tax_adjustments_v1');
    prefs.remove('${userId}_aura_temporary_expenses_v1');
    prefs.remove('${userId}_aura_account_balance_v1');
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  final authState = ref.watch(authProvider);
  return SalaryNotifier(userId: authState.user?.id ?? '');
});
