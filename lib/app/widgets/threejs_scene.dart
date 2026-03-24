import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'package:flutter_web_portfolio/app/services/threejs_interop.dart';

/// The type of Three.js scene preset to render.
enum ThreeJSScenePreset {
  /// Floating geometric shapes with ambient light and slow rotation.
  hero,

  /// 1 200+ floating particles with connection lines.
  particleField,

  /// Wireframe globe with highlighted city points.
  globe,
}

/// A Flutter widget that embeds a Three.js WebGL canvas.
///
/// This is a web-only widget. It creates an HTML div, registers it as a
/// platform view, and initialises a Three.js scene inside it via the
/// [ThreeJSBridge] JS interop layer.
///
/// ```dart
/// ThreeJSScene(
///   preset: ThreeJSScenePreset.hero,
///   backgroundColor: 0x00101F,
///   cameraFov: 60,
///   antiAlias: true,
/// )
/// ```
class ThreeJSScene extends StatefulWidget {
  const ThreeJSScene({
    super.key,
    this.preset = ThreeJSScenePreset.hero,
    this.backgroundColor = 0x00101F,
    this.cameraFov = 60,
    this.antiAlias = true,
    this.enablePostProcessing = false,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// Which scene preset to display.
  final ThreeJSScenePreset preset;

  /// Background color as a hex int (e.g. `0x00101F`).
  final int backgroundColor;

  /// Camera field-of-view in degrees.
  final int cameraFov;

  /// Whether to enable anti-aliasing on the WebGL renderer.
  final bool antiAlias;

  /// Whether to enable bloom post-processing (requires addon CDN load).
  final bool enablePostProcessing;

  /// Optional builder shown while Three.js is loading.
  final WidgetBuilder? loadingBuilder;

  /// Optional builder shown when initialisation fails.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  @override
  State<ThreeJSScene> createState() => _ThreeJSSceneState();
}

class _ThreeJSSceneState extends State<ThreeJSScene> {
  static int _idCounter = 0;

  late final String _viewType;
  late final String _containerId;

  bool _ready = false;
  String? _error;

  final ThreeJSService _service = ThreeJSService.instance;

  @override
  void initState() {
    super.initState();
    _idCounter++;
    _containerId = 'threejs-container-$_idCounter';
    _viewType = 'threejs-view-$_idCounter';

    _registerView();
  }

  void _registerView() {
    // Register the platform view factory using dart:ui_web.
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) {
        final div = web.document.createElement('div') as web.HTMLDivElement
          ..id = _containerId;
        div.style
          ..width = '100%'
          ..height = '100%'
          ..overflow = 'hidden'
          ..position = 'relative';
        return div;
      },
    );

    // Wait a frame for the element to be in the DOM, then initialise.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initScene();
    });
  }

  Future<void> _initScene() async {
    // Allow the platform view to mount into the DOM.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    if (!_service.isAvailable) {
      if (mounted) {
        setState(() {
          _error = 'Three.js bridge not loaded. '
              'Ensure threejs_setup.js is included in index.html.';
        });
      }
      return;
    }

    final success = await _service.init(
      canvasId: _containerId,
      backgroundColor: widget.backgroundColor,
      fov: widget.cameraFov,
      antialias: widget.antiAlias,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _error = 'Failed to initialise Three.js renderer.';
      });
      return;
    }

    // Create the requested scene preset.
    _applyPreset(widget.preset);

    if (widget.enablePostProcessing) {
      await _service.enablePostProcessing();
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void _applyPreset(ThreeJSScenePreset preset) {
    switch (preset) {
      case ThreeJSScenePreset.hero:
        _service.createHeroScene();
      case ThreeJSScenePreset.particleField:
        _service.createParticleField();
      case ThreeJSScenePreset.globe:
        _service.createGlobeScene();
    }
  }

  @override
  void didUpdateWidget(ThreeJSScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset && _ready) {
      _applyPreset(widget.preset);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Input forwarding
  // --------------------------------------------------------------------------

  void _onPointerMove(PointerEvent event) {
    if (!_ready) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;

    // Normalise to -1..1
    final x = (event.localPosition.dx / size.width) * 2 - 1;
    final y = -((event.localPosition.dy / size.height) * 2 - 1);
    _service.updateMouse(x, y);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_ready) {
          _service.updateScroll(notification.metrics.pixels);
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Notify JS of size changes.
          if (_ready && constraints.maxWidth > 0 && constraints.maxHeight > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _service.resize(constraints.maxWidth, constraints.maxHeight);
            });
          }

          return Listener(
            onPointerMove: _onPointerMove,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The platform-embedded canvas.
                HtmlElementView(viewType: _viewType),

                // Loading overlay.
                if (!_ready && _error == null)
                  widget.loadingBuilder?.call(context) ??
                      const _DefaultLoadingIndicator(),

                // Error overlay.
                if (_error != null)
                  widget.errorBuilder?.call(context, _error!) ??
                      _DefaultErrorDisplay(error: _error!),
              ],
            ),
          );
        },
      ),
    );
}

// ---------------------------------------------------------------------------
// Default loading / error widgets
// ---------------------------------------------------------------------------

class _DefaultLoadingIndicator extends StatelessWidget {
  const _DefaultLoadingIndicator();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF00101F),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF00D4FF),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Initialising 3D scene\u2026',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DefaultErrorDisplay extends StatelessWidget {
  const _DefaultErrorDisplay({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF00101F),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xCCFF4444),
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}
