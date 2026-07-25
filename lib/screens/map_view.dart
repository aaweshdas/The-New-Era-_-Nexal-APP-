import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/map_video_preloader.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  HttpServer? _server;
  int _port = 0;
  bool _serverReady = false;
  bool _isLoading = true;
  bool _locationDenied = false;
  bool _firstGPSInjected = false;
  WebViewController? _ctrl;
  StreamSubscription<Position>? _gpsSub;
  final Map<String, Uint8List> _assetCache = {};
  int _currentDistanceFilter = 3; // 3 meters default when browsing

  // ── Loading animation controllers ─────────────────────────────────────────
  late AnimationController _signalCtrl;     // signal bar shimmer & coordinate oscillation
  late AnimationController _fadeCtrl;       // final fade-to-map
  late Animation<double> _fadeAnim;

  // Synchronization flags for ending the loading screen
  bool _pageFinished = false;
  bool _videoEnded = false;
  VoidCallback? _videoListener;
  Timer? _fallbackTimeout;

  // Background video — provided by the pre-warmed singleton (zero-delay)
  VideoPlayerController? get _bgVideoCtrl => MapVideoPreloader.instance.controller;

  // Status text cycling
  final List<_StatusStep> _statusSteps = const [
    _StatusStep('Initializing NEXAL Maps', 0),
    _StatusStep('Requesting location access', 1),
    _StatusStep('Scanning for GPS satellites', 2),
    _StatusStep('Locking signal...', 3),
    _StatusStep('Loading map tiles', 3),
    _StatusStep('Calibrating position', 4),
    _StatusStep('Ready to navigate', 5),
  ];
  int _statusIdx = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initLoadingAnimations();
    _startStatusCycler();
    _requestLocationThenInit();
    _setupVideoListener();
    // Start the pre-warmed video immediately — zero codec init delay
    MapVideoPreloader.instance.play();
  }

  void _initLoadingAnimations() {
    // Signal shimmer (fast, oscillates progress bar & simulated coordinates)
    _signalCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();

    // Fade-to-map
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    // Note: video is handled by MapVideoPreloader singleton — no init needed here
  }

  void _startStatusCycler() {
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted && _isLoading) {
        setState(() {
          _statusIdx = math.min(_statusIdx + 1, _statusSteps.length - 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    if (_videoListener != null) {
      MapVideoPreloader.instance.controller?.removeListener(_videoListener!);
    }
    _fallbackTimeout?.cancel();
    // Load empty page to force WebWebView/Chromium to release WebGL context and tile memory immediately
    _ctrl?.loadRequest(Uri.parse('about:blank'));
    _server?.close(force: true);
    _assetCache.clear();
    _signalCtrl.dispose();
    _fadeCtrl.dispose();
    _statusTimer?.cancel();
    // Rewind the preloaded video (not dispose) so the next Maps open is instant
    MapVideoPreloader.instance.reset();
    super.dispose();
  }

  // ── Video Completion & Page Loading Synchronization ────────────────────────
  void _setupVideoListener() {
    final ctrl = MapVideoPreloader.instance.controller;
    if (ctrl == null) {
      _videoEnded = true;
      return;
    }

    _videoListener = () {
      if (!mounted) return;
      final val = ctrl.value;
      if (val.isInitialized && !val.isPlaying) {
        // Video has ended if position is at or near duration
        final diff = (val.duration - val.position).inMilliseconds.abs();
        if (diff < 250 || val.position >= val.duration) {
          if (_videoListener != null) {
            ctrl.removeListener(_videoListener!);
            _videoListener = null;
          }
          if (mounted) {
            setState(() {
              _videoEnded = true;
            });
            _checkAndDismissLoading();
          }
        }
      }
    };
    ctrl.addListener(_videoListener!);

    // Safety fallback timeout to prevent being stuck if video/page load fails
    _fallbackTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        debugPrint('[MapView] Safety fallback triggered');
        _dismissLoading();
      }
    });
  }

  void _checkAndDismissLoading() {
    if (_pageFinished && _videoEnded && _isLoading) {
      _dismissLoading();
    }
  }

  void _dismissLoading() {
    if (!mounted || !_isLoading) return;
    _fallbackTimeout?.cancel();
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _signalCtrl.stop();
      }
    });
  }

  // ── 1. Ask for location permission ────────────────────────────────────────────
  Future<void> _requestLocationThenInit() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyGranted = prefs.getBool('nexal_location_granted') ?? false;

    if (alreadyGranted) {
      if (mounted) {
        setState(() => _locationDenied = false);
        await _startLocalServer();
      }
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showServiceDisabledDialog();
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationDenied = true);
      return;
    }

    if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
      await prefs.setBool('nexal_location_granted', true);
    }

    if (mounted) {
      setState(() => _locationDenied = false);
      await _startLocalServer();
    }
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Disabled',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Please enable Location Services on your device to use NexalMaps.',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              if (mounted) _requestLocationThenInit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── 2. Start local HTTP asset server ──────────────────────────────────────────
  Future<void> _startLocalServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      debugPrint('[NexalMap] Asset server → http://127.0.0.1:$_port');

      _server!.listen((HttpRequest req) async {
        // ── Performance: long-lived cache headers for immutable JS/CSS assets ──
        req.response.headers.add('Access-Control-Allow-Origin', '*');
        req.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
        req.response.headers.add('Access-Control-Allow-Headers', '*');

        // Vary cache TTL: JS/CSS bundle hashes never change → 1 year; HTML → no-cache
        final ext = req.uri.path.split('.').last.toLowerCase();
        if (ext == 'html') {
          req.response.headers.add('Cache-Control', 'no-cache');
        } else {
          req.response.headers.add('Cache-Control', 'public, max-age=31536000, immutable');
        }

        if (req.method == 'OPTIONS') {
          req.response.statusCode = HttpStatus.ok;
          await req.response.close();
          return;
        }
        if (req.method != 'GET') {
          req.response.statusCode = HttpStatus.methodNotAllowed;
          await req.response.close();
          return;
        }

        String path = req.uri.path;
        if (path == '/' || path.isEmpty) path = '/index.html';

        final assetKey = 'assets/map$path';
        try {
          Uint8List buf;
          if (_assetCache.containsKey(assetKey)) {
            buf = _assetCache[assetKey]!;
          } else {
            final data = await rootBundle.load(assetKey);
            buf = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            if (buf.length < 10 * 1024 * 1024) _assetCache[assetKey] = buf;
          }
          req.response.headers.contentType = ContentType.parse(_mime(path));
          req.response.headers.contentLength = buf.length;
          req.response.add(buf);
        } catch (e) {
          req.response.statusCode = HttpStatus.notFound;
          req.response.write('File not found: $assetKey');
        } finally {
          await req.response.close();
        }
      });

      await _initWebView();
    } catch (e) {
      debugPrint('[NexalMap] Server error: $e');
    }
  }

  // ── 3. Build WebView ───────────────────────────────────────────────────────────
  Future<void> _initWebView() async {
    final controller = WebViewController();

    if (controller.platform is AndroidWebViewController) {
      final ac = controller.platform as AndroidWebViewController;
      await ac.setGeolocationEnabled(true);
      // Enable hardware-accelerated rendering and smooth scrolling
      await ac.setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0F))
      // NOTE: Do NOT call clearCache() — it forces re-download of all JS/CSS on
      // every map open. Assets are served from the local HTTP server which already
      // sends long-lived Cache-Control headers, so the WebView cache is beneficial.
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message == 'exit_map' && mounted) {
            Navigator.of(context).pop();
          } else if (msg.message == 'nav_start') {
            _updateGPSStream(0); // Switch to continuous turn-by-turn tracking
          } else if (msg.message == 'nav_stop') {
            _updateGPSStream(3); // Throttle tracking rate when stationary/browsing map
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          if (!mounted) return;

          // ── Inject exit bridge ──────────────────────────────────────────────
          await controller.runJavaScript("""
            (function() {
              window.addEventListener('message', function(e) {
                if (e.data === 'exit_map') FlutterBridge.postMessage('exit_map');
                if (e.data === 'nav_start') FlutterBridge.postMessage('nav_start');
                if (e.data === 'nav_stop') FlutterBridge.postMessage('nav_stop');
              });
            })();
          """);

          // ── Override navigator.geolocation with Flutter GPS bridge ─────────
          // This must run BEFORE the React app accesses navigator.geolocation
          await controller.runJavaScript("""
            (function() {
              var _watchCallbacks = {};
              var _watchId = 0;

              // Called by Flutter on every GPS update
              window.__nexalGPSUpdate = function(lat, lng, accuracy, heading, speed, altitude) {
                var pos = {
                  coords: {
                    latitude: lat, longitude: lng,
                    accuracy: accuracy, heading: heading,
                    speed: speed, altitude: altitude,
                    altitudeAccuracy: null,
                  },
                  timestamp: Date.now()
                };
                window.__lastNexalPos = pos;
                Object.values(_watchCallbacks).forEach(function(cb) {
                  try { cb(pos); } catch(e) {}
                });
              };

              // Full geolocation API override
              Object.defineProperty(navigator, 'geolocation', {
                get: function() {
                  return {
                    getCurrentPosition: function(success, error, opts) {
                      if (window.__lastNexalPos) {
                        success(window.__lastNexalPos);
                      } else {
                        var id = ++_watchId;
                        _watchCallbacks[id] = function(pos) {
                          delete _watchCallbacks[id];
                          success(pos);
                        };
                        // Timeout after 8s
                        setTimeout(function() {
                          if (_watchCallbacks[id]) {
                            delete _watchCallbacks[id];
                            if (error) error({ code: 3, message: 'Timeout' });
                          }
                        }, 8000);
                      }
                    },
                    watchPosition: function(success, error, opts) {
                      var id = ++_watchId;
                      _watchCallbacks[id] = function(pos) { success(pos); };
                      if (window.__lastNexalPos) success(window.__lastNexalPos);
                      return id;
                    },
                    clearWatch: function(id) { delete _watchCallbacks[id]; }
                  };
                },
                configurable: true
              });
            })();
          """);

          // ── Start GPS stream immediately ────────────────────────────────────
          _startGPSStream(controller);

          // ── Re-inject after 800ms to handle React hydration timing ─────────
          // React mounts asynchronously; a second inject guarantees the first
          // watchPosition call inside useGeolocation gets a position.
          Future.delayed(const Duration(milliseconds: 800), () async {
            if (!mounted) return;
            try {
              final pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                ),
              ).timeout(const Duration(seconds: 5));
              _injectPosition(controller, pos);
            } catch (_) {}
          });

          // Page load finished: update page status flag & check if we can dismiss the loading screen
          if (mounted) {
            setState(() {
              _pageFinished = true;
            });
            _checkAndDismissLoading();
          }
        },
      ));

    await controller.loadRequest(Uri.parse('http://127.0.0.1:$_port/index.html'));

    if (mounted) {
      setState(() {
        _ctrl = controller;
        _serverReady = true;
      });
    }
  }

  // ── 4. High-accuracy GPS stream ───────────────────────────────────────────────
  void _updateGPSStream(int distanceFilter) {
    if (_currentDistanceFilter == distanceFilter && _gpsSub != null) return;
    _currentDistanceFilter = distanceFilter;
    debugPrint('[GPS] Switching distance filter threshold to: ${distanceFilter}m');
    if (_ctrl != null) {
      _startGPSStream(_ctrl!);
    }
  }

  void _startGPSStream(WebViewController controller) {
    _gpsSub?.cancel();

    final settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _currentDistanceFilter,
    );

    // Immediate first fix
    Geolocator.getCurrentPosition(locationSettings: settings)
        .timeout(const Duration(seconds: 10))
        .then((pos) {
      _injectPosition(controller, pos);
      if (mounted) setState(() => _firstGPSInjected = true);
    }).catchError((e) {
      debugPrint('[GPS] Initial fix error: $e');
    });

    // Continuous stream
    _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position pos) {
        _injectPosition(controller, pos);
        if (mounted && !_firstGPSInjected) setState(() => _firstGPSInjected = true);
      },
      onError: (e) => debugPrint('[GPS] Stream error: $e'),
    );
  }

  void _injectPosition(WebViewController controller, Position pos) {
    // Only log in debug mode to avoid string allocation overhead in production
    assert(() {
      debugPrint('[GPS] Fix → ${pos.latitude}, ${pos.longitude}  acc=${pos.accuracy.toStringAsFixed(1)}m');
      return true;
    }());
    controller.runJavaScript(
      'if(window.__nexalGPSUpdate) window.__nexalGPSUpdate(${pos.latitude},${pos.longitude},${pos.accuracy},${pos.heading},${pos.speed},${pos.altitude});',
    );
  }

  // ── Mime types ────────────────────────────────────────────────────────────────
  String _mime(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'html':  return 'text/html; charset=utf-8';
      case 'js':    return 'application/javascript; charset=utf-8';
      case 'mjs':   return 'application/javascript; charset=utf-8';
      case 'css':   return 'text/css; charset=utf-8';
      case 'png':   return 'image/png';
      case 'jpg':
      case 'jpeg':  return 'image/jpeg';
      case 'svg':   return 'image/svg+xml; charset=utf-8';
      case 'json':  return 'application/json; charset=utf-8';
      case 'woff':  return 'font/woff';
      case 'woff2': return 'font/woff2';
      case 'ttf':   return 'font/ttf';
      case 'ico':   return 'image/x-icon';
      default:      return 'application/octet-stream';
    }
  }

  // ── Permission denied screen ──────────────────────────────────────────────────
  Widget _buildDeniedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF141420), shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 4)],
                ),
                child: const Icon(Icons.location_off_rounded, color: Color(0xFF8B5CF6), size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              Text('Location Access Needed',
                style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'NexalMaps needs your location to show where you are on the map and find nearby places.\n\nGo to Settings → Apps → Nexal → Permissions → Location.',
                style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14, height: 1.7),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) _requestLocationThenInit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Open App Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back', style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 14)),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ── Innovative Holographic Loading Screen ────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF05050F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background: video (or space black fallback while initializing) ──
          if (_bgVideoCtrl != null && _bgVideoCtrl!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width:  _bgVideoCtrl!.value.size.width,
                  height: _bgVideoCtrl!.value.size.height,
                  child: VideoPlayer(_bgVideoCtrl!),
                ),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF05050F)),
            ),

          // Subtle vignette so the holographic UI pops against any video frame
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),

          // Orb removed, video background displays cleanly and optimized here

          // ── 4. UI Panel — bottom half ─────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF05050F).withValues(alpha: 0.95),
                    const Color(0xFF05050F),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFD4BBFF), Color(0xFF8B5CF6), Color(0xFF67E8F9)],
                        ).createShader(r),
                        child: Text(
                          'NEXAL',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          ),
                        ),
                        child: Text(
                          'MAPS',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),

                  const SizedBox(height: 28),

                  // ── Signal lock bars ──────────────────────────────────────
                  _SignalBars(
                    signalCtrl: _signalCtrl,
                    lockedBars: _statusSteps[_statusIdx].signalBars,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 20),

                  // ── Status text ───────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey(_statusIdx),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Blinking dot indicator
                            AnimatedBuilder(
                              animation: _signalCtrl,
                              builder: (ctx, val) => Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF67E8F9).withValues(alpha: 
                                    0.4 + 0.6 * math.sin(_signalCtrl.value * math.pi * 2).abs(),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF67E8F9).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusSteps[_statusIdx].label,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD4BBFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Progress track ────────────────────────────────────────
                  _AnimatedProgressTrack(
                    progress: (_statusIdx + 1) / _statusSteps.length,
                    signalCtrl: _signalCtrl,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 14),

                  // Coordinates placeholder (bound to active _signalCtrl)
                  AnimatedBuilder(
                    animation: _signalCtrl,
                    builder: (anim, _) {
                      // Simulated scanning coordinates
                      final lat = (17.0918 + math.sin(_signalCtrl.value * math.pi * 6) * 0.0003);
                      final lng = (82.0689 + math.cos(_signalCtrl.value * math.pi * 4) * 0.0003);
                      return Text(
                        '${lat.toStringAsFixed(4)}°N  ${lng.toStringAsFixed(4)}°E',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF67E8F9).withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── 5. Top corner — version tag ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              ),
              child: Text(
                'v2.0  LIVE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locationDenied) return _buildDeniedScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Map WebView (always in tree once server ready)
          if (_serverReady && _ctrl != null)
            Positioned.fill(child: WebViewWidget(controller: _ctrl!)),

          // Cinematic loading screen
          if (_isLoading)
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnim),
                child: _buildLoadingScreen(),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper data types
// ──────────────────────────────────────────────────────────────────────────────

class _StatusStep {
  final String label;
  final int signalBars; // 0..5
  const _StatusStep(this.label, this.signalBars);
}

// ──────────────────────────────────────────────────────────────────────────────
// Signal Bars Widget
// ──────────────────────────────────────────────────────────────────────────────
class _SignalBars extends StatelessWidget {
  final AnimationController signalCtrl;
  final int lockedBars;
  const _SignalBars({required this.signalCtrl, required this.lockedBars});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: signalCtrl,
      builder: (anim, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SIGNAL  ',
              style: GoogleFonts.outfit(
                color: const Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            ...List.generate(5, (i) {
              final locked = i < lockedBars;
              final shimmer = locked
                ? 1.0
                : (0.15 + 0.12 * math.sin(signalCtrl.value * math.pi * 2 + i));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 10.0 + i * 3.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: locked
                    ? const Color(0xFF8B5CF6).withValues(alpha: shimmer)
                    : const Color(0xFF2A2A3E),
                  boxShadow: locked ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4 * shimmer),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Animated Progress Track
// ──────────────────────────────────────────────────────────────────────────────
class _AnimatedProgressTrack extends StatelessWidget {
  final double progress;
  final AnimationController signalCtrl;
  const _AnimatedProgressTrack({required this.progress, required this.signalCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: signalCtrl,
      builder: (anim, _) {
        final shimmer = 0.7 + 0.3 * math.sin(signalCtrl.value * math.pi * 4);
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (ctx, v, child) {
                  return Stack(
                    children: [
                      // Track
                      Container(
                        width: double.infinity,
                        height: 3,
                        color: const Color(0xFF1E1B30),
                      ),
                      // Fill
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6D28D9),
                                Color.lerp(
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFF67E8F9),
                                  v,
                                )!.withValues(alpha: shimmer),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'INITIALIZING',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4B5563).withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
