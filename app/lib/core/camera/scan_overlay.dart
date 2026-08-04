import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    required this.frameAspectRatio,
    this.hint,
    this.showScanLine = true,
    super.key,
  });

  final double frameAspectRatio;
  final String? hint;
  final bool showScanLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - 72;
        final maxHeight = constraints.maxHeight * 0.42;
        var frameWidth = maxWidth;
        var frameHeight = frameWidth / frameAspectRatio;

        if (frameHeight > maxHeight) {
          frameHeight = maxHeight;
          frameWidth = frameHeight * frameAspectRatio;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _DimmedOverlayPainter(
                frameSize: Size(frameWidth, frameHeight),
              ),
            ),
            SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(frameWidth, frameHeight),
                    painter: _CornerFramePainter(),
                  ),
                  if (showScanLine)
                    _ScanLineAnimation(height: frameHeight - 24),
                  if (hint != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        hint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation({required this.height});

  final double height;

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, -1 + (_controller.value * 2)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DimmedOverlayPainter extends CustomPainter {
  _DimmedOverlayPainter({required this.frameSize});

  final Size frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.52);
    final fullRect = Offset.zero & size;
    final frameRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameSize.width,
      height: frameSize.height,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
        ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DimmedOverlayPainter oldDelegate) {
    return oldDelegate.frameSize != frameSize;
  }
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset start, Offset horizontalEnd, Offset verticalEnd) {
      canvas.drawLine(start, horizontalEnd, paint);
      canvas.drawLine(start, verticalEnd, paint);
    }

    drawCorner(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      const Offset(0, cornerLength),
    );
    drawCorner(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      Offset(size.width, cornerLength),
    );
    drawCorner(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      Offset(0, size.height - cornerLength),
    );
    drawCorner(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height - cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
