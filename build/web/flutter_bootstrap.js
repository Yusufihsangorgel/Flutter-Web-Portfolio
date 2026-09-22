(()=>{var C={blink:!0,gecko:!1,webkit:!1,unknown:!1},A=()=>navigator.vendor==="Google Inc."||navigator.userAgent.includes("Edg/")?"blink":navigator.vendor==="Apple Computer, Inc."?"webkit":navigator.vendor===""&&navigator.userAgent.includes("Firefox")?"gecko":"unknown",T=A(),x=()=>typeof ImageDecoder>"u"?!1:T==="blink",R=()=>typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u",j=()=>typeof window.TextCluster<"u",B=()=>{let n=[0,97,115,109,1,0,0,0,1,5,1,95,1,120,0];return WebAssembly.validate(new Uint8Array(n))},K=()=>{let n=document.createElement("canvas");return n.width=1,n.height=1,n.getContext("webgl2")!=null?2:n.getContext("webgl")!=null?1:-1},$=()=>window.chrome&&chrome.runtime&&chrome.runtime.id,f={browserEngine:T,hasImageCodecs:x(),hasChromiumBreakIterators:R(),hasTextCluster:j(),supportsWasmGC:B(),crossOriginIsolated:window.crossOriginIsolated,webGLVersion:K(),isChromeExtension:$()};function m(...n){return new URL(W(...n),document.baseURI).toString()}function W(...n){return n.filter(e=>!!e).map((e,s)=>s===0?L(e):F(L(e))).filter(e=>e.length).join("/")}function F(n){let e=0;for(;e<n.length&&n.charAt(e)==="/";)e++;return n.substring(e)}function L(n){let e=n.length;for(;e>0&&n.charAt(e-1)==="/";)e--;return n.substring(0,e)}function _(n,e){return n.canvasKitBaseUrl?n.canvasKitBaseUrl:e.engineRevision&&!e.useLocalCanvasKit?W("https://www.gstatic.com/flutter-canvaskit",e.engineRevision):"canvaskit"}var g=class{constructor(){this._scriptLoaded=!1}setTrustedTypesPolicy(e){this._ttPolicy=e}async loadEntrypoint(e){let{entrypointUrl:s=m("main.dart.js"),onEntrypointLoaded:t,nonce:r}=e||{};return this._loadJSEntrypoint(s,t,r)}async load(e,s,t,r,i){i??=a=>{a.initializeEngine(t).then(l=>l.runApp())};let{entrypointBaseUrl:o}=t,{entryPointBaseUrl:c}=t;if(!o&&c&&(console.warn("[deprecated] `entryPointBaseUrl` is deprecated and will be removed in a future release. Use `entrypointBaseUrl` instead."),o=c),e.compileTarget==="dart2wasm")return this._loadWasmEntrypoint(e,s,o,i);{let a=e.mainJsPath??"main.dart.js",l=m(o,a);return this._loadJSEntrypoint(l,i,r)}}didCreateEngineInitializer(e){typeof this._didCreateEngineInitializerResolve=="function"&&(this._didCreateEngineInitializerResolve(e),this._didCreateEngineInitializerResolve=null,delete _flutter.loader.didCreateEngineInitializer),typeof this._onEntrypointLoaded=="function"&&this._onEntrypointLoaded(e)}_loadJSEntrypoint(e,s,t){let r=typeof s=="function";if(!this._scriptLoaded){this._scriptLoaded=!0;let i=this._createScriptTag(e,t);if(r)console.debug("Injecting <script> tag. Using callback."),this._onEntrypointLoaded=s,document.head.append(i);else return new Promise((o,c)=>{console.debug("Injecting <script> tag. Using Promises. Use the callback approach instead!"),this._didCreateEngineInitializerResolve=o,i.addEventListener("error",c),document.head.append(i)})}}async _loadWasmEntrypoint(e,s,t,r){if(!this._scriptLoaded){this._scriptLoaded=!0,this._onEntrypointLoaded=r;let{mainWasmPath:i,jsSupportRuntimePath:o}=e,c=m(t,i),a=m(t,o);this._ttPolicy!=null&&(a=this._ttPolicy.createScriptURL(a));let p=(await import(a)).compileStreaming(fetch(c)),d;e.renderer==="skwasm"?d=(async()=>{let u=await s.skwasm;return window._flutter_skwasmInstance=u,{skwasm:u.wasmExports,skwasmWrapper:u,ffi:{memory:u.wasmMemory}}})():d=Promise.resolve({}),await(await(await p).instantiate(await d)).invokeMain()}}_createScriptTag(e,s){let t=document.createElement("script");t.type="application/javascript",s&&(t.nonce=s);let r=e;return this._ttPolicy!=null&&(r=this._ttPolicy.createScriptURL(e)),t.src=r,t}};async function E(n,e,s){if(e<0)return n;let t,r=new Promise((i,o)=>{t=setTimeout(()=>{o(new Error(`${s} took more than ${e}ms to resolve. Moving on.`,{cause:E}))},e)});return Promise.race([n,r]).finally(()=>{clearTimeout(t)})}var v=class{setTrustedTypesPolicy(e){this._ttPolicy=e}loadServiceWorker(e){if(!e||!("serviceWorker"in navigator))return Promise.resolve();let s=()=>{console.warn(`Loading the service worker using Flutter bootstrap is deprecated and will stop working in a future release.
For more details, see: https://github.com/flutter/flutter/issues/156910`)},t=()=>{let{serviceWorkerVersion:r,serviceWorkerUrl:i=m(`flutter_service_worker.js?v=${r}`),timeoutMillis:o=4e3}=e,c=i;this._ttPolicy!=null&&(c=this._ttPolicy.createScriptURL(c));let a=navigator.serviceWorker.register(c).then(l=>this._getNewServiceWorker(l,r)).then(this._waitForServiceWorkerActivation);return E(a,o,"prepareServiceWorker")};return e.serviceWorkerUrl!=null?(s(),t()):navigator.serviceWorker.getRegistration().then(r=>r?t():Promise.resolve())}async _getNewServiceWorker(e,s){if(!e.active&&(e.installing||e.waiting))return console.debug("Installing/Activating first service worker."),e.installing||e.waiting;if(e.active.scriptURL.endsWith(s))return console.debug("Loading from existing service worker."),e.active;{let t=await e.update();return console.debug("Updating service worker."),t.installing||t.waiting||t.active}}async _waitForServiceWorkerActivation(e){if(!e||e.state==="activated")if(e){console.debug("Service worker already active.");return}else throw new Error("Cannot activate a null service worker!");return new Promise((s,t)=>{e.addEventListener("statechange",()=>{e.state==="activated"&&(console.debug("Activated new service worker."),s())})})}};var y=class{constructor(e,s="flutter-js"){let t=e||[/\.js$/,/\.mjs$/];window.trustedTypes&&(this.policy=trustedTypes.createPolicy(s,{createScriptURL:function(r){if(r.startsWith("blob:"))return r;let i=new URL(r,window.location),o=i.pathname.split("/").pop();if(t.some(a=>a.test(o)))return i.toString();console.error("URL rejected by TrustedTypes policy",s,":",r,"(download prevented)")}}))}};var b=(n,e)=>{let s=window._flutter?.buildConfig?.wasmHashes,t=s?.[e];if(!t&&e.includes("/")){let a=e.split("/").pop();t=s?.[a]}let r="crossOriginStorage"in navigator&&"requestFileHandles"in navigator.crossOriginStorage;r&&console.log("Cross-Origin Storage is supported. See https://wicg.github.io/cross-origin-storage/ for more details.");let i=async a=>{let l={algorithm:"SHA-256",value:a};try{let[p]=await navigator.crossOriginStorage.requestFileHandles([l]),d=await p.getFile();return new Response(d,{headers:{"Content-Type":"application/wasm"}})}catch(p){p.name==="NotAllowedError"?console.warn(`Not allowed to retrieve ${e} (hash: ${a}).`):p.name!=="NotFoundError"&&console.warn(`Unexpected error during retrieval of ${e} (hash: ${a}).`,p)}},o=async()=>{if(r&&t){let l=await i(t);if(l)return l}let a=await fetch(n);if(r&&t&&a.ok){let l={algorithm:"SHA-256",value:t},p=a.clone();(async()=>{try{let d=await p.blob(),[h]=await navigator.crossOriginStorage.requestFileHandles([l],{create:!0}),w=await h.createWritable();await w.write(d),await w.close()}catch(d){console.warn(`Error storing ${e} (hash: ${t}):`,d)}})()}return a},c=WebAssembly.compileStreaming(o());return(a,l)=>((async()=>{let p=await c,d=await WebAssembly.instantiate(p,a);l(d,p)})(),{})};var I=(n,e,s,t)=>(window.flutterCanvasKitLoaded=(async()=>{if(window.flutterCanvasKit)return window.flutterCanvasKit;let r=s.hasChromiumBreakIterators&&s.hasImageCodecs;if(!r&&e.canvasKitVariant=="chromium")throw"Chromium CanvasKit variant specifically requested, but unsupported in this browser";let i=r&&e.canvasKitVariant!=="full",o=i&&e.preferWebParagraph&&s.hasTextCluster,c=t;o?c=m(c,"webparagraph"):i&&(c=m(c,"chromium"));let a=m(c,"canvaskit.js");n.flutterTT.policy&&(a=n.flutterTT.policy.createScriptURL(a));let l="canvaskit.wasm";o?l="webparagraph/canvaskit.wasm":i&&(l="chromium/canvaskit.wasm");let p=b(m(c,"canvaskit.wasm"),l),d=await import(a);return window.flutterCanvasKit=await d.default({instantiateWasm:p}),window.flutterCanvasKit})(),window.flutterCanvasKitLoaded);var U=async(n,e,s,t)=>{let i=!s.hasImageCodecs||!s.hasChromiumBreakIterators?"skwasm_heavy":e.enableWimp?"wimp":"skwasm",o=m(t,`${i}.js`),c=o;n.flutterTT.policy&&(c=n.flutterTT.policy.createScriptURL(c));let a=b(m(t,`${i}.wasm`),`${i}.wasm`),l=await import(c);return!s.crossOriginIsolated&&!e.forceSingleThreadedSkwasm&&!e.suppressMultithreadingWarning&&console.warn(`Flutter Web: Skwasm uses multi-threading and web workers for better performance, but your page needs to be cross-origin isolated to support multi-threading. Skwasm will run in single-threaded mode.
To enable multithreading, serve your app with these HTTP response headers:
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
See https://web.dev/articles/coop-coep for guidance.
To silence this warning, set \`suppressMultithreadingWarning: true\` in your Flutter configuration.`),await l.default({skwasmSingleThreaded:e.enableWimp||!s.crossOriginIsolated||s.isChromeExtension||e.forceSingleThreadedSkwasm,instantiateWasm:a,locateFile:(p,d)=>p.endsWith(".ww.js")?URL.createObjectURL(new Blob([`
"use strict";

let eventListener;
eventListener = (message) => {
    const pendingMessages = [];
    const data = message.data;
    data["instantiateWasm"] = (info,receiveInstance) => {
        const instance = new WebAssembly.Instance(data["wasm"], info);
        return receiveInstance(instance, data["wasm"])
    };
    import(data.js).then(async (skwasm) => {
        await skwasm.default(data);

        removeEventListener("message", eventListener);
        for (const message of pendingMessages) {
            dispatchEvent(message);
        }
    });
    removeEventListener("message", eventListener);
    eventListener = (message) => {

        pendingMessages.push(message);
    };

    addEventListener("message", eventListener);
};
addEventListener("message", eventListener);
`],{type:"application/javascript"})):m(t,p),mainScriptUrlOrBlob:o})};var P=f.supportsWasmGC,k=class{async loadEntrypoint(e){let{serviceWorker:s,...t}=e||{},r=new y,i=new v;i.setTrustedTypesPolicy(r.policy),await i.loadServiceWorker(s).catch(c=>{console.warn("Exception while loading service worker:",c)});let o=new g;return o.setTrustedTypesPolicy(r.policy),this.didCreateEngineInitializer=o.didCreateEngineInitializer.bind(o),o.loadEntrypoint(t)}async load({serviceWorkerSettings:e,onEntrypointLoaded:s,nonce:t,config:r}={}){r??={};let i=_flutter.buildConfig;if(!i)throw"FlutterLoader.load requires _flutter.buildConfig to be set";let o=r.wasmAllowList?.[f.browserEngine]??C[f.browserEngine],c=u=>{switch(u){case"skwasm":return P?f.webGLVersion>0?o?null:`Skwasm is disabled by your wasmAllowList configuration for browser engine "${f.browserEngine}".`:"Skwasm requires WebGL support; this browser does not provide it.":"Skwasm requires WasmGC support; this browser does not implement it yet.";default:return null}},a=u=>u.compileTarget==="dart2wasm"&&!P?"dart2wasm requires WasmGC support; this browser does not implement it yet.":r.renderer&&r.renderer!=u.renderer?`The application is configured to use the "${r.renderer}" renderer; this build targets "${u.renderer}".`:c(u.renderer),l,p=[];for(let u of i.builds){let S=a(u);if(S===null){l=u;break}p.push({candidate:u,reason:S})}if(r.verboseBuildSelection)for(let u of p)console.warn(`Flutter Web: build ${u.candidate.compileTarget}/${u.candidate.renderer} was skipped: ${u.reason}`);if(!l)throw console.warn("Flutter Web: no compatible build found for this browser."+(r.verboseBuildSelection?"":" Set `verboseBuildSelection: true` in your Flutter configuration to see why each candidate was rejected.")),new Error("FlutterLoader could not find a build compatible with configuration and environment.");let d={};d.flutterTT=new y,e&&(d.serviceWorkerLoader=new v,d.serviceWorkerLoader.setTrustedTypesPolicy(d.flutterTT.policy),await d.serviceWorkerLoader.loadServiceWorker(e).catch(u=>{console.warn("Exception while loading service worker:",u)}));let h=_(r,i);l.renderer==="canvaskit"?d.canvasKit=I(d,r,f,h):l.renderer==="skwasm"&&(d.skwasm=U(d,r,f,h));let w=new g;return w.setTrustedTypesPolicy(d.flutterTT.policy),this.didCreateEngineInitializer=w.didCreateEngineInitializer.bind(w),w.load(l,d,r,t,s)}};window._flutter||(window._flutter={});window._flutter.loader||(window._flutter.loader=new k);})();
//# sourceMappingURL=flutter.js.map

