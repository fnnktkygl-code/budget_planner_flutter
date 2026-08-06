import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../widgets/notification_header.dart';

class SalaryAuditScreen extends ConsumerStatefulWidget {
  const SalaryAuditScreen({super.key});

  @override
  ConsumerState<SalaryAuditScreen> createState() => _SalaryAuditScreenState();
}

class _SalaryAuditScreenState extends ConsumerState<SalaryAuditScreen> {
  int _canvasTab = 0; // 0 = Canevas masqué, 1 = Rendu original
  bool _isProcessing = false;
  bool _isMaskVisible = true;
  int _selectedTool = 1; // 0 = Move, 1 = Paint, 2 = Box, 3 = Circle

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Big Green Check Circle (Matching Screenshot 9)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentEmerald, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.accentEmerald, size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                'Analyse Réussie !',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Les données de votre bulletin ont été extraites avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Summary Box (Matching Screenshot 9)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: const [
                    _DialogRow(label: 'Période', value: '01 MAI 2024 - 31 MAI 2024'),
                    SizedBox(height: 10),
                    _DialogRow(label: 'Salaire Brut', value: '3 666.67 €'),
                    SizedBox(height: 10),
                    _DialogRow(label: 'Net à Payer (Après Impôt)', value: '2 815.79 €'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Redirection dans 2s...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 16),

              // Big Emerald Action Button (Matching Screenshot 9)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Accéder au Tableau de Bord', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Analyseur de bulletin de paie'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caviardage Bullets Card (Matching Screenshots 7 & 10)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
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
            const SizedBox(height: 16),

            // Main Action Button: Masquer & Analyser (Matching Screenshot 7)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.settings_suggest_rounded, size: 20),
                label: const Text('Masquer & Analyser le document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  setState(() => _isProcessing = true);
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() => _isProcessing = false);
                      // ignore: use_build_context_synchronously
                      _showSuccessDialog(context);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Canvas Toggle Tabs: Canevas masqué vs Rendu original (Matching Screenshots 7 & 10)
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
            const SizedBox(height: 16),

            // Document & Canvas Container with Floating Redaction Toolbar Overlay (Matching Screenshot 7)
            SizedBox(
              height: 480,
              width: double.infinity,
              child: Stack(
                children: [
                  // Document Paper Frame
                  Container(
                    width: double.infinity,
                    height: 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Payslip Document Mockup Content
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 50),
                                const Text('93360 NEUILLY PLAISANCE', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                  color: Colors.grey.shade200,
                                  child: const Text('BULLETIN DE PAIE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 320,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                                  child: Column(
                                    children: [
                                      Container(color: Colors.grey.shade300, height: 24),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text('REMUNERATION BRUTE : 3 666.67 €', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                              SizedBox(height: 6),
                                              Text('COTISATIONS SOCIALES : - 860.78 €', style: TextStyle(color: Colors.black54, fontSize: 10)),
                                              SizedBox(height: 4),
                                              Text('TICKETS RESTO DEDUITS : - 3.90 €', style: TextStyle(color: Colors.black54, fontSize: 10)),
                                              SizedBox(height: 4),
                                              Text('INDEMNITE TELETRAVAIL : + 15.00 €', style: TextStyle(color: Colors.black54, fontSize: 10)),
                                              SizedBox(height: 16),
                                              Text('NET A PAYER : 2 815.79 €', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Caviardage Mask Overlay
                          if (_isMaskVisible && _canvasTab == 0) ...[
                            Positioned(
                              top: 60,
                              left: 30,
                              right: 30,
                              height: 30,
                              child: Container(color: Colors.black87),
                            ),
                            Positioned(
                              top: 100,
                              left: 30,
                              width: 180,
                              height: 24,
                              child: Container(color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Floating Toolbar Overlay (Matching Screenshot 7)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.drag_indicator_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = 0),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: _selectedTool == 1 ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = 1),
                          ),
                          IconButton(
                            icon: Icon(Icons.crop_square_rounded, color: _selectedTool == 2 ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = 2),
                          ),
                          IconButton(
                            icon: Icon(Icons.circle_outlined, color: _selectedTool == 3 ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = 3),
                          ),
                          const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                          IconButton(
                            icon: const Icon(Icons.undo_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.redo_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                            onPressed: () => setState(() => _isMaskVisible = false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom-Right Floating Eye Button (Matching Screenshot 7)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      onPressed: () {
                        setState(() {
                          _isMaskVisible = !_isMaskVisible;
                        });
                      },
                      child: Icon(_isMaskVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
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
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentCyan, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
