import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Journal d'audit temporel immuable des modifications budgétaires.
/// Consigne chaque ajout, cumul arithmétique, écrasement radar, édition manuelle,
/// suppression ou arbitrage prévisionnel afin de garantir une traçabilité totale.
class BudgetAuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actionType; // 'cumul', 'overwrite', 'manual_edit', 'add', 'delete', 'arbitrage'
  final String categoryName;
  final String pillar; // 'Épargne & Investissement', 'Charges Fixes', 'Dépenses Quotidiennes', 'Arbitrage Global'
  final double? previousAmount;
  final bool? previousIsPercentage;
  final double? newAmount;
  final bool? newIsPercentage;
  final double effectiveDeltaEuro; // +/- X €
  final String? note;
  final String? period; // ex: "2026-09"

  BudgetAuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.categoryName,
    required this.pillar,
    this.previousAmount,
    this.previousIsPercentage,
    this.newAmount,
    this.newIsPercentage,
    this.effectiveDeltaEuro = 0.0,
    this.note,
    this.period,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'actionType': actionType,
        'categoryName': categoryName,
        'pillar': pillar,
        'previousAmount': previousAmount,
        'previousIsPercentage': previousIsPercentage,
        'newAmount': newAmount,
        'newIsPercentage': newIsPercentage,
        'effectiveDeltaEuro': effectiveDeltaEuro,
        'note': note,
        'period': period,
      };

  factory BudgetAuditLogEntry.fromJson(Map<String, dynamic> json) => BudgetAuditLogEntry(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        actionType: json['actionType'] as String? ?? 'manual_edit',
        categoryName: json['categoryName'] as String? ?? '',
        pillar: json['pillar'] as String? ?? 'Budget',
        previousAmount: (json['previousAmount'] as num?)?.toDouble(),
        previousIsPercentage: json['previousIsPercentage'] as bool?,
        newAmount: (json['newAmount'] as num?)?.toDouble(),
        newIsPercentage: json['newIsPercentage'] as bool?,
        effectiveDeltaEuro: (json['effectiveDeltaEuro'] as num?)?.toDouble() ?? 0.0,
        note: json['note'] as String?,
        period: json['period'] as String?,
      );

  String get actionLabel {
    switch (actionType) {
      case 'cumul':
        return 'Cumul Arithmétique';
      case 'overwrite':
        return 'Écrasement Radar';
      case 'arbitrage':
        return 'Arbitrage Prévisionnel';
      case 'manual_edit':
        return 'Modification Manuelle';
      case 'add':
        return 'Nouvelle Catégorie';
      case 'delete':
        return 'Suppression';
      default:
        return 'Mise à jour';
    }
  }

  IconData get actionIcon {
    switch (actionType) {
      case 'cumul':
        return Icons.add_circle_outline_rounded;
      case 'overwrite':
        return Icons.bolt_rounded;
      case 'arbitrage':
        return Icons.balance_rounded;
      case 'manual_edit':
        return Icons.edit_rounded;
      case 'add':
        return Icons.playlist_add_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color get actionColor {
    switch (actionType) {
      case 'cumul':
        return AppColors.accentEmerald;
      case 'overwrite':
        return AppColors.accentGold;
      case 'arbitrage':
        return AppColors.accentCyan;
      case 'manual_edit':
        return AppColors.accentPurple;
      case 'add':
        return Colors.blue;
      case 'delete':
        return AppColors.accentRose;
      default:
        return AppColors.textSecondary;
    }
  }
}
