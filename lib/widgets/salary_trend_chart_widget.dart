import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/salary_record.dart';

class SalaryTrendChartWidget extends StatefulWidget {
  final List<SalaryRecord> records;
  final double averageNet;
  final Function(SalaryRecord)? onRecordTap;

  const SalaryTrendChartWidget({
    super.key,
    required this.records,
    required this.averageNet,
    this.onRecordTap,
  });

  @override
  State<SalaryTrendChartWidget> createState() => _SalaryTrendChartWidgetState();
}

class _SalaryTrendChartWidgetState extends State<SalaryTrendChartWidget> {
  int? _selectedIndex;
  bool _useNetSocialView = false; // Normalisation fiscale (Net Social Avant PAS)

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    // Chronological order (oldest to newest) for line graph
    final sortedRecords = List<SalaryRecord>.from(widget.records)
      ..sort((a, b) => a.period.compareTo(b.period));

    final selectedIndex = _selectedIndex != null && _selectedIndex! < sortedRecords.length
        ? _selectedIndex!
        : sortedRecords.length - 1;
    final selectedRecord = sortedRecords[selectedIndex];

    final effectiveValue = _useNetSocialView ? selectedRecord.netSocial : selectedRecord.netSalary;

    // Detect if current selected record is a permanent salary increase vs previous month
    bool isSalaryIncrease = false;
    double growthPercent = 0.0;
    if (selectedIndex > 0) {
      final prevVal = _useNetSocialView
          ? sortedRecords[selectedIndex - 1].netSocial
          : sortedRecords[selectedIndex - 1].netSalary;
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
          // Header & Tax Normalization Toggle Row
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
                    '${sortedRecords.length} bulletins analysés chronologiquement',
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
                    InkWell(
                      onTap: () => setState(() => _useNetSocialView = false),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_useNetSocialView ? AppColors.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '🏦 En Banque',
                          style: TextStyle(
                            color: !_useNetSocialView ? Colors.white : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _useNetSocialView = true),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _useNetSocialView ? AppColors.accentPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '📈 Avant Impôt',
                          style: TextStyle(
                            color: _useNetSocialView ? Colors.white : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Chart Canvas
          SizedBox(
            height: 200,
            width: double.infinity,
            child: GestureDetector(
              onTapDown: (details) {
                final width = context.size?.width ?? 300;
                final dx = details.localPosition.dx;
                final step = width / max(1, sortedRecords.length - 1);
                final index = (dx / step).round().clamp(0, sortedRecords.length - 1);
                setState(() => _selectedIndex = index);
                if (widget.onRecordTap != null) {
                  widget.onRecordTap!(sortedRecords[index]);
                }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _SalaryChartPainter(
                  records: sortedRecords,
                  averageNet: widget.averageNet,
                  selectedIndex: selectedIndex,
                  useNetSocialView: _useNetSocialView,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected Point Details Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _useNetSocialView
                    ? AppColors.accentPurple.withValues(alpha: 0.4)
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
                        color: _useNetSocialView ? AppColors.accentPurple : AppColors.accentCyan,
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
                Row(
                  children: [
                    if (_useNetSocialView) ...[
                      Text(
                        'Net Social : ${selectedRecord.netSocial.toStringAsFixed(2)} €',
                        style: const TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Taux PAS : ${selectedRecord.incomeTaxRatePercent.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ] else ...[
                      Text(
                        'Net Banque : ${selectedRecord.netSalary.toStringAsFixed(2)} €',
                        style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Impôt IR : ${selectedRecord.incomeTaxAmount != 0.0 ? selectedRecord.incomeTaxAmount.toStringAsFixed(2) : "0.00"} €',
                        style: const TextStyle(color: AppColors.accentRose, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final double averageNet;
  final int selectedIndex;
  final bool useNetSocialView;

  _SalaryChartPainter({
    required this.records,
    required this.averageNet,
    required this.selectedIndex,
    required this.useNetSocialView,
  });

  double _getVal(SalaryRecord r) => useNetSocialView ? r.netSocial : r.netSalary;

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

    // 1. Draw Dashed Average Line
    final effAverage = useNetSocialView ? (averageNet * 1.08) : averageNet;
    final avgY = size.height - (((effAverage - minVal) / valRange) * (size.height - 40)) - 20;
    final lineColor = useNetSocialView ? AppColors.accentPurple : AppColors.accentCyan;

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

    // 2. Draw Smooth Bezier Curve & Fill
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

    // 3. Draw Data Points & Active Selection Highlight
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSel = i == selectedIndex;
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
