import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';


// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

enum _ChatRole { user, aria }

class _Message {
  final _ChatRole role;
  final String text;
  final DateTime timestamp;
  _Message(this.role, this.text) : timestamp = DateTime.now();
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
  // ---- Controllers ----
  late AnimationController _orbPulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _typingCtrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ---- State ----
  bool _isListening = false;
  bool _ariaTyping = false;
  final List<_Message> _messages = [
    _Message(_ChatRole.user, "What's trending in tech?"),
    _Message(
      _ChatRole.aria,
      "Here's what's making waves across the neural networks today:\n\n"
          "1. Quantum computing breakthroughs — error correction rates reached 99.9%.\n"
          "2. Agentic AI frameworks are reshaping software development workflows.\n"
          "3. Spatial computing headsets are driving a new wave of immersive apps.",
    ),
    _Message(_ChatRole.user, "Summarize that"),
  ];

  static const List<String> _commands = [
    '✦  Write',
    '✦  Analyse',
    '✦  Create',
    '✦  Summarize',
    '✦  Translate',
  ];

  // ---- Colors (from the Stitch design system) ----
  static const Color _bg = Color(0xFF020105);
  static const Color _primary = Color(0xFFCC97FF);
  static const Color _primaryDim = Color(0xFF9C48EA);
  static const Color _secondary = Color(0xFFFF67AD);
  static const Color _tertiary = Color(0xFF8CE7FF);
  static const Color _surfaceContainer = Color(0xFF1C1823);
  static const Color _surfaceContainerHigh = Color(0xFF221D2A);
  static const Color _surfaceBright = Color(0xFF2F2A38);
  static const Color _onSurface = Color(0xFFF6EEFC);
  static const Color _onSurfaceVariant = Color(0xFFAFA8B5);
  static const Color _outlineVariant = Color(0xFF4B4651);

