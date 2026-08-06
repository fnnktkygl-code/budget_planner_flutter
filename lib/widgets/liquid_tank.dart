import 'package:flutter/material.dart';
import '../constants/colors.dart';

class LiquidTankWidget extends StatelessWidget {
  final String title;
  final double currentAmount;
  final double targetAmount;
  final Color liquidColor;
  final VoidCallback? onEdit;

  const LiquidTankWidget({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    this.liquidColor = const Color(0xFFF59E0B), // Default Gold/Amber
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final int percentInt = (percentage * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Title + Edit Pencil Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.accentGold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cible : ${targetAmount.toStringAsFixed(0)} €',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),

          // Vertical Liquid Reservoir Capsule
          SizedBox(
            width: 110,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glass Capsule Border & Fill Painter
                CustomPaint(
                  size: const Size(110, 190),
                  painter: _LiquidCapsulePainter(
                    fillPercentage: percentage,
                    color: liquidColor,
                  ),
                ),

                // Center Percentage Text
                Text(
                  '$percentInt%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Amount Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              '${currentAmount.toStringAsFixed(0)} €',
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidCapsulePainter extends CustomPainter {
  final double fillPercentage;
  final Color color;

  _LiquidCapsulePainter({
    required this.fillPercentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2));

    // Outer Glass Track background
    final glassPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, glassPaint);

    final borderPaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    if (fillPercentage > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      final liquidHeight = size.height * fillPercentage;
      final liquidTop = size.height - liquidHeight;

      // Curved Liquid Surface Path
      final path = Path();
      path.moveTo(0, liquidTop);

      const waveCount = 2;
      final waveWidth = size.width / waveCount;
      for (int i = 0; i < waveCount; i++) {
        final startX = i * waveWidth;
        path.quadraticBezierTo(
          startX + waveWidth / 4,
          liquidTop - 3,
          startX + waveWidth / 2,
          liquidTop,
        );
        path.quadraticBezierTo(
          startX + (3 * waveWidth) / 4,
          liquidTop + 3,
          startX + waveWidth,
          liquidTop,
        );
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final liquidGradient = LinearGradient(
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final liquidPaint = Paint()
        ..shader = liquidGradient.createShader(Rect.fromLTWH(0, liquidTop, size.width, liquidHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, liquidPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
