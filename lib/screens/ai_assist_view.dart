import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/aria_service.dart';
import '../services/aria_config.dart';

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

enum _ChatRole { user, aria }

class _Message {
  final _ChatRole role;
  String text;
  final DateTime timestamp;
  bool isFinal;
  final Uint8List? imageBytes;

  _Message(this.role, this.text, {this.isFinal = true, this.imageBytes})
      : timestamp = DateTime.now();

  _Message.fromHistory({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isFinal = true,
    this.imageBytes,
  });

  Map<String, dynamic> toJson() => {
        'role': role.index,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'imageBytes': imageBytes != null ? List<int>.from(imageBytes!) : null,
      };

  factory _Message.fromJson(Map<String, dynamic> json) =>
      _Message.fromHistory(
        role: _ChatRole.values[json['role'] as int],
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        imageBytes: json['imageBytes'] != null
            ? Uint8List.fromList(List<int>.from(json['imageBytes']))
            : null,
      );
}

class _OrbParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double speed;
  final double phase;

  _OrbParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.speed,
    required this.phase,
  });
}

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

class AIAssistView extends StatefulWidget {
  const AIAssistView({super.key});

  @override
  State<AIAssistView> createState() => _AIAssistViewState();
}

class _AIAssistViewState extends State<AIAssistView>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────
  late AnimationController _orbCtrl;
  late AnimationController _orbPulseCtrl;
  late AnimationController _waveCtrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ── Backend subscriptions + keep-alive ──────────────────────────────────
  final List<StreamSubscription> _subs = [];
  Timer? _keepAliveTimer; // Periodic ping to prevent Render dyno from sleeping

  // ── Audio ─────────────────────────────────────────────────────────
  // ── Audio (TTS playback only — STT uses native SpeechToText)
  late final AudioRecorder _audioRecorder;  // kept for TTS playback pipeline
  late final AudioPlayer _audioPlayer;
  StreamSubscription<List<int>>? _micStreamSub;
  final List<List<int>> _audioQueue = [];
  bool _isPlayingAudio = false;

  // ── Native STT ─────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String _liveWords = '';          // partial words shown in voice bar

  // ── State ─────────────────────────────────────────────────────────
  bool _isListening = false;
  bool _ariaTyping = false;
  bool _isBackendConnected = false;
  bool _isWakingServer = false;   // true while Render is booting up
  bool _hasText = false;
  bool _inputFocused = false;
  Uint8List? _selectedImageBytes;
  final List<_Message> _messages = [];
  final List<List<_Message>> _chatHistory = [];
  final List<_OrbParticle> _particles = [];

  // ── Design Tokens ─────────────────────────────────────────────────
  static const Color _bg          = Color(0xFF080810);
  static const Color _surface     = Color(0xFF10101E);
  static const Color _card        = Color(0xFF161628);
  static const Color _accent      = Color(0xFF9D6FFF);
  static const Color _accentSoft  = Color(0xFF7C4DFF);
  static const Color _accentGlow  = Color(0xFF6633FF);
  static const Color _pink        = Color(0xFFEC4899);
  static const Color _cyan        = Color(0xFF22D3EE);
  static const Color _green       = Color(0xFF10B981);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _textPri     = Color(0xFFF8F8FF);
  static const Color _textSec     = Color(0xFF9898B8);
  static const Color _textMuted   = Color(0xFF55556A);
  static const Color _border      = Color(0xFF1E1E35);

  // ── Suggestion chips ─────────────────────────────────────────────
  static const _chips = [
    (LucideIcons.penTool,  'Write',     'Write me a short creative story about space'),
    (LucideIcons.lightbulb,'Explain',   'Explain quantum computing in simple terms'),
    (LucideIcons.code2,    'Code',      'Help me write a Python function to sort a list'),
    (LucideIcons.globe,    'Translate', 'Translate "Hello world" into 5 languages'),
    (LucideIcons.brain,    'Brainstorm','Give me 10 unique startup ideas in AI'),
    (LucideIcons.fileText, 'Summarize', 'Summarize the history of the internet'),
  ];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer   = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) => _playNextAudio());

    // Initialize falling particles along the background's central lightning path
    final rand = math.Random();
    const particleColors = [
      Color(0xFFFFFFFF), // White highlights
      Color(0xFF22D3EE), // Cyan
      Color(0xFFEC4899), // Pink
      Color(0xFF9D6FFF), // Purple
      Color(0xFFFF9E0B), // Orange
    ];
    for (int i = 0; i < 90; i++) {
      _particles.add(_OrbParticle(
        angle: (rand.nextDouble() - 0.5) * 45.0, // horizontal spread in pixels
        distance: rand.nextDouble(), // vertical fraction (0.0 to 1.0)
        size: rand.nextDouble() > 0.85 ? (rand.nextDouble() * 2.5 + 1.2) : (rand.nextDouble() * 1.0 + 0.4),
        color: particleColors[rand.nextInt(particleColors.length)],
        speed: 1.0 + rand.nextInt(3).toDouble(), // integer speed factor
        phase: rand.nextDouble() * 2 * math.pi, // phase offset
      ));
    }

    // Initialise native speech recognition in background
    _speech.initialize(
      onStatus: (status) {
        debugPrint('[STT] status: $status');
        if ((status == 'done' || status == 'notListening') && _isListening) {
          // Auto-send when speech ends naturally
          _onSpeechDone();
        }
      },
      onError: (err) {
        debugPrint('[STT] error: ${err.errorMsg}');
        _isListening = false;
        if (mounted) setState(() {});
      },
    ).then((available) {
      if (mounted) setState(() => _speechAvailable = available);
      debugPrint('[STT] Available: $available');
    });

    _orbCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat();

    _orbPulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..repeat();

    _inputCtrl.addListener(() {
      final h = _inputCtrl.text.trim().isNotEmpty;
      if (h != _hasText) setState(() => _hasText = h);
    });

    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });

    _loadHistory();
    _connectToBackend();
  }

  // ---------------------------------------------------------------------------
  // BACKEND
  // ---------------------------------------------------------------------------

  void _connectToBackend() {
    final aria = AriaService.instance;
    aria.connect();

    _subs.add(aria.onConnected.listen((c) {
      if (!mounted) return;
      setState(() {
        _isBackendConnected = c;
        if (c) _isWakingServer = false; // clear spinner the instant socket connects
      });
      // Start/stop keep-alive timer based on connection
      if (c) {
        _keepAliveTimer?.cancel();
        _keepAliveTimer = Timer.periodic(const Duration(minutes: 10), (_) {
          // Ping /health every 10 min to prevent Render free-tier dyno sleeping
          AriaConfig.load().then((cfg) {
            final url = cfg.backendUrl
                .replaceFirst('wss://', 'https://')
                .replaceFirst('ws://', 'http://');
            http_pkg.get(Uri.parse('$url/health'))
                .timeout(const Duration(seconds: 15))
                .catchError((_) => http_pkg.Response('', 200));
          });
        });
      } else {
        _keepAliveTimer?.cancel();
        _keepAliveTimer = null;
      }
    }));

    _subs.add(aria.onProcessingStart.listen((_) {
      if (!mounted) return;
      setState(() => _ariaTyping = true);
      _scrollToBottom();
      _stopMicStream();
    }));

    // STT ready event from backend (Deepgram) — no longer driving UI state
    _subs.add(aria.onSttReady.listen((_) {
      debugPrint('[UI] Backend STT ready (Deepgram)');
    }));

    _subs.add(aria.onTranscript.listen((text) {
      // Only handle backend transcripts during active STT listening.
      // When using text input, _sendMessage() already adds the bubble —
      // the backend's echo must NOT create a second one.
      if (!mounted || !_isListening) return;
      setState(() {
        if (_messages.isNotEmpty && _messages.last.role == _ChatRole.user) {
          _messages.last.text = text; // update live STT bubble in place
        } else {
          _messages.add(_Message(_ChatRole.user, text));
        }
      });
      _scrollToBottom();
    }));

    _subs.add(aria.onTtsAudio.listen((bytes) {
      if (!mounted) return;
      _audioQueue.add(bytes);
      if (!_isPlayingAudio) _playNextAudio();
    }));

    _subs.add(aria.onStreamChunk.listen((chunk) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.role == _ChatRole.aria &&
            !_messages.last.isFinal) {
          _messages.last.text += chunk;
        } else {
          _messages.add(_Message(_ChatRole.aria, chunk, isFinal: false));
        }
      });
      _scrollToBottom();
    }));

    _subs.add(aria.onAiResponse.listen((_) {
      if (!mounted) return;
      setState(() {
        _ariaTyping = false;
        if (_messages.isNotEmpty &&
            _messages.last.role == _ChatRole.aria &&
            !_messages.last.isFinal) {
          _messages.last.isFinal = true;
        }
      });
      _scrollToBottom();
    }));

    _subs.add(aria.onError.listen((msg) {
      if (!mounted) return;
      setState(() {
        _ariaTyping = false;
        _messages.add(_Message(_ChatRole.aria, '⚠ $msg'));
      });
      _scrollToBottom();
    }));
  }

  // ---------------------------------------------------------------------------
  // HISTORY
  // ---------------------------------------------------------------------------

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('aria_chat_history') ?? [];
    Future.microtask(() {
      final List<List<_Message>> history = [];
      for (final s in list) {
        try {
          final j = jsonDecode(s) as List<dynamic>;
          final c = j.map((e) => _Message.fromJson(e)).toList();
          if (c.isNotEmpty) { history.add(c); }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(history);
        });
      }
    });
  }

  Future<void> _saveCurrentChat() async {
    if (_messages.isEmpty) return;
    _chatHistory.insert(0, List.from(_messages));
    if (_chatHistory.length > 20) _chatHistory.removeRange(20, _chatHistory.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'aria_chat_history',
      _chatHistory.map((c) => jsonEncode(c.map((m) => m.toJson()).toList())).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    _micStreamSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    AriaService.instance.disconnect();
    _keepAliveTimer?.cancel();
    _orbCtrl.dispose();
    _orbPulseCtrl.dispose();
    _waveCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopAudioPlayback() {
    try { _audioPlayer.stop(); } catch (_) {}
    _audioQueue.clear();
    if (_isPlayingAudio) setState(() => _isPlayingAudio = false);
  }

  Future<void> _playNextAudio() async {
    if (!mounted) return;
    if (_audioQueue.isEmpty) { setState(() => _isPlayingAudio = false); return; }
    setState(() => _isPlayingAudio = true);
    final bytes = _audioQueue.removeAt(0);
    try {
      final f = File('${Directory.systemTemp.path}/aria_${DateTime.now().microsecondsSinceEpoch}.wav');
      await f.writeAsBytes(bytes, flush: true);
      await _audioPlayer.play(DeviceFileSource(f.path));
    } catch (_) { _playNextAudio(); }
  }

  void _sendMessage([String? override]) {
    final text = override ?? _inputCtrl.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;
    HapticFeedback.lightImpact();
    _stopAudioPlayback();
    final img = _selectedImageBytes;
    setState(() {
      _messages.add(_Message(_ChatRole.user, text, imageBytes: img));
      _inputCtrl.clear();
      _selectedImageBytes = null;
    });
    _scrollToBottom();
    AriaService.instance.sendTextMessage(text, imageBytes: img);
  }

  // ── Native STT: start ───────────────────────────────────────────
  Future<void> _startMicStream() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack('Microphone permission is required for speech recognition', LucideIcons.micOff, _pink);
      return;
    }

    if (!_speechAvailable) {
      // Try to re-initialize with proper callbacks
      final ok = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[STT] status: $status');
          if ((status == 'done' || status == 'notListening') && _isListening) {
            _onSpeechDone();
          }
        },
        onError: (err) {
          debugPrint('[STT] error: ${err.errorMsg}');
          _isListening = false;
          if (mounted) setState(() {});
        },
      );
      if (!ok) {
        _showSnack('Speech recognition not available on this device', LucideIcons.micOff, _pink);
        return;
      }
      if (mounted) setState(() => _speechAvailable = true);
    }

    _stopAudioPlayback();
    HapticFeedback.mediumImpact();
    setState(() { _isListening = true; _liveWords = ''; });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _liveWords = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _onSpeechDone();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  // ── Called when speech ends (naturally or via stop button) ───────
  void _onSpeechDone() {
    if (!_isListening) return; // Guard against multiple asynchronous triggers
    _isListening = false; // Synchronously block duplicate calls

    final words = _liveWords.trim();
    setState(() { _liveWords = ''; });
    _speech.stop();
    if (words.isNotEmpty) {
      HapticFeedback.lightImpact();
      _sendMessage(words);
    }
  }

  // ── Native STT: stop ────────────────────────────────────────────
  Future<void> _stopMicStream() async {
    if (!_isListening) return;
    _onSpeechDone();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAttachSheet(ctx),
    );
    if (src == null) return;
    final f = await picker.pickImage(source: src, imageQuality: 85);
    if (f != null) {
      setState(() => _selectedImageBytes = null);
      final bytes = await f.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
      HapticFeedback.lightImpact();
    }
  }

  void _newChat() async {
    HapticFeedback.mediumImpact();
    if (_messages.isEmpty) return;
    await _saveCurrentChat();
    _stopAudioPlayback();
    AriaService.instance.clearHistory();
    setState(() { _messages.clear(); _selectedImageBytes = null; });
  }

  void _loadPastChat(List<_Message> past) {
    if (_messages.isNotEmpty) _saveCurrentChat();
    setState(() {
      _messages.clear();
      _messages.addAll(past.map((m) => _Message.fromHistory(
        role: m.role, text: m.text,
        timestamp: m.timestamp, isFinal: m.isFinal, imageBytes: m.imageBytes,
      )));
      _selectedImageBytes = null;
    });
    AriaService.instance.clearHistory();
    Navigator.of(context).pop();
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _showSnack('Copied to clipboard', LucideIcons.check, _cyan);
  }

  void _shareMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _showSnack('Copied — ready to share', LucideIcons.share2, _accent);
  }

  void _showSnack(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(msg, style: GoogleFonts.outfit(color: _textPri, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
      duration: const Duration(seconds: 2),
    ));
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final showWelcome = _messages.isEmpty && !_ariaTyping;
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/aria_background.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0x4C000000), // 30% black overlay (70% image brightness)
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          // Winding Vertical Flowing Particle Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_orbCtrl, _orbPulseCtrl]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _OrbPainter(
                    animationValue: _orbCtrl.value,
                    pulseValue: _orbPulseCtrl.value,
                    isListening: _isListening,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),

          // Interactive UI Elements
          Positioned.fill(
            child: SafeArea(
              child: Column(children: [
                _buildHeader(),
                Expanded(child: showWelcome ? _buildWelcome() : _buildChat()),
                if (_isListening) _buildVoiceBar(),
                _buildInputBar(),
                const SizedBox(height: 6),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        // Back
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Icon(LucideIcons.chevronLeft, color: _textSec, size: 18),
          ),
        ),

        const SizedBox(width: 12),

        // Mini orb + title
        _buildMiniOrb(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: _orbPulseCtrl,
              builder: (context, child) {
                final t = _orbPulseCtrl.value;
                final color1 = Color.lerp(const Color(0xFF8CE7FF), const Color(0xFF9D6FFF), t)!;
                final color2 = Color.lerp(const Color(0xFF9D6FFF), const Color(0xFFEC4899), t)!;
                final color3 = Color.lerp(const Color(0xFFEC4899), const Color(0xFFFF9E0B), t)!;
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [color1, color2, color3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: child,
                );
              },
              child: Text('ARIA', style: GoogleFonts.rye(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                letterSpacing: 2,
              )),
            ),
            Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBackendConnected ? _green : _amber,
                  boxShadow: [BoxShadow(
                    color: (_isBackendConnected ? _green : _amber).withValues(alpha: 0.6),
                    blurRadius: 6, spreadRadius: 1,
                  )],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isBackendConnected ? 'Online' : 'Connecting...',
                style: GoogleFonts.outfit(
                  color: _isBackendConnected ? _green : _amber,
                  fontSize: 11, fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ]),
        ),

        // Play / Pause TTS audio
        _headerAudioBtn(),
        const SizedBox(width: 8),
        // History
        _headerBtn(LucideIcons.history, _showHistory),
        const SizedBox(width: 8),
        // New chat
        _headerBtn(LucideIcons.edit3, _newChat, highlighted: true),
      ]),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap, {bool highlighted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: highlighted ? _accent.withValues(alpha: 0.12) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlighted ? _accent.withValues(alpha: 0.3) : _border),
        ),
        child: Icon(icon, color: highlighted ? _accent : _textSec, size: 17),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SERVER WAKE / PAUSE CONTROL
  // ---------------------------------------------------------------------------

  /// HTTP ping to wake up the sleeping Render service, then reconnect socket.
  Future<void> _wakeRenderServer() async {
    if (_isWakingServer || _isBackendConnected) return;
    HapticFeedback.mediumImpact();
    setState(() => _isWakingServer = true);
    _showSnack('Waking backend server on Render...', LucideIcons.server, _amber);

    // Fire-and-forget HTTP ping — just kicks the Render dyno awake.
    // We do NOT await it; the socket reconnect runs in parallel.
    AriaConfig.load().then((config) {
      final baseUrl = config.backendUrl
          .replaceFirst('wss://', 'https://')
          .replaceFirst('ws://', 'http://');
      http_pkg
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 90))
          .catchError((_) => http_pkg.Response('', 200));
    });

    // Reconnect socket immediately — it retries every 2s automatically.
    // _isWakingServer is cleared by the onConnected listener the moment the
    // socket establishes a connection (no need to wait for HTTP response).
    await AriaService.instance.reconnect();

    // Safety: if still waking after 90s, give up and show an error.
    Future.delayed(const Duration(seconds: 90), () {
      if (mounted && _isWakingServer) {
        setState(() => _isWakingServer = false);
        _showSnack('Server not responding. Try again.', LucideIcons.alertTriangle, _pink);
      }
    });
  }

  /// Disconnect the socket (pauses the session; server keeps running on Render).
  void _pauseServer() {
    if (!_isBackendConnected) return;
    HapticFeedback.lightImpact();
    _stopAudioPlayback();
    AriaService.instance.disconnect();
    setState(() {});
    _showSnack('Backend disconnected — tap play to reconnect', LucideIcons.pauseCircle, _amber);
  }

  /// Server control button shown in the header.
  Widget _headerAudioBtn() {
    // Three visual states: waking (spinner), running (green play), paused (grey)
    if (_isWakingServer) {
      // Spinning loading state while Render boots
      return AnimatedBuilder(
        animation: _orbCtrl,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withValues(alpha: 0.4)),
            ),
            child: Transform.rotate(
              angle: _orbCtrl.value * 2 * math.pi,
              child: const Icon(LucideIcons.loader, color: _amber, size: 17),
            ),
          );
        },
      );
    }

    final isRunning = _isBackendConnected;
    return GestureDetector(
      onTap: isRunning ? _pauseServer : _wakeRenderServer,
      child: AnimatedBuilder(
        animation: _orbPulseCtrl,
        builder: (context, child) {
          final pulse = _orbPulseCtrl.value;
          return Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isRunning
                  ? _green.withValues(alpha: 0.08 + 0.05 * pulse)
                  : _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRunning
                    ? _green.withValues(alpha: 0.35 + 0.15 * pulse)
                    : _border,
              ),
              boxShadow: isRunning
                  ? [BoxShadow(
                      color: _green.withValues(alpha: 0.15 * pulse),
                      blurRadius: 10,
                    )]
                  : [],
            ),
            child: Icon(
              isRunning ? LucideIcons.pauseCircle : LucideIcons.playCircle,
              color: isRunning ? _green : _textSec,
              size: 17,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniOrb() {
    return AnimatedBuilder(
      animation: _orbPulseCtrl,
      builder: (context, _) {
        final t = _orbPulseCtrl.value;
        return Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Color.lerp(_accentGlow, _accent, t)!,
              _accentSoft.withValues(alpha: 0.4),
              Colors.transparent,
            ]),
            boxShadow: [BoxShadow(
              color: _accent.withValues(alpha: 0.3 + 0.2 * t),
              blurRadius: 12 + 6 * t, spreadRadius: 0,
            )],
          ),
          child: const Icon(LucideIcons.cpu, color: Colors.white, size: 14),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WELCOME STATE
  // ---------------------------------------------------------------------------

  Widget _buildWelcome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const SizedBox(height: 120), // Spacer exposing the background brain
        const SizedBox(height: 28),
        Text(_greeting(), style: GoogleFonts.outfit(
          color: _textSec, fontSize: 16, fontWeight: FontWeight.w500,
        )).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _orbPulseCtrl,
          builder: (context, child) {
            final t = _orbPulseCtrl.value;
            final color1 = Color.lerp(const Color(0xFF8CE7FF), const Color(0xFF9D6FFF), t)!;
            final color2 = Color.lerp(const Color(0xFF9D6FFF), const Color(0xFFEC4899), t)!;
            final color3 = Color.lerp(const Color(0xFFEC4899), const Color(0xFFFF9E0B), t)!;
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color1, color2, color3],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ).createShader(bounds),
              child: child,
            );
          },
          child: Text("I'm ARIA", style: GoogleFonts.orbitron(
            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900,
            letterSpacing: 4.0, height: 1.1,
            shadows: [
              Shadow(color: const Color(0xFF9D6FFF).withValues(alpha: 0.25), blurRadius: 10),
            ],
          )),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 8),
        Text('Your intelligent AI companion.\nAsk me anything.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: _textSec, fontSize: 15, height: 1.5, fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        _buildCapabilities(),
        const SizedBox(height: 28),
        _buildChips(),
        const SizedBox(height: 20),
      ]),
    );
  }

  // Orb is removed from welcome screen. Particle layer is stacked behind the UI.

  Widget _buildCapabilities() {
    final caps = [
      (_accentSoft, LucideIcons.zap, 'Instant Answers'),
      (_pink,        LucideIcons.image, 'Vision AI'),
      (_cyan,        LucideIcons.mic2, 'Voice Input'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: caps.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.$1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: c.$1.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.$2, color: c.$1, size: 13),
            const SizedBox(width: 6),
            Text(c.$3, style: GoogleFonts.outfit(
              color: c.$1, fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ]),
        ),
      )).toList(),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Try asking',
            style: GoogleFonts.outfit(
              color: _textSec,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: _chips.length,
          itemBuilder: (context, i) {
            final chip = _chips[i];
            final Color iconColor;
            switch (chip.$2) {
              case 'Write':
                iconColor = _accent;
                break;
              case 'Explain':
                iconColor = _cyan;
                break;
              case 'Code':
                iconColor = _pink;
                break;
              case 'Translate':
                iconColor = _green;
                break;
              case 'Brainstorm':
                iconColor = _amber;
                break;
              case 'Summarize':
              default:
                iconColor = const Color(0xFFD4BBFF);
                break;
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _sendMessage(chip.$3);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.$1, color: iconColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chip.$2,
                        style: GoogleFonts.outfit(
                          color: _textPri,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: 50 * i))
             .fadeIn(duration: 300.ms)
             .slideY(begin: 0.15, end: 0, duration: 300.ms);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CHAT AREA
  // ---------------------------------------------------------------------------

  Widget _buildChat() {
    final showTyping = _ariaTyping &&
        (_messages.isEmpty ||
            _messages.last.role != _ChatRole.aria ||
            _messages.last.isFinal);

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _messages.length) return _buildTypingDots();
        final msg = _messages[i];
        return msg.role == _ChatRole.user
            ? _buildUserMsg(msg)
            : _buildAriaMsg(msg);
      },
    );
  }

  Widget _buildUserMsg(_Message msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 60),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (msg.imageBytes != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(msg.imageBytes!, width: 200, fit: BoxFit.cover),
                    ),
                  ),
                if (msg.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FFF), Color(0xFF9D6FFF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [BoxShadow(
                        color: _accent.withValues(alpha: 0.25),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )],
                    ),
                    child: Text(msg.text, style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14.5, height: 1.5,
                    )),
                  ),
                const SizedBox(height: 4),
                Text(_timeLabel(msg.timestamp), style: GoogleFonts.outfit(
                  color: _textMuted, fontSize: 10,
                )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FFF), Color(0xFF9D6FFF)],
              ),
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildAriaMsg(_Message msg) {
    final isStreaming = !msg.isFinal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ARIA avatar
          AnimatedBuilder(
            animation: _orbPulseCtrl,
            builder: (context, _) => Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF7B2FFF), Color(0xFF4C0FCC)]),
                boxShadow: isStreaming ? [BoxShadow(
                  color: _accent.withValues(alpha: 0.4 + 0.2 * _orbPulseCtrl.value),
                  blurRadius: 10, spreadRadius: 0,
                )] : [],
              ),
              child: const Icon(LucideIcons.cpu, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: _border.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: Text(msg.text, style: GoogleFonts.outfit(
                        color: _textPri, fontSize: 14.5, height: 1.6,
                      ))),
                      if (isStreaming) ...[
                        const SizedBox(width: 4),
                        _buildCursor(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Action bar (only for final messages)
                if (msg.isFinal && msg.text.isNotEmpty)
                  Row(children: [
                    _msgAction(LucideIcons.copy, 'Copy', () => _copyText(msg.text)),
                    const SizedBox(width: 6),
                    _msgAction(LucideIcons.volume2, 'Read', () => AriaService.instance.triggerTts(msg.text)),
                    const SizedBox(width: 6),
                    _msgAction(LucideIcons.share2, 'Share', () => _shareMessage(msg.text)),
                    const Spacer(),
                    Text(_timeLabel(msg.timestamp), style: GoogleFonts.outfit(
                      color: _textMuted, fontSize: 10,
                    )),
                  ]),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _msgAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: _textSec),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(color: _textSec, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _orbPulseCtrl,
      builder: (context, _) => Opacity(
        opacity: _orbPulseCtrl.value,
        child: Container(
          width: 2, height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color(0xFF7B2FFF), Color(0xFF4C0FCC)]),
          ),
          child: const Icon(LucideIcons.cpu, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: _border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 4),
            _dot(1), const SizedBox(width: 4),
            _dot(2),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int i) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        final offset = math.sin((_waveCtrl.value * 2 * math.pi) - (i * 0.6));
        return Transform.translate(
          offset: Offset(0, -4 * offset),
          child: Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(_textMuted, _accent, (offset + 1) / 2),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VOICE BAR
  // ---------------------------------------------------------------------------

  Widget _buildVoiceBar() {
    // Native STT is always immediately ready — always pink
    final label = _liveWords.isNotEmpty ? _liveWords : 'Listening...';
    return GestureDetector(
      onTap: _stopMicStream,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _pink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _pink.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _pink),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleXY(begin: 0.7, end: 1.3, duration: 600.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: _liveWords.isNotEmpty ? _textPri : _pink,
                fontSize: 13,
                fontWeight: _liveWords.isNotEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (context, _) => Row(
              children: List.generate(5, (i) {
                final h = 4 + 12 * math.sin((_waveCtrl.value * 2 * math.pi) + i * 0.8).abs();
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3, height: h,
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text('Tap to send', style: GoogleFonts.outfit(color: _textMuted, fontSize: 11)),
        ]),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT BAR
  // ---------------------------------------------------------------------------

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03), // transparent glass color
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _inputFocused
                    ? _accent.withValues(alpha: 0.4)
                    : _isListening
                        ? _pink.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                width: _inputFocused ? 1.5 : 1,
              ),
              boxShadow: _inputFocused ? [BoxShadow(
                color: _accent.withValues(alpha: 0.08),
                blurRadius: 20, offset: const Offset(0, 4),
              )] : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                if (_selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_selectedImageBytes!, width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 3, right: 3,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImageBytes = null),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black87, shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
      
                Row(children: [
                  // Attach button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedImageBytes != null ? _accent.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.paperclip,
                        color: _selectedImageBytes != null ? _accent : _textMuted,
                        size: 18,
                      ),
                    ),
                  ),
      
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      style: GoogleFonts.outfit(color: _textPri, fontSize: 14.5),
                      maxLines: 5, minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Ask ARIA anything...',
                        hintStyle: GoogleFonts.outfit(color: _textMuted, fontSize: 14.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      ),
                      cursorColor: _accent,
                    ),
                  ),
      
                  // Mic / Send
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _hasText || _selectedImageBytes != null
                        ? GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B2FFF), Color(0xFF9D6FFF)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                boxShadow: [BoxShadow(
                                  color: _accent.withValues(alpha: 0.4),
                                  blurRadius: 12, offset: const Offset(0, 3),
                                )],
                              ),
                              child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 18),
                            ),
                          ).animate().scale(duration: 200.ms, curve: Curves.elasticOut)
                        : GestureDetector(
                            onTap: _isListening ? _stopMicStream : _startMicStream,
                            child: AnimatedBuilder(
                              animation: _orbPulseCtrl,
                              builder: (context, _) => Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? _pink.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: _isListening
                                      ? Border.all(color: _pink.withValues(alpha: 0.5))
                                      : null,
                                  boxShadow: _isListening ? [BoxShadow(
                                    color: _pink.withValues(alpha: 0.2 + 0.15 * _orbPulseCtrl.value),
                                    blurRadius: 10, spreadRadius: 1,
                                  )] : [],
                                ),
                                child: Icon(
                                  _isListening ? LucideIcons.micOff : LucideIcons.mic,
                                  color: _isListening ? _pink : _textSec,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HISTORY SHEET
  // ---------------------------------------------------------------------------

  void _showHistory() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: _border),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: _textMuted, borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.history, color: _accent, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Chat History', style: GoogleFonts.outfit(
                  color: _textPri, fontSize: 18, fontWeight: FontWeight.w700,
                )),
                const Spacer(),
                Text('${_chatHistory.length} chats', style: GoogleFonts.outfit(
                  color: _textMuted, fontSize: 12,
                )),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _chatHistory.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.messageSquare, color: _textMuted, size: 40),
                      const SizedBox(height: 12),
                      Text('No previous chats', style: GoogleFonts.outfit(
                        color: _textMuted, fontSize: 15,
                      )),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _chatHistory.length,
                      itemBuilder: (ctx, i) {
                        final chat = _chatHistory[i];
                        final first = chat.firstWhere(
                          (m) => m.role == _ChatRole.user, orElse: () => chat.first,
                        );
                        final count = chat.length;
                        return GestureDetector(
                          onTap: () => _loadPastChat(chat),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.messageSquare, color: _accent, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(first.text.isEmpty ? '[Image]' : first.text,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(color: _textPri, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 3),
                                Text('$count messages · ${_timeLabel(first.timestamp)}',
                                  style: GoogleFonts.outfit(color: _textMuted, fontSize: 11),
                                ),
                              ])),
                              const Icon(LucideIcons.chevronRight, color: _textMuted, size: 16),
                            ]),
                          ),
                        ).animate(delay: Duration(milliseconds: 40 * i))
                         .fadeIn(duration: 200.ms)
                         .slideY(begin: 0.1, end: 0);
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTACH SHEET
  // ---------------------------------------------------------------------------

  Widget _buildAttachSheet(BuildContext ctx) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: _textMuted, borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 20),
          Text('Attach Image', style: GoogleFonts.outfit(
            color: _textPri, fontSize: 17, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: _cyan, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text('Camera', style: GoogleFonts.outfit(
                    color: _textPri, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                  Text('Take a photo', style: GoogleFonts.outfit(
                    color: _textMuted, fontSize: 11,
                  )),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: _accent, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text('Gallery', style: GoogleFonts.outfit(
                    color: _textPri, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                  Text('Pick from library', style: GoogleFonts.outfit(
                    color: _textMuted, fontSize: 11,
                  )),
                ]),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;
  final bool isListening;
  final List<_OrbParticle> particles;

  _OrbPainter({
    required this.animationValue,
    required this.pulseValue,
    required this.isListening,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // DRAW VERTICAL FLOWING PARTICLES DOWN THE CENTER LINE OF THE SCREEN
    for (final p in particles) {
      // Calculate vertical position fraction seamlessly
      final yFraction = (p.distance + animationValue * (p.speed * 0.12)) % 1.0;
      final yPos = yFraction * size.height;

      // Winding curve following the background lightning/neural path
      // The lightning curve has 2.5 cycles of sin wave down the screen height
      final mainCurve = math.sin(yFraction * math.pi * 2.5) * 28.0;
      final microWobble = math.sin(yFraction * 12.0 + p.phase) * 5.0;

      final xPos = center.dx + mainCurve + microWobble + p.angle;

      // Pulsing effect based on pulseValue and phase
      final pulseVal = math.sin((animationValue * 2 * math.pi * 2) + p.phase);
      final sizeVal = p.size * (0.85 + 0.3 * (pulseVal + 1) / 2);
      
      // Particles fade out near the very top and bottom margins for a smooth transition
      double edgeFade = 1.0;
      if (yFraction < 0.1) {
        edgeFade = yFraction / 0.1;
      } else if (yFraction > 0.9) {
        edgeFade = (1.0 - yFraction) / 0.1;
      }
      
      final opacity = (p.color.a * edgeFade * (0.4 + 0.6 * (pulseVal + 1) / 2)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (sizeVal > 1.2) {
        paint.imageFilter = ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6);
      }

      canvas.drawCircle(Offset(xPos, yPos), sizeVal, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.particles != particles;
  }
}