  @override
  void initState() {
    super.initState();
    _orbPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Simulate ARIA typing response to "Summarize that"
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _ariaTyping = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _ariaTyping = false;
          _messages.add(
            _Message(
              _ChatRole.aria,
              "In short: quantum computing is maturing, agentic AI is disrupting dev workflows, and spatial computing is the next frontier for immersive experiences.",
            ),
          );
        });
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _orbPulseCtrl.dispose();
    _waveCtrl.dispose();
    _typingCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Message(_ChatRole.user, text));
      _inputCtrl.clear();
      _ariaTyping = true;
    });
    _scrollToBottom();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _ariaTyping = false;
        _messages.add(
          _Message(
            _ChatRole.aria,
            "Processing your query through the neural lattice… Here's what I found across the data streams.",
          ),
        );
      });
      _scrollToBottom();
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ---- Ambient star field ----
          ..._buildStarField(),

          // ---- Ambient background nebula glows ----
          _buildNebulaGlows(),

          // ---- Main layout ----
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildOrbSection(),
                _buildWaveformSection(),
                _buildCommandChips(),
                Expanded(child: _buildChatArea()),
                _buildInputBar(),
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STAR FIELD
  // ---------------------------------------------------------------------------

  List<Widget> _buildStarField() {
    final rng = math.Random(99);
    return List.generate(24, (i) {
      final size = rng.nextBool() ? 1.0 : 1.5;
      return Positioned(
        top: rng.nextDouble() * 900,
        left: rng.nextDouble() * 420,
        child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Color(0xFFF6EEFC),
                shape: BoxShape.circle,
              ),
            )
            .animate(
              delay: Duration(milliseconds: rng.nextInt(4000)),
              onPlay: (c) => c.repeat(reverse: true),
            )
            .fadeIn(begin: 0.1, duration: 2500.ms)
            .fadeOut(begin: 0.9, duration: 2500.ms),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // NEBULA GLOWS (ambient)
  // ---------------------------------------------------------------------------

  Widget _buildNebulaGlows() {
    return Stack(
      children: [
        // Top-left nebula
        Positioned(
          top: -60,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryDim.withValues(alpha: 0.12),
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
        // Bottom-right nebula
        Positioned(
          bottom: 100,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _secondary.withValues(alpha: 0.08),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Close button
              _GlassIconButton(
                icon: LucideIcons.x,
                onTap: () => Navigator.of(context).maybePop(),
              ),

              const Spacer(),

              // Title
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEXAL AI',
                    style: GoogleFonts.rye(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Neural Companion v2.0',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // History button
              _GlassIconButton(
                icon: LucideIcons.history,
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  // ---------------------------------------------------------------------------
  // NEURAL ORB  (ARIA)
  // ---------------------------------------------------------------------------

  Widget _buildOrbSection() {
    return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Ambient Breathing Halo
                    AnimatedBuilder(
                      animation: _orbPulseCtrl,
                      builder: (_, __) {
                        final scale = 0.85 + (_orbPulseCtrl.value * 0.15);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryDim.withValues(alpha: 0.3),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. Quantum Core (Spirograph)
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _QuantumCorePainter(
                          _secondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 25.seconds),

                    // 3. Dashed HUD Ring (Inner)
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _DashedRingPainter(
                          color: _primary.withValues(alpha: 0.8),
                          dashCount: 24,
                          dashRatio: 0.4,
                          strokeWidth: 2,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 14.seconds, begin: 1, end: 0),

                    // 4. Outer Photon Data Stream
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: CustomPaint(painter: _DataStreamPainter()),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 8.seconds),

                    // 5. Orbital 3D Rings
                    _Orbital3DRing(
                      size: 200,
                      color: _primary,
                      rotateX: 1.1,
                      rotateY: 0.25,
                      duration: 11.seconds,
                    ),
                    _Orbital3DRing(
                      size: 180,
                      color: _secondary,
                      rotateX: -0.7,
                      rotateY: 0.55,
                      duration: 14.seconds,
                      reverse: true,
                    ),

                    // 6. Orbital Particles
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            color: _secondary, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _secondary, blurRadius: 8, spreadRadius: 2)],
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 6.seconds),
                    
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: _tertiary, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _tertiary, blurRadius: 10, spreadRadius: 3)],
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 9.seconds, begin: 1, end: 0),

                    // 7. Core Glass Element (The AI "Eye")
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.9),
                            _tertiary.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 0.4, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _tertiary.withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'ARIA',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Status line beneath orb
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blinking dot
                  AnimatedBuilder(
                    animation: _typingCtrl,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _tertiary.withValues(
                          alpha: 0.4 + _typingCtrl.value * 0.6,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _tertiary.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active  •  Neural Mode',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: _tertiary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  // ---------------------------------------------------------------------------
  // WAVEFORM SECTION
  // ---------------------------------------------------------------------------

  Widget _buildWaveformSection() {
    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(14, (i) {
                        final phase = (i / 14) * math.pi * 2;
                        final t =
                            _waveCtrl.value * math.pi * 2 + phase;
                        final rawH = (math.sin(t) + 1) / 2;
                        final minH = 4.0;
                        final maxH = 28.0;
                        final h = minH + rawH * (maxH - minH);
                        return Container(
                          width: 3,
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [_primaryDim, _secondary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listening to your thoughts...',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 350.ms)
        .slideY(begin: 0.15, end: 0, duration: 500.ms);
  }

  // ---------------------------------------------------------------------------
  // QUICK COMMAND CHIPS
  // ---------------------------------------------------------------------------

  Widget _buildCommandChips() {
    return SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _commands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _CommandChip(
              label: _commands[i],
              onTap: () {
                HapticFeedback.selectionClick();
                _inputCtrl.text = _commands[i].replaceAll('✦  ', '');
                _focusNode.requestFocus();
              },
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 450.ms)
        .slideX(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // CHAT AREA
  // ---------------------------------------------------------------------------

  Widget _buildChatArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _surfaceContainer.withValues(alpha: 0.7),
        border: Border.all(
          color: _outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_ariaTyping ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _messages.length && _ariaTyping) {
              return _buildTypingIndicator();
            }
            final msg = _messages[i];
            return _ChatBubble(
              message: msg,
              primaryColor: _primary,
              primaryDim: _primaryDim,
              surfaceContainerHigh: _surfaceContainerHigh,
              onSurface: _onSurface,
              onSurfaceVariant: _onSurfaceVariant,
              outlineVariant: _outlineVariant,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ARIA orb dot
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_primary.withValues(alpha: 0.8), _primaryDim],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: _primary.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingCtrl,
                  builder: (_, __) {
                    final phase = i * 0.33;
                    final t = (_typingCtrl.value + phase) % 1.0;
                    final opacity = 0.3 + (math.sin(t * math.pi) * 0.7);
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  // ---------------------------------------------------------------------------
  // INPUT BAR
  // ---------------------------------------------------------------------------

  Widget _buildInputBar() {
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: _surfaceBright.withValues(alpha: 0.6),
            border: Border.all(
              color: _primary.withValues(alpha: 0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryDim.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Microphone
              GestureDetector(
                onTapDown: (_) => setState(() => _isListening = true),
                onTapUp: (_) => setState(() => _isListening = false),
                onTapCancel: () => setState(() => _isListening = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? _secondary.withValues(alpha: 0.25)
                        : Colors.transparent,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: _secondary.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? LucideIcons.mic : LucideIcons.micOff,
                    color: _isListening
                        ? _secondary
                        : _onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Text input
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: _onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask ARIA anything...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  maxLines: 1,
                  cursorColor: _primary,
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primary, _primaryDim],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDim.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAV
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav() {
    return Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: _surfaceContainer.withValues(alpha: 0.8),
            border: Border.all(
              color: _outlineVariant.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // History
              _BottomNavItem(
                icon: LucideIcons.history,
                label: 'History',
                color: _onSurfaceVariant,
                onTap: () {},
              ),

              // Modes (center, primary)
              GestureDetector(
                onTap: () => HapticFeedback.mediumImpact(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primary, _primaryDim],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDim.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.06, 1.06),
                      duration: 2.seconds,
                      curve: Curves.easeInOut,
                    ),
              ),

              // Voice
              _BottomNavItem(
                icon: LucideIcons.radio,
                label: 'Voice',
                color: _onSurfaceVariant,
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// SUB-WIDGETS
// ---------------------------------------------------------------------------

/// Glassmorphic icon button (top bar)
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2F2A38).withValues(alpha: 0.5),
          border: Border.all(
            color: const Color(0xFFF6EEFC).withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFFAFA8B5),
        ),
      ),
    );
  }
}

/// Quick command chip
class _CommandChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CommandChip({required this.label, required this.onTap});

  @override
  State<_CommandChip> createState() => _CommandChipState();
}

class _CommandChipState extends State<_CommandChip> {
  bool _pressed = false;

  static const Color _primary = Color(0xFFCC97FF);
  static const Color _surfaceBright = Color(0xFF2F2A38);
  static const Color _onSurface = Color(0xFFF6EEFC);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _pressed
              ? _primary.withValues(alpha: 0.2)
              : _surfaceBright.withValues(alpha: 0.4),
          border: Border.all(
            color: _primary.withValues(alpha: _pressed ? 0.5 : 0.15),
            width: 0.8,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: _onSurface.withValues(alpha: _pressed ? 1.0 : 0.8),
          ),
        ),
      ),
    );
  }
}

/// Animated chat bubble
class _ChatBubble extends StatelessWidget {
  final _Message message;
  final Color primaryColor;
  final Color primaryDim;
  final Color surfaceContainerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outlineVariant;

  const _ChatBubble({
    required this.message,
    required this.primaryColor,
    required this.primaryDim,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outlineVariant,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ARIA avatar dot (left side)
              if (!isUser)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.8),
                        primaryDim,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bubble
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: isUser
                      ? BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.35),
                              primaryDim.withValues(alpha: 0.55),
                            ],
                          ),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryDim.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          color: surfaceContainerHigh,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.08),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: isUser
                          ? onSurface
                          : onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: isUser ? 0.1 : -0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Bottom nav item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTERS
// ---------------------------------------------------------------------------

class _QuantumCorePainter extends CustomPainter {
  final Color color;
  _QuantumCorePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final int petals = 16;
    final r = size.width / 3;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi) / petals;
      final cx = center.dx + (size.width/2 - r) * math.cos(angle);
      final cy = center.dy + (size.height/2 - r) * math.sin(angle);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double dashRatio;
  final double strokeWidth;

  _DashedRingPainter({
    required this.color,
    required this.dashCount,
    required this.dashRatio,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final double step = (2 * math.pi) / dashCount;
    final double dashLength = step * dashRatio;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DataStreamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF7C3AED),
          const Color(0xFFCC97FF),
          const Color(0xFFFF67AD),
          const Color(0xFF7C3AED),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.65, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final double dashCount = 36;
    final double step = (2 * math.pi) / dashCount;
    final double dashLength = step * 0.4;
    
    for (int i = 0; i < dashCount; i++) {
      if (i % 5 == 0 || i % 7 == 0) continue;
      final startAngle = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Orbital3DRing extends StatelessWidget {
  final double size;
  final Color color;
  final double rotateX;
  final double rotateY;
  final Duration duration;
  final bool reverse;

  const _Orbital3DRing({
    required this.size,
    required this.color,
    required this.rotateX,
    required this.rotateY,
    required this.duration,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX)
            ..rotateY(rotateY),
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .rotate(
          begin: 0,
          end: reverse ? -1 : 1,
          duration: duration,
          curve: Curves.linear,
        );
  }
}
