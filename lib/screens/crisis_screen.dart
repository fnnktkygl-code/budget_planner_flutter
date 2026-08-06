import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/notification_header.dart';

class CrisisScreen extends ConsumerStatefulWidget {
  const CrisisScreen({super.key});

  @override
  ConsumerState<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends ConsumerState<CrisisScreen> {
  double _incomeDropPercent = 30.0;

  @override
  Widget build(BuildContext context) {
    const baseNet = 2861.26;
    final reducedNet = baseNet * (1 - (_incomeDropPercent / 100));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Simulateur de Crise & Stress-Test'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Banner Notification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_rounded, color: AppColors.accentRose, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stress-Test financier : Simulez une baisse de revenus ou une perte d\'emploi',
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

            // Slider Card
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pourcentage de baisse de revenu :',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '- ${_incomeDropPercent.toStringAsFixed(0)} %',
                        style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  Slider(
                    value: _incomeDropPercent,
                    min: 0,
                    max: 80,
                    divisions: 16,
                    activeColor: AppColors.accentRose,
                    onChanged: (val) => setState(() => _incomeDropPercent = val),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Revenu habituel : ${baseNet.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('Revenu réduit : ${reducedNet.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shield_rounded),
                label: const Text('Activer le Mode Économie de Guerre', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛡️ Plan d\'urgence activé : Seules les charges vitales sont conservées !'),
                      backgroundColor: AppColors.accentRose,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
