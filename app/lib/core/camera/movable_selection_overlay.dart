import 'package:flutter/material.dart';

/// Simple movable and scalable selection overlay.
class MovableSelectionOverlay extends StatefulWidget {
  const MovableSelectionOverlay({this.onChanged, super.key});

  final ValueChanged<Rect>? onChanged;

  @override
  State<MovableSelectionOverlay> createState() =>
      _MovableSelectionOverlayState();
}

class _MovableSelectionOverlayState extends State<MovableSelectionOverlay> {
  // Position and size as fractions of parent size.
  Offset _center = const Offset(0.5, 0.4);
  double _widthFraction = 0.8;
  double _heightFraction = 0.35;

  Rect? _moveStartRect;
  Rect? _resizeStartRect;
  _Handle? _activeHandle;

  void _emitChange(Size parentSize) {
    widget.onChanged?.call(
      Rect.fromLTWH(
        _currentRect(parentSize).left / parentSize.width,
        _currentRect(parentSize).top / parentSize.height,
        _currentRect(parentSize).width / parentSize.width,
        _currentRect(parentSize).height / parentSize.height,
      ),
    );
  }

  Rect _currentRect(Size parentSize) {
    final frameSize = Size(
      parentSize.width * _widthFraction,
      parentSize.height * _heightFraction,
    );
    final topLeft = Offset(
      _center.dx * parentSize.width - frameSize.width / 2,
      _center.dy * parentSize.height - frameSize.height / 2,
    );
    return topLeft & frameSize;
  }

  Rect _clampRect(Rect rect, Size parentSize) {
    final minWidth = parentSize.width * 0.3;
    final minHeight = parentSize.height * 0.2;
    final maxWidth = parentSize.width * 0.95;
    final maxHeight = parentSize.height * 0.9;

    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    if (right - left < minWidth) right = left + minWidth;
    if (bottom - top < minHeight) bottom = top + minHeight;

    if (right - left > maxWidth) right = left + maxWidth;
    if (bottom - top > maxHeight) bottom = top + maxHeight;

    if (left < 0) {
      right -= left;
      left = 0;
    }
    if (top < 0) {
      bottom -= top;
      top = 0;
    }
    if (right > parentSize.width) {
      left -= right - parentSize.width;
      right = parentSize.width;
    }
    if (bottom > parentSize.height) {
      top -= bottom - parentSize.height;
      bottom = parentSize.height;
    }

    left = left.clamp(0.0, parentSize.width - minWidth);
    top = top.clamp(0.0, parentSize.height - minHeight);
    right = right.clamp(left + minWidth, parentSize.width);
    bottom = bottom.clamp(top + minHeight, parentSize.height);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _applyRect(Rect rect, Size parentSize) {
    final clamped = _clampRect(rect, parentSize);
    setState(() {
      final width = clamped.width;
      final height = clamped.height;
      _widthFraction = width / parentSize.width;
      _heightFraction = height / parentSize.height;
      _center = Offset(
        (clamped.left + clamped.width / 2) / parentSize.width,
        (clamped.top + clamped.height / 2) / parentSize.height,
      );
    });
    _emitChange(parentSize);
  }

  void _move(DragUpdateDetails details, Size parentSize) {
    final start = _moveStartRect;
    if (start == null) return;
    final newRect = start.shift(details.delta);
    _applyRect(newRect, parentSize);
    _moveStartRect = _currentRect(parentSize);
  }

  void _resize(DragUpdateDetails details, Size parentSize) {
    final start = _resizeStartRect;
    final handle = _activeHandle;
    if (start == null || handle == null) return;

    final minWidth = parentSize.width * 0.3;
    final minHeight = parentSize.height * 0.2;

    Rect next = start;
    switch (handle) {
      case _Handle.topLeft:
        next = Rect.fromLTRB(
          (start.left + details.delta.dx).clamp(0.0, start.right - minWidth),
          (start.top + details.delta.dy).clamp(0.0, start.bottom - minHeight),
          start.right,
          start.bottom,
        );
      case _Handle.topRight:
        next = Rect.fromLTRB(
          start.left,
          (start.top + details.delta.dy).clamp(0.0, start.bottom - minHeight),
          (start.right + details.delta.dx).clamp(
            start.left + minWidth,
            parentSize.width,
          ),
          start.bottom,
        );
      case _Handle.bottomLeft:
        next = Rect.fromLTRB(
          (start.left + details.delta.dx).clamp(0.0, start.right - minWidth),
          start.top,
          start.right,
          (start.bottom + details.delta.dy).clamp(
            start.top + minHeight,
            parentSize.height,
          ),
        );
      case _Handle.bottomRight:
        next = Rect.fromLTRB(
          start.left,
          start.top,
          (start.right + details.delta.dx).clamp(
            start.left + minWidth,
            parentSize.width,
          ),
          (start.bottom + details.delta.dy).clamp(
            start.top + minHeight,
            parentSize.height,
          ),
        );
    }

    _applyRect(next, parentSize);
    _resizeStartRect = _currentRect(parentSize);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
        final frameRect = _currentRect(parentSize);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _emitChange(parentSize);
          }
        });

        return Stack(
          children: [
            CustomPaint(
              size: parentSize,
              painter: _DimmerPainter(frameRect: frameRect),
            ),
            Positioned(
              left: frameRect.left,
              top: frameRect.top,
              width: frameRect.width,
              height: frameRect.height,
              child: GestureDetector(
                onPanStart: (_) {
                  _moveStartRect = frameRect;
                },
                onPanUpdate: (details) => _move(details, parentSize),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HandleWidget(
                        alignment: Alignment.topLeft,
                        onPanStart: (_) {
                          _resizeStartRect = frameRect;
                          _activeHandle = _Handle.topLeft;
                        },
                        onPanUpdate: (details) => _resize(details, parentSize),
                      ),
                      _HandleWidget(
                        alignment: Alignment.topRight,
                        onPanStart: (_) {
                          _resizeStartRect = frameRect;
                          _activeHandle = _Handle.topRight;
                        },
                        onPanUpdate: (details) => _resize(details, parentSize),
                      ),
                      _HandleWidget(
                        alignment: Alignment.bottomLeft,
                        onPanStart: (_) {
                          _resizeStartRect = frameRect;
                          _activeHandle = _Handle.bottomLeft;
                        },
                        onPanUpdate: (details) => _resize(details, parentSize),
                      ),
                      _HandleWidget(
                        alignment: Alignment.bottomRight,
                        onPanStart: (_) {
                          _resizeStartRect = frameRect;
                          _activeHandle = _Handle.bottomRight;
                        },
                        onPanUpdate: (details) => _resize(details, parentSize),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                'Drag and pinch the frame to select the ingredients area',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _Handle { topLeft, topRight, bottomLeft, bottomRight }

class _HandleWidget extends StatelessWidget {
  const _HandleWidget({
    required this.alignment,
    required this.onPanStart,
    required this.onPanUpdate,
  });

  final Alignment alignment;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(alignment.x < 0 ? -14 : 14, alignment.y < 0 ? -14 : 14),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black54, width: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DimmerPainter extends CustomPainter {
  _DimmerPainter({required this.frameRect});

  final Rect frameRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.52);
    final full = Offset.zero & size;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(full),
        Path()..addRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
        ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DimmerPainter oldDelegate) =>
      oldDelegate.frameRect != frameRect;
}
