import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/background_provider.dart';
import '../../theme/app_theme.dart';

class DashboardBackgroundScreen extends StatefulWidget {
  const DashboardBackgroundScreen({super.key});

  @override
  State<DashboardBackgroundScreen> createState() =>
      _DashboardBackgroundScreenState();
}

class _DashboardBackgroundScreenState
    extends State<DashboardBackgroundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ImagePicker _picker = ImagePicker();

  // Mini video preview controller for the selected item
  VideoPlayerController? _previewCtrl;
  String? _previewingPath;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _previewCtrl?.dispose();
    super.dispose();
  }

  // ─── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final prov = context.read<BackgroundProvider>();
    try {
      final files = await _picker.pickMultiImage();
      if (files.isEmpty || !mounted) return;

      for (final file in files) {
        final item = BackgroundItem(
          path: file.path,
          type: BackgroundType.customImage,
          name: file.name,
          addedAt: DateTime.now(),
        );
        await prov.addToLibrary(item);
      }
      _showSnack('${files.length} images added to your library ✓');
    } catch (e) {
      _showSnack('Failed to pick images', error: true);
    }
  }

  Future<void> _pickVideo() async {
    final prov = context.read<BackgroundProvider>();
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      final item = BackgroundItem(
        path: file.path,
        type: BackgroundType.customVideo,
        name: file.name,
        addedAt: DateTime.now(),
      );
      await prov.addToLibrary(item);
      _showSnack('Video added to your library ✓');
    } catch (e) {
      _showSnack('Failed to pick video', error: true);
    }
  }

  // ─── Apply ────────────────────────────────────────────────────────────────

  Future<void> _applyBackground(BackgroundItem item) async {
    final prov = context.read<BackgroundProvider>();
    await prov.setBackground(item);
    if (mounted) {
      _showSnack('Background applied! ✨');
    }
  }

  Future<void> _resetDefault() async {
    await context.read<BackgroundProvider>().resetToDefault();
    if (mounted) _showSnack('Reset to default background');
  }

  // ─── Preview ──────────────────────────────────────────────────────────────

  Future<void> _startPreview(String path, BackgroundType type) async {
    if (_previewingPath == path) return;
    _previewCtrl?.dispose();
    setState(() {
      _previewingPath = path;
    });
    if (type == BackgroundType.customVideo) {
      final ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      ctrl.setVolume(0);
      ctrl.setLooping(true);
      ctrl.play();
      if (mounted) {
        setState(() {
          _previewCtrl = ctrl;
        });
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor:
          error ? Colors.red.shade800 : const Color(0xFF00E5FF).withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _label(BackgroundType t) {
    switch (t) {
      case BackgroundType.defaultVideo: return 'Default';
      case BackgroundType.assetVideo:   return 'Asset Video';
      case BackgroundType.customVideo:  return 'Custom Video';
      case BackgroundType.assetImage:   return 'Asset Image';
      case BackgroundType.customImage:  return 'Custom Image';
    }
  }

  Color _typeColor(BackgroundType t) {
    switch (t) {
      case BackgroundType.defaultVideo: return const Color(0xFF22D3EE);
      case BackgroundType.assetVideo:   return const Color(0xFF00FFB2);
      case BackgroundType.customVideo:  return const Color(0xFFC084FC);
      case BackgroundType.assetImage:   return const Color(0xFFFFB200);
      case BackgroundType.customImage:  return const Color(0xFFFF6B9D);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildLibraryTab(),
                  _buildAddMediaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DASHBOARD BACKGROUND',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF22D3EE),
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      'Personalize your home screen',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              // Reset button
              _GlassButton(
                icon: LucideIcons.rotateCcw,
                label: 'Reset',
                onTap: _resetDefault,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.layoutGrid, size: 14),
                const SizedBox(width: 6),
                Text('My Library', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plusCircle, size: 14),
                const SizedBox(width: 6),
                Text('Add Media', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Library Tab ──────────────────────────────────────────────────────────

  Widget _buildLibraryTab() {
    return Consumer<BackgroundProvider>(
      builder: (context, prov, _) {
        // Always include the default entry at top
        final defaultItem = BackgroundItem(
          path: 'assets/videos/Background.mp4',
          type: BackgroundType.defaultVideo,
          name: 'Nexal Default',
          addedAt: DateTime(2024),
        );

        final allItems = [defaultItem, ...prov.library];

        if (allItems.length == 1) {
          // Only default item — show empty state for library
          return Column(
            children: [
              const SizedBox(height: 12),
              _buildDefaultCard(defaultItem, prov),
              const SizedBox(height: 40),
              _buildEmptyLibrary(),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Active preview banner
            _buildActivePreviewBanner(prov),
            const SizedBox(height: 20),
            Text(
              'YOUR BACKGROUNDS',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: allItems.length,
              itemBuilder: (context, i) {
                final item = allItems[i];
                final isActive = prov.activePath == item.path;
                return _BackgroundCard(
                  item: item,
                  isActive: isActive,
                  onApply: () => _applyBackground(item),
                  onDelete: (item.type == BackgroundType.defaultVideo ||
                          item.type == BackgroundType.assetVideo ||
                          item.type == BackgroundType.assetImage)
                      ? null
                      : () => prov.removeFromLibrary(item.path),
                  onPreview: () => _startPreview(item.path, item.type),
                  typeColor: _typeColor(item.type),
                  typeLabel: _label(item.type),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultCard(BackgroundItem item, BackgroundProvider prov) {
    final isActive = prov.activePath == item.path;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _BackgroundCard(
        item: item,
        isActive: isActive,
        onApply: () => _applyBackground(item),
        onDelete: null,
        onPreview: null,
        typeColor: _typeColor(item.type),
        typeLabel: _label(item.type),
      ),
    );
  }

  Widget _buildActivePreviewBanner(BackgroundProvider prov) {
    final isDefault = prov.activeType == BackgroundType.defaultVideo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22D3EE).withValues(alpha: 0.12),
            const Color(0xFF0EA5E9).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.monitor, color: Color(0xFF22D3EE), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Active',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDefault ? 'Nexal Default Video' : prov.activePath.split('/').last,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _label(prov.activeType),
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF22D3EE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLibrary() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(LucideIcons.image, color: Colors.white24, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Your library is empty',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add images or videos from the\n"Add Media" tab to get started.',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white30),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _GlassButton(
          icon: LucideIcons.plusCircle,
          label: 'Add Media',
          onTap: () => _tabCtrl.animateTo(1),
          accent: true,
        ),
      ],
    );
  }

  // ─── Add Media Tab ────────────────────────────────────────────────────────

  Widget _buildAddMediaTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _buildPickerCard(
          icon: LucideIcons.image,
          title: 'Add Image',
          subtitle: 'JPG, PNG, WEBP • From your gallery',
          gradientColors: const [Color(0xFFFF6B9D), Color(0xFFBE185D)],
          onTap: _pickImage,
        ),
        const SizedBox(height: 16),
        _buildPickerCard(
          icon: LucideIcons.video,
          title: 'Add Video',
          subtitle: 'MP4, MOV, WEBM • Plays as animated background',
          gradientColors: const [Color(0xFFC084FC), Color(0xFF7E22CE)],
          onTap: _pickVideo,
        ),
        const SizedBox(height: 32),
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withValues(alpha: 0.12),
              gradientColors[1].withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: gradientColors[0], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      (LucideIcons.video, 'Videos loop seamlessly as your background'),
      (LucideIcons.image, 'Images are displayed with a subtle parallax effect'),
      (LucideIcons.hardDrive, 'Saved media stays available even offline'),
      (LucideIcons.rotateCcw, 'Reset to default anytime from the header'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: Color(0xFFD4A843), size: 16),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4A843),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t.$1, color: Colors.white38, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.$2,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── BackgroundCard ─────────────────────────────────────────────────────────

class _BackgroundCard extends StatelessWidget {
  final BackgroundItem item;
  final bool isActive;
  final VoidCallback onApply;
  final VoidCallback? onDelete;
  final VoidCallback? onPreview;
  final Color typeColor;
  final String typeLabel;

  const _BackgroundCard({
    required this.item,
    required this.isActive,
    required this.onApply,
    required this.onDelete,
    required this.onPreview,
    required this.typeColor,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onApply,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isActive ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? typeColor : Colors.white.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: typeColor.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail / Preview
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildThumbnail(),
              ),
            ),

            // Footer info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.checkCircle, size: 12, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.outfit(fontSize: 11, color: typeColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.type == BackgroundType.defaultVideo) {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.video, color: Colors.white38, size: 32),
            SizedBox(height: 8),
            Text('Default', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    if (item.type == BackgroundType.customImage) {
      return Image.file(File(item.path), fit: BoxFit.cover, cacheWidth: 300);
    }

    if (item.type == BackgroundType.assetImage) {
      return Image.asset(item.path, fit: BoxFit.cover, cacheWidth: 300);
    }

    // Video — show a file icon + name since we can't easily thumbnail without initializing
    return Container(
      color: const Color(0xFF1A0A2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.film, color: Color(0xFFC084FC), size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.name,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GlassButton ────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: accent
              ? const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)])
              : null,
          color: accent ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
