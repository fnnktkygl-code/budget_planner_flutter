import 'package:flutter/material.dart';
import '../constants/colors.dart';

class RedactorScreen extends StatefulWidget {
  const RedactorScreen({super.key});

  @override
  State<RedactorScreen> createState() => _RedactorScreenState();
}

class _RedactorScreenState extends State<RedactorScreen> {
  bool _anonymized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Anonymisation IA de Documents', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masquage automatique des données personnelles (NIR, IBAN, Nom)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
              child: Column(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.accentCyan, size: 40),
                  const SizedBox(height: 12),
                  Text(_anonymized ? '✓ Document Anonymisé avec Succès' : 'Document Prêt pour Masquage', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(_anonymized ? 'Les numéros de sécurité sociale, adresses et noms ont été caviardés.' : 'Cliquez pour appliquer l\'anonymisation automatique.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: AppColors.background),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_anonymized ? 'Recommencer' : 'Appliquer le Masquage IA'),
                    onPressed: () => setState(() => _anonymized = !_anonymized),
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
