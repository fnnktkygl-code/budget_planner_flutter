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

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    // Chronological order (oldest to newest) for line graph
    final sortedRecords = List<SalaryRecord>.from(widget.records)
      ..sort((a, b) => a.period.compareTo(b.period));

    final maxNet = sortedRecords.map((r) => r.netSalary).reduce(max);

    final selectedRecord = _selectedIndex != null && _selectedIndex! < sortedRecords.length
        ? sortedRecords[_selectedIndex!]
        : sortedRecords.last;

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
          // Header KPI Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, color: AppColors.accentCyan, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Évolution & Tendance des Salaires',
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
              if (maxNet > widget.averageNet * 1.03)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentEmerald),
                  ),
                  child: Row(
                    children: [
                      const Text('🎁 Pic Prime : ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(
                        '${maxNet.toStringAsFixed(2)} €',
                        style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12),
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
                  selectedIndex: _selectedIndex ?? sortedRecords.length - 1,
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
              border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedRecord.periodLabel,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (selectedRecord.netSalary > widget.averageNet * 1.03) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🎁 Mois de Prime', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Net : ${selectedRecord.netSalary.toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Brut : ${(selectedRecord.grossSalary ?? 0).toStringAsFixed(2)} €',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
}

class _SalaryChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final double averageNet;
  final int selectedIndex;

  _SalaryChartPainter({
    required this.records,
    required this.averageNet,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final maxVal = records.map((r) => r.netSalary).reduce(max) * 1.05;
    final minVal = max(0.0, records.map((r) => r.netSalary).reduce(min) * 0.9);
    final valRange = max(1.0, maxVal - minVal);

    final double stepX = records.length > 1 ? size.width / (records.length - 1) : size.width;

    List<Offset> points = [];
    for (int i = 0; i < records.length; i++) {
      final x = records.length > 1 ? i * stepX : size.width / 2;
      final normalizedY = (records[i].netSalary - minVal) / valRange;
      final y = size.height - (normalizedY * (size.height - 40)) - 20;
      points.add(Offset(x, y));
    }

    // 1. Draw Dashed Average Line
    final avgY = size.height - (((averageNet - minVal) / valRange) * (size.height - 40)) - 20;
    final avgPaint = Paint()
      ..color = AppColors.accentCyan.withValues(alpha: 0.35)
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
        text: 'Moyenne : ${averageNet.toStringAsFixed(0)} €',
        style: TextStyle(color: AppColors.accentCyan.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
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
            AppColors.accentEmerald.withValues(alpha: 0.35),
            AppColors.accentCyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      // Stroke Line
      final strokePaint = Paint()
        ..color = AppColors.accentEmerald
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);
    }

    // 3. Draw Data Node Points & Month Labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;
      final isBonus = records[i].netSalary > averageNet * 1.03;

      // Vertical guide line for selected point
      if (isSelected) {
        final guidePaint = Paint()
          ..color = AppColors.accentCyan.withValues(alpha: 0.5)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(pt.dx, 0), Offset(pt.dx, size.height), guidePaint);
      }

      // Circle Point
      final pointPaint = Paint()
        ..color = isSelected ? Colors.white : (isBonus ? AppColors.accentEmerald : AppColors.accentCyan);

      final outerPaint = Paint()
        ..color = isSelected ? AppColors.accentCyan : (isBonus ? AppColors.accentEmerald.withValues(alpha: 0.4) : AppColors.cardBackground)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;

      canvas.drawCircle(pt, isSelected ? 7 : 5, pointPaint);
      canvas.drawCircle(pt, isSelected ? 7 : 5, outerPaint);

      // Month Label under point
      final labelText = records[i].periodLabel.split(' ')[0].substring(0, min(3, records[i].periodLabel.length));
      final tpMonth = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: isSelected ? AppColors.accentCyan : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpMonth.paint(canvas, Offset(pt.dx - (tpMonth.width / 2), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _SalaryChartPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.averageNet != averageNet;
  }
}
