import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AllocationSegment {
  final String id;
  final String label;
  final double percentage;
  final Color color;
  final List<AllocationSubItem> subItems;

  AllocationSegment({
    this.id = '',
    required this.label,
    required this.percentage,
    required this.color,
    this.subItems = const [],
  });
}

class AllocationSubItem {
  final String name;
  final double amount;
  final String? subtext;

  AllocationSubItem({
    required this.name,
    required this.amount,
    this.subtext,
  });
}

class DonutChartWidget extends StatefulWidget {
  final List<AllocationSegment> segments;
  final double netSalary;
  final Function(AllocationSegment)? onSegmentTap;

  const DonutChartWidget({
    super.key,
    required this.segments,
    this.netSalary = 2713.74,
    this.onSegmentTap,
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectSegment(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else {
        _selectedIndex = index;
        _animController.forward(from: 0.0);
      }
    });

    final selected = _selectedIndex != null ? widget.segments[_selectedIndex!] : null;
    if (selected != null) {
      widget.onSegmentTap?.call(selected);
      _showSubBreakdownBottomSheet(context, selected, widget.netSalary);
    }
  }

  void _showSubBreakdownBottomSheet(BuildContext context, AllocationSegment segment, double netSalary) {
    final segmentAmount = (netSalary * segment.percentage / 100);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Détail — ${segment.label} (${segment.percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: segment.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: segment.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant Total Alloué :', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${segmentAmount.toStringAsFixed(2)} € / mois',
                      style: TextStyle(color: segment.color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (segment.subItems.isNotEmpty) ...[
                const Text('Décomposition des postes :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: segment.subItems.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
                    itemBuilder: (context, i) {
                      final item = segment.subItems[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (item.subtext != null)
                                  Text(item.subtext!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                            Text(
                              '${item.amount.toStringAsFixed(2)} €',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun sous-poste spécifique configuré.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSegment = _selectedIndex != null ? widget.segments[_selectedIndex!] : null;
    final selectedAmount = selectedSegment != null
        ? (widget.netSalary * selectedSegment.percentage / 100)
        : widget.netSalary;

    return Column(
      children: [
        // Donut Chart Graphic with Interactive Touch & Dynamic Center Text
        GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localOffset = details.localPosition;
            final center = Offset(box.size.width / 2, 110);
            final dx = localOffset.dx - center.dx;
            final dy = localOffset.dy - center.dy;
            final dist = sqrt(dx * dx + dy * dy);

            // Ring touch boundary check
            if (dist >= 60 && dist <= 120) {
              double angle = atan2(dy, dx) + pi / 2;
              if (angle < 0) angle += 2 * pi;

              double total = widget.segments.fold(0.0, (sum, s) => sum + s.percentage);
              double accumulatedAngle = 0.0;

              for (int i = 0; i < widget.segments.length; i++) {
                double sweepAngle = (widget.segments[i].percentage / (total > 0 ? total : 100)) * 2 * pi;
                if (angle >= accumulatedAngle && angle <= accumulatedAngle + sweepAngle) {
                  _selectSegment(i);
                  break;
                }
                accumulatedAngle += sweepAngle;
              }
            }
          },
          child: SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _DonutChartPainter(
                    segments: widget.segments,
                    selectedIndex: _selectedIndex,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedSegment != null ? selectedSegment.label.toUpperCase() : 'ALLOCATION',
                      style: TextStyle(
                        color: selectedSegment != null ? selectedSegment.color : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedAmount.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: selectedSegment != null ? selectedSegment.color : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedSegment != null)
                      Text(
                        '${selectedSegment.percentage.toStringAsFixed(0)}% du net',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Legend Grid with Hover & Tap feedback
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.segments.length,
          itemBuilder: (context, idx) {
            final seg = widget.segments[idx];
            final isSelected = _selectedIndex == idx;

            return InkWell(
              onTap: () => _selectSegment(idx),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? seg.color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? seg.color : Colors.transparent),
                ),
                child: Row(
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
                        style: TextStyle(
                          color: isSelected ? seg.color : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isSelected ? seg.color : AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<AllocationSegment> segments;
  final int? selectedIndex;

  _DonutChartPainter({
    required this.segments,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) / 2 - 14;
    const baseStrokeWidth = 24.0;

    // Background track ring
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStrokeWidth;
    canvas.drawCircle(center, baseRadius, bgPaint);

    double startAngle = -pi / 2;
    final total = segments.fold(0.0, (sum, s) => sum + s.percentage);

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isSelected = selectedIndex == i;
      final sweepAngle = (seg.percentage / (total > 0 ? total : 100.0)) * 2 * pi;

      final strokeWidth = isSelected ? 30.0 : baseStrokeWidth;
      final radius = isSelected ? baseRadius + 3 : baseRadius;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
