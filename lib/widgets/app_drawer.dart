import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/settings_provider.dart';
import '../widgets/banking_modal.dart';

class AppDrawerWidget extends ConsumerWidget {
  final int currentIndex;
  final Function(int)? onSelectScreen;

  const AppDrawerWidget({
    super.key,
    this.currentIndex = 0,
    this.onSelectScreen,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Logo & Brand Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.radiantGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.circle_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'AuraBudget Pro',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Synchronisation bancaire & IA',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 20),

                  // Section: NAVIGATION PRINCIPALE
                  const Text(
                    'NAVIGATION PRINCIPALE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildDrawerTile(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    title: 'Tableau de bord',
                    index: 0,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.account_tree_outlined,
                    activeIcon: Icons.account_tree_rounded,
                    title: 'Règles de Répartition',
                    index: 1,
                    context: context,
                  ),
                  const SizedBox(height: 4),

                  _buildDrawerTile(
                    icon: Icons.document_scanner_outlined,
                    activeIcon: Icons.document_scanner_rounded,
                    title: 'Analyseur de bulletin de paie',
                    index: 2,
                    context: context,
                  ),
                  const SizedBox(height: 20),

                  // Section: OUTILS D'ANALYSE & ÉPARGNE
                  const Text(
                    'OUTILS D\'ANALYSE & ÉPARGNE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildDrawerTile(
                    icon: Icons.savings_outlined,
                    activeIcon: Icons.savings_rounded,
                    title: 'Entonnoir d\'épargne',
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
                    icon: Icons.credit_score_outlined,
                    activeIcon: Icons.credit_score_rounded,
                    title: 'Crédit & Financement',
                    index: 5,
                    context: context,
                  ),
                  const SizedBox(height: 20),

                  // Section: PRÉFÉRENCES & CONFIGURATION
                  const Text(
                    'PRÉFÉRENCES & CONFIG',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    title: 'Configuration System',
                    index: 6,
                    context: context,
                  ),
                  const SizedBox(height: 14),

                  // Language Dropdown Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
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
                                Text('🇫🇷 ', style: TextStyle(fontSize: 15)),
                                SizedBox(width: 8),
                                Text('Français', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('🇬🇧 ', style: TextStyle(fontSize: 15)),
                                SizedBox(width: 8),
                                Text('English', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  ),
                  const SizedBox(height: 12),

                  // Auto Sync Bank Button
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.account_balance_rounded, color: AppColors.accentCyan, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Synchroniser Banque (TrueLayer)',
                              style: TextStyle(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Version Tag
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: const [
                  Text(
                    'AuraBudget Pro — v1.0.0',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      selected: isSelected,
      selectedTileColor: AppColors.accentCyan.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
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
    );
  }
}
