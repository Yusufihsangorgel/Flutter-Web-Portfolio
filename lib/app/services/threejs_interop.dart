/// Three.js JavaScript interop service for Flutter Web.
///
/// Uses `dart:js_interop` (the modern API) to bind to Three.js classes and
/// the `ThreeJSBridge` global exposed by `web/threejs_setup.js`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// ---------------------------------------------------------------------------
// ThreeJSBridge – the global object from threejs_setup.js
// ---------------------------------------------------------------------------

/// Options passed to [ThreeJSBridge.init].
///
/// Creates a plain JS object literal `{ bgColor, fov, antialias }`.
extension type ThreeJSInitOptions._(JSObject _) implements JSObject {
  /// Build an options object from Dart values.
  factory ThreeJSInitOptions({
    int? bgColor,
    int? fov,
    bool? antialias,
  }) {
    final obj = JSObject();
    if (bgColor != null) obj['bgColor'] = bgColor.toJS;
    if (fov != null) obj['fov'] = fov.toJS;
    if (antialias != null) obj['antialias'] = antialias.toJS;
    return ThreeJSInitOptions._(obj);
  }
}

/// Dart binding for `window.ThreeJSBridge`.
extension type ThreeJSBridge._(JSObject _) implements JSObject {
  /// Retrieve the singleton bridge from `window.ThreeJSBridge`.
  ///
  /// Returns `null` if the JS file has not been loaded yet.
  static ThreeJSBridge? get instance {
    final obj = globalContext['ThreeJSBridge'];
    if (obj == null || obj.isUndefinedOrNull) return null;
    return obj as ThreeJSBridge;
  }

  // -- lifecycle -------------------------------------------------------------

  external JSPromise<JSBoolean> init(
    String canvasId,
    ThreeJSInitOptions opts,
  );

  external void dispose();
  external void resize(double width, double height);

  // -- controls --------------------------------------------------------------

  external void updateMouse(double x, double y);
  external void updateScroll(double y);

  // -- scene presets ---------------------------------------------------------

  external void createHeroScene();
  external void createParticleField();
  external void createGlobeScene();

  // -- post-processing -------------------------------------------------------

  external JSPromise<JSBoolean> setupPostProcessing();

  // -- state -----------------------------------------------------------------

  external bool isReady();
  external void setOnReady(JSFunction callback);
}

// ---------------------------------------------------------------------------
// Three.js Core Class Bindings
//
// These bindings assume Three.js is available on the global `THREE` namespace.
// If Three.js is loaded as an ES module (as in threejs_setup.js), these
// constructors will NOT work directly from Dart. They are provided for
// advanced use cases where Three.js is loaded via a UMD/global script tag:
//
//   <script src="https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.min.js"></script>
//
// For the default setup, use ThreeJSBridge / ThreeJSService which delegates
// all Three.js construction to the JS bridge layer.
// ---------------------------------------------------------------------------

// --- Scene ------------------------------------------------------------------

@JS('THREE.Scene')
extension type ThreeScene._(JSObject _) implements JSObject {
  external factory ThreeScene();

  external void add(JSObject object);
  external void remove(JSObject object);
  external void clear();
  external void traverse(JSFunction callback);
  external JSArray<JSObject> get children;
}

// --- Camera -----------------------------------------------------------------

@JS('THREE.PerspectiveCamera')
extension type ThreePerspectiveCamera._(JSObject _) implements JSObject {
  external factory ThreePerspectiveCamera(
    num fov,
    num aspect,
    num near,
    num far,
  );

  external num get fov;
  external set fov(num value);
  external num get aspect;
  external set aspect(num value);
  external num get near;
  external set near(num value);
  external num get far;
  external set far(num value);

  external ThreeVector3 get position;
  external ThreeEuler get rotation;
  external void updateProjectionMatrix();
  external void lookAt(num x, num y, num z);
}

// --- Renderer ---------------------------------------------------------------

@JS('THREE.WebGLRenderer')
extension type ThreeWebGLRenderer._(JSObject _) implements JSObject {
  external factory ThreeWebGLRenderer(JSObject parameters);

