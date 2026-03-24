/**
 * Three.js Bridge for Flutter Web Portfolio
 *
 * Loads Three.js via CDN and exposes scene presets and control
 * functions to Dart through the global `ThreeJSBridge` object.
 */

(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  let _scene, _camera, _renderer, _clock;
  let _animationId = null;
  let _composer = null;
  let _disposed = false;
  let _mouseX = 0, _mouseY = 0;
  let _scrollY = 0;
  let _sceneObjects = [];
  let _particleSystem = null;
  let _connections = null;
  let _fpsHistory = [];
  let _qualityScale = 1.0;
  let _onReady = null;
  let _animateCallback = null;

  // ---------------------------------------------------------------------------
  // CDN Loading
  // ---------------------------------------------------------------------------

  const THREE_CDN = 'https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js';
  let THREE = null;

  async function loadThreeJS() {
    if (THREE) return THREE;
    try {
      THREE = await import(THREE_CDN);
      return THREE;
    } catch (e) {
      console.error('[ThreeJSBridge] Failed to load Three.js:', e);
      throw e;
    }
  }

  // ---------------------------------------------------------------------------
  // Core lifecycle
  // ---------------------------------------------------------------------------

  /**
   * Initialise renderer, scene, camera and attach to the given canvas element.
   *
   * @param {string}  canvasId        – DOM id of the canvas element
   * @param {object}  opts
   * @param {number}  opts.bgColor    – hex background colour (default 0x00101F)
   * @param {number}  opts.fov        – camera field-of-view (default 60)
   * @param {boolean} opts.antialias  – enable anti-aliasing (default true)
   */
  async function init(canvasId, opts) {
    _disposed = false;
    await loadThreeJS();

    const container = document.getElementById(canvasId);
    if (!container) {
      console.error('[ThreeJSBridge] Container not found:', canvasId);
      return false;
    }

    const bgColor = (opts && opts.bgColor != null) ? opts.bgColor : 0x00101F;
    const fov = (opts && opts.fov) || 60;
    const antialias = (opts && opts.antialias != null) ? opts.antialias : true;

    // Renderer
    _renderer = new THREE.WebGLRenderer({
      antialias: antialias,
      alpha: true,
      powerPreference: 'high-performance',
    });
    _renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    _renderer.setSize(container.clientWidth, container.clientHeight);
    _renderer.setClearColor(bgColor, 1);
    _renderer.outputColorSpace = THREE.SRGBColorSpace;
    container.appendChild(_renderer.domElement);

    // Scene & Camera
    _scene = new THREE.Scene();
    _camera = new THREE.PerspectiveCamera(
      fov,
      container.clientWidth / container.clientHeight,
      0.1,
      1000,
    );
    _camera.position.z = 5;

    // Clock
    _clock = new THREE.Clock();

    if (_onReady) _onReady();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Animation loop with adaptive quality
  // ---------------------------------------------------------------------------

  function animate() {
    if (_disposed) return;
    _animationId = requestAnimationFrame(animate);

    const delta = _clock.getDelta();
    const elapsed = _clock.getElapsedTime();

    // FPS monitoring for adaptive quality
    _monitorFPS(delta);

    // Call the active scene's per-frame callback
    if (_animateCallback) {
      _animateCallback(delta, elapsed);
    }

    // Render
    if (_composer) {
      _composer.render(delta);
    } else if (_renderer && _scene && _camera) {
      _renderer.render(_scene, _camera);
    }
  }

  function _monitorFPS(delta) {
    if (delta <= 0) return;
    const fps = 1 / delta;
    _fpsHistory.push(fps);
    if (_fpsHistory.length > 60) _fpsHistory.shift();

    if (_fpsHistory.length === 60) {
      const avg = _fpsHistory.reduce((a, b) => a + b, 0) / _fpsHistory.length;
      if (avg < 24 && _qualityScale > 0.5) {
        _qualityScale = Math.max(0.5, _qualityScale - 0.1);
        _applyQualityScale();
      } else if (avg > 55 && _qualityScale < 1.0) {
        _qualityScale = Math.min(1.0, _qualityScale + 0.05);
        _applyQualityScale();
      }
    }
  }

  function _applyQualityScale() {
    if (!_renderer) return;
    _renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2) * _qualityScale);
  }

  // ---------------------------------------------------------------------------
  // Controls from Dart
  // ---------------------------------------------------------------------------

  function updateMouse(x, y) {
    // Normalised -1..1
    _mouseX = x;
    _mouseY = y;
  }

  function updateScroll(y) {
    _scrollY = y;
  }

  function resize(width, height) {
    if (!_renderer || !_camera) return;
    _camera.aspect = width / height;
    _camera.updateProjectionMatrix();
    _renderer.setSize(width, height);
    if (_composer) {
      _composer.setSize(width, height);
    }
  }

  function dispose() {
    _disposed = true;
    if (_animationId != null) {
      cancelAnimationFrame(_animationId);
      _animationId = null;
    }

    // Dispose scene objects
    _sceneObjects.forEach(function (obj) {
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) {
        if (Array.isArray(obj.material)) {
          obj.material.forEach(function (m) { m.dispose(); });
        } else {
          obj.material.dispose();
        }
      }
    });
    _sceneObjects = [];

    if (_particleSystem) {
      if (_particleSystem.geometry) _particleSystem.geometry.dispose();
      if (_particleSystem.material) _particleSystem.material.dispose();
      _particleSystem = null;
    }

    if (_connections) {
      if (_connections.geometry) _connections.geometry.dispose();
      if (_connections.material) _connections.material.dispose();
      _connections = null;
    }

    if (_scene) {
      _scene.traverse(function (child) {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
          if (Array.isArray(child.material)) {
            child.material.forEach(function (m) { m.dispose(); });
          } else {
            child.material.dispose();
          }
        }
      });
      _scene.clear();
      _scene = null;
    }

    if (_renderer) {
      _renderer.dispose();
      if (_renderer.domElement && _renderer.domElement.parentNode) {
        _renderer.domElement.parentNode.removeChild(_renderer.domElement);
      }
      _renderer = null;
    }

    if (_composer) {
      _composer = null;
    }

    _camera = null;
    _clock = null;
    _animateCallback = null;
    _fpsHistory = [];
    _qualityScale = 1.0;
  }

  // ---------------------------------------------------------------------------
  // Scene Preset: Hero Scene
  // ---------------------------------------------------------------------------

  function createHeroScene() {
    if (!THREE || !_scene) {
      console.error('[ThreeJSBridge] Call init() before creating a scene.');
      return;
    }

    _clearScene();

    // Ambient light
    const ambient = new THREE.AmbientLight(0x4466aa, 0.6);
    _scene.add(ambient);

    // Directional light
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(5, 5, 5);
    _scene.add(dirLight);

    // Point light that follows mouse subtly
    const pointLight = new THREE.PointLight(0x00d4ff, 1.2, 20);
    pointLight.position.set(0, 0, 4);
    _scene.add(pointLight);

    // Floating geometries
    const shapes = [];
    const geometries = [
      new THREE.IcosahedronGeometry(0.6, 1),
      new THREE.TorusGeometry(0.5, 0.2, 16, 32),
      new THREE.OctahedronGeometry(0.5, 0),
      new THREE.IcosahedronGeometry(0.4, 0),
      new THREE.TorusKnotGeometry(0.35, 0.12, 64, 16),
    ];

    const palette = [0x00d4ff, 0x7b2dff, 0x00ffaa, 0xff006e, 0xffbe0b];

    for (let i = 0; i < geometries.length; i++) {
      const material = new THREE.MeshPhysicalMaterial({
        color: palette[i % palette.length],
        metalness: 0.3,
        roughness: 0.4,
        transparent: true,
        opacity: 0.85,
        clearcoat: 0.5,
      });

      const mesh = new THREE.Mesh(geometries[i], material);

      // Distribute in a loose arrangement
      const angle = (i / geometries.length) * Math.PI * 2;
      const radius = 1.8 + Math.random() * 1.2;
      mesh.position.set(
        Math.cos(angle) * radius,
        Math.sin(angle) * radius * 0.6,
        (Math.random() - 0.5) * 2,
      );

      mesh.userData = {
        basePos: mesh.position.clone(),
        rotSpeed: 0.2 + Math.random() * 0.5,
        floatSpeed: 0.5 + Math.random() * 0.5,
        floatAmplitude: 0.15 + Math.random() * 0.2,
        phase: Math.random() * Math.PI * 2,
      };

      _scene.add(mesh);
      shapes.push(mesh);
      _sceneObjects.push(mesh);
    }

    _camera.position.set(0, 0, 6);

    _animateCallback = function (delta, elapsed) {
      // Rotate and float each shape
      shapes.forEach(function (mesh) {
        const ud = mesh.userData;
        mesh.rotation.x += ud.rotSpeed * delta;
        mesh.rotation.y += ud.rotSpeed * delta * 0.7;

        mesh.position.y = ud.basePos.y +
          Math.sin(elapsed * ud.floatSpeed + ud.phase) * ud.floatAmplitude;
      });

      // Subtle mouse parallax on camera
      _camera.position.x += (_mouseX * 0.8 - _camera.position.x) * 0.05;
      _camera.position.y += (_mouseY * 0.5 - _camera.position.y) * 0.05;
      _camera.lookAt(0, 0, 0);

      // Move point light towards mouse
      pointLight.position.x += (_mouseX * 3 - pointLight.position.x) * 0.1;
      pointLight.position.y += (_mouseY * 2 - pointLight.position.y) * 0.1;

      // Scroll-based camera z shift
      _camera.position.z = 6 + _scrollY * 0.002;
    };

    animate();
  }

  // ---------------------------------------------------------------------------
  // Scene Preset: Particle Field
  // ---------------------------------------------------------------------------

  function createParticleField() {
    if (!THREE || !_scene) {
      console.error('[ThreeJSBridge] Call init() before creating a scene.');
      return;
    }

    _clearScene();

    const PARTICLE_COUNT = 1200;
    const CONNECTION_DISTANCE = 1.5;
    const MAX_CONNECTIONS = 3000;

    // Particle positions & velocities
    const positions = new Float32Array(PARTICLE_COUNT * 3);
    const velocities = new Float32Array(PARTICLE_COUNT * 3);
    const colors = new Float32Array(PARTICLE_COUNT * 3);
    const baseColor = new THREE.Color(0x00d4ff);
    const accentColor = new THREE.Color(0x7b2dff);

    for (let i = 0; i < PARTICLE_COUNT; i++) {
      const i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 12;
      positions[i3 + 1] = (Math.random() - 0.5) * 12;
      positions[i3 + 2] = (Math.random() - 0.5) * 12;

      velocities[i3] = (Math.random() - 0.5) * 0.01;
      velocities[i3 + 1] = (Math.random() - 0.5) * 0.01;
      velocities[i3 + 2] = (Math.random() - 0.5) * 0.01;

      const mix = Math.random();
      const c = baseColor.clone().lerp(accentColor, mix);
      colors[i3] = c.r;
      colors[i3 + 1] = c.g;
      colors[i3 + 2] = c.b;
    }

    const particleGeometry = new THREE.BufferGeometry();
    particleGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    particleGeometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const particleMaterial = new THREE.PointsMaterial({
      size: 0.04,
      vertexColors: true,
      transparent: true,
      opacity: 0.8,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });

    _particleSystem = new THREE.Points(particleGeometry, particleMaterial);
    _scene.add(_particleSystem);

    // Connection lines
    const linePositions = new Float32Array(MAX_CONNECTIONS * 6);
    const lineColors = new Float32Array(MAX_CONNECTIONS * 6);
    const lineGeometry = new THREE.BufferGeometry();
    lineGeometry.setAttribute('position', new THREE.BufferAttribute(linePositions, 3));
    lineGeometry.setAttribute('color', new THREE.BufferAttribute(lineColors, 3));
    lineGeometry.setDrawRange(0, 0);

    const lineMaterial = new THREE.LineBasicMaterial({
      vertexColors: true,
      transparent: true,
      opacity: 0.3,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });

    _connections = new THREE.LineSegments(lineGeometry, lineMaterial);
    _scene.add(_connections);

    _camera.position.set(0, 0, 7);

    _animateCallback = function (delta) {
      const pos = _particleSystem.geometry.attributes.position.array;
      const bound = 6;

      // Update particle positions
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        const i3 = i * 3;
        pos[i3] += velocities[i3];
        pos[i3 + 1] += velocities[i3 + 1];
        pos[i3 + 2] += velocities[i3 + 2];

        // Boundary wrap
        for (let a = 0; a < 3; a++) {
          if (pos[i3 + a] > bound) pos[i3 + a] = -bound;
          if (pos[i3 + a] < -bound) pos[i3 + a] = bound;
        }
      }
      _particleSystem.geometry.attributes.position.needsUpdate = true;

      // Build connections (check only a subset each frame for performance)
      const lp = _connections.geometry.attributes.position.array;
      const lc = _connections.geometry.attributes.color.array;
      let lineIdx = 0;

      for (let i = 0; i < PARTICLE_COUNT && lineIdx < MAX_CONNECTIONS; i++) {
        const i3 = i * 3;
        for (let j = i + 1; j < PARTICLE_COUNT && lineIdx < MAX_CONNECTIONS; j++) {
          const j3 = j * 3;
          const dx = pos[i3] - pos[j3];
          const dy = pos[i3 + 1] - pos[j3 + 1];
          const dz = pos[i3 + 2] - pos[j3 + 2];
          const distSq = dx * dx + dy * dy + dz * dz;

          if (distSq < CONNECTION_DISTANCE * CONNECTION_DISTANCE) {
            const idx = lineIdx * 6;
            lp[idx] = pos[i3];
            lp[idx + 1] = pos[i3 + 1];
            lp[idx + 2] = pos[i3 + 2];
            lp[idx + 3] = pos[j3];
            lp[idx + 4] = pos[j3 + 1];
            lp[idx + 5] = pos[j3 + 2];

            const alpha = 1 - Math.sqrt(distSq) / CONNECTION_DISTANCE;
            lc[idx] = 0; lc[idx + 1] = 0.83 * alpha; lc[idx + 2] = 1.0 * alpha;
            lc[idx + 3] = 0; lc[idx + 4] = 0.83 * alpha; lc[idx + 5] = 1.0 * alpha;

            lineIdx++;
          }
        }
      }

      _connections.geometry.setDrawRange(0, lineIdx * 2);
      _connections.geometry.attributes.position.needsUpdate = true;
      _connections.geometry.attributes.color.needsUpdate = true;

      // Mouse parallax
      _camera.position.x += (_mouseX * 1.5 - _camera.position.x) * 0.03;
      _camera.position.y += (_mouseY * 1.0 - _camera.position.y) * 0.03;
      _camera.lookAt(0, 0, 0);

      // Scroll effect
      _camera.position.z = 7 + _scrollY * 0.003;
    };

    animate();
  }

  // ---------------------------------------------------------------------------
  // Scene Preset: Globe Scene
  // ---------------------------------------------------------------------------

  function createGlobeScene() {
    if (!THREE || !_scene) {
      console.error('[ThreeJSBridge] Call init() before creating a scene.');
      return;
    }

    _clearScene();

    // Ambient light
    const ambient = new THREE.AmbientLight(0x334466, 0.5);
    _scene.add(ambient);

    const pointLight = new THREE.PointLight(0x00d4ff, 1.5, 30);
    pointLight.position.set(5, 3, 5);
    _scene.add(pointLight);

    // Wireframe globe
    const globeGeom = new THREE.SphereGeometry(2, 32, 32);
    const globeMat = new THREE.MeshBasicMaterial({
      color: 0x00d4ff,
      wireframe: true,
      transparent: true,
      opacity: 0.15,
    });
    const globe = new THREE.Mesh(globeGeom, globeMat);
    _scene.add(globe);
    _sceneObjects.push(globe);

    // Inner solid sphere for depth
    const innerGeom = new THREE.SphereGeometry(1.95, 32, 32);
    const innerMat = new THREE.MeshPhysicalMaterial({
      color: 0x001830,
      transparent: true,
      opacity: 0.6,
      metalness: 0.2,
      roughness: 0.8,
    });
    const innerSphere = new THREE.Mesh(innerGeom, innerMat);
    _scene.add(innerSphere);
    _sceneObjects.push(innerSphere);

    // Highlighted points on globe surface
    const highlightPoints = [
      { lat: 41.0, lon: 29.0 },   // Istanbul
      { lat: 37.7, lon: -122.4 }, // San Francisco
      { lat: 51.5, lon: -0.1 },   // London
      { lat: 35.6, lon: 139.7 },  // Tokyo
      { lat: -33.8, lon: 151.2 }, // Sydney
      { lat: 48.8, lon: 2.3 },    // Paris
      { lat: 1.3, lon: 103.8 },   // Singapore
      { lat: 55.7, lon: 37.6 },   // Moscow
      { lat: -22.9, lon: -43.2 }, // Rio
      { lat: 25.2, lon: 55.3 },   // Dubai
    ];

    const dotGeom = new THREE.SphereGeometry(0.04, 8, 8);
    const dots = [];

    highlightPoints.forEach(function (pt) {
      const phi = (90 - pt.lat) * (Math.PI / 180);
      const theta = (pt.lon + 180) * (Math.PI / 180);
      const r = 2.02;

      const x = -r * Math.sin(phi) * Math.cos(theta);
      const y = r * Math.cos(phi);
      const z = r * Math.sin(phi) * Math.sin(theta);

      const dotMat = new THREE.MeshBasicMaterial({
        color: 0x00ffaa,
        transparent: true,
        opacity: 0.9,
      });
      const dot = new THREE.Mesh(dotGeom, dotMat);
      dot.position.set(x, y, z);
      dot.userData.phase = Math.random() * Math.PI * 2;
      globe.add(dot);
      dots.push(dot);
      _sceneObjects.push(dot);
    });

    // Rings
    const ringGeom = new THREE.RingGeometry(2.4, 2.42, 64);
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0x00d4ff,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.15,
    });
    const ring = new THREE.Mesh(ringGeom, ringMat);
    ring.rotation.x = Math.PI / 2.5;
    _scene.add(ring);
    _sceneObjects.push(ring);

    _camera.position.set(0, 1, 5);

    _animateCallback = function (delta, elapsed) {
      globe.rotation.y += 0.15 * delta;
      innerSphere.rotation.y += 0.15 * delta;
      ring.rotation.z += 0.05 * delta;

      // Pulsing dots
      dots.forEach(function (dot) {
        const pulse = 0.7 + 0.3 * Math.sin(elapsed * 2 + dot.userData.phase);
        dot.material.opacity = pulse;
        const s = 0.8 + 0.4 * Math.sin(elapsed * 1.5 + dot.userData.phase);
        dot.scale.setScalar(s);
      });

      // Mouse parallax
      _camera.position.x += (_mouseX * 1.0 - _camera.position.x) * 0.04;
      _camera.position.y += (1 + _mouseY * 0.5 - _camera.position.y) * 0.04;
      _camera.lookAt(0, 0, 0);

      // Scroll
      _camera.position.z = 5 + _scrollY * 0.002;
    };

    animate();
  }

  // ---------------------------------------------------------------------------
  // Post-processing (basic EffectComposer stub)
  // ---------------------------------------------------------------------------

  /**
   * Sets up a basic post-processing pipeline.
   * Requires Three.js addons loaded separately; this provides the wiring.
   */
  async function setupPostProcessing() {
    // Post-processing addons must be loaded from CDN
    try {
      const { EffectComposer } = await import(
        'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/postprocessing/EffectComposer.js'
      );
      const { RenderPass } = await import(
        'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/postprocessing/RenderPass.js'
      );
      const { UnrealBloomPass } = await import(
        'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/postprocessing/UnrealBloomPass.js'
      );

      if (!_renderer || !_scene || !_camera) return false;

      _composer = new EffectComposer(_renderer);
      _composer.addPass(new RenderPass(_scene, _camera));

      const bloomPass = new UnrealBloomPass(
        new THREE.Vector2(window.innerWidth, window.innerHeight),
        0.4,  // strength
        0.3,  // radius
        0.85, // threshold
      );
      _composer.addPass(bloomPass);

      return true;
    } catch (e) {
      console.warn('[ThreeJSBridge] Post-processing not available:', e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  function _clearScene() {
    if (_animationId != null) {
      cancelAnimationFrame(_animationId);
      _animationId = null;
    }

    _sceneObjects.forEach(function (obj) {
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) {
        if (Array.isArray(obj.material)) {
          obj.material.forEach(function (m) { m.dispose(); });
        } else {
          obj.material.dispose();
        }
      }
    });
    _sceneObjects = [];

    if (_particleSystem) {
      if (_particleSystem.geometry) _particleSystem.geometry.dispose();
      if (_particleSystem.material) _particleSystem.material.dispose();
      _particleSystem = null;
    }

    if (_connections) {
      if (_connections.geometry) _connections.geometry.dispose();
      if (_connections.material) _connections.material.dispose();
      _connections = null;
    }

    if (_scene) {
      while (_scene.children.length > 0) {
        _scene.remove(_scene.children[0]);
      }
    }

    _animateCallback = null;
    _composer = null;
  }

  function isReady() {
    return THREE !== null && _renderer !== null && !_disposed;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  window.ThreeJSBridge = {
    init: init,
    dispose: dispose,
    resize: resize,
    updateMouse: updateMouse,
    updateScroll: updateScroll,
    createHeroScene: createHeroScene,
    createParticleField: createParticleField,
    createGlobeScene: createGlobeScene,
    setupPostProcessing: setupPostProcessing,
    isReady: isReady,
    setOnReady: function (cb) { _onReady = cb; },
  };
})();
