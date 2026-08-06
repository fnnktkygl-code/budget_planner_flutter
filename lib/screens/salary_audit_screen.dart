import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';

class SalaryAuditScreen extends ConsumerStatefulWidget {
  const SalaryAuditScreen({super.key});

  @override
  ConsumerState<SalaryAuditScreen> createState() => _SalaryAuditScreenState();
}

class _SalaryAuditScreenState extends ConsumerState<SalaryAuditScreen> {
  int _currentStep = 1; // 1 = Importer, 2 = Masquer, 3 = Analyser
  bool _isAccordionExpanded = true;
  int _canvasTab = 0; // 0 = Canevas masqué, 1 = Rendu original
  bool _isProcessing = false;
  String? _uploadedDocName;

  @override
  Widget build(BuildContext context) {
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
              'Analyseur de bulletin de paie',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
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
            // 3-Step Stepper Header (Matching Screenshot 4)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStepItem(1, 'Importer', _currentStep >= 1),
                  const Text('—', style: TextStyle(color: AppColors.borderSubtle, fontWeight: FontWeight.bold)),
                  _buildStepItem(2, 'Masquer', _currentStep >= 2),
                  const Text('—', style: TextStyle(color: AppColors.borderSubtle, fontWeight: FontWeight.bold)),
                  _buildStepItem(3, 'Analyser', _currentStep >= 3),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Cloud Upload Box (Matching Screenshot 4)
            GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedDocName = 'bulletin_paye_juin_2026.pdf';
                  _currentStep = 2;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document PDF chargé avec succès !'),
                    backgroundColor: AppColors.accentCyan,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: AppColors.accentCyan, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _uploadedDocName != null ? '📄 $_uploadedDocName' : 'Choisir le bulletin PDF',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Prend en charge les bulletins de paie français',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Digiposte Import Card (Matching Screenshot 4)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2B4D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: AppColors.accentCyan, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Importer depuis Digiposte',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connectez-vous et récupérez votre bulletin',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: Indications de Caviardage Accordion (Matching Screenshot 4)
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      setState(() {
                        _isAccordionExpanded = !_isAccordionExpanded;
                      });
                    },
                    leading: const Icon(Icons.shield_outlined, color: AppColors.accentCyan),
                    title: const Text(
                      'Indications de Caviardage',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Icon(
                      _isAccordionExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  if (_isAccordionExpanded) ...[
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _BulletPoint('Nom et Prénom de l\'employé'),
                          SizedBox(height: 10),
                          _BulletPoint('Adresse personnelle complète'),
                          SizedBox(height: 10),
                          _BulletPoint('Numéro de Sécurité Sociale (NIR)'),
                          SizedBox(height: 10),
                          _BulletPoint('Coordonnées bancaires (IBAN/BIC)'),
                          SizedBox(height: 10),
                          _BulletPoint('Nom et SIRET de l\'entreprise'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Action Button: Masquer & Analyser le document
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                      )
                    : const Icon(Icons.settings_suggest_rounded, size: 20),
                label: const Text(
                  'Masquer & Analyser le document',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() {
                    _isProcessing = true;
                  });
                  Future.delayed(const Duration(seconds: 2), () {
                    if (!mounted) return;
                    setState(() {
                      _isProcessing = false;
                      _currentStep = 3;
                    });
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Analyse IA du bulletin effectuée avec succès !'),
                        backgroundColor: AppColors.accentEmerald,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Canvas Toggle Tabs: Canevas masqué vs Rendu original (Matching Screenshot 4)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _canvasTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _canvasTab == 0 ? AppColors.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Canevas masqué',
                          style: TextStyle(
                            color: _canvasTab == 0 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _canvasTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _canvasTab == 1 ? AppColors.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Rendu original',
                          style: TextStyle(
                            color: _canvasTab == 1 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepNum, String title, bool isActive) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentCyan : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppColors.accentCyan : AppColors.textMuted),
          ),
          alignment: Alignment.center,
          child: Text(
            '$stepNum',
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accentCyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
