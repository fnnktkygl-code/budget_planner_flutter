import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/notification_header.dart';

class ClicScreen extends ConsumerStatefulWidget {
  const ClicScreen({super.key});

  @override
  ConsumerState<ClicScreen> createState() => _ClicScreenState();
}

class _ClicScreenState extends ConsumerState<ClicScreen> {
  double _loanAmount = 150000;
  double _durationYears = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Crédit & Financement'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Banner Notification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.credit_score_rounded, color: AppColors.accentEmerald, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Simulateur de Capacité d\'Emprunt Immobilier & Taux Effectif',
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

            // Card Form
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
                      const Text('Montant de l\'emprunt :', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      Text('${_loanAmount.toStringAsFixed(0)} €', style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: _loanAmount,
                    min: 10000,
                    max: 500000,
                    divisions: 49,
                    activeColor: AppColors.accentCyan,
                    onChanged: (val) => setState(() => _loanAmount = val),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Durée du prêt :', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      Text('${_durationYears.toStringAsFixed(0)} ans', style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: _durationYears,
                    min: 5,
                    max: 30,
                    divisions: 25,
                    activeColor: AppColors.accentCyan,
                    onChanged: (val) => setState(() => _durationYears = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calculer ma Mensualité', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📊 Simulation calculée : Mensualité estimée de 870 €/mois'),
                      backgroundColor: AppColors.accentEmerald,
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
