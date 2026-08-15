import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/salary_provider.dart';
import '../widgets/banking_modal.dart';
import '../widgets/notification_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final salary = ref.watch(salaryProvider);

    final lastSyncStr = salary.lastBankSync != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(salary.lastBankSync!)
        : (settings.lastSyncTimestamp != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(settings.lastSyncTimestamp!)
            : 'Aucune');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Configuration System'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Banner Notification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.settings_suggest_rounded, color: AppColors.accentCyan, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gestion du compte, Clés TrueLayer & Préférences de sécurité',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accentCyan.withValues(alpha: 0.2),
                    child: Text(
                      (authState.user?.displayName.isNotEmpty == true)
                          ? authState.user!.displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.displayName ?? 'Utilisateur AuraBudget',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.user?.email ?? 'fnnktkygl@gmail.com',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                    },
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TrueLayer Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Synchronisation TrueLayer', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (settings.truelayerUseSandbox ? AppColors.accentGold : AppColors.accentEmerald).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: (settings.truelayerUseSandbox ? AppColors.accentGold : AppColors.accentEmerald).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          settings.truelayerUseSandbox ? 'Mode Sandbox' : 'Mode Live (Production)',
                          style: TextStyle(
                            color: settings.truelayerUseSandbox ? AppColors.accentGold : AppColors.accentEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Client ID : ${settings.truelayerClientId}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  Text(
                    'Statut : ${settings.bankConnected ? "Connecté à ${settings.connectedBankName.isNotEmpty ? settings.connectedBankName : (salary.syncBankName ?? 'BoursoBank')}" : "Non connecté"}',
                    style: TextStyle(
                      color: settings.bankConnected ? AppColors.accentEmerald : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Dernière synchronisation : $lastSyncStr', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.account_balance_rounded, size: 18),
                            label: const Text('Gérer mes banques'),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const BankingModalContent(),
                              );
                            },
                          ),
                        ),
                      ),
                      if (settings.bankConnected) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.link_off_rounded, size: 18),
                            label: const Text('Déconnecter'),
                            onPressed: () async {
                              await ref.read(settingsProvider.notifier).disconnectBank();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Banque déconnectée.'),
                                    backgroundColor: AppColors.surface,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
