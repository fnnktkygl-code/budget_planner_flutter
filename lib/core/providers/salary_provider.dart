import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/salary_record.dart';
import '../../models/tax_adjustment.dart';
import '../../services/salary_analyzer_service.dart';

class SalaryState {
  final List<SalaryRecord> records;
  final List<TaxAdjustment> taxAdjustments;

  SalaryState({
    required this.records,
    this.taxAdjustments = const [],
  });

  SalaryRecord? get activeBaseline => getActiveBaselineSalary(records);

  SalaryAnalytics get analytics => computeSalaryAnalytics(records);

  double get activeTaxAdjustmentMonthlyInstallment {
    double total = 0;
    for (var adj in taxAdjustments) {
      total += adj.monthlyInstallment;
    }
    return total;
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  SalaryNotifier() : super(SalaryState(records: [], taxAdjustments: [])) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('aura_salary_records_v3');
    final rawTaxJson = prefs.getString('aura_tax_adjustments_v1');

    List<SalaryRecord> list = [];
    List<TaxAdjustment> taxList = [];

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawJson);
        list = parsed.map((item) => SalaryRecord.fromJson(item)).toList();
        
        // Ensure sorted chronologically descending by period (newest month first)
        list.sort((a, b) => b.period.compareTo(a.period));
        
        // Ensure active baseline is assigned to the chronologically latest record if none explicitly set
        if (list.isNotEmpty && !list.any((r) => r.isLatestActive)) {
          list[0] = list[0].copyWith(isLatestActive: true);
        }

        state = SalaryState(records: list, taxAdjustments: state.taxAdjustments);
      } catch (_) {
        state = SalaryState(records: [], taxAdjustments: state.taxAdjustments);
      }
    } else {
      state = SalaryState(records: [], taxAdjustments: state.taxAdjustments);
      prefs.remove('aura_salary_records');
      prefs.remove('aura_salary_records_v2');
    }

    if (rawTaxJson != null && rawTaxJson.isNotEmpty) {
      try {
        final List<dynamic> parsedTax = jsonDecode(rawTaxJson);
        taxList = parsedTax.map((item) => TaxAdjustment.fromJson(item)).toList();
        state = SalaryState(records: list, taxAdjustments: taxList);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.records.map((r) => r.toJson()).toList());
    prefs.setString('aura_salary_records_v3', jsonStr);

    final taxJsonStr = jsonEncode(state.taxAdjustments.map((t) => t.toJson()).toList());
    prefs.setString('aura_tax_adjustments_v1', taxJsonStr);
  }

  void addRecord(SalaryRecord record) {
    List<SalaryRecord> updated = state.records.toList();

    // Remove any existing record matching the same id or period
    updated.removeWhere((r) => r.id == record.id || r.period == record.period);
    updated.add(record);

    // Sort chronologically descending by period (e.g. 2026-07 > 2026-03)
    updated.sort((a, b) => b.period.compareTo(a.period));

    // The chronologically latest record (index 0) ALWAYS becomes the active baseline
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(isLatestActive: i == 0);
    }

    state = SalaryState(records: updated);
    _save();
  }

  void addMultipleRecords(List<SalaryRecord> newRecords) {
    if (newRecords.isEmpty) return;

    List<SalaryRecord> updated = state.records.toList();

    for (var r in newRecords) {
      updated.removeWhere((existing) => existing.id == r.id || existing.period == r.period);
      updated.add(r);
    }

    // Sort chronologically descending by period (e.g. 2026-07 > 2026-03)
    updated.sort((a, b) => b.period.compareTo(a.period));

    // The chronologically latest record (index 0) ALWAYS becomes the active baseline
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(isLatestActive: i == 0);
    }

    state = SalaryState(records: updated);
    _save();
  }

  void updateRecord(SalaryRecord record) {
    List<SalaryRecord> updated = List.from(state.records);
    if (record.isLatestActive) {
      updated = updated.map((r) => r.copyWith(isLatestActive: false)).toList();
    }
    final idx = updated.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      updated[idx] = record;
      
      // Ensure sorted descending
      updated.sort((a, b) => b.period.compareTo(a.period));
      
      state = SalaryState(records: updated);
      _save();
    }
  }

  void deleteRecord(String id) {
    final updated = state.records.where((r) => r.id != id).toList();
    updated.sort((a, b) => b.period.compareTo(a.period));

    // If active baseline was deleted, make the chronologically latest remaining record active
    if (updated.isNotEmpty && !updated.any((r) => r.isLatestActive)) {
      updated[0] = updated[0].copyWith(isLatestActive: true);
    }

    state = SalaryState(records: updated);
    _save();
  }

  void setActiveBaseline(String id) {
    final updated = state.records.map((r) => r.copyWith(isLatestActive: r.id == id)).toList();
    state = SalaryState(records: updated);
    _save();
  }

  void addTaxAdjustment(TaxAdjustment adjustment) {
    final updated = state.taxAdjustments.where((t) => t.id != adjustment.id).toList();
    updated.add(adjustment);
    state = SalaryState(records: state.records, taxAdjustments: updated);
    _save();
  }

  void deleteTaxAdjustment(String id) {
    final updated = state.taxAdjustments.where((t) => t.id != id).toList();
    state = SalaryState(records: state.records, taxAdjustments: updated);
    _save();
  }

  void clearAllRecords() async {
    state = SalaryState(records: [], taxAdjustments: []);
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('aura_salary_records_v3');
    prefs.remove('aura_salary_records_v2');
    prefs.remove('aura_salary_records');
    prefs.remove('aura_tax_adjustments_v1');
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  return SalaryNotifier();
});
