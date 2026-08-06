import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/salary_record.dart';

class MultiTrendChartWidget extends StatefulWidget {
  final List<SalaryRecord> records;
  final double defaultFixedCharges;
  final double defaultSavings;
  final double defaultDaily;

  const MultiTrendChartWidget({
    super.key,
    required this.records,
    this.defaultFixedCharges = 1249.0,
    this.defaultSavings = 1139.77,
    this.defaultDaily = 189.96,
  });

  @override
  State<MultiTrendChartWidget> createState() => _MultiTrendChartWidgetState();
}

class _MultiTrendChartWidgetState extends State<MultiTrendChartWidget> {
  bool _includeIncomeTax = true; // With PAS vs Before PAS
  int? _hoverIndex;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Importez vos bulletins de paie pour visualiser le graphique multi-courbes.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final availableYears = widget.records.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));

    // Sort records chronologically by period key
    final allSorted = List<SalaryRecord>.from(widget.records)
      ..sort((a, b) => a.period.compareTo(b.period));

    final sorted = _selectedYear == null
        ? allSorted
        : allSorted.where((r) => r.year == _selectedYear).toList();

    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

    final salaryValues = sorted.map((r) {
      if (!_includeIncomeTax) return r.regularNetSocial;
      final yearRecs = sorted.where((x) => x.year == r.year && x.incomeTaxAmount.abs() > 1.0).toList();
      double pas = 0.0;
      if (yearRecs.isNotEmpty) {
        final normalPasRecs = yearRecs.where((x) => x.incomeTaxAmount.abs() < 400.0).toList();
        if (normalPasRecs.isNotEmpty) {
          pas = normalPasRecs.fold(0.0, (sum, x) => sum + x.incomeTaxAmount.abs()) / normalPasRecs.length;
        } else {
          pas = yearRecs.fold(0.0, (sum, x) => sum + x.incomeTaxAmount.abs()) / yearRecs.length;
        }
      }
      return (r.regularNetSocial - pas).clamp(0.0, double.infinity);
    }).toList();

    final fixedValues = sorted.map((_) => widget.defaultFixedCharges).toList();
    final savingsValues = sorted.map((_) => widget.defaultSavings).toList();
    final resteValues = List.generate(sorted.length, (i) {
      final s = salaryValues[i];
      final f = fixedValues[i];
      final v = savingsValues[i];
      final d = widget.defaultDaily;
      return (s - f - v - d).clamp(0.0, 10000.0);
    });

    final allMax = [
      ...salaryValues,
      ...fixedValues,
      ...savingsValues,
      ...resteValues,
    ].reduce((a, b) => a > b ? a : b);

    final maxY = (allMax * 1.15).clamp(2000.0, 6000.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar & PAS Filter Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart_rounded, color: AppColors.accentCyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Évolutions Superposées Temporelles',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Switcher: Avec Impôt PAS vs Net Social
              InkWell(
                onTap: () => setState(() => _includeIncomeTax = !_includeIncomeTax),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _includeIncomeTax ? Icons.account_balance_rounded : Icons.money_off_rounded,
                        size: 14,
                        color: AppColors.accentCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _includeIncomeTax ? 'Avec Impôt (Net)' : 'Avant Impôt (Social)',
                        style: const TextStyle(
                          color: AppColors.accentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMultiChartYearChip(null, 'Toutes les périodes (${widget.records.length} m)'),
                for (int y in availableYears) ...[
                  const SizedBox(width: 8),
                  _buildMultiChartYearChip(y, '$y (${widget.records.where((r) => r.year == y).length} m)'),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Multi-Curve Canvas Area with Hover & Touch Gestures
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final n = sorted.length;
                final stepX = n > 1 ? width / (n - 1) : width / 2;

                void updateHover(Offset localPos) {
                  final idx = (localPos.dx / stepX).round().clamp(0, n - 1);
                  if (_hoverIndex != idx) {
                    setState(() => _hoverIndex = idx);
                  }
                }

                return MouseRegion(
                  onHover: (evt) => updateHover(evt.localPosition),
                  onExit: (_) => setState(() => _hoverIndex = null),
                  child: GestureDetector(
                    onTapDown: (evt) => updateHover(evt.localPosition),
                    child: CustomPaint(
                      size: Size(width, constraints.maxHeight),
                      painter: _MultiTrendPainter(
                        records: sorted,
                        salaryValues: salaryValues,
                        fixedValues: fixedValues,
                        savingsValues: savingsValues,
                        resteValues: resteValues,
                        maxY: maxY,
                        hoverIndex: _hoverIndex,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Legend Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendPill('Revenu', AppColors.accentCyan),
              _buildLegendPill('Charges Fixes', AppColors.chartRed),
              _buildLegendPill('Épargne & PEA', AppColors.chartBlue),
              _buildLegendPill('Reste à vivre', AppColors.accentEmerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
  Widget _buildMultiChartYearChip(int? year, String label) {
    final isSelected = _selectedYear == year;
    return InkWell(
      onTap: () => setState(() {
        _selectedYear = year;
        _hoverIndex = null;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MultiTrendPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final List<double> salaryValues;
  final List<double> fixedValues;
  final List<double> savingsValues;
  final List<double> resteValues;
  final double maxY;
  final int? hoverIndex;

  _MultiTrendPainter({
    required this.records,
    required this.salaryValues,
    required this.fixedValues,
    required this.savingsValues,
    required this.resteValues,
    required this.maxY,
    this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final n = records.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width / 2;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset getPoint(int index, double val) {
      final x = n > 1 ? index * stepX : size.width / 2;
      final y = size.height - (val / maxY * size.height);
      return Offset(x, y.clamp(0.0, size.height));
    }

    void drawCurve(List<double> values, Color color, {double strokeWidth = 2.5}) {
      if (values.isEmpty) return;

      final pts = List.generate(values.length, (i) => getPoint(i, values[i]));
      final path = Path();
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      path.moveTo(pts[0].dx, pts[0].dy);

      if (pts.length == 1) {
        path.addOval(Rect.fromCircle(center: pts[0], radius: 2));
      } else {
        for (int i = 0; i < pts.length - 1; i++) {
          final p0 = pts[i];
          final p1 = pts[i + 1];
          final controlP1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
          final controlP2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
          path.cubicTo(controlP1.dx, controlP1.dy, controlP2.dx, controlP2.dy, p1.dx, p1.dy);
        }
      }

      canvas.drawPath(path, paint);

      // Draw points
      final dotPaint = Paint()..color = color;
      final bgDotPaint = Paint()..color = AppColors.cardBackground;

      for (int i = 0; i < pts.length; i++) {
        final isHovered = hoverIndex == i;
        final radius = isHovered ? 6.0 : 4.0;
        canvas.drawCircle(pts[i], radius, dotPaint);
        canvas.drawCircle(pts[i], isHovered ? 3.0 : 2.0, bgDotPaint);
      }
    }

    // Draw lines
    drawCurve(salaryValues, AppColors.accentCyan, strokeWidth: 3.0);
    drawCurve(fixedValues, AppColors.chartRed);
    drawCurve(savingsValues, AppColors.chartBlue);
    drawCurve(resteValues, AppColors.accentEmerald);

    // Draw active hover guide line and tooltip box
    if (hoverIndex != null && hoverIndex! >= 0 && hoverIndex! < n) {
      final idx = hoverIndex!;
      final record = records[idx];
      final salary = salaryValues[idx];
      final fixed = fixedValues[idx];
      final savings = savingsValues[idx];
      final reste = resteValues[idx];

      final x = n > 1 ? idx * stepX : size.width / 2;

      // Vertical dashed guide line
      final guidePaint = Paint()
        ..color = AppColors.accentCyan.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;

      for (double dy = 0; dy < size.height; dy += 6) {
        canvas.drawLine(Offset(x, dy), Offset(x, (dy + 3).clamp(0.0, size.height)), guidePaint);
      }

      // Draw Tooltip Card Box
      final String periodText = record.periodLabel.isNotEmpty ? record.periodLabel : record.period;
      const tooltipWidth = 175.0;
      const tooltipHeight = 105.0;
      double tooltipX = x + 12;
      if (tooltipX + tooltipWidth > size.width) {
        tooltipX = x - tooltipWidth - 12;
      }
      const tooltipY = 10.0;

      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(12),
      );

      canvas.drawRRect(
        cardRect,
        Paint()..color = AppColors.surface.withValues(alpha: 0.95),
      );
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = AppColors.accentCyan.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      TextPainter makeText(String text, Color color, {bool isBold = false, double fontSize = 11}) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        return tp;
      }

      final titleTp = makeText(periodText, AppColors.textPrimary, isBold: true, fontSize: 12);
      titleTp.paint(canvas, Offset(tooltipX + 10, tooltipY + 8));

      final revTp = makeText('• Revenu: ${salary.toStringAsFixed(2)} €', AppColors.accentCyan, isBold: true);
      revTp.paint(canvas, Offset(tooltipX + 10, tooltipY + 28));

      final fixTp = makeText('• Charges: ${fixed.toStringAsFixed(2)} €', AppColors.accentRose, isBold: true);
      fixTp.paint(canvas, Offset(tooltipX + 10, tooltipY + 46));

      final savTp = makeText('• Épargne: ${savings.toStringAsFixed(2)} €', AppColors.accentPurple, isBold: true);
      savTp.paint(canvas, Offset(tooltipX + 10, tooltipY + 64));

      final rstTp = makeText('• Reste: ${reste.toStringAsFixed(2)} €', AppColors.accentEmerald, isBold: true);
      rstTp.paint(canvas, Offset(tooltipX + 10, tooltipY + 82));
    }
  }

  @override
  bool shouldRepaint(covariant _MultiTrendPainter oldDelegate) {
    return oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.records != records ||
        oldDelegate.salaryValues != salaryValues;
  }
}
