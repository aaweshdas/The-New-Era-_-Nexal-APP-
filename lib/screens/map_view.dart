import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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

  // Loading animation controllers
  late AnimationController _pulseCtrl1;
  late AnimationController _pulseCtrl2;
  late AnimationController _pulseCtrl3;
  late AnimationController _orbitCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;
  late Animation<double> _orbit;
  late Animation<double> _fadeAnim;

  // Status text cycling
  final List<String> _statusMessages = [
    'Connecting to satellites...',
    'Acquiring GPS signal...',
    'Calculating position...',
    'Rendering map tiles...',
    'Almost ready...',
  ];
  int _statusIdx = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initLoadingAnimations();
    _startStatusCycler();
    _requestLocationThenInit();
  }

  void _initLoadingAnimations() {
    // Pulse ring 1 (innermost, fastest)
    _pulseCtrl1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulse1 = CurvedAnimation(parent: _pulseCtrl1, curve: Curves.easeOut);

    // Pulse ring 2 (middle, 300ms delay)
    _pulseCtrl2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulse2 = CurvedAnimation(parent: _pulseCtrl2, curve: Curves.easeOut);

    // Pulse ring 3 (outermost, 600ms delay)
    _pulseCtrl3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulse3 = CurvedAnimation(parent: _pulseCtrl3, curve: Curves.easeOut);

    // Orbit animation for the GPS dot
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _orbit = CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear);

    // Fade controller for loading → map transition
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Stagger the pulse rings
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _pulseCtrl2.forward(from: 0.33);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseCtrl3.forward(from: 0.66);
    });
  }

  void _startStatusCycler() {
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted && _isLoading) {
        setState(() => _statusIdx = (_statusIdx + 1) % _statusMessages.length);
      }
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _server?.close(force: true);
    _assetCache.clear();
    _pulseCtrl1.dispose();
    _pulseCtrl2.dispose();
    _pulseCtrl3.dispose();
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  // ── 1. Ask for location permission ────────────────────────────────────────────
  Future<void> _requestLocationThenInit() async {
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
        req.response.headers.add('Access-Control-Allow-Origin', '*');
        req.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
        req.response.headers.add('Access-Control-Allow-Headers', '*');

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
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0F))
      ..clearCache()
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message == 'exit_map' && mounted) {
            Navigator.of(context).pop();
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

          // Dismiss loading screen after a short delay to ensure map renders
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              _fadeCtrl.forward();
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _isLoading = false);
              });
            }
          });
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
  void _startGPSStream(WebViewController controller) {
    _gpsSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // fire every update for maximum accuracy
    );

    // Immediate first fix
    Geolocator.getCurrentPosition(locationSettings: settings)
        .timeout(const Duration(seconds: 10))
        .then((pos) {
      _injectPosition(controller, pos);
      if (mounted) setState(() => _firstGPSInjected = true);
    }).catchError((e) => debugPrint('[GPS] Initial fix error: $e'));

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
    debugPrint('[GPS] Fix → ${pos.latitude}, ${pos.longitude}  acc=${pos.accuracy.toStringAsFixed(1)}m');
    controller.runJavaScript(
      'if(window.__nexalGPSUpdate) window.__nexalGPSUpdate(${pos.latitude}, ${pos.longitude}, ${pos.accuracy}, ${pos.heading}, ${pos.speed}, ${pos.altitude});',
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
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.15), blurRadius: 24, spreadRadius: 4)],
                ),
                child: const Icon(Icons.location_off_rounded, color: Color(0xFF8B5CF6), size: 36),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              const Text('Location Access Needed',
                style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              const Text(
                'NexalMaps needs your location to show where you are on the map and find nearby places.\n\nGo to Settings → Apps → Nexal → Permissions → Location.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.7),
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
                  child: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cinematic loading screen ──────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Stack(
        children: [
          // Animated radial background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RadialGradientPainter(_orbitCtrl.value),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Orbit + Pulse rings
                SizedBox(
                  width: 200, height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring 3 (outermost)
                      AnimatedBuilder(
                        animation: _pulse3,
                        builder: (_, __) => Opacity(
                          opacity: (1.0 - _pulse3.value).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.4 + _pulse3.value * 1.6,
                            child: Container(
                              width: 200, height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pulse ring 2 (middle)
                      AnimatedBuilder(
                        animation: _pulse2,
                        builder: (_, __) => Opacity(
                          opacity: (1.0 - _pulse2.value).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.4 + _pulse2.value * 1.3,
                            child: Container(
                              width: 160, height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pulse ring 1 (innermost)
                      AnimatedBuilder(
                        animation: _pulse1,
                        builder: (_, __) => Opacity(
                          opacity: (1.0 - _pulse1.value).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.4 + _pulse1.value * 1.0,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center compass icon
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF2D1B69), Color(0xFF141420)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 24, spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFFB07CFF),
                          size: 32,
                        ),
                      ),

                      // Orbiting GPS dot
                      AnimatedBuilder(
                        animation: _orbit,
                        builder: (_, __) {
                          const orbitRadius = 54.0;
                          final angle = _orbit.value * 2 * math.pi;
                          final x = math.cos(angle) * orbitRadius;
                          final y = math.sin(angle) * orbitRadius;
                          return Transform.translate(
                            offset: Offset(x, y),
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF67E8F9),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF67E8F9).withOpacity(0.7),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // App name
                const Text(
                  'NEXAL MAPS',
                  style: TextStyle(
                    color: Color(0xFFF1F0F5),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 12),

                // Animated status message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _statusMessages[_statusIdx],
                    key: ValueKey(_statusIdx),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Loading bar
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: const Color(0xFF2A2A3E),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
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

// ── Custom painter for the animated radial background ─────────────────────────
class _RadialGradientPainter extends CustomPainter {
  final double t;
  _RadialGradientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Slowly breathing gradient
    final radius = size.longestSide * (0.5 + math.sin(t * 2 * math.pi) * 0.05);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0D0D1F),
          const Color(0xFF0A0A0F),
        ],
        stops: const [0.0, 1.0],
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle purple glow in center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy * 0.85),
        radius: size.width * 0.5,
      ));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_RadialGradientPainter old) => old.t != t;
}
