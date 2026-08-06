import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/salary_record.dart';
import '../../services/salary_analyzer_service.dart';

class SalaryState {
  final List<SalaryRecord> records;

  SalaryState({required this.records});

  SalaryRecord? get activeBaseline => getActiveBaselineSalary(records);

  SalaryAnalytics get analytics => computeSalaryAnalytics(records);
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  SalaryNotifier() : super(SalaryState(records: [])) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('aura_salary_records_v3');
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawJson);
        final list = parsed.map((item) => SalaryRecord.fromJson(item)).toList();
        state = SalaryState(records: list);
      } catch (_) {
        state = SalaryState(records: []);
      }
    } else {
      state = SalaryState(records: []);
      prefs.remove('aura_salary_records');
      prefs.remove('aura_salary_records_v2');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.records.map((r) => r.toJson()).toList());
    prefs.setString('aura_salary_records_v3', jsonStr);
  }

  void addRecord(SalaryRecord record) {
    // Preserve ALL existing records, set isLatestActive to false for older entries
    List<SalaryRecord> updated = state.records
        .map((r) => r.copyWith(isLatestActive: false))
        .toList();

    // Remove any duplicate period entry
    updated.removeWhere((r) => r.id == record.id);

    final activeRecord = record.copyWith(isLatestActive: true);
    updated.add(activeRecord);

    // Sort descending by period
    updated.sort((a, b) => b.period.compareTo(a.period));

    state = SalaryState(records: updated);
    _save();
  }

  void addMultipleRecords(List<SalaryRecord> newRecords) {
    if (newRecords.isEmpty) return;

    List<SalaryRecord> updated = state.records
        .map((r) => r.copyWith(isLatestActive: false))
        .toList();

    for (var r in newRecords) {
      updated.removeWhere((existing) => existing.id == r.id);
      updated.add(r.copyWith(isLatestActive: false));
    }

    // Set the latest chronological record as active baseline
    updated.sort((a, b) => b.period.compareTo(a.period));
    if (updated.isNotEmpty) {
      updated[0] = updated[0].copyWith(isLatestActive: true);
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
      state = SalaryState(records: updated);
      _save();
    }
  }

  void deleteRecord(String id) {
    final updated = state.records.where((r) => r.id != id).toList();
    state = SalaryState(records: updated);
    _save();
  }

  void setActiveBaseline(String id) {
    final updated = state.records.map((r) => r.copyWith(isLatestActive: r.id == id)).toList();
    state = SalaryState(records: updated);
    _save();
  }

  void clearAllRecords() async {
    state = SalaryState(records: []);
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('aura_salary_records_v3');
    prefs.remove('aura_salary_records_v2');
    prefs.remove('aura_salary_records');
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  return SalaryNotifier();
});
