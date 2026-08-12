import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLight;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLight = false,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isLight ? const Color(0xFF334155) : AppColors.cardBackground;
    final highlightColor = widget.isLight ? const Color(0xFF64748B) : AppColors.accentCyan;
    final accentColor = widget.isLight ? const Color(0xFF94A3B8) : AppColors.accentPurple;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor,
                highlightColor.withValues(alpha: 0.6),
                accentColor,
                highlightColor.withValues(alpha: 0.6),
                baseColor,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              begin: Alignment(-1.5 + (_controller.value * 3.5), -0.4),
              end: Alignment(-0.5 + (_controller.value * 3.5), 0.4),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerAnalysisOverlay extends StatefulWidget {
  final String statusText;
  const ShimmerAnalysisOverlay({
    super.key,
    this.statusText = 'Analyse du bulletin par l\'IA Gemini...',
  });

  @override
  State<ShimmerAnalysisOverlay> createState() => _ShimmerAnalysisOverlayState();
}

class _ShimmerAnalysisOverlayState extends State<ShimmerAnalysisOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _beamController;

  @override
  void initState() {
    super.initState();
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _beamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Scanning Beam Moving Up & Down
          AnimatedBuilder(
            animation: _beamController,
            builder: (context, child) {
              return Positioned(
                top: _beamController.value * 480,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accentCyan,
                        AppColors.accentPurple,
                        AppColors.accentCyan,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.8),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Central Shimmering Skeleton Card
          Center(
            child: ShimmerLoading(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: AppColors.accentCyan, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ShimmerBox(width: double.infinity, height: 16, borderRadius: 6),
                    const SizedBox(height: 10),
                    const ShimmerBox(width: 200, height: 14, borderRadius: 6),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: ShimmerBox(width: double.infinity, height: 40, borderRadius: 10)),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(width: double.infinity, height: 40, borderRadius: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerQueueRow extends StatelessWidget {
  final String fileName;
  const ShimmerQueueRow({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 16, height: 16, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 120, height: 10, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBox(width: 70, height: 20, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
