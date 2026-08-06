// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import '../constants/colors.dart';
import '../core/providers/salary_provider.dart';
import '../models/salary_record.dart';
import '../services/redactor_engine.dart';
import '../services/salary_parser_service.dart';
import '../widgets/notification_header.dart';
import '../widgets/salary_trend_chart_widget.dart';

class SalaryAuditScreen extends ConsumerStatefulWidget {
  const SalaryAuditScreen({super.key});

  @override
  ConsumerState<SalaryAuditScreen> createState() => _SalaryAuditScreenState();
}

class _SalaryAuditScreenState extends ConsumerState<SalaryAuditScreen> {
  final RedactorEngine _redactor = RedactorEngine();
  RedactionTool _selectedTool = RedactionTool.rect;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  double _zoomScale = 1.0; // 1.0 = 100%, 1.5 = 150%, 2.0 = 200%

  int _canvasTab = 0; // 0 = Canevas masqué, 1 = Rendu original
  bool _isProcessing = false;
  bool _isMaskVisible = true;

  Uint8List? _customFileBytes;
  Uint8List? _renderedPdfImageBytes;
  String? _customFileName;
  bool _isRenderingPdf = false;

  Offset? _startDrag;
  Offset? _currentDrag;
  List<Offset> _currentPaintPoints = [];

  // Draggable Toolbar Position State
  Offset _toolbarPos = const Offset(14, 14);