if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"af7e796e161ae0bb1ff0758c71a7105418bd9ded","wasmHashes":{"wimp.wasm":"e924eaafd801d41e017d178f3fd5cf8a417f641fe35c9ed34a4e1d7582283e0c","webparagraph/canvaskit.wasm":"0ce1b05082efdc8529550e8a01f6ff0593972d55525035010e26f5600aa9f254","skwasm.wasm":"e540fd5e8303b7b68ec2718cb49e9c421f8ade3075b15e02a7059a62654df9a1","chromium/canvaskit.wasm":"ae8ff1d858140f7b1300ced3fa89fb8c9dce0a400a0f4f1e11f6dcfb3315fdcf","canvaskit.wasm":"fbed517a43e82452404446683f00f2e876d835aed84410695759e67b6bb01cd3","skwasm_heavy.wasm":"565f5cc1cca6ab120f11934b105f01fec4b58b480c82e0889dca93af8e6f8635","main.dart.wasm":"226fa3cbad52076155ee8c68d1c1d37ad61d5be882467d32f7adc828189c56dd"},"builds":[{"compileTarget":"dart2wasm","renderer":"skwasm","mainWasmPath":"main.dart.wasm?v=ad5b9422714bae17","jsSupportRuntimePath":"main.dart.mjs?v=ad5b9422714bae17"},{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js?v=ad5b9422714bae17"}],"useLocalCanvasKit":true};


const markRuntime = (name) => window.performance?.mark(name);
const measureRuntime = (name, start, end) => {
  if (
    !window.performance?.getEntriesByName(start, 'mark').length ||
    !window.performance?.getEntriesByName(end, 'mark').length
  ) {
    return;
  }
  window.performance.measure(name, start, end);
};

markRuntime('flutter-bootstrap-start');

const bootstrapCopy = window.__portfolioBootstrapLocale ?? {
  loadingPortfolio: 'Loading interactive portfolio',
  loadFailure: 'The portfolio could not load. Please try again.',
  retry: 'Retry',
};

let revealStarted = false;

const removeBootstrapSurface = () => {
  markRuntime('flutter-surface-reveal-start');
  measureRuntime(
    'flutter-first-frame-to-reveal',
    'flutter-first-frame-signal',
    'flutter-surface-reveal-start',
  );
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;
  splash.setAttribute('aria-busy', 'false');
  splash.classList.add('bootstrap-surface--done');
  window.setTimeout(() => {
    splash.remove();
    markRuntime('flutter-bootstrap-surface-removed');
    measureRuntime(
      'flutter-bootstrap-to-surface-removed',
      'flutter-bootstrap-start',
      'flutter-bootstrap-surface-removed',
    );
  }, 220);
};

// Flutter dispatches its first-frame event while the browser is still
// compositing that frame. Keeping the matching HTML surface for two browser
// frames prevents a one-frame blank flash on cold GPU/Wasm starts.
const revealFlutterSurface = () => {
  if (revealStarted) return;
  revealStarted = true;
  window.removeEventListener('flutter-first-frame', onFlutterFirstFrame);
  markRuntime('flutter-first-frame-signal');
  // The observable first surface can come from Flutter's event or from one of
  // the guarded WebKit/CanvasKit fallbacks below. Record the primary measure
  // at the shared signal so every successful reveal has exactly one timing
  // entry, regardless of which supported source won the race.
  measureRuntime(
    'flutter-bootstrap-to-first-frame',
    'flutter-bootstrap-start',
    'flutter-first-frame-signal',
  );
  measureRuntime(
    'flutter-bootstrap-to-reveal-signal',
    'flutter-bootstrap-start',
    'flutter-first-frame-signal',
  );
  window.requestAnimationFrame(() => {
    markRuntime('flutter-reveal-frame-1');
    window.requestAnimationFrame(removeBootstrapSurface);
  });
};

const onFlutterFirstFrame = () => {
  markRuntime('flutter-first-frame-event');
  revealFlutterSurface();
};

const revealAfterRunApp = () => {
  window.setTimeout(() => {
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        if (revealStarted) return;
        markRuntime('flutter-run-app-fallback');
        revealFlutterSurface();
      });
    });
  }, 250);
};

