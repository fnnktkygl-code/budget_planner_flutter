import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/settings_provider.dart';
import '../widgets/banking_modal.dart';

class AppDrawerWidget extends ConsumerWidget {
  final Function(int)? onSelectScreen;

  const AppDrawerWidget({
    super.key,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // Logo & Brand Header (Matching Screenshot 2)
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
                          size: 28,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Synchronisation bancaire & Intelligence Artificielle',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 24),

                  // Section 1: OUTILS D'ANALYSE & ÉPARGNE
                  const Text(
                    'OUTILS D\'ANALYSE & ÉPARGNE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildDrawerTile(
                    icon: Icons.savings_outlined,
                    title: 'Entonnoir d\'épargne',
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectScreen != null) onSelectScreen!(2);
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildDrawerTile(
                    icon: Icons.tune_rounded,
                    title: 'Simulateurs',
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectScreen != null) onSelectScreen!(3);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Section 2: PRÉFÉRENCES
                  const Text(
                    'PRÉFÉRENCES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Language Dropdown Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
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
                                Text('🇫🇷 ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text('Français', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text('English', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  const SizedBox(height: 14),

                  // Auto Sync Bank Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const BankingModalContent(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.account_balance_rounded, color: AppColors.accentCyan, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Synchroniser\nautomatiquement',
                              style: TextStyle(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.3,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Text(
                    'AuraBudget Pro',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Version 1.0.0',
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
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
