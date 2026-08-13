import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';

// --- MODELS ---

class BonusDestination {
  final String id;
  final String name;
  final String iconName;
  final Color color;
  final double total;

  BonusDestination({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.total,
  });

  factory BonusDestination.fromJson(Map<String, dynamic> json) {
    return BonusDestination(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String? ?? 'wallet',
      color: Color(json['colorValue'] as int? ?? AppColors.accentCyan.value),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorValue': color.value,
        'total': total,
      };

  BonusDestination copyWith({
    String? id,
    String? name,
    String? iconName,
    Color? color,
    double? total,
  }) {
    return BonusDestination(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      total: total ?? this.total,
    );
  }
}

class BonusBreakdown {
  final String destId;
  final double pct;

  BonusBreakdown({required this.destId, required this.pct});

  factory BonusBreakdown.fromJson(Map<String, dynamic> json) {
    return BonusBreakdown(
      destId: json['destId'] as String,
      pct: (json['pct'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'destId': destId,
        'pct': pct,
      };
}

class BonusEvent {
  final String id;
  final String label;
  final double amount;
  final DateTime date;
  final String source; // 'auto' or 'manual'
  final String iconName; // 'gift', 'banknote', 'wallet', 'business'
  final bool isVentilated;
  final List<BonusBreakdown> breakdown;

  BonusEvent({
    required this.id,
    required this.label,
    required this.amount,
    required this.date,
    required this.source,
    required this.iconName,
    this.isVentilated = false,
    this.breakdown = const [],
  });

  factory BonusEvent.fromJson(Map<String, dynamic> json) {
    return BonusEvent(
      id: json['id'] as String,
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      source: json['source'] as String? ?? 'manual',
      iconName: json['iconName'] as String? ?? 'gift',
      isVentilated: json['isVentilated'] as bool? ?? false,
      breakdown: (json['breakdown'] as List<dynamic>?)
              ?.map((e) => BonusBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'date': date.toIso8601String(),
        'source': source,
        'iconName': iconName,
        'isVentilated': isVentilated,
        'breakdown': breakdown.map((e) => e.toJson()).toList(),
      };

  BonusEvent copyWith({
    String? id,
    String? label,
    double? amount,
    DateTime? date,
    String? source,
    String? iconName,
    bool? isVentilated,
    List<BonusBreakdown>? breakdown,
  }) {
    return BonusEvent(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      iconName: iconName ?? this.iconName,
      isVentilated: isVentilated ?? this.isVentilated,
      breakdown: breakdown ?? this.breakdown,
    );
  }
}

class BonusState {
  final List<BonusDestination> destinations;
  final List<BonusEvent> events; // Both pending and ventilated (Funnel events)
  final List<BonusEvent> peeEvents; // PEE additions history
  final double peeTotal;

  BonusState({
    required this.destinations,
    required this.events,
    required this.peeEvents,
    required this.peeTotal,
  });

  List<BonusEvent> get pending => events.where((e) => !e.isVentilated).toList();
  List<BonusEvent> get history => events.where((e) => e.isVentilated).toList();

  BonusState copyWith({
    List<BonusDestination>? destinations,
    List<BonusEvent>? events,
    List<BonusEvent>? peeEvents,
    double? peeTotal,
  }) {
    return BonusState(
      destinations: destinations ?? this.destinations,
      events: events ?? this.events,
      peeEvents: peeEvents ?? this.peeEvents,
      peeTotal: peeTotal ?? this.peeTotal,
    );
  }

  factory BonusState.initial() {
    return BonusState(
      destinations: [
        BonusDestination(id: 'pea', name: 'PEA', iconName: 'target', color: const Color(0xFF5B8DEF), total: 0),
        BonusDestination(id: 'livreta', name: 'Livret A', iconName: 'shield', color: const Color(0xFF34D399), total: 0),
        BonusDestination(id: 'cto', name: 'CTO', iconName: 'trending', color: const Color(0xFFA78BFA), total: 0),
      ],
      events: [],
      peeEvents: [],
      peeTotal: 0,
    );
  }

  factory BonusState.fromJson(Map<String, dynamic> json) {
    return BonusState(
      destinations: (json['destinations'] as List<dynamic>?)
              ?.map((e) => BonusDestination.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => BonusEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      peeEvents: (json['peeEvents'] as List<dynamic>?)
              ?.map((e) => BonusEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      peeTotal: (json['peeTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'destinations': destinations.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'peeEvents': peeEvents.map((e) => e.toJson()).toList(),
        'peeTotal': peeTotal,
      };
}

// --- PROVIDER ---

class BonusNotifier extends StateNotifier<BonusState> {
  BonusNotifier() : super(BonusState.initial()) {
    _loadState();
  }

  static const _storageKey = 'aura_bonus_state_v1';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_storageKey);
      if (dataStr != null) {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        state = BonusState.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading bonus state: $e');
    }
  }

  Future<void> _saveState(BonusState newState) async {
    state = newState;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newState.toJson()));
    } catch (e) {
      debugPrint('Error saving bonus state: $e');
    }
  }

  // Actions
  void addDestination(String name) {
    final colors = [
      const Color(0xFF5B8DEF),
      const Color(0xFF34D399),
      const Color(0xFFA78BFA),
      const Color(0xFFF5A623),
      const Color(0xFFF472B6),
      const Color(0xFF38BDF8),
    ];
    final color = colors[state.destinations.length % colors.length];

    final newDest = BonusDestination(
      id: 'dest_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      iconName: 'wallet',
      color: color,
      total: 0,
    );
    _saveState(state.copyWith(destinations: [...state.destinations, newDest]));
  }

  void removeDestination(String id) {
    _saveState(state.copyWith(
      destinations: state.destinations.where((d) => d.id != id).toList(),
    ));
  }

  void addPendingEvent({required String label, required double amount, required DateTime date, required String type}) {
    final ev = BonusEvent(
      id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      amount: amount,
      date: date,
      source: 'manual',
      iconName: type,
    );
    _saveState(state.copyWith(events: [ev, ...state.events]));
  }

  void ventilate(List<String> eventIds, Map<String, double> allocationPct) {
    // 1. Calculate total selected amount
    final selectedEvents = state.events.where((e) => eventIds.contains(e.id)).toList();
    final totalAmount = selectedEvents.fold(0.0, (sum, e) => sum + e.amount);

    // 2. Update destinations
    final updatedDestinations = state.destinations.map((d) {
      final pct = allocationPct[d.id] ?? 0;
      if (pct > 0) {
        return d.copyWith(total: d.total + (totalAmount * pct / 100));
      }
      return d;
    }).toList();

    // 3. Mark events as ventilated and attach breakdown
    final breakdown = allocationPct.entries
        .where((e) => e.value > 0)
        .map((e) => BonusBreakdown(destId: e.key, pct: e.value))
        .toList();

    final updatedEvents = state.events.map((e) {
      if (eventIds.contains(e.id)) {
        return e.copyWith(isVentilated: true, breakdown: breakdown);
      }
      return e;
    }).toList();

    _saveState(state.copyWith(
      destinations: updatedDestinations,
      events: updatedEvents,
    ));
  }

  void addPeeAmount({required String label, required double amount, required DateTime date}) {
    final ev = BonusEvent(
      id: 'pee_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      amount: amount,
      date: date,
      source: 'manual',
      iconName: 'business', // or something else
      isVentilated: true, // PEE events are already placed
    );
    _saveState(state.copyWith(
      peeEvents: [ev, ...state.peeEvents],
      peeTotal: state.peeTotal + amount,
    ));
  }
}

final bonusProvider = StateNotifierProvider<BonusNotifier, BonusState>((ref) {
  return BonusNotifier();
});
