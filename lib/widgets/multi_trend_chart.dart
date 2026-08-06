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

    // Sort records chronologically by period key
    final sorted = List<SalaryRecord>.from(widget.records)
      ..sort((a, b) => a.period.compareTo(b.period));

    final salaryValues = sorted.map((r) {
      return _includeIncomeTax ? r.netSalary : r.netSocial;
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
          const SizedBox(height: 16),

          // Multi-Curve Canvas Area
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _MultiTrendPainter(
                    records: sorted,
                    salaryValues: salaryValues,
                    fixedValues: fixedValues,
                    savingsValues: savingsValues,
                    resteValues: resteValues,
                    maxY: maxY,
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
}

class _MultiTrendPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final List<double> salaryValues;
  final List<double> fixedValues;
  final List<double> savingsValues;
  final List<double> resteValues;
  final double maxY;

  _MultiTrendPainter({
    required this.records,
    required this.salaryValues,
    required this.fixedValues,
    required this.savingsValues,
    required this.resteValues,
    required this.maxY,
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
      final path = Path();
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < values.length; i++) {
        final pt = getPoint(i, values[i]);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, paint);

      // Draw points
      final dotPaint = Paint()..color = color;
      final bgDotPaint = Paint()..color = AppColors.cardBackground;

      for (int i = 0; i < values.length; i++) {
        final pt = getPoint(i, values[i]);
        canvas.drawCircle(pt, 4, dotPaint);
        canvas.drawCircle(pt, 2, bgDotPaint);
      }
    }

    // Draw lines
    drawCurve(salaryValues, AppColors.accentCyan, strokeWidth: 3.0);
    drawCurve(fixedValues, AppColors.chartRed);
    drawCurve(savingsValues, AppColors.chartBlue);
    drawCurve(resteValues, AppColors.accentEmerald);
  }

  @override
  bool shouldRepaint(covariant _MultiTrendPainter oldDelegate) => true;
}
