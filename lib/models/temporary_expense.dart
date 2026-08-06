import 'dart:convert';

class TemporaryExpense {
  final String id;
  final String label;
  final double monthlyAmount;
  final String startPeriod; // YYYY-MM e.g. "2026-06"
  final int durationMonths; // e.g. 12
  final String category; // e.g. "Santé", "Équipement", "Impôts"

  TemporaryExpense({
    required this.id,
    required this.label,
    required this.monthlyAmount,
    required this.startPeriod,
    required this.durationMonths,
    this.category = 'Exceptionnel',
  });

  /// Calculates end period label YYYY-MM
  String get endPeriod {
    try {
      final parts = startPeriod.split('-');
      if (parts.length < 2) return startPeriod;
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);

      int totalMonths = month - 1 + durationMonths - 1;
      int endYear = year + (totalMonths ~/ 12);
      int endMonth = (totalMonths % 12) + 1;

      final mStr = endMonth < 10 ? '0$endMonth' : '$endMonth';
      return '$endYear-$mStr';
    } catch (_) {
      return startPeriod;
    }
  }

  /// Checks if this expense is active during a given period YYYY-MM
  bool isActiveForPeriod(String period) {
    return period.compareTo(startPeriod) >= 0 && period.compareTo(endPeriod) <= 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'monthlyAmount': monthlyAmount,
      'startPeriod': startPeriod,
      'durationMonths': durationMonths,
      'category': category,
    };
  }

  factory TemporaryExpense.fromJson(Map<String, dynamic> json) {
    return TemporaryExpense(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Dépense temporaire',
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
      startPeriod: json['startPeriod'] ?? '2026-06',
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 12,
      category: json['category'] ?? 'Exceptionnel',
    );
  }

  String toRawJson() => jsonEncode(toJson());

  factory TemporaryExpense.fromRawJson(String str) => TemporaryExpense.fromJson(jsonDecode(str));
}
