import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/notification_header.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Entonnoir d\'Épargne'),
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
                  Icon(Icons.savings_rounded, color: AppColors.accentCyan, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Entonnoir d\'épargne automatique : Priorisation Sécurité -> PEA -> Immo',
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

            // Savings Cards
            _buildFunnelStepCard(
              stepNumber: 1,
              title: 'Épargne de Précaution (Livret A / LDD)',
              targetAmount: '6 000.00 €',
              currentAmount: '4 200.00 €',
              progress: 0.70,
              color: AppColors.accentGold,
              icon: Icons.shield_rounded,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildFunnelStepCard(
              stepNumber: 2,
              title: 'Épargne Long Terme (PEA / ETF World)',
              targetAmount: '20 000.00 €',
              currentAmount: '12 500.00 €',
              progress: 0.625,
              color: AppColors.accentCyan,
              icon: Icons.show_chart_rounded,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildFunnelStepCard(
              stepNumber: 3,
              title: 'Projets Immobiliers & Apport',
              targetAmount: '15 000.00 €',
              currentAmount: '3 000.00 €',
              progress: 0.20,
              color: AppColors.accentEmerald,
              icon: Icons.home_work_rounded,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStepCard({
    required int stepNumber,
    required String title,
    required String targetAmount,
    required String currentAmount,
    required double progress,
    required Color color,
    required IconData icon,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Étape $stepNumber',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surface,
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actuel : $currentAmount', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Cible : $targetAmount', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Alimenter cette poche d\'épargne'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Virement automatique programmé vers $title !'),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