  external void setSize(num width, num height);
  external void setPixelRatio(num ratio);
  external void setClearColor(JSAny color, [num? alpha]);
  external void render(ThreeScene scene, ThreePerspectiveCamera camera);
  external void dispose();

  external JSObject get domElement;
  external set outputColorSpace(String value);
}

// --- Geometries -------------------------------------------------------------

@JS('THREE.BoxGeometry')
extension type ThreeBoxGeometry._(JSObject _) implements JSObject {
  external factory ThreeBoxGeometry([
    num? width,
    num? height,
    num? depth,
    num? widthSegments,
    num? heightSegments,
    num? depthSegments,
  ]);
  external void dispose();
}

@JS('THREE.SphereGeometry')
extension type ThreeSphereGeometry._(JSObject _) implements JSObject {
  external factory ThreeSphereGeometry([
    num? radius,
    num? widthSegments,
    num? heightSegments,
  ]);
  external void dispose();
}

@JS('THREE.PlaneGeometry')
extension type ThreePlaneGeometry._(JSObject _) implements JSObject {
  external factory ThreePlaneGeometry([
    num? width,
    num? height,
    num? widthSegments,
    num? heightSegments,
  ]);
  external void dispose();
}

@JS('THREE.IcosahedronGeometry')
extension type ThreeIcosahedronGeometry._(JSObject _) implements JSObject {
  external factory ThreeIcosahedronGeometry([num? radius, num? detail]);
  external void dispose();
}

@JS('THREE.TorusGeometry')
extension type ThreeTorusGeometry._(JSObject _) implements JSObject {
  external factory ThreeTorusGeometry([
    num? radius,
    num? tube,
    num? radialSegments,
    num? tubularSegments,
  ]);
  external void dispose();
}

// --- Materials --------------------------------------------------------------

@JS('THREE.MeshStandardMaterial')
extension type ThreeMeshStandardMaterial._(JSObject _) implements JSObject {
  external factory ThreeMeshStandardMaterial([JSObject? parameters]);
  external void dispose();
  external set color(ThreeColor value);
  external set metalness(num value);
  external set roughness(num value);
  external set transparent(bool value);
  external set opacity(num value);
}

@JS('THREE.MeshPhysicalMaterial')
extension type ThreeMeshPhysicalMaterial._(JSObject _) implements JSObject {
  external factory ThreeMeshPhysicalMaterial([JSObject? parameters]);
  external void dispose();
  external set color(ThreeColor value);
  external set metalness(num value);
  external set roughness(num value);
  external set clearcoat(num value);
  external set transparent(bool value);
  external set opacity(num value);
}

// --- Lights -----------------------------------------------------------------

@JS('THREE.AmbientLight')
extension type ThreeAmbientLight._(JSObject _) implements JSObject {
  external factory ThreeAmbientLight([JSAny? color, num? intensity]);
  external num get intensity;
  external set intensity(num value);
}

@JS('THREE.PointLight')
extension type ThreePointLight._(JSObject _) implements JSObject {
  external factory ThreePointLight([
    JSAny? color,
    num? intensity,
    num? distance,
    num? decay,
  ]);
  external ThreeVector3 get position;
  external num get intensity;
  external set intensity(num value);
}

@JS('THREE.DirectionalLight')
extension type ThreeDirectionalLight._(JSObject _) implements JSObject {
  external factory ThreeDirectionalLight([JSAny? color, num? intensity]);
  external ThreeVector3 get position;
  external num get intensity;
  external set intensity(num value);
}

// --- Animation --------------------------------------------------------------

@JS('THREE.AnimationMixer')
extension type ThreeAnimationMixer._(JSObject _) implements JSObject {
  external factory ThreeAnimationMixer(JSObject root);
  external JSObject clipAction(JSObject clip);
  external void update(num delta);
}

@JS('THREE.Clock')
extension type ThreeClock._(JSObject _) implements JSObject {
  external factory ThreeClock([bool? autoStart]);
  external num getDelta();
  external num getElapsedTime();
  external void start();
  external void stop();
}

// --- Math helpers -----------------------------------------------------------

