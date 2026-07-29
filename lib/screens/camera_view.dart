import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/snap_camera_controller.dart';
import '../widgets/camera/snap_capture_button.dart';
import '../widgets/camera/snap_post_capture_overlay.dart';
import '../../utils/filter_generator.dart';

class CameraView extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenDiscover;
  final VoidCallback? onOpenMemories;
  final String? replyToUser;

  const CameraView({
    super.key,
    this.onClose,
    this.onOpenChat,
    this.onOpenDiscover,
    this.onOpenMemories,
    this.replyToUser,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late SnapCameraController _snapCtrl;
  bool _isShutterFlashing = false;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Hide status bar for immersive full-screen camera viewfinder
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _snapCtrl = SnapCameraController();
    _snapCtrl.addListener(_onControllerUpdate);
    _snapCtrl.initCamera();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _snapCtrl.initCamera();
    }
  }

  @override
  void deactivate() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _snapCtrl.removeListener(_onControllerUpdate);
    _snapCtrl.dispose();
    super.dispose();
  }

  void _triggerShutterFlash() {
    setState(() => _isShutterFlashing = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _isShutterFlashing = false);
    });
  }

  Future<void> _handleTakePhoto() async {
    _triggerShutterFlash();
    await _snapCtrl.takePhoto();
  }

  ColorFilter _getActiveFilter() {
    final idx = _snapCtrl.activeFilterIndex;
    if (idx >= 0 && idx < FilterGenerator.filters.length) {
      return FilterGenerator.filters[idx];
    }
    return const ColorFilter.mode(Colors.transparent, BlendMode.srcOver);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_snapCtrl.isPermissionDenied) {
      return _buildPermissionRequestScreen();
    }

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onScaleStart: (details) {
              _isPinching = details.pointerCount > 1;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount > 1 || (details.scale - 1.0).abs() > 0.02) {
                _isPinching = true;
                _snapCtrl.setZoom(details.scale);
              }
            },
            onScaleEnd: (details) {
              if (!_isPinching) {
                final vx = details.velocity.pixelsPerSecond.dx;
                final vy = details.velocity.pixelsPerSecond.dy;
                if (vx.abs() > vy.abs()) {
                  if (vx < -300) {
                    // Swipe Left -> Open Chat
                    if (widget.onOpenChat != null) {
                      widget.onOpenChat!();
                    } else {
                      _snapCtrl.swipeFilter(1);
                    }
                  } else if (vx > 300) {
                    // Swipe Right -> Open Discover
                    if (widget.onOpenDiscover != null) {
                      widget.onOpenDiscover!();
                    } else {
                      _snapCtrl.swipeFilter(-1);
                    }
                  }
                } else {
                  if (vy > 300) {
                    // Swipe Down -> Open Memories
                    if (widget.onOpenMemories != null) {
                      widget.onOpenMemories!();
                    } else {
                      _snapCtrl.pickGalleryImage();
                    }
                  }
                }
              }
              _isPinching = false;
            },
            onTapUp: (details) {
              _snapCtrl.setFocus(details, constraints);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── LAYER 1: Full-Screen Viewfinder (100% Fit & No Distortion) ──
                if (_snapCtrl.isInitialized &&
                    _snapCtrl.cameraController != null &&
                    _snapCtrl.cameraController!.value.isInitialized)
                  Builder(
                    builder: (context) {
                      final camera = _snapCtrl.cameraController!;
                      double aspectRatio = camera.value.aspectRatio;
                      if (aspectRatio <= 0) aspectRatio = 16 / 9;
                      var scale = screenSize.aspectRatio * aspectRatio;
                      if (scale < 1) scale = 1 / scale;
                      return Transform.scale(
                        scale: scale,
                        child: Center(
                          child: ColorFiltered(
                            colorFilter: _getActiveFilter(),
                            child: CameraPreview(camera),
                          ),
                        ),
                      );
                    },
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFFC00)),
                  ),

                // ── LAYER 2: Tap-To-Focus Yellow Ring ──
                if (_snapCtrl.showFocusRing && _snapCtrl.focusPoint != null)
                  Positioned(
                    left: _snapCtrl.focusPoint!.dx - 30,
                    top: _snapCtrl.focusPoint!.dy - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFFFC00), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).animate().scale(begin: const Offset(1.4, 1.4), end: const Offset(1.0, 1.0), duration: 200.ms).fadeOut(delay: 400.ms, duration: 200.ms),
                  ),

                // ── LAYER 3: Shutter Flash Overlay ──
                if (_isShutterFlashing)
                  Positioned.fill(
                    child: Container(color: Colors.white),
                  ),

                // ── LAYER 4: Pinch-To-Zoom Badge ──
                if (_snapCtrl.isZoomVisible)
                  Positioned(
                    bottom: 210,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_snapCtrl.zoomLevel.toStringAsFixed(1)}x',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFFC00),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── LAYER 5: Translucent Edge Swipe Hints ──
                _buildEdgeSwipeHints(),

                // ── LAYER 6: Top Bar Controls ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side Avatar
                      _buildProfileAvatar(),

                      // Center: "TO: Friend Name" Reply pill
                      if (widget.replyToUser != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFFC00), width: 1.2),
                          ),
                          child: Text(
                            'TO: ${widget.replyToUser}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFFFC00),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),

                      // Right side vertical icon column
                      _buildTopRightColumn(),
                    ],
                  ),
                ),

                // ── LAYER 7: Filter Carousel + Bottom Controls ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Filter Carousel Row
                          _buildFilterCarousel(),

                          const SizedBox(height: 12),

                          // Bottom Bar (3 Columns: Gallery | Capture Button | Chat)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Column: Memories / Gallery Thumbnail
                                _buildGalleryButton(),

                                // Center Column: Snapchat 80px Capture Button
                                SnapCaptureButton(
                                  onTap: _handleTakePhoto,
                                  onLongPressStart: () {
                                    _snapCtrl.startVideoRecording();
                                  },
                                  onLongPressEnd: () {
                                    _snapCtrl.stopVideoRecording();
                                  },
                                  progress: _snapCtrl.recordingProgress,
                                  isRecording: _snapCtrl.isRecording,
                                ),

                                // Right Column: Chat / Send Bubble
                                _buildChatButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── LAYER 8: Post-Capture Full-Screen Overlay ──
                if (_snapCtrl.capturedFile != null)
                  SnapPostCaptureOverlay(
                    controller: _snapCtrl,
                    onClose: () {
                      _snapCtrl.resetCapturedSnap();
                    },
                    onSend: () {
                      _snack('Snap sent successfully! ✨');
                      _snapCtrl.resetCapturedSnap();
                    },
                    onAddToStory: () {
                      _snack('Added to My Story! 👻');
                      _snapCtrl.resetCapturedSnap();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── TOP PROFILE AVATAR ──
  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        if (widget.onClose != null) widget.onClose!();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
              ],
            ),
          ),
          // Yellow notification dot
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFC00),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP RIGHT VERTICAL ICON COLUMN ──
  Widget _buildTopRightColumn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flash toggle
          _buildDropShadowIconButton(
            icon: _snapCtrl.flashState == FlashModeState.on
                ? LucideIcons.zap
                : (_snapCtrl.flashState == FlashModeState.auto ? LucideIcons.zap : LucideIcons.zapOff),
            color: _snapCtrl.flashState == FlashModeState.on ? const Color(0xFFFFFC00) : Colors.white,
            onTap: _snapCtrl.cycleFlashMode,
          ),
          const SizedBox(height: 12),

          // Flip Camera
          _buildDropShadowIconButton(
            icon: LucideIcons.refreshCw,
            onTap: _snapCtrl.switchCamera,
          ),
          const SizedBox(height: 12),

          // Settings / Gear
          _buildDropShadowIconButton(
            icon: LucideIcons.settings,
            onTap: () => _snack('Camera Settings'),
          ),
          const SizedBox(height: 12),

          // Timer
          _buildDropShadowIconButton(
            icon: LucideIcons.timer,
            color: _snapCtrl.timerDuration > 0 ? const Color(0xFFFFFC00) : Colors.white,
            onTap: _snapCtrl.cycleTimer,
          ),
          const SizedBox(height: 12),

          // Snapchat Ghost
          _buildDropShadowIconButton(
            icon: LucideIcons.ghost,
            color: const Color(0xFFFFFC00),
            onTap: () => _snack('Snapchat Features'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropShadowIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: color,
        size: 22,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
        ],
      ),
    );
  }

  // ── FILTER CAROUSEL ROW ──
  Widget _buildFilterCarousel() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _snapCtrl.filters.length,
        itemBuilder: (context, index) {
          final item = _snapCtrl.filters[index];
          final isSel = _snapCtrl.activeFilterIndex == index;
          final size = isSel ? 56.0 : 46.0;

          return GestureDetector(
            onTap: () => _snapCtrl.selectFilter(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.white38,
                        width: isSel ? 3.0 : 1.5,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFFC00).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : const [
                              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        item.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade900,
                          child: const Icon(LucideIcons.smile, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(
                      color: isSel ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── MEMORIES / GALLERY BUTTON ──
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () => _snapCtrl.pickGalleryImage(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.black54,
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=100',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Memories',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CHAT BUTTON ──
  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () {
        if (widget.onOpenChat != null) {
          widget.onOpenChat!();
        } else {
          _snack('Chat opened');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                  ],
                ),
                child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 24),
              ),
              // Unread Badge
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF0055),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chat',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TRANSLUCENT SWIPE HINTS ──
  Widget _buildEdgeSwipeHints() {
    return Stack(
      children: [
        // Left Edge Arrow (Chat)
        Positioned(
          left: 4,
          top: MediaQuery.of(context).size.height * 0.48,
          child: Icon(LucideIcons.chevronLeft, color: Colors.white.withValues(alpha: 0.4), size: 24),
        ),
        // Right Edge Arrow (Discover)
        Positioned(
          right: 4,
          top: MediaQuery.of(context).size.height * 0.48,
          child: Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.4), size: 24),
        ),
      ],
    );
  }

  // ── PERMISSION DENIED REQUEST SCREEN ──
  Widget _buildPermissionRequestScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Snapchat Ghost Illustration
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFC00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.ghost, color: Colors.black, size: 64),
                ),
                const SizedBox(height: 28),
                Text(
                  'Snapchat Camera Access',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please enable camera and microphone access to capture Snaps, try lenses, and share with friends.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => _snapCtrl.initCamera(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFC00),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66FFFC00), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Allow Camera Access',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => openAppSettings(),
                  child: Text(
                    'Open App Settings',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
