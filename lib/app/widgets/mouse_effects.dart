import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Fare pozisyonunu takip eden ışık efekti widget'ı
class MouseLight extends StatefulWidget {
  final Widget child;
  final Color lightColor;
  final double lightSize;
  final double intensity;

  const MouseLight({
    Key? key,
    required this.child,
    this.lightColor = Colors.blue,
    this.lightSize = 300,
    this.intensity = 0.3,
  }) : super(key: key);

  @override
  State<MouseLight> createState() => _MouseLightState();
}

class _MouseLightState extends State<MouseLight> {
  Offset _mousePosition = Offset.zero;
  bool _isMouseInside = false;

  @override
  Widget build(BuildContext context) {
    // Web platformu dışında bu efekti devre dışı bırak
    if (!kIsWeb) return widget.child;

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isMouseInside = true;
          _mousePosition = event.localPosition;
        });
      },
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      onExit: (event) {
        setState(() {
          _isMouseInside = false;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_isMouseInside)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  isComplex: false, // Gereksiz yeniden çizimlerden kaçın
                  willChange: false, // Gereksiz yeniden çizimlerden kaçın
                  painter: _LightPainter(
                    mousePosition: _mousePosition,
                    lightColor: widget.lightColor,
                    lightSize: widget.lightSize,
                    intensity: widget.intensity,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Işık efekti için CustomPainter
class _LightPainter extends CustomPainter {
  final Offset mousePosition;
  final Color lightColor;
  final double lightSize;
  final double intensity;

  _LightPainter({
    required this.mousePosition,
    required this.lightColor,
    required this.lightSize,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return; // Boş alanlara çizim yapma

    final Paint paint = Paint();
    try {
      paint.shader = ui.Gradient.radial(mousePosition, lightSize, [
        lightColor.withOpacity(intensity),
        Colors.transparent,
      ]);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } catch (e) {
      // Shader oluşturma hatası olursa sessizce geç
      debugPrint('Shader error: $e');
    }
  }

  @override
  bool shouldRepaint(_LightPainter oldDelegate) {
    return mousePosition != oldDelegate.mousePosition;
  }
}

/// Hover animasyonu widget'ı
class HoverAnimatedWidget extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final Duration duration;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const HoverAnimatedWidget({
    Key? key,
    required this.child,
    this.hoverScale = 1.05,
    this.duration = const Duration(milliseconds: 200),
    this.hoverColor,
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  State<HoverAnimatedWidget> createState() => _HoverAnimatedWidgetState();
}

class _HoverAnimatedWidgetState extends State<HoverAnimatedWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Web platformu dışında basit bir wrapper olarak davran
    if (!kIsWeb) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()..scale(_isHovered ? widget.hoverScale : 1.0),
        padding: widget.padding,
        decoration:
            widget.hoverColor != null
                ? BoxDecoration(
                  color:
                      _isHovered
                          ? widget.hoverColor
                          : widget.hoverColor!.withOpacity(0),
                  borderRadius: widget.borderRadius,
                )
                : null,
        child: widget.child,
      ),
    );
  }
}

/// 360 derece döndürülebilir widget
class RotatableWidget extends StatefulWidget {
  final Widget child;
  final double size;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const RotatableWidget({
    Key? key,
    required this.child,
    this.size = 200,
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<RotatableWidget> createState() => _RotatableWidgetState();
}

class _RotatableWidgetState extends State<RotatableWidget> {
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  bool _isDragging = false;
  Offset _startPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    // Web platformu dışında sadece statik container göster
    if (!kIsWeb) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      );
    }

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _startPosition = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          setState(() {
            // Y ekseninde döndürme (x hareketi ile)
            _rotationY += (details.localPosition.dx - _startPosition.dx) / 100;
            // X ekseninde döndürme (y hareketi ile, ters yönde)
            _rotationX -= (details.localPosition.dy - _startPosition.dy) / 100;
            _startPosition = details.localPosition;
          });
        }
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 0 : 300),
            curve: Curves.easeOutBack,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: widget.borderRadius,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspektif
                      ..rotateX(_rotationX)
                      ..rotateY(_rotationY),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