@JS('THREE.Vector3')
extension type ThreeVector3._(JSObject _) implements JSObject {
  external factory ThreeVector3([num? x, num? y, num? z]);
  external num get x;
  external set x(num value);
  external num get y;
  external set y(num value);
  external num get z;
  external set z(num value);
  external ThreeVector3 set(num x, num y, num z);
  external ThreeVector3 clone();
  external ThreeVector3 add(ThreeVector3 v);
  external ThreeVector3 sub(ThreeVector3 v);
  external ThreeVector3 multiplyScalar(num s);
  external num distanceTo(ThreeVector3 v);
  external ThreeVector3 normalize();
  external num length();
}

@JS('THREE.Euler')
extension type ThreeEuler._(JSObject _) implements JSObject {
  external factory ThreeEuler([num? x, num? y, num? z, String? order]);
  external num get x;
  external set x(num value);
  external num get y;
  external set y(num value);
  external num get z;
  external set z(num value);
  external ThreeEuler set(num x, num y, num z, [String? order]);
}

@JS('THREE.Color')
extension type ThreeColor._(JSObject _) implements JSObject {
  external factory ThreeColor([JSAny? color]);
  external num get r;
  external set r(num value);
  external num get g;
  external set g(num value);
  external num get b;
  external set b(num value);
  external ThreeColor set(JSAny value);
  external ThreeColor clone();
  external ThreeColor lerp(ThreeColor color, num alpha);
  external int getHex();
}

// --- Mesh -------------------------------------------------------------------

@JS('THREE.Mesh')
extension type ThreeMesh._(JSObject _) implements JSObject {
  external factory ThreeMesh(JSObject geometry, JSObject material);
  external ThreeVector3 get position;
  external ThreeEuler get rotation;
  external ThreeVector3 get scale;
}

// ---------------------------------------------------------------------------
// requestAnimationFrame binding
// ---------------------------------------------------------------------------

@JS('requestAnimationFrame')
external int jsRequestAnimationFrame(JSFunction callback);

@JS('cancelAnimationFrame')
external void jsCancelAnimationFrame(int id);

// ---------------------------------------------------------------------------
// High-level Dart helpers
// ---------------------------------------------------------------------------

/// Convenience wrapper for typical Dart-side Three.js operations.
class ThreeJSService {
  ThreeJSService._();

  static final ThreeJSService instance = ThreeJSService._();

  ThreeJSBridge? _bridge;

  /// Whether the bridge JS has been loaded and is accessible.
  bool get isAvailable => ThreeJSBridge.instance != null;

  /// Returns the bridge, caching the lookup.
  ThreeJSBridge? get bridge {
    _bridge ??= ThreeJSBridge.instance;
    return _bridge;
  }

  /// Initialise the renderer inside the given [canvasId] element.
  Future<bool> init({
    required String canvasId,
    int backgroundColor = 0x00101F,
    int fov = 60,
    bool antialias = true,
  }) async {
    final b = bridge;
    if (b == null) return false;

    try {
      final opts = ThreeJSInitOptions(
        bgColor: backgroundColor,
        fov: fov,
        antialias: antialias,
      );
      final result = await b.init(canvasId, opts).toDart;
      return result.toDart;
    } catch (e) {
      // ignore – JS side logs the error
      return false;
    }
  }

  /// Dispose all Three.js resources.
  void dispose() {
    bridge?.dispose();
  }

  /// Notify the JS scene of the current normalised mouse position (-1..1).
  void updateMouse(double x, double y) {
    bridge?.updateMouse(x, y);
  }

  /// Notify the JS scene of the current scroll offset.
  void updateScroll(double scrollY) {
    bridge?.updateScroll(scrollY);
  }

  /// Resize the renderer.
  void resize(double width, double height) {
    bridge?.resize(width, height);
  }

  /// Create the hero scene preset.
  void createHeroScene() => bridge?.createHeroScene();

  /// Create the particle field preset.
  void createParticleField() => bridge?.createParticleField();

  /// Create the globe scene preset.
  void createGlobeScene() => bridge?.createGlobeScene();

  /// Enable bloom post-processing if available.
  Future<bool> enablePostProcessing() async {
    final b = bridge;
    if (b == null) return false;
    try {
      final result = await b.setupPostProcessing().toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }
}
