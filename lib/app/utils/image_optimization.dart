import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

// ---------------------------------------------------------------------------
// Responsive image size resolver
// ---------------------------------------------------------------------------

/// Determines the appropriate image width for the current viewport.
class ResponsiveImageSize {
  const ResponsiveImageSize._();

  static const double mobile = 400;
  static const double tablet = 800;
  static const double desktop = 1200;

  /// Returns the image width bucket for the given screen width.
  static double forScreenWidth(double screenWidth) {
    if (screenWidth < Breakpoints.mobile) return mobile;
    if (screenWidth < Breakpoints.tablet) return tablet;
    return desktop;
  }

  /// Builds a responsive image URL by appending a width suffix.
  ///
  /// Given `assets/images/photo.jpg` and width 400, returns
  /// `assets/images/photo_400.jpg`.
  ///
  /// If [preferWebP] is true and the original is not already WebP, the
  /// extension is swapped to `.webp`.
  static String resolveUrl(
    String baseUrl, {
    required double targetWidth,
    bool preferWebP = true,
  }) {
    final dotIndex = baseUrl.lastIndexOf('.');
    if (dotIndex == -1) return baseUrl;

    final name = baseUrl.substring(0, dotIndex);
    final ext = baseUrl.substring(dotIndex); // includes the dot
    final widthSuffix = '_${targetWidth.toInt()}';

    if (preferWebP && ext.toLowerCase() != '.webp') {
      return '$name$widthSuffix.webp';
    }
    return '$name$widthSuffix$ext';
  }
}

// ---------------------------------------------------------------------------
// In-memory image cache
// ---------------------------------------------------------------------------

/// Simple bounded cache for decoded images keyed by URL.
class _ImageCache {
  _ImageCache({this.maxEntries = 100}); // ignore: unused_element_parameter

  final int maxEntries;
  final Map<String, ImageProvider> _cache = {};

  ImageProvider? get(String key) => _cache[key];

