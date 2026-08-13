patch -p0 << 'PATCH_EOF'
--- lib/screens/rules_screen.dart
+++ lib/screens/rules_screen.dart
@@ -1,7 +1,10 @@
+import 'dart:convert';
 import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:shared_preferences/shared_preferences.dart';
 import '../constants/colors.dart';
 import '../core/providers/salary_provider.dart';
+import '../core/providers/auth_provider.dart';
 import '../models/temporary_expense.dart';
 import '../widgets/notification_header.dart';
 
@@ -23,6 +26,26 @@
     required this.iconType,
     required this.iconBgColor,
   });
+
+  Map<String, dynamic> toJson() => {
+    'id': id,
+    'name': name,
+    'amount': amount,
+    'isPercentage': isPercentage,
+    'isLocked': isLocked,
+    'iconType': iconType,
+    'iconBgColor': iconBgColor.value,
+  };
+
+  factory RuleCategoryItem.fromJson(Map<String, dynamic> json) => RuleCategoryItem(
+    id: json['id'] ?? '',
+    name: json['name'] ?? '',
+    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
+    isPercentage: json['isPercentage'] ?? false,
+    isLocked: json['isLocked'] ?? false,
+    iconType: json['iconType'] ?? 'default',
+    iconBgColor: Color(json['iconBgColor'] ?? 0xFF000000),
+  );
 
   double getEffectiveAmount(double netSalary) {
     if (isPercentage) {
@@ -46,22 +69,64 @@
 }
 
 class _RulesScreenState extends ConsumerState<RulesScreen> {
-  final List<RuleCategoryItem> _savingsCategories = [
+  List<RuleCategoryItem> _savingsCategories = [
     RuleCategoryItem(id: 'sav-1', name: 'Cible PEA', amount: 35.0, isPercentage: true, iconType: 'chart', iconBgColor: AppColors.accentCyan),
     RuleCategoryItem(id: 'sav-2', name: 'Livret A', amount: 7.0, isPercentage: true, iconType: 'shield', iconBgColor: AppColors.accentGold),
   ];
 
-  final List<RuleCategoryItem> _fixedChargesCategories = [
+  List<RuleCategoryItem> _fixedChargesCategories = [
     RuleCategoryItem(id: 'fix-1', name: 'Loyer', amount: 677, isPercentage: false, iconType: 'home', iconBgColor: AppColors.accentRose),
     RuleCategoryItem(id: 'fix-2', name: 'Abonnement', amount: 41, isPercentage: false, iconType: 'video', iconBgColor: AppColors.accentRose),
     RuleCategoryItem(id: 'fix-3', name: 'Tontine', amount: 300, isPercentage: false, iconType: 'people', iconBgColor: AppColors.accentPurple),
     RuleCategoryItem(id: 'fix-4', name: 'Soutien', amount: 231, isPercentage: false, iconType: 'heart', iconBgColor: AppColors.accentRose),
   ];
 
-  final List<RuleCategoryItem> _dailyCategories = [
+  List<RuleCategoryItem> _dailyCategories = [
     RuleCategoryItem(id: 'day-1', name: 'Revolut (Reste à vivre)', amount: 7.0, isPercentage: true, iconType: 'card', iconBgColor: AppColors.accentCyan),
     RuleCategoryItem(id: 'day-2', name: 'Tampon / Marge €', amount: 0, isPercentage: false, iconType: 'basket', iconBgColor: AppColors.accentEmerald),
   ];
 
+  @override
+  void initState() {
+    super.initState();
+    _loadCategories();
+  }
+
+  Future<void> _loadCategories() async {
+    final prefs = await SharedPreferences.getInstance();
+    final userId = ref.read(authProvider).user?.id ?? '';
+    final key = userId.isEmpty ? 'aura_rules_categories' : '${userId}_aura_rules_categories';
+    
+    final raw = prefs.getString(key);
+    if (raw != null && raw.isNotEmpty) {
+      try {
+        final Map<String, dynamic> data = jsonDecode(raw);
+        if (data.containsKey('savings')) {
+          _savingsCategories = (data['savings'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
+        }
+        if (data.containsKey('fixed')) {
+          _fixedChargesCategories = (data['fixed'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
+        }
+        if (data.containsKey('daily')) {
+          _dailyCategories = (data['daily'] as List).map((i) => RuleCategoryItem.fromJson(i)).toList();
+        }
+        setState(() {});
+      } catch (_) {}
+    }
+  }
+
+  Future<void> _saveCategories() async {
+    final prefs = await SharedPreferences.getInstance();
+    final userId = ref.read(authProvider).user?.id ?? '';
+    final key = userId.isEmpty ? 'aura_rules_categories' : '${userId}_aura_rules_categories';
+    
+    final data = {
+      'savings': _savingsCategories.map((c) => c.toJson()).toList(),
+      'fixed': _fixedChargesCategories.map((c) => c.toJson()).toList(),
+      'daily': _dailyCategories.map((c) => c.toJson()).toList(),
+    };
+    await prefs.setString(key, jsonEncode(data));
+  }
+
   Widget _buildGaugeLegend(String label, double amount, Color color) {
     return Row(
@@ -207,6 +272,7 @@
                         ),
                       );
                     });
+                    _saveCategories();
                     Navigator.pop(ctx);
                   },
                   child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
@@ -373,6 +439,7 @@
                       item.amount = newAmount;
                       item.isPercentage = isPercentage;
                     });
+                    _saveCategories();
                     Navigator.pop(ctx);
                   },
                   child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
@@ -417,6 +484,7 @@
                 setState(() {
                   targetList.removeWhere((i) => i.id == item.id);
                 });
+                _saveCategories();
                 Navigator.pop(ctx);
               },
               child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
PATCH_EOF
