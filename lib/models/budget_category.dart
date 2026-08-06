class BudgetCategory {
  final String id;
  final String name;
  final double allocatedAmount;
  final double spentAmount;
  final String iconName;
  final String colorHex;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.iconName,
    required this.colorHex,
  });

  double get remaining => allocatedAmount - spentAmount;
  double get percentUsed => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'allocatedAmount': allocatedAmount,
        'spentAmount': spentAmount,
        'iconName': iconName,
        'colorHex': colorHex,
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'],
        name: json['name'],
        allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
        spentAmount: (json['spentAmount'] as num).toDouble(),
        iconName: json['iconName'] ?? 'category',
        colorHex: json['colorHex'] ?? '#06B6D4',
      );
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'isIncome': isIncome,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        category: json['category'],
        isIncome: json['isIncome'] ?? false,
      );
}
