import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  HttpServer? _server;
  int _port = 0;
  bool _serverReady = false;
  bool _isLoading  = true;
  bool _locationDenied = false;
  WebViewController? _ctrl;
  StreamSubscription<Position>? _gpsSub;
  final Map<String, Uint8List> _assetCache = {};

  @override
  void initState() {
    super.initState();
    _requestLocationThenInit();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _server?.close(force: true);
    _assetCache.clear();
    super.dispose();
  }

  // ── 1. Ask for location permission ───────────────────────────────────────────
  Future<void> _requestLocationThenInit() async {
    // Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services disabled on device — show dialog
      if (mounted) {
        _showServiceDisabledDialog();
      }
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

    // Permission granted (whileInUse or always) — start the map
    if (mounted) {
      setState(() => _locationDenied = false);
      await _startLocalServer();
    }
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Disabled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Please enable Location Services on your device to use the map.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              if (mounted) _requestLocationThenInit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── 2. Start local HTTP asset server ─────────────────────────────────────────
  Future<void> _startLocalServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      debugPrint('MAPS server → http://127.0.0.1:$_port');

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
          req.response.write('File not found');
        } finally {
          await req.response.close();
        }
      });

      await _initWebView();
    } catch (e) {
      debugPrint('Server error: $e');
    }
  }

  // ── 3. Build WebView ──────────────────────────────────────────────────────────
  Future<void> _initWebView() async {
    final controller = WebViewController();

    // Enable geolocation in Android WebView (belt-and-suspenders)
    if (controller.platform is AndroidWebViewController) {
      final ac = controller.platform as AndroidWebViewController;
      await ac.setGeolocationEnabled(true);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
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
          setState(() => _isLoading = false);

          // ── Inject postMessage bridge ──────────────────────────────────────
          await controller.runJavaScript("""
            (function() {
              window.addEventListener('message', function(e) {
                if (e.data === 'exit_map') FlutterBridge.postMessage('exit_map');
              });
              try {
                var origPM = window.parent.postMessage.bind(window.parent);
                window.parent = new Proxy(window.parent, {
                  get: function(t, p) {
                    if (p === 'postMessage') return function(msg) {
                      if (msg === 'exit_map') FlutterBridge.postMessage('exit_map');
                      else origPM(msg, '*');
                    };
                    return t[p];
                  }
                });
              } catch(e) {}
            })();
          """);

          // ── Override navigator.geolocation with Flutter-injected GPS ───────
          // This bypasses WebView's broken geolocation and uses the accurate
          // system GPS obtained by the Geolocator package.
          await controller.runJavaScript("""
            (function() {
              var _watchCallbacks = {};
              var _watchId = 0;

              // Flutter calls this whenever a new GPS fix is available
              window.__nexalGPSUpdate = function(lat, lng, accuracy, heading, speed, altitude) {
                var pos = {
                  coords: {
                    latitude:         lat,
                    longitude:        lng,
                    accuracy:         accuracy,
                    heading:          heading,
                    speed:            speed,
                    altitude:         altitude,
                    altitudeAccuracy: null,
                  },
                  timestamp: Date.now()
                };
                // Notify all watchPosition callbacks
                Object.values(_watchCallbacks).forEach(function(cb) { try { cb(pos); } catch(e) {} });
              };

              // Override navigator.geolocation entirely
              Object.defineProperty(navigator, 'geolocation', {
                get: function() {
                  return {
                    getCurrentPosition: function(success, error, opts) {
                      // Return last known position immediately if available
                      if (window.__lastNexalPos) {
                        success(window.__lastNexalPos);
                      } else {
                        // Register a one-time callback
                        var id = ++_watchId;
                        _watchCallbacks[id] = function(pos) {
                          window.__lastNexalPos = pos;
                          delete _watchCallbacks[id];
                          success(pos);
                        };
                      }
                    },
                    watchPosition: function(success, error, opts) {
                      var id = ++_watchId;
                      _watchCallbacks[id] = function(pos) {
                        window.__lastNexalPos = pos;
                        success(pos);
                      };
                      // Deliver immediately if we already have a fix
                      if (window.__lastNexalPos) success(window.__lastNexalPos);
                      return id;
                    },
                    clearWatch: function(id) {
                      delete _watchCallbacks[id];
                    }
                  };
                },
                configurable: true
              });
            })();
          """);

          // ── Start pumping GPS into the page ──────────────────────────────
          _startGPSStream(controller);
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

  // ── 4. High-accuracy GPS stream → inject into WebView ────────────────────────
  void _startGPSStream(WebViewController controller) {
    _gpsSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // metres — only update if moved 2m
    );

    // Send one immediate fix first
    Geolocator.getCurrentPosition(locationSettings: settings).then((pos) {
      _injectPosition(controller, pos);
    }).catchError((e) => debugPrint('GPS initial fix error: $e'));

    // Then stream continuous updates
    _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position pos) => _injectPosition(controller, pos),
      onError: (e) => debugPrint('GPS stream error: $e'),
    );
  }

  void _injectPosition(WebViewController controller, Position pos) {
    final lat      = pos.latitude;
    final lng      = pos.longitude;
    final acc      = pos.accuracy;
    final heading  = pos.heading;
    final speed    = pos.speed;
    final altitude = pos.altitude;

    debugPrint('GPS fix → $lat, $lng  acc=${acc.toStringAsFixed(1)}m');

    controller.runJavaScript(
      'if(window.__nexalGPSUpdate) window.__nexalGPSUpdate($lat, $lng, $acc, $heading, $speed, $altitude);'
    );
  }

  // ── Mime types ────────────────────────────────────────────────────────────────
  String _mime(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'html':  return 'text/html; charset=utf-8';
      case 'js':    return 'application/javascript; charset=utf-8';
      case 'css':   return 'text/css; charset=utf-8';
      case 'png':   return 'image/png';
      case 'jpg':
      case 'jpeg':  return 'image/jpeg';
      case 'svg':   return 'image/svg+xml; charset=utf-8';
      case 'json':  return 'application/json; charset=utf-8';
      case 'woff':  return 'font/woff';
      case 'woff2': return 'font/woff2';
      case 'ttf':   return 'font/ttf';
      default:      return 'application/octet-stream';
    }
  }

  // ── Permission denied screen ──────────────────────────────────────────────────
  Widget _buildDeniedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: const Icon(Icons.location_off_rounded, color: Color(0xFF64748B), size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Location Access Needed',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'NexalMaps needs your location to show where you are on the map and find nearby places.\n\nGo to Settings → Apps → Nexal → Permissions → Location.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
                textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) _requestLocationThenInit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locationDenied) return _buildDeniedScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          if (_serverReady && _ctrl != null)
            Positioned.fill(child: WebViewWidget(controller: _ctrl!))
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ),

          // Loading overlay with map icon
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text('Loading Map...',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
