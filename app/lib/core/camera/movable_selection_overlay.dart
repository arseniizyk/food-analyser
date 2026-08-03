import 'package:flutter/material.dart';

class MovableSelectionOverlay extends StatefulWidget {
  const MovableSelectionOverlay({this.onChanged, super.key});

  final ValueChanged<Rect>? onChanged;

  @override
  State<MovableSelectionOverlay> createState() =>
      _MovableSelectionOverlayState();
}

class _MovableSelectionOverlayState extends State<MovableSelectionOverlay> {
  Offset _center = const Offset(0.5, 0.4);
  double _widthFraction = 0.45;
  double _heightFraction = 0.18;

  Size _parentSize = Size.zero;
  bool _initialEmitted = false;

  // Синхронизируем радиус маркера и радиус хит-теста
  static const double _handleRadius = 14;

  Rect get _frameRect {
    final w = _parentSize.width * _widthFraction;
    final h = _parentSize.height * _heightFraction;
    return Rect.fromCenter(
      center: Offset(
        _center.dx * _parentSize.width,
        _center.dy * _parentSize.height,
      ),
      width: w,
      height: h,
    );
  }

  Rect _normalizedRect(Rect r) {
    // Защита от деления на 0 при нулевых размерах родителя
    if (_parentSize.width <= 0 || _parentSize.height <= 0) {
      return const Rect.fromLTRB(0.1, 0.3, 0.9, 0.65);
    }
    return Rect.fromLTRB(
      (r.left / _parentSize.width).clamp(0.0, 1.0),
      (r.top / _parentSize.height).clamp(0.0, 1.0),
      (r.right / _parentSize.width).clamp(0.0, 1.0),
      (r.bottom / _parentSize.height).clamp(0.0, 1.0),
    );
  }

  void _emitChange() {
    if (_parentSize.width > 0 && _parentSize.height > 0) {
      widget.onChanged?.call(_normalizedRect(_frameRect));
    }
  }

  Rect _clampRect(Rect r) {
    final w = r.width.clamp(0.0, _parentSize.width);
    final h = r.height.clamp(0.0, _parentSize.height);

    var clamped = Rect.fromCenter(center: r.center, width: w, height: h);

    if (clamped.left < 0) clamped = clamped.shift(Offset(-clamped.left, 0));
    if (clamped.top < 0) clamped = clamped.shift(Offset(0, -clamped.top));
    if (clamped.right > _parentSize.width) {
      clamped = clamped.shift(Offset(_parentSize.width - clamped.right, 0));
    }
    if (clamped.bottom > _parentSize.height) {
      clamped = clamped.shift(Offset(0, _parentSize.height - clamped.bottom));
    }

    return clamped;
  }

  void _applyRect(Rect r) {
    if (_parentSize.width <= 0 || _parentSize.height <= 0) return;

    final clamped = _clampRect(r);
    setState(() {
      _widthFraction = clamped.width / _parentSize.width;
      _heightFraction = clamped.height / _parentSize.height;
      _center = Offset(
        (clamped.left + clamped.width / 2) / _parentSize.width,
        (clamped.top + clamped.height / 2) / _parentSize.height,
      );
    });
    _emitChange();
  }

  Rect _handleRectFor(Alignment corner) {
    final f = _frameRect;
    final dx = corner.x < 0 ? f.left : f.right;
    final dy = corner.y < 0 ? f.top : f.bottom;
    return Rect.fromCenter(
      center: Offset(dx, dy),
      width: _handleRadius * 2,
      height: _handleRadius * 2,
    );
  }

  bool _isOnBody(Offset localPos) =>
      _frameRect.contains(localPos) && !_isOnAnyHandle(localPos);

  bool _isOnAnyHandle(Offset localPos) {
    for (final c in _allCorners) {
      if (_handleRectFor(c).contains(localPos)) return true;
    }
    return false;
  }

  Alignment? _hitHandle(Offset localPos) {
    for (final c in _allCorners) {
      if (_handleRectFor(c).contains(localPos)) return c;
    }
    return null;
  }

  static const _allCorners = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  Offset? _dragStartPointer;
  Rect? _dragStartRect;
  Alignment? _activeCorner;

  void _onPointerDown(PointerDownEvent event) {
    final pos = event.localPosition;
    final corner = _hitHandle(pos);
    if (corner != null) {
      _activeCorner = corner;
      _dragStartRect = _frameRect;
      _dragStartPointer = pos;
    } else if (_isOnBody(pos)) {
      _activeCorner = null;
      _dragStartRect = _frameRect;
      _dragStartPointer = pos;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragStartPointer == null || _dragStartRect == null) return;
    final delta = event.localPosition - _dragStartPointer!;
    final start = _dragStartRect!;

    if (_activeCorner == null) {
      final shifted = start.shift(delta);
      _applyRect(shifted);
    } else {
      final c = _activeCorner!;

      double l = start.left, t = start.top, r = start.right, b = start.bottom;

      if (c.x < 0) l = (start.left + delta.dx).clamp(0.0, start.right);
      if (c.x > 0) {
        r = (start.right + delta.dx).clamp(start.left, _parentSize.width);
      }
      if (c.y < 0) t = (start.top + delta.dy).clamp(0.0, start.bottom);
      if (c.y > 0) {
        b = (start.bottom + delta.dy).clamp(start.top, _parentSize.height);
      }
      _applyRect(Rect.fromLTRB(l, t, r, b));
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _dragStartPointer = null;
    _dragStartRect = null;
    _activeCorner = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          final sizeChanged = _parentSize != newSize;
          _parentSize = newSize;

          // Пропускаем отрисовку, если контейнер еще не имеет размеров
          if (_parentSize.width <= 0 || _parentSize.height <= 0) {
            return const SizedBox.shrink();
          }

          // Переизлучаем координаты при первом кадре или при изменении размера экрана
          if (!_initialEmitted || sizeChanged) {
            _initialEmitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _emitChange();
            });
          }

          final f = _frameRect;

          return Stack(
            children: [
              CustomPaint(
                size: _parentSize,
                painter: _DimmerPainter(frameRect: f),
              ),
              Positioned(
                left: f.left,
                top: f.top,
                width: f.width,
                height: f.height,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
              for (final c in _allCorners)
                Positioned(
                  left: c.x < 0
                      ? f.left - _handleRadius
                      : f.right - _handleRadius,
                  top: c.y < 0
                      ? f.top - _handleRadius
                      : f.bottom - _handleRadius,
                  child: SizedBox(
                    width: _handleRadius * 2,
                    height: _handleRadius * 2,
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
              // const Positioned(
              //   left: 12,
              //   right: 12,
              //   bottom: 12,
              //   child: Text(
              //     'Drag the frame to select the ingredients area',
              //     textAlign: TextAlign.center,
              //     style: TextStyle(color: Colors.white70),
              //   ),
              // ),
            ],
          );
        },
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
