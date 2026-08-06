import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/salary_record.dart';
import '../models/tax_adjustment.dart';

class SalaryTrendChartWidget extends StatefulWidget {
  final List<SalaryRecord> records;
  final double averageNet;
  final List<TaxAdjustment>? taxAdjustments;
  final Function(SalaryRecord)? onRecordTap;

  const SalaryTrendChartWidget({
    super.key,
    required this.records,
    required this.averageNet,
    this.taxAdjustments,
    this.onRecordTap,
  });

  @override
  State<SalaryTrendChartWidget> createState() => _SalaryTrendChartWidgetState();
}

class _SalaryTrendChartWidgetState extends State<SalaryTrendChartWidget> {
  int? _hoverIndex;
  int _viewMode = 0; // 0: En Banque (Net), 1: Avant Impôt (Net Social), 2: Réel Après DGFiP

  double _getRetroactiveNet(SalaryRecord record) {
    if (widget.taxAdjustments == null || widget.taxAdjustments!.isEmpty) {
      return record.netSalary;
    }
    final yearStr = record.period.split('-').first;
    final year = int.tryParse(yearStr) ?? 0;
    
    // Find tax adjustment matching this year
    final adjList = widget.taxAdjustments!.where((t) => t.taxYear == year).toList();
    if (adjList.isEmpty) {
      return record.netSalary;
    }
    
    final totalYearNetTaxDue = adjList.fold(0.0, (sum, t) => sum + t.netTaxDue);
    final monthlyRetroactiveTax = totalYearNetTaxDue / 12.0;

    return max(0.0, record.netSocial - monthlyRetroactiveTax);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    // Chronological order (oldest to newest) for line graph
    final sortedRecords = List<SalaryRecord>.from(widget.records)
      ..sort((a, b) => a.period.compareTo(b.period));

    final hoverIndex = _hoverIndex != null && _hoverIndex! < sortedRecords.length
        ? _hoverIndex!
        : sortedRecords.length - 1;
    final selectedRecord = sortedRecords[hoverIndex];

    final effectiveValue = _viewMode == 1
        ? selectedRecord.netSocial
        : _viewMode == 2
            ? _getRetroactiveNet(selectedRecord)
            : selectedRecord.netSalary;

    // Detect if current hovered record is a permanent salary increase vs previous month
    bool isSalaryIncrease = false;
    double growthPercent = 0.0;
    if (hoverIndex > 0) {
      final prevVal = _viewMode == 1
          ? sortedRecords[hoverIndex - 1].netSocial
          : _viewMode == 2
              ? _getRetroactiveNet(sortedRecords[hoverIndex - 1])
              : sortedRecords[hoverIndex - 1].netSalary;
      if (effectiveValue > prevVal + 15.0 && !selectedRecord.hasExplicitBonus) {
        isSalaryIncrease = true;
        growthPercent = ((effectiveValue - prevVal) / prevVal) * 100;
      }
    }

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
          // Header & Tax Normalization Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.show_chart_rounded, color: AppColors.accentCyan, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Évolution & Normalisation Fiscale',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sortedRecords.length} bulletins analysés (Survolez la courbe)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              // Tax Toggle Selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    _buildModeButton(0, '🏦 Banque'),
                    _buildModeButton(1, '📈 Brut Social'),
                    _buildModeButton(2, '⚖️ Réel DGFiP'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Chart Canvas with Hover & Touch Gestures
          SizedBox(
            height: 220,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final n = sortedRecords.length;
                final stepX = n > 1 ? width / (n - 1) : width / 2;

                void updateHover(Offset localPos) {
                  final idx = (localPos.dx / stepX).round().clamp(0, n - 1);
                  if (_hoverIndex != idx) {
                    setState(() => _hoverIndex = idx);
                    if (widget.onRecordTap != null) {
                      widget.onRecordTap!(sortedRecords[idx]);
                    }
                  }
                }

                return MouseRegion(
                  onHover: (evt) => updateHover(evt.localPosition),
                  onExit: (_) => setState(() => _hoverIndex = null),
                  child: GestureDetector(
                    onTapDown: (evt) => updateHover(evt.localPosition),
                    child: CustomPaint(
                      size: Size(width, constraints.maxHeight),
                      painter: _SalaryChartPainter(
                        records: sortedRecords,
                        averageNet: widget.averageNet,
                        selectedIndex: hoverIndex,
                        hoverIndex: _hoverIndex,
                        viewMode: _viewMode,
                        taxAdjustments: widget.taxAdjustments,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Floating / Glassmorphic Details Card for Hovered Node
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _viewMode == 1
                    ? AppColors.accentPurple.withValues(alpha: 0.4)
                    : _viewMode == 2
                        ? AppColors.accentGold.withValues(alpha: 0.4)
                        : AppColors.accentCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _viewMode == 1
                            ? AppColors.accentPurple
                            : _viewMode == 2
                                ? AppColors.accentGold
                                : AppColors.accentCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedRecord.periodLabel,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (selectedRecord.hasExplicitBonus) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🎁 ${selectedRecord.bonusDescription ?? "Prime Extrait"}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (isSalaryIncrease) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentCyan),
                        ),
                        child: Text(
                          '📈 Augmentation (${growthPercent > 0 ? "+" : ""}${growthPercent.toStringAsFixed(1)}%)',
                          style: const TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Net Social : ${selectedRecord.netSocial.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const Text('➔', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selectedRecord.incomeTaxAmount != 0.0
                            ? AppColors.accentRose.withValues(alpha: 0.15)
                            : AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedRecord.incomeTaxAmount != 0.0
                            ? 'IR (${selectedRecord.incomeTaxRatePercent.toStringAsFixed(1)}%) : -${selectedRecord.incomeTaxAmount.toStringAsFixed(2)} €'
                            : 'Non Imposé (0%)',
                        style: TextStyle(
                          color: selectedRecord.incomeTaxAmount != 0.0 ? AppColors.accentRose : AppColors.accentEmerald,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text('➔', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      'Net Banque : ${selectedRecord.netSalary.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, String label) {
    final isSelected = _viewMode == mode;
    Color activeColor = AppColors.accentCyan;
    if (mode == 1) activeColor = AppColors.accentPurple;
    if (mode == 2) activeColor = AppColors.accentGold;

    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SalaryChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final double averageNet;
  final int selectedIndex;
  final int? hoverIndex;
  final int viewMode;
  final List<TaxAdjustment>? taxAdjustments;

  _SalaryChartPainter({
    required this.records,
    required this.averageNet,
    required this.selectedIndex,
    this.hoverIndex,
    required this.viewMode,
    this.taxAdjustments,
  });

  double _getVal(SalaryRecord r) {
    if (viewMode == 1) return r.netSocial;
    if (viewMode == 2) {
      if (taxAdjustments == null || taxAdjustments!.isEmpty) return r.netSalary;
      final yearStr = r.period.split('-').first;
      final year = int.tryParse(yearStr) ?? 0;
      final adjList = taxAdjustments!.where((t) => t.taxYear == year).toList();
      if (adjList.isEmpty) return r.netSalary;
      final totalYearNetTaxDue = adjList.fold(0.0, (sum, t) => sum + t.netTaxDue);
      final monthlyRetroactiveTax = totalYearNetTaxDue / 12.0;
      return max(0.0, r.netSocial - monthlyRetroactiveTax);
    }
    return r.netSalary;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final values = records.map(_getVal).toList();
    final maxVal = values.reduce(max) * 1.05;
    final minVal = max(0.0, values.reduce(min) * 0.9);
    final valRange = max(1.0, maxVal - minVal);

    final double stepX = records.length > 1 ? size.width / (records.length - 1) : size.width;

    List<Offset> points = [];
    for (int i = 0; i < records.length; i++) {
      final x = records.length > 1 ? i * stepX : size.width / 2;
      final normalizedY = (values[i] - minVal) / valRange;
      final y = size.height - (normalizedY * (size.height - 40)) - 20;
      points.add(Offset(x, y));
    }

    // 1. Draw Dashed Vertical Guide Line on Hover
    if (hoverIndex != null && hoverIndex! < points.length) {
      final hoverPt = points[hoverIndex!];
      final guidePaint = Paint()
        ..color = AppColors.accentCyan.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      double dashY = 0;
      while (dashY < size.height) {
        canvas.drawLine(Offset(hoverPt.dx, dashY), Offset(hoverPt.dx, dashY + 4), guidePaint);
        dashY += 8;
      }
    }

    // 2. Draw Dashed Average Line
    final effAverage = viewMode == 1 ? (averageNet * 1.08) : averageNet;
    final avgY = size.height - (((effAverage - minVal) / valRange) * (size.height - 40)) - 20;
    Color lineColor = AppColors.accentCyan;
    if (viewMode == 1) lineColor = AppColors.accentPurple;
    if (viewMode == 2) lineColor = AppColors.accentGold;

    final avgPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 6, dashSpace = 4, startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, avgY), Offset(startX + dashWidth, avgY), avgPaint);
      startX += dashWidth + dashSpace;
    }

    // Label for Average Line
    final textPainterAvg = TextPainter(
      text: TextSpan(
        text: 'Moyenne : ${effAverage.toStringAsFixed(0)} €',
        style: TextStyle(color: lineColor.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterAvg.paint(canvas, Offset(10, avgY - 14));

    // 3. Draw Smooth Bezier Curve & Gradient Fill
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlP1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlP2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p1.dx, p1.dy);
      }

      // Gradient Fill
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Stroke Path
      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }

    // 4. Draw Data Points & Active Hover Highlight
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSel = i == (hoverIndex ?? selectedIndex);
      final rec = records[i];

      final pointColor = rec.hasExplicitBonus ? AppColors.accentGold : lineColor;

      if (isSel) {
        final outerPaint = Paint()..color = pointColor.withValues(alpha: 0.3);
        canvas.drawCircle(pt, 12, outerPaint);
        final innerPaint = Paint()..color = pointColor;
        canvas.drawCircle(pt, 6, innerPaint);
        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(pt, 2.5, corePaint);
      } else {
        final dotPaint = Paint()..color = pointColor;
        canvas.drawCircle(pt, rec.hasExplicitBonus ? 4.5 : 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