const showBootstrapFailure = (error) => {
  markRuntime('flutter-bootstrap-failed');
  console.error('Flutter bootstrap failed', error);
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;

  splash.setAttribute('aria-busy', 'false');
  splash.setAttribute('aria-label', bootstrapCopy.loadFailure);
  splash.replaceChildren();
  const status = document.createElement('div');
  status.className = 'bootstrap-error';
  status.setAttribute('role', 'alert');
  status.textContent = bootstrapCopy.loadFailure;
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.className = 'bootstrap-retry';
  retry.textContent = bootstrapCopy.retry;
  retry.addEventListener('click', () => window.location.reload());
  status.appendChild(retry);
  splash.appendChild(status);
};

const engineConfig = {
  // Flutter's engine revision becomes part of the renderer URL. This lets the
  // server cache large SkWasm/CanvasKit binaries for a year without a future
  // Flutter upgrade reusing stale bytes at the same path.
  canvasKitBaseUrl: new URL(
    `canvaskit/${_flutter.buildConfig.engineRevision}/`,
    document.baseURI,
  ).toString(),
  // Keep Flutter's implicit Roboto/emoji fallback fonts on the same origin.
  // The application typography is bundled through pubspec fonts; this path
  // covers glyphs outside those families without a fonts.gstatic.com fetch.
  // An absolute URL avoids both document-relative `/fallback_fonts` requests
  // and renderer-side duplication of the `assets/` prefix. `document.baseURI`
  // also preserves repository subpaths in GitHub Pages builds.
  fontFallbackBaseUrl: new URL(
    'assets/fallback_fonts/',
    document.baseURI,
  ).toString(),
};

_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    markRuntime('flutter-entrypoint-loaded');
    window.addEventListener('flutter-first-frame', onFlutterFirstFrame, {
      once: true,
    });
    const appRunner = await engineInitializer.initializeEngine(engineConfig);
    markRuntime('flutter-engine-initialized');
    await appRunner.runApp();
    markRuntime('flutter-run-app-complete');
    revealAfterRunApp();
  },
}).catch(showBootstrapFailure);

// Older WebKit/CanvasKit combinations can paint the application without
// dispatching Flutter's web first-frame event. Keep the generated critical
// shell until Flutter owns a glass pane, then retire it instead of trapping
// those browsers behind an otherwise healthy loading surface.
window.setTimeout(() => {
  if (revealStarted || !document.querySelector('flt-glass-pane')) return;
  markRuntime('flutter-glass-pane-fallback');
  revealFlutterSurface();
}, 12000);