  void put(String key, ImageProvider provider) {
    if (_cache.length >= maxEntries) {
      // Evict oldest entry (insertion-order in Dart maps).
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = provider;
  }

  void clear() => _cache.clear();

  bool containsKey(String key) => _cache.containsKey(key);
}

final _imageCache = _ImageCache();

/// Clears the global optimized-image cache.
void clearOptimizedImageCache() => _imageCache.clear();

// ---------------------------------------------------------------------------
// OptimizedImage widget
// ---------------------------------------------------------------------------

/// Displays an image with progressive blur-up loading and responsive sizing.
///
/// Shows a tiny blurred [placeholderUrl] immediately, then loads the
/// full-resolution image appropriate for the viewport width. The transition
/// uses a smooth cross-fade.
///
/// ```dart
/// OptimizedImage(
///   imageUrl: 'assets/images/hero.jpg',
///   placeholderUrl: 'assets/images/hero_tiny.jpg',
///   width: double.infinity,
///   height: 400,
/// )
/// ```
class OptimizedImage extends StatefulWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.placeholderUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.preferWebP = true,
    this.lazyLoad = true,
    this.placeholderBlurSigma = 20.0,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.fadeCurve = Curves.easeOut,
    this.errorWidget,
  });

  /// Base URL/path of the image (without size suffix).
  final String imageUrl;

  /// Optional tiny placeholder for the blur-up effect.
  /// If null, a solid color placeholder is shown.
  final String? placeholderUrl;

  /// Widget dimensions. If null, the image determines its own size.
  final double? width;
  final double? height;

  /// How the image fits within its bounds.
  final BoxFit fit;

  /// Alignment within the bounds.
  final Alignment alignment;

  /// Optional border radius for clipping.
  final BorderRadius? borderRadius;

  /// Whether to prefer WebP format.
  final bool preferWebP;

  /// Whether to defer loading until the widget is near the viewport.
  final bool lazyLoad;

  /// Blur sigma applied to the placeholder during the blur-up phase.
  final double placeholderBlurSigma;

  /// Duration of the cross-fade from placeholder to full image.
  final Duration fadeDuration;

  /// Curve of the cross-fade animation.
  final Curve fadeCurve;

  /// Widget shown if the full image fails to load.
  final Widget? errorWidget;

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  ImageProvider? _fullImageProvider;
  bool _fullImageLoaded = false;
  bool _fullImageError = false;
  bool _isInViewport = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: widget.fadeCurve,
    );

    if (!widget.lazyLoad) {
      // Load immediately; viewport check happens in didChangeDependencies
      // when we have access to MediaQuery.
      _isInViewport = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInViewport && _fullImageProvider == null) {
      _resolveAndLoad();
    }
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _reset();
      if (_isInViewport) _resolveAndLoad();
    }
  }

  @override
  void dispose() {
    _removeImageStreamListener();
    _fadeController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Image resolution & loading
  // -----------------------------------------------------------------------

  void _resolveAndLoad() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetWidth = ResponsiveImageSize.forScreenWidth(screenWidth);
    final resolvedUrl = ResponsiveImageSize.resolveUrl(
      widget.imageUrl,
      targetWidth: targetWidth,
      preferWebP: widget.preferWebP,
    );

    // Check cache first.
    final cached = _imageCache.get(resolvedUrl);
    if (cached != null) {
      _fullImageProvider = cached;
      _onFullImageReady();
      return;
    }

    final provider = _createProvider(resolvedUrl);
    _fullImageProvider = provider;
    _imageCache.put(resolvedUrl, provider);

    // Listen for load completion.
    _removeImageStreamListener();
    final stream = provider.resolve(ImageConfiguration.empty);
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener(
      (_, __) => _onFullImageReady(),
      onError: _onFullImageError,
    );
    stream.addListener(_imageStreamListener!);
  }

  ImageProvider _createProvider(String url) {
    // Network images start with http(s), otherwise treat as asset.
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return AssetImage(url);
  }

  void _onFullImageReady() {
    if (!mounted) return;
    setState(() {
      _fullImageLoaded = true;
      _fullImageError = false;
    });
    _fadeController.forward();
  }

  void _onFullImageError(Object error, StackTrace? stack) {
    dev.log(
      'Failed to load image: ${widget.imageUrl}',
      name: 'OptimizedImage',
      error: error,
      stackTrace: stack,
    );

    if (!mounted) return;

    // Try original URL without WebP as fallback.
    if (widget.preferWebP && _fullImageProvider is! AssetImage) {
      _tryFallbackLoad();
      return;
    }

    setState(() {
      _fullImageError = true;
    });
  }

  void _tryFallbackLoad() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetWidth = ResponsiveImageSize.forScreenWidth(screenWidth);
    final fallbackUrl = ResponsiveImageSize.resolveUrl(
      widget.imageUrl,
      targetWidth: targetWidth,
      preferWebP: false,
    );

    final cached = _imageCache.get(fallbackUrl);
    if (cached != null) {
      _fullImageProvider = cached;
      _onFullImageReady();
      return;
    }

    final provider = _createProvider(fallbackUrl);
    _fullImageProvider = provider;
    _imageCache.put(fallbackUrl, provider);

    _removeImageStreamListener();
    final stream = provider.resolve(ImageConfiguration.empty);
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener(
      (_, __) => _onFullImageReady(),
      onError: (error, stack) {
        if (mounted) setState(() => _fullImageError = true);
      },
    );
    stream.addListener(_imageStreamListener!);
  }

  void _removeImageStreamListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _reset() {
    _removeImageStreamListener();
    _fadeController.reset();
    _fullImageProvider = null;
    _fullImageLoaded = false;
    _fullImageError = false;
  }

  // -----------------------------------------------------------------------
  // Viewport detection for lazy loading
  // -----------------------------------------------------------------------

  void _onVisibilityChanged(bool visible) {
    if (visible && !_isInViewport) {
      _isInViewport = true;
      _resolveAndLoad();
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    var content = _buildImageStack();

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    if (widget.lazyLoad && !_isInViewport) {
      return _ViewportDetector(
        onVisible: () => _onVisibilityChanged(true),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _buildPlaceholder(),
        ),
      );
    }

    return content;
  }

  Widget _buildImageStack() => SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder layer (always present until full image loads).
          if (!_fullImageLoaded) _buildPlaceholder(),

          // Full image layer with fade-in.
          if (_fullImageLoaded && _fullImageProvider != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image(
                image: _fullImageProvider!,
                fit: widget.fit,
                alignment: widget.alignment,
                errorBuilder: (_, __, ___) =>
                    widget.errorWidget ?? _buildErrorFallback(),
              ),
            ),

          // Error state.
          if (_fullImageError)
            widget.errorWidget ?? _buildErrorFallback(),
        ],
      ),
    );

  Widget _buildPlaceholder() {
    if (widget.placeholderUrl != null) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: _fullImageLoaded ? 0 : widget.placeholderBlurSigma,
          sigmaY: _fullImageLoaded ? 0 : widget.placeholderBlurSigma,
        ),
        child: Image.asset(
          widget.placeholderUrl!,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (_, __, ___) => _buildColorPlaceholder(),
        ),
      );
    }
    return _buildColorPlaceholder();
  }

  Widget _buildColorPlaceholder() => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );

  Widget _buildErrorFallback() => Container(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 32,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Viewport detector (lightweight intersection observer)
// ---------------------------------------------------------------------------

/// Detects when a widget enters the viewport and fires [onVisible].
class _ViewportDetector extends StatefulWidget {
  const _ViewportDetector({
    required this.onVisible,
    required this.child,
  });

  final VoidCallback onVisible;
  final Widget child;

  @override
  State<_ViewportDetector> createState() => _ViewportDetectorState();
}

class _ViewportDetectorState extends State<_ViewportDetector> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Schedule the visibility check after layout.
        if (!_notified) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _notified) return;
            _checkVisibility();
          });
        }
        return widget.child;
      },
    );
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) {
      // No scrollable ancestor — treat as visible.
      _notify();
      return;
    }

    final offset = viewport.getOffsetToReveal(renderObject, 0.0);
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _notify();
      return;
    }

    final scrollPosition = scrollable.position;
    final viewportStart = scrollPosition.pixels;
    final viewportEnd = viewportStart + scrollPosition.viewportDimension;
    final sectionStart = offset.offset;

    // Consider visible if the top is within or near the viewport.
    if (sectionStart <= viewportEnd + 500) {
      _notify();
    }
  }

  void _notify() {
    if (_notified) return;
    _notified = true;
    widget.onVisible();
  }
}
