import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/settings_provider.dart';
import '../widgets/banking_modal.dart';

class AppDrawerWidget extends ConsumerWidget {
  final int currentIndex;
  final Function(int)? onSelectScreen;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppDrawerWidget({
    super.key,
    this.currentIndex = 0,
    this.onSelectScreen,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 16,
                  vertical: 20,
                ),
                children: [
                  // Logo & Brand Header with Collapse Toggle Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.radiantGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.circle_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AuraBudget Pro',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Budget & IA Fiscale',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onToggleCollapse != null)
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: onToggleCollapse,
                            tooltip: 'Réduire le menu',
                          ),
                      ] else ...[
                        if (onToggleCollapse != null)
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: onToggleCollapse,
                            tooltip: 'Agrandir le menu',
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 16),

                  // Section: MENU PRINCIPAL
                  if (!isCollapsed)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'MENU PRINCIPAL',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  _buildDrawerTile(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    title: 'Tableau de bord',
                    index: 0,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.tune_outlined,
                    activeIcon: Icons.tune_rounded,
                    title: 'Règles & Budget',
                    index: 1,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    title: 'Bulletins & Salaires',
                    index: 2,
                    context: context,
                  ),
                  const SizedBox(height: 16),

                  // Section: SIMULATION & ANALYSE
                  if (!isCollapsed)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'SIMULATION & ANALYSE',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  _buildDrawerTile(
                    icon: Icons.savings_outlined,
                    activeIcon: Icons.savings_rounded,
                    title: 'Entonnoir d\'Épargne',
                    index: 3,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.warning_amber_rounded,
                    activeIcon: Icons.warning_rounded,
                    title: 'Simulateur de Crise',
                    index: 4,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.credit_card_outlined,
                    activeIcon: Icons.credit_card_rounded,
                    title: 'Crédit & Financement',
                    index: 5,
                    context: context,
                  ),
                  const SizedBox(height: 16),

                  // Section: RÉGLAGES
                  if (!isCollapsed)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'RÉGLAGES',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    title: 'Configuration System',
                    index: 6,
                    context: context,
                  ),
                  const SizedBox(height: 14),

                  // Language Dropdown Card
                  if (!isCollapsed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: settings.languageCode,
                          isExpanded: true,
                          dropdownColor: AppColors.cardBackground,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                          items: const [
                            DropdownMenuItem(
                              value: 'fr',
                              child: Row(
                                children: [
                                  Text('🇫🇷 ', style: TextStyle(fontSize: 14)),
                                  SizedBox(width: 8),
                                  Text('Français', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  Text('🇬🇧 ', style: TextStyle(fontSize: 14)),
                                  SizedBox(width: 8),
                                  Text('English', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (code) {
                            if (code != null) {
                              ref.read(settingsProvider.notifier).setLanguage(code);
                            }
                          },
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Text('🇫🇷', style: TextStyle(fontSize: 18)),
                      onPressed: () {
                        final nextLang = settings.languageCode == 'fr' ? 'en' : 'fr';
                        ref.read(settingsProvider.notifier).setLanguage(nextLang);
                      },
                      tooltip: 'Langue: ${settings.languageCode.toUpperCase()}',
                    ),
                  const SizedBox(height: 12),

                  // Auto Sync Bank CTA Button
                  GestureDetector(
                    onTap: () {
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.pop(context);
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const BankingModalContent(),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(isCollapsed ? 10 : 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_balance_rounded, color: AppColors.accentCyan, size: 18),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Synchro Banque',
                                style: TextStyle(
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Version Tag
            if (!isCollapsed)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'AuraBudget Pro — v1.2.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = currentIndex == index;

    Widget tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isSelected ? AppColors.accentCyan : Colors.transparent,
            width: 3.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12, vertical: 0),
        selected: isSelected,
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
          size: 20,
        ),
        title: isCollapsed
            ? null
            : Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
        onTap: () {
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
          if (onSelectScreen != null) {
            onSelectScreen!(index);
          }
        },
      ),
    );

    return isCollapsed ? Tooltip(message: title, child: tile) : tile;
  }
}