  // Period Selector Dialog State
  int _selectedYear = 2026;
  int _selectedMonth = 7;
  final List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() => _zoomScale = 1.0);
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale + 0.25).clamp(0.8, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale - 0.25).clamp(0.8, 3.0);
    });
  }

  void _clearCanvasDocument() {
    setState(() {
      _customFileBytes = null;
      _renderedPdfImageBytes = null;
      _customFileName = null;
      _redactor.clearAll();
      _resetZoom();
    });
  }

  Future<Uint8List?> _renderPdfBytesToImage(Uint8List bytes) async {
    if (kIsWeb) {
      final completer = Completer<Uint8List?>();

      js.context['onPdfPageRendered'] = (dynamic dataUrl) {
        if (dataUrl != null && dataUrl is String && dataUrl.startsWith('data:image')) {
          final base64Str = dataUrl.split(',')[1];
          completer.complete(base64Decode(base64Str));
        } else {
          completer.complete(null);
        }
      };

      try {
        final base64Pdf = base64Encode(bytes);
        js.context.callMethod('renderPdfBase64WithCallback', [base64Pdf, 'onPdfPageRendered']);
        return await completer.future;
      } catch (e) {
        debugPrint('[SalaryAuditScreen] JS PDF Render Exception: $e');
        return null;
      }
    } else {
      try {
        final pdfDoc = await PdfDocument.openData(bytes);
        final page = await pdfDoc.getPage(1);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );
        await pdfDoc.close();
        return pageImage?.bytes;
      } catch (e) {
        debugPrint('[SalaryAuditScreen] Native Pdfx Render Exception: $e');
        return null;
      }
    }
  }

  Future<String?> _extractPdfTextFromBytes(Uint8List bytes) async {
    if (kIsWeb) {
      final completer = Completer<String?>();
      js.context['onPdfTextExtracted'] = (dynamic text) {
        if (text != null && text is String && text.isNotEmpty) {
          completer.complete(text);
        } else {
          completer.complete(null);
        }
      };

      try {
        final base64Pdf = base64Encode(bytes);
        js.context.callMethod('extractPdfTextWithCallback', [base64Pdf, 'onPdfTextExtracted']);
        return await completer.future;
      } catch (e) {
        debugPrint('[SalaryAuditScreen] JS PDF Text Extraction Exception: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _processUploadedFile(Uint8List bytes, String fileName) async {
    setState(() {
      _customFileBytes = bytes;
      _customFileName = fileName;
      _renderedPdfImageBytes = null;
      _redactor.clearAll();
      _resetZoom();
    });

    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      setState(() => _isRenderingPdf = true);
      final renderedBytes = await _renderPdfBytesToImage(bytes);
      if (mounted) {
        setState(() {
          _renderedPdfImageBytes = renderedBytes;
          _isRenderingPdf = false;
        });
      }
    }
  }

  Future<void> _pickUserPayslipFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Single file import
        if (result.files.length == 1) {
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
          return;
        }

        // BATCH MULTI-FILE IMPORT QUEUE (5, 10, 12, 20 payslips)
        final files = result.files.where((f) => f.bytes != null).toList();
        if (files.isEmpty) return;

        int processedCount = 0;
        List<SalaryRecord> batchRecords = [];
        StateSetter? modalStateSetter;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                modalStateSetter = setModalState;
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      const Icon(Icons.folder_zip_rounded, color: AppColors.accentCyan, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Importation en lot ($processedCount / ${files.length})',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${((processedCount / files.length) * 100).round()}%',
                          style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 440,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'File d\'attente séquentielle IA anti-surcharge en cours...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 14),

                        // Linear Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: files.isNotEmpty ? processedCount / files.length : 0,
                            backgroundColor: AppColors.cardBackground,
                            color: AppColors.accentEmerald,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Live Processed List Items Checklist
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: ListView.builder(
                            itemCount: files.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, idx) {
                              final f = files[idx];
                              final isDone = idx < batchRecords.length;
                              final isCurrent = idx == batchRecords.length && processedCount < files.length;
                              final record = isDone ? batchRecords[idx] : null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.accentCyan.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    if (isDone)
                                      const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 18)
                                    else if (isCurrent)
                                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan))
                                    else
                                      const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        f.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isDone && record != null)
                                      Text(
                                        '${record.netSalary.toStringAsFixed(2)} €',
                                        style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12),
                                      )
                                    else if (isCurrent)
                                      const Text(
                                        'Analyse IA...',
                                        style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

        // Process batch sequentially in queue buffer
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          modalStateSetter?.call(() {});

          // Render PDF page image and extract text via PDF.js on Web
          Uint8List? renderedImg;
          String? extractedText;
          if (file.name.toLowerCase().endsWith('.pdf')) {
            renderedImg = await _renderPdfBytesToImage(file.bytes!);
            extractedText = await _extractPdfTextFromBytes(file.bytes!);
          }

          // Rate-limiting delay buffer to prevent API overload
          await Future.delayed(const Duration(milliseconds: 150));

          // Parse document values
          final parsed = await SalaryParserService.parseDocument(
            fileBytes: file.bytes,
            fileName: file.name,
            apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
            rawTextContent: extractedText,
          );

          final renderedB64 = renderedImg != null ? base64Encode(renderedImg) : null;
          final fileB64 = base64Encode(file.bytes!);

          final record = parsed.toSalaryRecord(
            customFileName: file.name,
            imageBase64: renderedB64,
            fileBase64: fileB64,
          );

          batchRecords.add(record);
          processedCount = i + 1;
          modalStateSetter?.call(() {});
        }

        // Add all batch records to state notifier
        ref.read(salaryProvider.notifier).addMultipleRecords(batchRecords);

        // Set latest processed file on canvas
        final lastFile = files.last;
        await _processUploadedFile(lastFile.bytes!, lastFile.name);

        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close batch modal
        }

        final zeroCount = batchRecords.where((r) => r.netSalary == 0.0).length;
        if (zeroCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $zeroCount bulletin(s) sur ${batchRecords.length} ont été importés. Veuillez cliquer sur la période pour indiquer le salaire net exact.'),
              backgroundColor: AppColors.accentRose,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Importation Réussie : ${batchRecords.length} bulletins analysés & ajoutés avec succès !'),
              backgroundColor: AppColors.accentEmerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[SalaryAuditScreen] Pick Multiple Files Exception: $e');
    }
  }

  void _switchDisplayedRecord(SalaryRecord record) {
    setState(() {
      _customFileName = record.documentName ?? record.periodLabel;
      if (record.renderedImageBase64 != null && record.renderedImageBase64!.isNotEmpty) {
        _renderedPdfImageBytes = base64Decode(record.renderedImageBase64!);
      } else {
        _renderedPdfImageBytes = null;
      }
      if (record.rawFileBase64 != null && record.rawFileBase64!.isNotEmpty) {
        _customFileBytes = base64Decode(record.rawFileBase64!);
      } else {
        _customFileBytes = null;
      }
      _redactor.clearAll();
      _resetZoom();
    });
    ref.read(salaryProvider.notifier).setActiveBaseline(record.id);
  }

  void _showExtractionConfirmationDialog(BuildContext context, RealParsedPayslip parsed) {
    _selectedYear = parsed.date.year;
    _selectedMonth = parsed.date.month;

    final netController = TextEditingController(text: parsed.netPayable.toStringAsFixed(2));
    final grossController = TextEditingController(text: parsed.grossSalary.toStringAsFixed(2));
    final netSocialController = TextEditingController(text: parsed.netSocial.toStringAsFixed(2));

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
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.accentCyan, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Validation des montants — ${parsed.period}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parsed.netPayable == 0.0 || !parsed.isParsedFromDocument) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentRose),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Veuillez saisir le montant Net à payer versé sur votre compte pour ce bulletin :',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const Text(
                        'Vérifiez et ajustez si besoin les montants de votre bulletin avant validation :',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        const Text('Mois :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 12),
                        const Text('Année :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            dropdownColor: AppColors.cardBackground,
                            isExpanded: true,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            items: [2023, 2024, 2025, 2026, 2027].map((yr) {
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
                    const SizedBox(height: 16),

                    TextField(
                      controller: netController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Net à payer (€)',
                        labelStyle: const TextStyle(color: AppColors.accentEmerald),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.accentEmerald),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: grossController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Salaire Brut (€)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentCyan),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: netSocialController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Montant Net Social (€)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.accentCyan),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final customNet = double.tryParse(netController.text.replaceAll(',', '.')) ?? parsed.netPayable;
                    final monthStr = _selectedMonth < 10 ? '0$_selectedMonth' : '$_selectedMonth';
                    final customPeriodKey = '$_selectedYear-$monthStr';
                    final customPeriodLabel = '${_monthsFr[_selectedMonth - 1]} $_selectedYear';

                    final renderedB64 = _renderedPdfImageBytes != null ? base64Encode(_renderedPdfImageBytes!) : null;
                    final fileB64 = _customFileBytes != null ? base64Encode(_customFileBytes!) : null;

                    final record = parsed.toSalaryRecord(
                      customPeriod: customPeriodKey,
                      customPeriodLabel: customPeriodLabel,
                      customNet: customNet,
                      customFileName: _customFileName,
                      imageBase64: renderedB64,
                      fileBase64: fileB64,
                    );

                    ref.read(salaryProvider.notifier).addRecord(record);

                    Navigator.pop(ctx);
                    _showSuccessDialog(context, record);
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

  void _showSuccessDialog(BuildContext context, SalaryRecord record) {
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
              Text(
                'Bulletin ${record.periodLabel} Enregistré !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ce bulletin a été ajouté avec succès à votre compte et devient votre salaire référent actif.',
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
                    _DialogRow(label: 'Période Validée', value: record.periodLabel),
                    const SizedBox(height: 10),
                    _DialogRow(label: 'Salaire Net à Payer', value: '${record.netSalary.toStringAsFixed(2)} €'),
                    const SizedBox(height: 10),
                    _DialogRow(label: 'Salaire Brut', value: '${(record.grossSalary ?? 0).toStringAsFixed(2)} €'),
                  ],
                ),
              ),
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
                  child: const Text('Fermer & Voir dans l\'Historique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvasContent(bool hasFileLoaded) {
    // 1. EMPTY STATE : No file imported yet
    if (_customFileBytes == null || _customFileBytes!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.note_add_outlined, color: AppColors.accentCyan, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun bulletin sur le canevas',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Importez un ou plusieurs bulletins de salaire (PDF / Images) pour les analyser et caviarder vos données.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                label: const Text('Importer bulletins (1 ou plusieurs)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _pickUserPayslipFiles,
              ),
            ],
          ),
        ),
      );
    }

    // 2. LOADING PDF RENDERER STATE
    if (_isRenderingPdf) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accentCyan),
            SizedBox(height: 16),
            Text('Rendu visuel du bulletin PDF en cours...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final Uint8List activeBytes = _renderedPdfImageBytes ?? _customFileBytes!;

    // 3. CENTERED CANVAS VIEWPORT WITH MOUSE WHEEL HORIZONTAL SCROLL
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleUpdate: (details) {
            if (details.scale != 1.0) {
              setState(() {
                _zoomScale = (_zoomScale * (details.scale > 1.0 ? 1.02 : 0.98)).clamp(0.8, 3.0);
              });
            }
          },
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dx != 0) {
                  if (_horizontalScrollController.hasClients) {
                    final target = (_horizontalScrollController.offset + pointerSignal.scrollDelta.dx).clamp(
                      0.0,
                      _horizontalScrollController.position.maxScrollExtent,
                    );
                    _horizontalScrollController.jumpTo(target);
                  }
                } else if (HardwareKeyboard.instance.isShiftPressed && pointerSignal.scrollDelta.dy != 0) {
                  if (_horizontalScrollController.hasClients) {
                    final target = (_horizontalScrollController.offset + pointerSignal.scrollDelta.dy).clamp(
                      0.0,
                      _horizontalScrollController.position.maxScrollExtent,
                    );
                    _horizontalScrollController.jumpTo(target);
                  }
                }
              }
            },
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                          child: Transform.scale(
                            scale: _zoomScale,
                            alignment: Alignment.topCenter,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 680),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // Document PDF Image Page
                                  Image.memory(
                                    activeBytes,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),

                                  // Redaction Mask Drawing Overlay
                                  if (_canvasTab == 0 && hasFileLoaded)
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryProvider);
    final records = salaryState.records;
    final analytics = salaryState.analytics;
    final hasFileLoaded = _customFileBytes != null && _customFileBytes!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NotificationHeaderWidget(title: 'Analyseur de bulletin de paie'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Guidance Checklist & Batch File Button
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
                      Row(
                        children: [
                          if (hasFileLoaded) ...[
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.accentRose, size: 22),
                              tooltip: 'Retirer le bulletin du canevas',
                              onPressed: _clearCanvasDocument,
                            ),
                            const SizedBox(width: 4),
                          ],
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 16),
                            label: Text(_customFileName ?? 'Importer bulletins (Lot / Unitaire)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _pickUserPayslipFiles,
                          ),
                        ],
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
                  backgroundColor: hasFileLoaded ? AppColors.accentCyan : AppColors.cardBackground,
                  foregroundColor: hasFileLoaded ? Colors.white : AppColors.textMuted,
                  elevation: hasFileLoaded ? 3 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology_rounded, size: 22),
                label: const Text('Masquer & Analyser le document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: hasFileLoaded
                    ? () async {
                        setState(() => _isProcessing = true);
                        String? extractedText;
                        if (_customFileBytes != null && (_customFileName ?? '').toLowerCase().endsWith('.pdf')) {
                          extractedText = await _extractPdfTextFromBytes(_customFileBytes!);
                        }
                        final parsed = await SalaryParserService.parseDocument(
                          fileBytes: _customFileBytes,
                          fileName: _customFileName,
                          apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
                          rawTextContent: extractedText,
                        );
                        setState(() => _isProcessing = false);

                        if (!mounted) return;
                        _showExtractionConfirmationDialog(context, parsed);
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Canvas Toggle Tabs & Zoom Controls Header
            Row(
              children: [
                Expanded(
                  child: Container(
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
                                'Canevas masqué (${_redactor.shapes.length})',
                                style: TextStyle(
                                  color: _canvasTab == 0 ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Industry Standard Zoom Controls (+ / - / % Badge)
                if (hasFileLoaded) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_out_rounded, color: AppColors.accentCyan, size: 20),
                          tooltip: 'Dézoomer (-25%)',
                          onPressed: _zoomOut,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${(_zoomScale * 100).round()}%',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in_rounded, color: AppColors.accentCyan, size: 20),
                          tooltip: 'Zoomer (+25%)',
                          onPressed: _zoomIn,
                        ),
                        IconButton(
                          icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textSecondary, size: 18),
                          tooltip: 'Réinitialiser 100%',
                          onPressed: _resetZoom,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Real Interactive Canvas Viewport
            SizedBox(
              height: 560,
              width: double.infinity,
              child: Stack(
                children: [
                  // Full Document Paper Card Container with Dual Scrollbars
                  Container(
                    width: double.infinity,
                    height: 560,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildCanvasContent(hasFileLoaded),
                    ),
                  ),

                  // Draggable Redaction Toolbar Overlay
                  if (hasFileLoaded)
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

                  // Bottom-Right Action Buttons (Remove & Eye Toggle)
                  if (hasFileLoaded)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Row(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'clearCanvasBtn',
                            backgroundColor: AppColors.accentRose.withValues(alpha: 0.85),
                            foregroundColor: Colors.white,
                            tooltip: 'Retirer le bulletin du canevas',
                            onPressed: _clearCanvasDocument,
                            child: const Icon(Icons.close_rounded, size: 20),
                          ),
                          const SizedBox(width: 10),
                          FloatingActionButton(
                            heroTag: 'eyeToggleBtn',
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
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Feature 2: Interactive Salary Trend & Bonus Chart Section
            if (records.isNotEmpty) ...[
              SalaryTrendChartWidget(
                records: records,
                averageNet: analytics.overallAverageNet,
                onRecordTap: (record) {
                  _switchDisplayedRecord(record);
                },
              ),
              const SizedBox(height: 28),
            ],

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
                            'Historique & Revenu Lissée',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            records.isNotEmpty
                                ? '${records.length} bulletins enregistrés dans votre compte'
                                : 'Aucun bulletin enregistré pour l\'instant',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      if (records.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppColors.accentRose),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('Vider l\'historique', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _clearCanvasDocument();
                            ref.read(salaryProvider.notifier).clearAllRecords();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (records.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Center(
                        child: Text(
                          'Vos bulletins de salaire analysés apparaîtront ici avec votre moyenne salariale lissée.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ),

                  if (records.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Salaire Net Moyen Lissée :', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${analytics.overallAverageNet.toStringAsFixed(2)} € / mois',
                            style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 14),
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
                                  _switchDisplayedRecord(record);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _switchDisplayedRecord(record),
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
                                  if (salaryState.activeBaseline?.id == record.id) {
                                    _clearCanvasDocument();
                                  }
                                  ref.read(salaryProvider.notifier).deleteRecord(record.id);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
