import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../services/redactor_engine.dart';
import '../services/salary_parser_service.dart';
import '../widgets/notification_header.dart';

class SalaryAuditScreen extends ConsumerStatefulWidget {
  const SalaryAuditScreen({super.key});

  @override
  ConsumerState<SalaryAuditScreen> createState() => _SalaryAuditScreenState();
}

class _SalaryAuditScreenState extends ConsumerState<SalaryAuditScreen> {
  final RedactorEngine _redactor = RedactorEngine();
  RedactionTool _selectedTool = RedactionTool.rect;

  int _canvasTab = 0; // 0 = Canevas masqué, 1 = Rendu original
  bool _isProcessing = false;
  bool _isMaskVisible = true;

  String _selectedDocId = 'payslip-2026-07'; // Default to Juillet 2026

  Offset? _startDrag;
  Offset? _currentDrag;
  List<Offset> _currentPaintPoints = [];

  void _triggerAutoRgpdMasks() {
    setState(() {
      _redactor.generateRgpdAutoMasks(const Size(380, 480));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛡️ Caviardage automatique RGPD appliqué : NIR, IBAN, Nom & Adresse masqués !'),
        backgroundColor: AppColors.accentCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, RealParsedPayslip parsed) {
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
              Text(
                'Les données réelles de M. ${parsed.employeeName} (${parsed.employerName}) ont été extraites avec succès.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Summary Box (Matching Screenshot 9 & Real Data)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _DialogRow(label: 'Période', value: parsed.period),
                    const SizedBox(height: 10),
                    _DialogRow(label: 'Salaire Brut', value: '${parsed.grossSalary.toStringAsFixed(2)} €'),
                    const SizedBox(height: 10),
                    _DialogRow(label: 'Montant Net Social', value: '${parsed.netSocial.toStringAsFixed(2)} €'),
                    const SizedBox(height: 10),
                    _DialogRow(label: 'Net à Payer (Après Impôt)', value: '${parsed.netPayable.toStringAsFixed(2)} €'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Mis à jour dans le tableau de bord...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
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
    final isJuillet2026 = _selectedDocId == 'payslip-2026-07';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Analyseur de bulletin de paie'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Selector Tabs Bar (Juillet 2026 vs Mai 2025)
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
                      onTap: () => setState(() => _selectedDocId = 'payslip-2026-07'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isJuillet2026 ? AppColors.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Juillet 2026 (3 776.67 €)',
                          style: TextStyle(
                            color: isJuillet2026 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDocId = 'payslip-2025-05'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isJuillet2026 ? AppColors.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mai 2025 (3 666.67 €)',
                          style: TextStyle(
                            color: !isJuillet2026 ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // RGPD Indications Card
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Text(
                        'Indications de Caviardage RGPD',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCyan,
                          side: const BorderSide(color: AppColors.accentCyan),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: const Text('Auto-Masquer RGPD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _triggerAutoRgpdMasks,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _BulletPoint('Nom et Prénom de l\'employé (M. NEGEM RICHARD)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Adresse personnelle complète (33 BD GALLIENI 93360 NEUILLY PLAISANCE)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Numéro de Sécurité Sociale (NIR : 193109934108822)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Coordonnées bancaires (IBAN : FR76 4061 8803 7300 0403 1180 429)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Nom et SIRET de l\'entreprise (VESTAS FRANCE SAS PEROLS)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Action Button: Masquer & Analyser le document via IA Gemini
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
                    : const Icon(Icons.psychology_rounded, size: 22),
                label: const Text('Masquer & Analyser via Gemini IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  setState(() => _isProcessing = true);
                  final parsed = await SalaryParserService.parseDocument(targetDocumentId: _selectedDocId);
                  ref.read(salaryProvider.notifier).addRecord(parsed.toSalaryRecord());
                  setState(() => _isProcessing = false);

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  _showSuccessDialog(context, parsed);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Canvas Toggle Tabs
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
                          'Canevas masqué (${_redactor.shapes.length} masques)',
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

            // Real Interactive Canvas Container
            SizedBox(
              height: 520,
              width: double.infinity,
              child: Stack(
                children: [
                  // Payslip Document Paper Box
                  Container(
                    width: double.infinity,
                    height: 520,
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
                        children: [
                          // Payslip Document Content (Matching Real Document)
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 48),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('VESTAS FRANCE SAS PEROLS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text('BAT LATITUDE PARC DE L AEROPORT', style: TextStyle(color: Colors.black87, fontSize: 10)),
                                        Text('34470 PEROLS', style: TextStyle(color: Colors.black87, fontSize: 10)),
                                        Text('SIRET : 44084901600066', style: TextStyle(color: Colors.black87, fontSize: 9)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('BULLETIN DE PAIE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(isJuillet2026 ? 'DU : 01 JUILLET 2026' : 'DU : 01 MAI 2025', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                                        Text(isJuillet2026 ? 'AU : 31 JUILLET 2026' : 'AU : 31 MAI 2025', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                                        const Text('NIR : 193109934108822', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.grey.shade200,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('SALARIÉ : NEGEM RICHARD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(isJuillet2026 ? 'SALAIRE BRUT : 3 776,67 €' : 'SALAIRE BRUT : 3 666,67 €', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 260,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                                  child: Column(
                                    children: [
                                      Container(color: Colors.grey.shade300, height: 20),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isJuillet2026 ? 'APPOINTEMENTS FORFAIT : 3 776.67 €' : 'APPOINTEMENTS FORFAIT : 3 666.67 €', style: const TextStyle(color: Colors.black, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text(isJuillet2026 ? 'COTISATIONS SALARIALES : - 840.78 €' : 'COTISATIONS SALARIALES : - 805.78 €', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                                            const SizedBox(height: 4),
                                            Text(isJuillet2026 ? 'TITRES REPAS DÉDUITS : - 52.80 €' : 'TITRES REPAS DÉDUITS : - 92.40 €', style: const TextStyle(color: Colors.black87, fontSize: 10)),
                                            if (isJuillet2026) ...[
                                              const SizedBox(height: 4),
                                              const Text('INDEMNITE TELETRAVAIL : + 15.00 €', style: TextStyle(color: Colors.black87, fontSize: 10)),
                                            ],
                                            const SizedBox(height: 12),
                                            Text(isJuillet2026 ? 'MONTANT NET SOCIAL : 2 952.28 €' : 'MONTANT NET SOCIAL : 2 860.89 €', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(isJuillet2026 ? 'NET A PAYER : 2 713.74 €' : 'NET A PAYER : 2 684.46 €', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 8),
                                            const Text('IBAN : FR76 4061 8803 7300 0403 1180 429', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Real Interactive Touch/Mouse Canvas Listener
                          if (_canvasTab == 0)
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: (details) {
                                  final pos = details.localPosition;
                                  setState(() {
                                    _startDrag = pos;
                                    _currentDrag = pos;
                                    if (_selectedTool == RedactionTool.paint) {
                                      _currentPaintPoints = [pos];
                                    }
                                  });
                                },
                                onPanUpdate: (details) {
                                  final pos = details.localPosition;
                                  setState(() {
                                    _currentDrag = pos;
                                    if (_selectedTool == RedactionTool.paint) {
                                      _currentPaintPoints.add(pos);
                                    }
                                  });
                                },
                                onPanEnd: (_) {
                                  if (_startDrag != null && _currentDrag != null) {
                                    final rect = Rect.fromPoints(_startDrag!, _currentDrag!);
                                    setState(() {
                                      if (_selectedTool == RedactionTool.rect || _selectedTool == RedactionTool.circle) {
                                        _redactor.addShape(
                                          RedactionShape(
                                            id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
                                            type: _selectedTool,
                                            rect: rect,
                                          ),
                                        );
                                      } else if (_selectedTool == RedactionTool.paint && _currentPaintPoints.isNotEmpty) {
                                        _redactor.addShape(
                                          RedactionShape(
                                            id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
                                            type: RedactionTool.paint,
                                            points: List.from(_currentPaintPoints),
                                          ),
                                        );
                                      }
                                      _startDrag = null;
                                      _currentDrag = null;
                                      _currentPaintPoints = [];
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: RedactionCanvasPainter(
                                    shapes: _redactor.shapes,
                                    isMaskVisible: _isMaskVisible,
                                    currentDraftShape: _startDrag != null && _currentDrag != null && (_selectedTool == RedactionTool.rect || _selectedTool == RedactionTool.circle)
                                        ? RedactionShape(
                                            id: 'draft',
                                            type: _selectedTool,
                                            rect: Rect.fromPoints(_startDrag!, _currentDrag!),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Toolbar Overlay (Matching Screenshot 7)
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            icon: Icon(Icons.drag_indicator_rounded, color: _selectedTool == RedactionTool.move ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = RedactionTool.move),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: _selectedTool == RedactionTool.paint ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = RedactionTool.paint),
                          ),
                          IconButton(
                            icon: Icon(Icons.crop_square_rounded, color: _selectedTool == RedactionTool.rect ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = RedactionTool.rect),
                          ),
                          IconButton(
                            icon: Icon(Icons.circle_outlined, color: _selectedTool == RedactionTool.circle ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _selectedTool = RedactionTool.circle),
                          ),
                          const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                          IconButton(
                            icon: Icon(Icons.undo_rounded, color: _redactor.canUndo ? AppColors.textPrimary : AppColors.textMuted, size: 20),
                            onPressed: _redactor.canUndo ? () => setState(() => _redactor.undo()) : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.redo_rounded, color: _redactor.canRedo ? AppColors.textPrimary : AppColors.textMuted, size: 20),
                            onPressed: _redactor.canRedo ? () => setState(() => _redactor.redo()) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                            onPressed: () => setState(() => _redactor.clearAll()),
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
