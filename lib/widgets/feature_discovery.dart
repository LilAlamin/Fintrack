import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

class FeatureDiscovery extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final VoidCallback onNext;
  final bool isLast;

  const FeatureDiscovery({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.onNext,
    this.isLast = false,
  });

  @override
  State<FeatureDiscovery> createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTargetRect();
    });
  }

  void _calculateTargetRect() {
    final RenderBox? renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _targetRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark Overlay with Hole
          GestureDetector(
            onTap: widget.onNext,
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SpotlightPainter(
                targetRect: _targetRect!,
                animationValue: _animation.value,
              ),
            ),
          ),
          
          // Instruction Card
          _buildInstructionCard(),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    // Determine positioning: if target is in bottom half, show card above it.
    final bool isBottomHalf = _targetRect!.top > MediaQuery.of(context).size.height / 2;
    
    return Positioned(
      left: 24,
      right: 24,
      top: isBottomHalf ? _targetRect!.top - 180 : _targetRect!.bottom + 40,
      child: FadeTransition(
        opacity: _animation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: widget.onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.isLast ? 'Selesai' : 'Lanjut',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double animationValue;

  _SpotlightPainter({required this.targetRect, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7 * animationValue);

    // Expand the rect slightly for better padding
    final spotlightRect = targetRect.inflate(10);
    final RRect spotlightRRect = RRect.fromRectAndRadius(
      spotlightRect,
      const Radius.circular(16),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(spotlightRRect),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => 
      oldDelegate.targetRect != targetRect || oldDelegate.animationValue != animationValue;
}
