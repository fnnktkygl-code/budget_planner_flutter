import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AllocationSegment {
  final String label;
  final double percentage;
  final Color color;

  AllocationSegment({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

class DonutChartWidget extends StatelessWidget {
  final List<AllocationSegment> segments;

  const DonutChartWidget({
    super.key,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Donut Chart Graphic with Center Text
        SizedBox(
          height: 220,
          width: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _DonutChartPainter(segments: segments),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'ALLOCATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Actifs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Legend Grid (Matching Screenshot 1)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
          ),
          itemCount: segments.length,
          itemBuilder: (context, idx) {
            final seg = segments[idx];
            return Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${seg.label} (${seg.percentage.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<AllocationSegment> segments;

  _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 26.0;

    // Background track ring
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -pi / 2;
    final total = segments.fold(0.0, (sum, s) => sum + s.percentage);

    for (var seg in segments) {
      final sweepAngle = (seg.percentage / (total > 0 ? total : 100.0)) * 2 * pi;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04, // slight segment spacing gap
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
