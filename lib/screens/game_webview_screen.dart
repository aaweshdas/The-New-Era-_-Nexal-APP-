import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class GameWebViewScreen extends StatefulWidget {
  /// When [gameUrl] is non-null the WebView loads this URL directly (no local
  /// asset server is started). This is used for web-hosted games like OpenTTD.
  final String? gameUrl;
  /// Display name shown in loading overlay and help dialog.
  final String gameTitle;

  const GameWebViewScreen({
    super.key,
    this.gameUrl,
    this.gameTitle = 'WORDL',
  });

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  HttpServer? _server;
  int _port = 0;
  bool _serverReady = false;
  bool _isLoadingGame = true;
  WebViewController? _controller;
  final Map<String, Uint8List> _assetCache = {};

  @override
  void initState() {
    super.initState();
    // Lock screen to Landscape for immersive gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide Status bar and Navigation bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.gameUrl != null) {
      // URL-mode: skip local server, load URL directly in WebView
      _startRemoteUrlGame(widget.gameUrl!);
    } else {
      _startLocalServer();
    }
  }

  @override
  void dispose() {
    // Shutdown local server and clear asset cache
    _server?.close(force: true);
    _assetCache.clear();

    // Restore Portrait screen locking and normal system UI mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  /// Loads a remotely-hosted game URL directly in the WebView without
  /// spinning up a local asset server. Used for OpenTTD and similar.
  Future<void> _startRemoteUrlGame(String url) async {
    // On desktop platforms, WebView isn't available — open in system browser.
    if (!(Platform.isAndroid || Platform.isIOS)) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) setState(() => _serverReady = true);
      return;
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        // Use a desktop Chrome User-Agent so sites like play.openttd.org
        // serve the full WebAssembly game instead of a mobile fallback page.
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView remote error: ${error.description}');
            },
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoadingGame = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoadingGame = false);
            },
          ),
        )
        ..setOnConsoleMessage((JavaScriptConsoleMessage msg) {
          debugPrint('JS [${msg.level}]: ${msg.message}');
        });

      await controller.loadRequest(Uri.parse(url));

      if (mounted) {
        setState(() {
          _controller = controller;
          _serverReady = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading remote game URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load game: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _startLocalServer() async {
    try {
      // Bind server to localhost on any available port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      
      debugPrint("WORDL local server listening on http://127.0.0.1:$_port");

      _server!.listen((HttpRequest request) async {
        // Handle CORS headers
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');
        
        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.method != 'GET') {
          request.response.statusCode = HttpStatus.methodNotAllowed;
          await request.response.close();
          return;
        }

        String path = request.uri.path;
        if (path == '/' || path.isEmpty) {
          path = '/index.html';
        }

        // Map request path to assets
        final assetKey = 'assets/wordl$path';
        
        try {
          Uint8List buffer;
          if (_assetCache.containsKey(assetKey)) {
            buffer = _assetCache[assetKey]!;
          } else {
            final data = await rootBundle.load(assetKey);
            buffer = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            // Cache small and medium size assets in memory (under 10MB) to optimize performance
            if (buffer.length < 10 * 1024 * 1024) {
              _assetCache[assetKey] = buffer;
            }
          }
          
          request.response.headers.contentType = ContentType.parse(_getMimeType(path));
          request.response.headers.contentLength = buffer.length;
          request.response.add(buffer);
        } catch (e) {
          debugPrint("Failed to find or serve asset $assetKey: $e");
          request.response.statusCode = HttpStatus.notFound;
          request.response.write("File not found");
        } finally {
          await request.response.close();
        }
      });

      final useWebView = Platform.isAndroid || Platform.isIOS;
      if (!useWebView) {
        setState(() {
          _serverReady = true;
        });
        _launchBrowserGame();
        return;
      }

      // Initialize WebView Controller
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              debugPrint("WebView error loading resource: ${error.description}");
            },
            onPageStarted: (String url) {
              setState(() {
                _isLoadingGame = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoadingGame = false;
              });
            },
          ),
        )
        ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
          debugPrint("JS Console [${message.level}]: ${message.message}");
        });

      final gameUrl = 'http://127.0.0.1:$_port/index.html';
      await controller.loadRequest(Uri.parse(gameUrl));

      setState(() {
        _controller = controller;
        _serverReady = true;
      });
    } catch (e) {
      debugPrint("Error starting local server: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start local game server: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return 'text/html; charset=utf-8';
      case 'js':
        return 'application/javascript; charset=utf-8';
      case 'css':
        return 'text/css; charset=utf-8';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'json':
        return 'application/json; charset=utf-8';
      case 'wasm':
        return 'application/wasm';
      case 'svg':
        return 'image/svg+xml';
      case 'ttf':
        return 'font/ttf';
      case 'woff':
        return 'font/woff';
      case 'woff2':
        return 'font/woff2';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'xml':
        return 'application/xml';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLoading = !_serverReady || _isLoadingGame;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. WebView Game Canvas (or Desktop Browser Fallback)
          if (_serverReady)
            Positioned.fill(
              child: (Platform.isAndroid || Platform.isIOS)
                  ? (_controller != null
                      ? WebViewWidget(controller: _controller!)
                      : const SizedBox.shrink())
                  : _buildDesktopFallback(),
            )
          else
            const Positioned.fill(
              child: SizedBox.shrink(),
            ),

          // 2. Loading State Overlay
          if (showLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cyan500,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyan500.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: AppTheme.purple500,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.gameUrl != null
                            ? 'CONNECTING TO CLOUD SERVER'
                            : 'INITIALIZING NEXAL ENGINE',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.gameUrl != null
                            ? 'Streaming ${widget.gameTitle} from Render Cloud...'
                            : 'Spawning Local Asset Server...',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Immersive Floating Controls (Top-Left Exit, Top-Right Refresh)
          Positioned(
            top: 20,
            left: 20,
            child: _buildFloatingActionCircle(
              icon: LucideIcons.arrowLeft,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                _buildFloatingActionCircle(
                  icon: LucideIcons.rotateCcw,
                  onPressed: () {
                    if (Platform.isAndroid || Platform.isIOS) {
                      _controller?.reload();
                    } else {
                      _launchBrowserGame();
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildFloatingActionCircle(
                  icon: LucideIcons.helpCircle,
                  onPressed: () {
                    _showGameHelpDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionCircle({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showGameHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF111122).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.cyan500.withValues(alpha: 0.3),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  LucideIcons.gamepad2,
                  color: AppTheme.cyan500,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  "Messenger Control Guide",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildControlInstructionRow(
                  action: "Steer / Drive",
                  control: "Tap Screen Left / Right or WASD / Arrow Keys",
                ),
                const SizedBox(height: 12),
                _buildControlInstructionRow(
                  action: "Deliver Cargo",
                  control: "Navigate close to the colored markers on the planet.",
                ),
                const SizedBox(height: 12),
                _buildControlInstructionRow(
                  action: "Objective",
                  control: "Drop off all packages safely before fuel or time runs out!",
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "RESUME GAME",
                  style: GoogleFonts.outfit(
                    color: AppTheme.cyan500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlInstructionRow({
    required String action,
    required String control,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          action.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.purple500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          control,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Future<void> _launchBrowserGame() async {
    final gameUrl = 'http://127.0.0.1:$_port/index.html';
    final uri = Uri.parse(gameUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $gameUrl';
      }
    } catch (e) {
      debugPrint("Error launching browser: $e");
    }
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.cyan500.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Gamepad Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cyan500.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.cyan500.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.gamepad2,
                  size: 40,
                  color: AppTheme.cyan500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "DESKTOP PLAY MODE",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: AppTheme.purple500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "MESSENGER (WORDL)",
                style: GoogleFonts.rye(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Since you are playing on Windows Desktop, the game is launched in your system web browser to run with full hardware acceleration and smooth 60 FPS performance.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.cyan500,
                        AppTheme.purple500,
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _launchBrowserGame,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.externalLink,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "RELAUNCH IN BROWSER",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Hosted locally on http://127.0.0.1:$_port",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
