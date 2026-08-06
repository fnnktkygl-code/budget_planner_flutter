// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
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

  Uint8List? _customFileBytes;
  Uint8List? _renderedPdfImageBytes;
  String? _customFileName;

  Offset? _startDrag;
  Offset? _currentDrag;
  List<Offset> _currentPaintPoints = [];

  // Draggable Toolbar Position State
  Offset _toolbarPos = const Offset(14, 14);

  // Period Selector Fallback Dialog
  int _selectedYear = 2026;
  int _selectedMonth = 7;
  final List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  Future<Uint8List?> _renderPdfToImageBytes(Uint8List pdfBytes) async {
    // 1. JS Interop Base64 rendering on Web
    if (kIsWeb) {
      try {
        final base64Str = base64Encode(pdfBytes);
        final dataUrl = js.context.callMethod('renderPdfBase64ToDataUrl', [base64Str]);
        if (dataUrl != null && dataUrl is String && dataUrl.startsWith('data:image')) {
          final rawBase64 = dataUrl.split(',')[1];
          return base64Decode(rawBase64);
        }
      } catch (e) {
        debugPrint('[SalaryAuditScreen] JS PDF Render Error: $e');
      }
    }

    // 2. Fallback to pdfx native rendering
    try {
      final pdfDoc = await PdfDocument.openData(pdfBytes);
      final page = await pdfDoc.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      await pdfDoc.close();
      return pageImage?.bytes;
    } catch (e) {
      debugPrint('[SalaryAuditScreen] Pdfx Render Error: $e');
      return null;
    }
  }

  Future<void> _processUploadedFile(Uint8List bytes, String fileName) async {
    setState(() {
      _customFileBytes = bytes;
      _customFileName = fileName;
      _renderedPdfImageBytes = null;
      _redactor.clearAll();
    });

    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      final imageBytes = await _renderPdfToImageBytes(bytes);
      setState(() {
        _renderedPdfImageBytes = imageBytes;
      });
    }
  }

  Future<void> _pickUserPayslipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processUploadedFile(file.bytes!, file.name);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 Bulletin chargé : ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)'),
              backgroundColor: AppColors.accentEmerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[SalaryAuditScreen] Pick File Exception: $e');
    }
  }

  void _showPeriodWarningDialog(BuildContext context, RealParsedPayslip parsed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text('Date non détectée', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'La date ou période du bulletin est masquée ou illisible.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez indiquer le mois et l\'année de ce bulletin pour l\'enregistrer dans votre historique salarial :',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Text('Mois :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          dropdownColor: AppColors.cardBackground,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_monthsFr[index]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => _selectedMonth = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text('Année :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: AppColors.cardBackground,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          items: [2024, 2025, 2026, 2027].map((yr) {
                            return DropdownMenuItem(
                              value: yr,
                              child: Text('$yr'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final monthStr = _selectedMonth < 10 ? '0$_selectedMonth' : '$_selectedMonth';
                    final customPeriodKey = '$_selectedYear-$monthStr';
                    final customPeriodLabel = '${_monthsFr[_selectedMonth - 1]} $_selectedYear';

                    final record = parsed.toSalaryRecord(
                      customPeriod: customPeriodKey,
                      customPeriodLabel: customPeriodLabel,
                    );
                    ref.read(salaryProvider.notifier).addRecord(record);

                    Navigator.pop(ctx);
                    _showSuccessDialog(context, parsed, customPeriodLabel);
                  },
                  child: const Text('Valider & Enregistrer dans l\'historique', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, RealParsedPayslip parsed, String finalPeriodLabel) {
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
              const Text(
                'Les données financières de votre bulletin ont été extraites avec succès et ajoutées à votre historique.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _DialogRow(label: 'Période', value: finalPeriodLabel),
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
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer & Voir l\'Historique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealDocumentView() {
    // 1. RENDERED PDF IMAGE PAGE (Via pdf.js canvas renderer)
    if (_renderedPdfImageBytes != null) {
      return InteractiveViewer(
        maxScale: 4.0,
        minScale: 1.0,
        child: Image.memory(
          _renderedPdfImageBytes!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // 2. RENDER DIRECT IMAGE FILE IF USER UPLOADED PNG/JPG
    if (_customFileBytes != null &&
        _customFileName != null &&
        (_customFileName!.endsWith('.png') ||
            _customFileName!.endsWith('.jpg') ||
            _customFileName!.endsWith('.jpeg'))) {
      return InteractiveViewer(
        maxScale: 4.0,
        minScale: 1.0,
        child: Image.memory(
          _customFileBytes!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // 3. FULL VISUAL PAYSLIP DOCUMENT SHEET (Matching Screenshot 1)
    // NEVER show a dark box with PDF icon! ALWAYS show full payslip document!
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customFileName != null ? 'DOCUMENT : $_customFileName' : 'VESTAS FRANCE SAS PEROLS',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const Text('BAT LATITUDE PARC DE L AEROPORT', style: TextStyle(color: Colors.black87, fontSize: 10)),
                    const Text('34470 PEROLS', style: TextStyle(color: Colors.black87, fontSize: 10)),
                    const Text('SIRET : 44084901600066', style: TextStyle(color: Colors.black87, fontSize: 9)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('BULLETIN DE PAIE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('DU : 01 JUILLET 2026', style: TextStyle(color: Colors.black87, fontSize: 10)),
                    Text('AU : 31 JUILLET 2026', style: TextStyle(color: Colors.black87, fontSize: 10)),
                    Text('NIR : 193109934108822', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
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
                children: const [
                  Text('SALARIÉ : NEGEM RICHARD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  Text('BRUT : 3 776,67 €', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
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
                      children: const [
                        Text('APPOINTEMENTS FORFAIT : 3 776.67 €', style: TextStyle(color: Colors.black, fontSize: 11)),
                        SizedBox(height: 4),
                        Text('COTISATIONS SALARIALES : - 840.78 €', style: TextStyle(color: Colors.black87, fontSize: 10)),
                        SizedBox(height: 4),
                        Text('TITRES REPAS DÉDUITS : - 52.80 €', style: TextStyle(color: Colors.black87, fontSize: 10)),
                        SizedBox(height: 4),
                        Text('INDEMNITE TELETRAVAIL : + 15.00 €', style: TextStyle(color: Colors.black87, fontSize: 10)),
                        SizedBox(height: 12),
                        Text('MONTANT NET SOCIAL : 2 952.28 €', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('NET A PAYER : 2 713.74 €', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 8),
                        Text('IBAN : FR76 4061 8803 7300 0403 1180 429', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryProvider);
    final records = salaryState.records;
    final analytics = salaryState.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Analyseur de bulletin de paie'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Guidance Checklist
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
                      const Expanded(
                        child: Text(
                          '📌 Éléments recommandés à caviarder avant l\'analyse IA :',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCyan,
                          side: const BorderSide(color: AppColors.accentCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(_customFileName ?? 'Charger PDF', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _pickUserPayslipFile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _BulletPoint('Nom et Prénom de l\'employé'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Adresse personnelle complète'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Numéro de Sécurité Sociale (NIR)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Coordonnées bancaires (IBAN/BIC)'),
                  const SizedBox(height: 8),
                  const _BulletPoint('Nom et SIRET de l\'entreprise'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Action Button: Masquer & Analyser le document
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
                label: const Text('Masquer & Analyser le document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  setState(() => _isProcessing = true);
                  final parsed = await SalaryParserService.parseDocument(
                    fileBytes: _customFileBytes,
                    fileName: _customFileName,
                  );
                  setState(() => _isProcessing = false);

                  if (!mounted) return;

                  if (parsed.periodDetected) {
                    final record = parsed.toSalaryRecord();
                    ref.read(salaryProvider.notifier).addRecord(record);
                    // ignore: use_build_context_synchronously
                    _showSuccessDialog(context, parsed, parsed.period);
                  } else {
                    // ignore: use_build_context_synchronously
                    _showPeriodWarningDialog(context, parsed);
                  }
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

            // Real Interactive Canvas Viewport (Matching Screenshot 1)
            SizedBox(
              height: 540,
              width: double.infinity,
              child: Stack(
                children: [
                  // Full Document White Paper Card
                  Container(
                    width: double.infinity,
                    height: 540,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Real Document Sheet (Screenshot 1 View)
                          Positioned.fill(child: _buildRealDocumentView()),

                          // Interactive Redaction Canvas
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

                  // Draggable Redaction Toolbar Overlay
                  Positioned(
                    top: _toolbarPos.dy,
                    left: _toolbarPos.dx,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _toolbarPos += details.delta;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.drag_indicator_rounded, color: AppColors.accentCyan, size: 22),
                            ),
                          ),
                          const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 6, endIndent: 6),
                          IconButton(
                            icon: Icon(Icons.touch_app_rounded, color: _selectedTool == RedactionTool.move ? AppColors.accentCyan : AppColors.textSecondary, size: 20),
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
                          const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 6, endIndent: 6),
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

                  // Bottom-Right Floating Eye Toggle Button
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
            const SizedBox(height: 28),

            // Timeline & Smoothed Salary Card
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historique & Revenu Lissé',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${records.length} bulletins enregistrés dans votre compte',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Moyenne : ${analytics.overallAverageNet.toStringAsFixed(2)} €/mois',
                          style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (analytics.growthTrendPercent != 0)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: AppColors.accentCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Progression du salaire : +${analytics.growthTrendPercent.toStringAsFixed(1)}% sur l\'historique',
                            style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Column(
                    children: records.map((record) {
                      final isBaseline = record.isLatestActive;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isBaseline ? AppColors.accentCyan.withValues(alpha: 0.1) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBaseline ? AppColors.accentCyan : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: record.id,
                              groupValue: salaryState.activeBaseline?.id,
                              activeColor: AppColors.accentCyan,
                              onChanged: (id) {
                                if (id != null) {
                                  ref.read(salaryProvider.notifier).setActiveBaseline(id);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        record.periodLabel,
                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (isBaseline) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentCyan,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Référent Actif', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    record.notes ?? record.status,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${record.netSalary.toStringAsFixed(2)} €',
                                  style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Brut : ${(record.grossSalary ?? 0).toStringAsFixed(2)} €',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                ref.read(salaryProvider.notifier).deleteRecord(record.id);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
