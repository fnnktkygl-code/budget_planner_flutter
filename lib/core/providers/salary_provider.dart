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
  SalaryNotifier() : super(SalaryState(records: defaultSalaryRecords)) {
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('aura_salary_records');
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(rawJson);
        final list = parsed.map((item) => SalaryRecord.fromJson(item)).toList();
        state = SalaryState(records: list);
      } catch (_) {
        state = SalaryState(records: List.from(defaultSalaryRecords));
      }
    } else {
      state = SalaryState(records: List.from(defaultSalaryRecords));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.records.map((r) => r.toJson()).toList());
    prefs.setString('aura_salary_records', jsonStr);
  }

  void addRecord(SalaryRecord record) {
    List<SalaryRecord> updated = List.from(state.records);
    if (record.isLatestActive) {
      updated = updated.map((r) => r.copyWith(isLatestActive: false)).toList();
    }
    updated.add(record);
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
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  return SalaryNotifier();
});
