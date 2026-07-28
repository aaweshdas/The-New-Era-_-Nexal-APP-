import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/snap_camera_controller.dart';

class SnapPostCaptureOverlay extends StatefulWidget {
  final SnapCameraController controller;
  final VoidCallback onClose;
  final VoidCallback onSend;
  final VoidCallback onAddToStory;

  const SnapPostCaptureOverlay({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onSend,
    required this.onAddToStory,
  });

  @override
  State<SnapPostCaptureOverlay> createState() => _SnapPostCaptureOverlayState();
}

class _SnapPostCaptureOverlayState extends State<SnapPostCaptureOverlay> {
  final TextEditingController _captionCtrl = TextEditingController();
  bool _isEditingCaption = false;

  final List<Color> _palette = const [
    Color(0xFFFFFC00), // Snapchat Yellow
    Colors.white,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _captionCtrl.text = widget.controller.captionText;
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final file = c.capturedFile;
    if (file == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Captured Photo / Media Viewport
          Positioned.fill(
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
            ),
          ),

          // 2. Interactive Drawing Canvas
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: c.isDrawingMode
                  ? (details) {
                      c.addDrawingPoint(details.localPosition);
                    }
                  : null,
              child: CustomPaint(
                painter: _DrawingPainter(points: c.drawingPoints),
              ),
            ),
          ),

          // 3. Caption Overlay Text
          if (c.captionText.isNotEmpty || _isEditingCaption)
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).size.height * 0.45,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _captionCtrl,
                  autofocus: _isEditingCaption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    c.captionText = val;
                  },
                  onSubmitted: (_) {
                    setState(() => _isEditingCaption = false);
                  },
                ),
              ),
            ),

          // 4. Color Palette Slider (When Drawing Mode active)
          if (c.isDrawingMode)
            Positioned(
              right: 60,
              top: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _palette.map((color) {
                    final isSel = c.currentDrawColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          c.currentDrawColor = color;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: isSel ? 26 : 20,
                        height: isSel ? 26 : 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSel ? 2.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 5. Top Bar (Close X button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, color: Colors.white, size: 22),
              ),
            ),
          ),

          // 6. Right Side Vertical Edit Toolbar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Column(
              children: [
                _buildToolBtn(
                  icon: LucideIcons.pencil,
                  label: 'Draw',
                  active: c.isDrawingMode,
                  onTap: () {
                    setState(() => c.isDrawingMode = !c.isDrawingMode);
                  },
                ),
                _buildToolBtn(
                  icon: LucideIcons.type,
                  label: 'Text',
                  onTap: () {
                    setState(() => _isEditingCaption = true);
                  },
                ),
                _buildToolBtn(
                  icon: LucideIcons.smile,
                  label: 'Sticker',
                  onTap: () {
                    _showStickersModal(context);
                  },
                ),
                _buildToolBtn(
                  icon: LucideIcons.scissors,
                  label: 'Cut',
                  onTap: () {},
                ),
                _buildToolBtn(
                  icon: LucideIcons.link,
                  label: 'Attach',
                  onTap: () {},
                ),
                _buildToolBtn(
                  icon: LucideIcons.timer,
                  label: c.snapTimerSeconds > 0 ? '${c.snapTimerSeconds}s' : '∞',
                  onTap: () {
                    setState(() {
                      c.snapTimerSeconds = c.snapTimerSeconds == 10 ? 3 : 10;
                    });
                  },
                ),
                if (c.isVideoSnap)
                  _buildToolBtn(
                    icon: c.isAudioMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                    label: 'Audio',
                    onTap: () {
                      setState(() => c.isAudioMuted = !c.isAudioMuted);
                    },
                  ),
              ],
            ),
          ),

          // 7. Bottom Bar (Add to Story + Blue Send To Button)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Add to Story Button
                GestureDetector(
                  onTap: widget.onAddToStory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.ghost, color: Color(0xFFFFFC00), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add to Story',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Blue Snapchat Send To Pill Button
                GestureDetector(
                  onTap: widget.onSend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0088FF), // Snapchat Blue
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0088FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Send To',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      ],
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

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFFC00) : Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: active ? Colors.black : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showStickersModal(BuildContext ctx) {
    final stickers = ['🔥', '✨', '⚡', '💯', '❤️', '👑', '🎉', '🌟', '👻', '🐶'];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF101020),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stickers', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stickers.map((s) => GestureDetector(
                onTap: () {
                  Navigator.pop(bCtx);
                  setState(() {
                    widget.controller.captionText += ' $s';
                  });
                },
                child: Text(s, style: const TextStyle(fontSize: 32)),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  _DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != Offset.zero && points[i + 1].offset != Offset.zero) {
        canvas.drawLine(points[i].offset, points[i + 1].offset, points[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
