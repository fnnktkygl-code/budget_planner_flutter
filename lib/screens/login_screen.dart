import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Brand & Logo
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentCyan, width: 2),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentCyan, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AuraBudget Pro',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Planificateur financier, Ingestion TrueLayer Open Banking & Audit Salarial IA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),

              // Feature Highlights Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: const [
                    _FeatureRow(icon: Icons.security_rounded, title: 'Données Sécurisées & Chiffrées', subtitle: 'Conforme RGPD & Chiffrement AES-256'),
                    SizedBox(height: 14),
                    _FeatureRow(icon: Icons.account_balance_rounded, title: 'Synchronisation Bancaire TrueLayer', subtitle: 'BoursoBank, BNP, Revolut, Crédit Agricole'),
                    SizedBox(height: 14),
                    _FeatureRow(icon: Icons.description_rounded, title: 'Audit Salarial & Lissage IA', subtitle: 'Visualisation des bulletins 2025 - 2026'),
                  ],
                ),
              ),

              // Auth Actions & Buttons
              Column(
                children: [
                  if (authState.errorMessage != null) ...[
                    Text(authState.errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],

                  if (authState.isLoading)
                    const CircularProgressIndicator(color: AppColors.accentCyan)
                  else ...[
                    // Google / Gmail Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).signInWithGoogle();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('🔴', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 12),
                            Text(
                              'Se connecter avec Gmail (Google)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Guest Mode Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).signInAsGuest();
                        },
                        child: const Text('Continuer en Mode Invité (Démo)'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.accentCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.accentCyan, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
