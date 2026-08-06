import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';

class RuleCategoryItem {
  final String id;
  final String name;
  final double amount;
  final String iconType;
  final Color iconBgColor;

  RuleCategoryItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.iconType,
    required this.iconBgColor,
  });
}

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  final List<RuleCategoryItem> _savingsCategories = [
    RuleCategoryItem(id: 'sav-1', name: 'Cible PEA', amount: 1000, iconType: 'chart', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'sav-2', name: 'Livret A', amount: 200, iconType: 'shield', iconBgColor: AppColors.accentGold),
  ];

  final List<RuleCategoryItem> _fixedChargesCategories = [
    RuleCategoryItem(id: 'fix-1', name: 'Loyer', amount: 677, iconType: 'home', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-2', name: 'Abonnement', amount: 41, iconType: 'video', iconBgColor: AppColors.accentRose),
    RuleCategoryItem(id: 'fix-3', name: 'Tontine', amount: 300, iconType: 'people', iconBgColor: AppColors.accentPurple),
    RuleCategoryItem(id: 'fix-4', name: 'Soutien', amount: 231, iconType: 'heart', iconBgColor: AppColors.accentRose),
  ];

  final List<RuleCategoryItem> _dailyCategories = [
    RuleCategoryItem(id: 'day-1', name: 'Revolut', amount: 200, iconType: 'card', iconBgColor: AppColors.accentCyan),
    RuleCategoryItem(id: 'day-2', name: 'Tampon €', amount: 0, iconType: 'basket', iconBgColor: AppColors.accentEmerald),
  ];

  void _addCategory(List<RuleCategoryItem> targetList, String defaultTitle, Color color) {
    setState(() {
      targetList.add(
        RuleCategoryItem(
          id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
          name: '$defaultTitle ${targetList.length + 1}',
          amount: 100,
          iconType: 'default',
          iconBgColor: color,
        ),
      );
    });
  }

  void _deleteCategory(List<RuleCategoryItem> targetList, String id) {
    setState(() {
      targetList.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryProvider);
    final netSalary = salary.activeBaseline?.netSalary ?? 2861.26;

    final totalSavings = _savingsCategories.fold(0.0, (sum, c) => sum + c.amount);
    final totalFixed = _fixedChargesCategories.fold(0.0, (sum, c) => sum + c.amount);
    final totalDaily = _dailyCategories.fold(0.0, (sum, c) => sum + c.amount);

    final resteAVivre = netSalary - totalSavings - totalFixed - totalDaily;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: const [
            Text(
              'Règles de Répartition',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radiant Gradient Card — RESTE À VIVRE ESTIMÉ (Matching Screenshot 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.radiantGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'RESTE À VIVRE ESTIMÉ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${resteAVivre.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wallet_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Basé sur un revenu net de ${netSalary.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: ALLOCATION MENSUELLE D'ÉPARGNE
            _buildSectionHeader('ALLOCATION MENSUELLE D\'ÉPARGNE'),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_savingsCategories, netSalary, allowDelete: false, onAdd: () => _addCategory(_savingsCategories, 'Épargne', AppColors.accentCyan)),

            const SizedBox(height: 24),

            // Section 2: CHARGES FIXES INCOMPRESSIBLES
            _buildSectionHeader('CHARGES FIXES INCOMPRESSIBLES'),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_fixedChargesCategories, netSalary, allowDelete: true, onAdd: () => _addCategory(_fixedChargesCategories, 'Charge', AppColors.accentRose)),

            const SizedBox(height: 24),

            // Section 3: DÉPENSES QUOTIDIENNES
            _buildSectionHeader('DÉPENSES QUOTIDIENNES'),
            const SizedBox(height: 12),
            _buildCategoryGroupCard(_dailyCategories, netSalary, allowDelete: true, onAdd: () => _addCategory(_dailyCategories, 'Dépense', AppColors.accentEmerald)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCategoryGroupCard(
    List<RuleCategoryItem> categories,
    double netSalary, {
    required bool allowDelete,
    required VoidCallback onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final percent = netSalary > 0 ? (cat.amount / netSalary) * 100 : 0.0;
              return _buildCategoryRow(cat, percent, allowDelete: allowDelete, onDelete: () => _deleteCategory(categories, cat.id));
            },
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Add Category Button (Matching Screenshots 3 & 5)
          InkWell(
            onTap: onAdd,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.accentCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter une catégorie',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    RuleCategoryItem item,
    double percent, {
    required bool allowDelete,
    required VoidCallback onDelete,
  }) {
    IconData getIcon(String type) {
      switch (type) {
        case 'chart':
          return Icons.show_chart_rounded;
        case 'shield':
          return Icons.shield_rounded;
        case 'home':
          return Icons.home_rounded;
        case 'video':
          return Icons.ondemand_video_rounded;
        case 'people':
          return Icons.people_alt_rounded;
        case 'heart':
          return Icons.favorite_rounded;
        case 'card':
          return Icons.credit_card_rounded;
        case 'basket':
          return Icons.shopping_basket_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.iconBgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(getIcon(item.iconType), color: item.iconBgColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Name & Percentage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percent.toStringAsFixed(1)}% du revenu',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount Box (Matching Screenshots 3 & 5)
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              '${item.amount.toStringAsFixed(0)} €',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Lock Icon
          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),

          if (allowDelete) ...[
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
