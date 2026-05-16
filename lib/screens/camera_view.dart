import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../utils/filter_generator.dart';
import 'camera_preview_screen.dart';

class CameraView extends StatefulWidget {
  final VoidCallback? onClose;
  const CameraView({super.key, this.onClose});
  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  int _timerDuration = 0;
  int _activeTimerCountdown = 0;
  int _selectedFilterIndex = 0;
  int _selectedMode = 1; // 0=Reel, 1=Story, 2=Spotlight, 3=Photo
  double _zoomLevel = 1.0;
  bool _isGridOn = false;
  final ImagePicker _picker = ImagePicker();
  late final FixedExtentScrollController _filterScrollController;
  late AnimationController _pulseCtrl;

  final _modes = ['REEL', 'STORY', 'SPOTLIGHT', 'PHOTO'];
  final _modeColors = [AppTheme.pink500, AppTheme.cyan500, const Color(0xFFFBBF24), AppTheme.purple500];

  @override
  void initState() {
    super.initState();
    _filterScrollController = FixedExtentScrollController(initialItem: _selectedFilterIndex);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) _setCamera(_selectedCameraIndex);
    } catch (e) { debugPrint("Error fetching cameras: $e"); }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras.isEmpty) return;
    final controller = CameraController(_cameras[index], ResolutionPreset.high, enableAudio: false);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) { debugPrint("Camera initialize error: $e"); }
  }

  void _switchCamera() async {
    if (_cameras.isEmpty || !_isInitialized) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    if (_selectedCameraIndex >= _cameras.length) _selectedCameraIndex = 0;
    setState(() => _isInitialized = false);
    await _controller?.dispose();
    _setCamera(_selectedCameraIndex);
  }

  void _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
  }

  void _toggleTimer() {
    setState(() {
      if (_timerDuration == 0) _timerDuration = 3;
      else if (_timerDuration == 3) _timerDuration = 10;
      else _timerDuration = 0;
    });
  }

  void _toggleGrid() => setState(() => _isGridOn = !_isGridOn);

  Future<void> _handleZoom(double scale) async {
    if (_controller == null || !_isInitialized) return;
    final newZoom = (_zoomLevel * scale).clamp(1.0, 5.0);
    await _controller!.setZoomLevel(newZoom);
    setState(() => _zoomLevel = newZoom);
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CameraPreviewScreen(imageFile: image, selectedFilterIndex: _selectedFilterIndex)));
      }
    } catch (e) { debugPrint("Gallery error: $e"); }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;
    try {
      if (_timerDuration > 0) {
        for (int i = _timerDuration; i > 0; i--) {
          if (!mounted) return;
          setState(() => _activeTimerCountdown = i);
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (!mounted) return;
      setState(() { _activeTimerCountdown = 0; _isTakingPicture = true; });
      final XFile picture = await _controller!.takePicture();
      setState(() => _isTakingPicture = false);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => CameraPreviewScreen(imageFile: picture, selectedFilterIndex: _selectedFilterIndex)));
    } catch (e) {
      debugPrint("Error taking picture: $e");
      setState(() { _isTakingPicture = false; _activeTimerCountdown = 0; });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF1a1a2e), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  void _showEffects() {
    final effects = ['Cyber Glitch', 'Neon Bloom', 'Matrix Rain', 'Retrowave', 'Hologram', 'Film Grain'];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Effects', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: effects.map((e) => GestureDetector(
          onTap: () { Navigator.pop(ctx); _snack('Applied: $e'); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.purple500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.wand2, color: AppTheme.purple500, size: 14), const SizedBox(width: 6), Text(e, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))]),
          ),
        )).toList()),
        const SizedBox(height: 16),
      ]),
    ));
  }

  void _showMusic() {
    final tracks = ['Midnight Drive – NeoPulse', 'Starlight – Aria Storm', 'Cyber Dawn – ZenBeats', 'Dreamscape – Luna Nova'];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Add Music', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...tracks.map((t) => GestureDetector(
          onTap: () { Navigator.pop(ctx); _snack('🎵 $t'); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
            child: Row(children: [Icon(LucideIcons.music, color: AppTheme.pink500, size: 18), const SizedBox(width: 12), Expanded(child: Text(t, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))), Icon(LucideIcons.play, color: AppTheme.cyan500, size: 16)]),
          ),
        )),
        const SizedBox(height: 12),
      ]),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _filterScrollController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller?.dispose();
      setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) _setCamera(_selectedCameraIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mc = _modeColors[_selectedMode];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onScaleUpdate: (d) => _handleZoom(d.scale),
        child: Stack(fit: StackFit.expand, children: [
          // Camera feed
          if (_isInitialized && _controller != null && _controller!.value.previewSize != null)
            SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: ColorFiltered(
                colorFilter: FilterGenerator.filters[_selectedFilterIndex],
                child: CameraPreview(_controller!),
              ),
            )))
          else
            const Center(child: CircularProgressIndicator(color: AppTheme.cyan500)),

          // Grid overlay
          if (_isGridOn) ...[
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GridPainter()))),
          ],

          // Timer countdown
          if (_activeTimerCountdown > 0)
            Center(child: Text('$_activeTimerCountdown', style: GoogleFonts.outfit(color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold, shadows: [Shadow(color: mc.withValues(alpha: 0.6), blurRadius: 30)]))),

          // Top gradient
          Positioned(top: 0, left: 0, right: 0, height: 120, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent])))),

          // Bottom gradient
          Positioned(bottom: 0, left: 0, right: 0, height: 240, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent])))),

          // HUD
          SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // ── TOP BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                _glassBtn(LucideIcons.arrowLeft, () { if (widget.onClose != null) widget.onClose!(); else Navigator.pop(context); }),
                const SizedBox(width: 10),
                // Zoom indicator
                if (_zoomLevel > 1.0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: Text('${_zoomLevel.toStringAsFixed(1)}x', style: GoogleFonts.outfit(color: mc, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                _glassBtn(_isFlashOn ? LucideIcons.zap : LucideIcons.zapOff, _toggleFlash, color: _isFlashOn ? const Color(0xFFFBBF24) : null),
                const SizedBox(width: 8),
                _glassBtn(LucideIcons.timer, _toggleTimer, badge: _timerDuration > 0 ? '${_timerDuration}s' : null, color: _timerDuration > 0 ? mc : null),
                const SizedBox(width: 8),
                _glassBtn(LucideIcons.grid, _toggleGrid, color: _isGridOn ? mc : null),
              ]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, duration: 400.ms),

            // ── MIDDLE: Right toolbar ──
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _toolBtn(LucideIcons.flipHorizontal, 'Flip', _switchCamera, mc),
                        const SizedBox(height: 18),
                        _toolBtn(LucideIcons.wand2, 'Effects', _showEffects, AppTheme.purple500),
                        const SizedBox(height: 18),
                        _toolBtn(LucideIcons.music, 'Music', _showMusic, AppTheme.pink500),
                        const SizedBox(height: 18),
                        _toolBtn(LucideIcons.type, 'Text', () => _snack('Text overlay mode'), AppTheme.cyan500),
                        const SizedBox(height: 18),
                        _toolBtn(LucideIcons.image, 'Gallery', _pickFromGallery, Colors.white),
                      ]),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.3, end: 0, duration: 400.ms),
              ]),
            )),

            // ── BOTTOM CONTROLS ──
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Column(children: [
                // Filter + Shutter row
                SizedBox(height: 110, child: Row(children: [
                  // Filter wheel
                  Expanded(child: Center(child: SizedBox(
                    width: 75, height: 110,
                    child: ListWheelScrollView.useDelegate(
                      controller: _filterScrollController, itemExtent: 70, diameterRatio: 2.0, perspective: 0.005,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setState(() => _selectedFilterIndex = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: FilterGenerator.filters.length,
                        builder: (context, index) {
                          final sel = _selectedFilterIndex == index;
                          return Opacity(opacity: sel ? 1.0 : 0.4, child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? mc : Colors.white.withValues(alpha: 0.2), width: sel ? 2 : 1),
                                boxShadow: sel ? [BoxShadow(color: mc.withValues(alpha: 0.3), blurRadius: 8)] : []),
                              child: ClipOval(child: ColorFiltered(colorFilter: FilterGenerator.filters[index], child: Image.network('https://picsum.photos/id/10/100', fit: BoxFit.cover))),
                            ),
                            const SizedBox(height: 3),
                            Text(FilterGenerator.filterNames[index], style: GoogleFonts.outfit(color: sel ? mc : Colors.white54, fontSize: 9, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                          ]));
                        },
                      ),
                    ),
                  ))),

                  // Shutter button
                  GestureDetector(
                    onTap: _takePicture,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (ctx, child) {
                        final pulse = 1.0 + _pulseCtrl.value * 0.06;
                        return Transform.scale(scale: pulse, child: Container(
                          width: 78, height: 78,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: mc.withValues(alpha: 0.6), width: 4),
                            boxShadow: [BoxShadow(color: mc.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2)]),
                          child: Container(margin: EdgeInsets.all(_isTakingPicture ? 8 : 4), decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [mc, mc.withValues(alpha: 0.7)]),
                            shape: BoxShape.circle,
                          )),
                        ));
                      },
                    ),
                  ),

                  // Placeholder to balance
                  const Expanded(child: SizedBox()),
                ])),
                const SizedBox(height: 20),

                // Mode selector
                _buildModeSelector(mc),
              ]),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms),
          ])),
        ]),
      ),
    );
  }

  // ── MODE SELECTOR ──
  Widget _buildModeSelector(Color mc) {
    return SizedBox(
      height: 36,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_modes.length, (i) {
        final sel = _selectedMode == i;
        final c = _modeColors[i];
        return GestureDetector(
          onTap: () => setState(() => _selectedMode = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(horizontal: sel ? 18 : 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? c.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: sel ? Border.all(color: c.withValues(alpha: 0.4), width: 1) : null,
            ),
            child: Text(_modes[i], style: GoogleFonts.outfit(color: sel ? c : Colors.white38, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: sel ? 13 : 12, letterSpacing: 1.2)),
          ),
        );
      })),
    );
  }

  // ── GLASS BUTTON ──
  Widget _glassBtn(IconData icon, VoidCallback onTap, {Color? color, String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Icon(icon, color: color ?? Colors.white, size: 20),
          )),
        ),
        if (badge != null) Positioned(top: -4, right: -4, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: _modeColors[_selectedMode], borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  // ── TOOL BUTTON ──
  Widget _toolBtn(IconData icon, String label, VoidCallback onTap, Color c) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9)),
      ]),
    );
  }
}

// ── GRID PAINTER ──
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      final dx = size.width / 3 * i;
      final dy = size.height / 3 * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
