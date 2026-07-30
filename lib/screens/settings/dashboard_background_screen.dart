import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/background_provider.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

// ─── Accent used throughout this screen ────────────────────────────────────
const _kAccent   = Color(0xFF22D3EE);
const _kAccent2  = Color(0xFF0EA5E9);
const _kSurface  = Color(0xFF0A0F1E);
const _kCard     = Color(0xFF0D1220);

class DashboardBackgroundScreen extends StatefulWidget {
  const DashboardBackgroundScreen({super.key});

  @override
  State<DashboardBackgroundScreen> createState() =>
      _DashboardBackgroundScreenState();
}

class _DashboardBackgroundScreenState
    extends State<DashboardBackgroundScreen> {
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _previewCtrl;
  String? _previewingPath;

  @override
  void dispose() {
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
        await prov.addToLibrary(BackgroundItem(
          path: file.path,
          type: BackgroundType.customImage,
          name: file.name,
          addedAt: DateTime.now(),
        ));
      }
      _showSnack('${files.length} image${files.length == 1 ? '' : 's'} added ✓');
    } catch (_) {
      _showSnack('Failed to pick images', error: true);
    }
  }

  Future<void> _pickVideo() async {
    final prov = context.read<BackgroundProvider>();
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      await prov.addToLibrary(BackgroundItem(
        path: file.path,
        type: BackgroundType.customVideo,
        name: file.name,
        addedAt: DateTime.now(),
      ));
      _showSnack('Video added ✓');
    } catch (_) {
      _showSnack('Failed to pick video', error: true);
    }
  }

  Future<void> _applyBackground(BackgroundItem item) async {
    await context.read<BackgroundProvider>().setBackground(item);
    if (mounted) _showSnack('Background applied ✨');
  }

  Future<void> _resetDefault() async {
    await context.read<BackgroundProvider>().resetToDefault();
    if (mounted) _showSnack('Reset to default');
  }

  Future<void> _startPreview(String path, BackgroundType type) async {
    if (_previewingPath == path) return;
    _previewCtrl?.dispose();
    setState(() => _previewingPath = path);
    if (type == BackgroundType.customVideo) {
      final ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      ctrl.setVolume(0);
      ctrl.setLooping(true);
      ctrl.play();
      if (mounted) setState(() => _previewCtrl = ctrl);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            error ? LucideIcons.alertCircle : LucideIcons.checkCircle,
            color: Colors.white, size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
      backgroundColor: error ? const Color(0xFF991B1B) : const Color(0xFF065F46),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  String _label(BackgroundType t) => switch (t) {
    BackgroundType.defaultVideo => 'Default',
    BackgroundType.assetVideo   => 'Built-in',
    BackgroundType.customVideo  => 'Video',
    BackgroundType.assetImage   => 'Built-in',
    BackgroundType.customImage  => 'Image',
  };

  Color _typeColor(BackgroundType t) => switch (t) {
    BackgroundType.defaultVideo => const Color(0xFF22D3EE),
    BackgroundType.assetVideo   => const Color(0xFF34D399),
    BackgroundType.customVideo  => const Color(0xFFC084FC),
    BackgroundType.assetImage   => const Color(0xFFFBBF24),
    BackgroundType.customImage  => const Color(0xFFF472B6),
  };

  IconData _typeIcon(BackgroundType t) => switch (t) {
    BackgroundType.defaultVideo => LucideIcons.star,
    BackgroundType.assetVideo   => LucideIcons.film,
    BackgroundType.customVideo  => LucideIcons.video,
    BackgroundType.assetImage   => LucideIcons.image,
    BackgroundType.customImage  => LucideIcons.imageOff,
  };

  // ─── Import Modal Sheet ───────────────────────────────────────────────────

  void _showImportOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.plus, color: _kAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Background',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Select media from your device',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ModalImportOption(
              icon: LucideIcons.image,
              title: 'Add Images / Photos',
              subtitle: 'Select one or multiple images from gallery',
              accentColor: const Color(0xFFF472B6),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            const SizedBox(height: 12),
            _ModalImportOption(
              icon: LucideIcons.video,
              title: 'Add Video Background',
              subtitle: 'Select animated video file (MP4, MOV)',
              accentColor: const Color(0xFFC084FC),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kAccent, _kAccent2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showImportOptionsModal,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(
                  LucideIcons.plus,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildLibraryTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 — back + title + reset
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 16, 10),
            child: Row(
              children: [
                // Pill back button
                Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.arrowLeft, color: Colors.white70, size: 16),
                          SizedBox(width: 5),
                          Text('Back', style: TextStyle(
                            color: Colors.white60, fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallpaper', style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.0,
                      )),
                      const SizedBox(height: 2),
                      Text('Personalize your home screen',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.33),
                          fontSize: 11.5,
                        )),
                    ],
                  ),
                ),
                // Reset button — compact icon+label pill
                Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _resetDefault,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.rotateCcw,
                              color: Colors.white54, size: 14),
                          const SizedBox(width: 5),
                          const Text('Reset', style: TextStyle(
                            color: Colors.white54, fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 2 — active status indicator
          Consumer<BackgroundProvider>(
            builder: (context, prov, _) {
              final name = prov.activeType == BackgroundType.defaultVideo
                  ? 'Nexal Default'
                  : prov.activePath.split('/').last;
              final color = _typeColor(prov.activeType);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(color: color, width: 3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon(prov.activeType),
                              size: 13, color: color),
                          const SizedBox(width: 7),
                          Text(
                            'Active: $name',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            color.withValues(alpha: 0.4),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Library Tab ──────────────────────────────────────────────────────────

  Widget _buildLibraryTab() {
    return Consumer<BackgroundProvider>(
      builder: (context, prov, _) {
        final defaultItem = BackgroundItem(
          path: 'assets/videos/Background.mp4',
          type: BackgroundType.defaultVideo,
          name: 'Nexal Default',
          addedAt: DateTime(2024),
        );
        final allItems = [defaultItem, ...prov.library];

        if (allItems.length == 1) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Column(
              children: [
                _BackgroundCard(
                  item: defaultItem,
                  isActive: prov.activePath == defaultItem.path,
                  onApply: () => _applyBackground(defaultItem),
                  onDelete: null,
                  onPreview: null,
                  typeColor: _typeColor(defaultItem.type),
                  typeLabel: _label(defaultItem.type),
                  typeIcon: _typeIcon(defaultItem.type),
                ),
                const SizedBox(height: 40),
                _buildEmptyLibrary(),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(child: _buildStatsBar(prov, allItems.length)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(LucideIcons.layers, size: 13,
                        color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 7),
                    Text(
                      'ALL BACKGROUNDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${allItems.length}',
                          style: const TextStyle(
                              color: _kAccent, fontSize: 10.5,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
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
                      typeIcon: _typeIcon(item.type),
                    );
                  },
                  childCount: allItems.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(BackgroundProvider prov, int total) {
    final videos = prov.library.where((x) =>
        x.type == BackgroundType.customVideo ||
        x.type == BackgroundType.assetVideo).length;
    final images = prov.library.where((x) =>
        x.type == BackgroundType.customImage ||
        x.type == BackgroundType.assetImage).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent.withValues(alpha: 0.1),
            _kAccent2.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: LucideIcons.layoutGrid, label: 'Total',
            value: '$total', color: _kAccent,
          ),
          _vDivider(),
          _StatChip(
            icon: LucideIcons.video, label: 'Videos',
            value: '$videos', color: const Color(0xFFC084FC),
          ),
          _vDivider(),
          _StatChip(
            icon: LucideIcons.image, label: 'Images',
            value: '$images', color: const Color(0xFFF472B6),
          ),
          _vDivider(),
          _StatChip(
            icon: LucideIcons.checkCircle, label: 'Active',
            value: _label(prov.activeType),
            color: _typeColor(prov.activeType),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white.withValues(alpha: 0.08),
      );

  Widget _buildEmptyLibrary() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
          ),
          child: const Icon(LucideIcons.image, color: _kAccent, size: 34),
        ),
        const SizedBox(height: 18),
        const Text('No custom backgrounds yet',
          style: TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          )),
        const SizedBox(height: 8),
        Text(
          'Tap the + button at bottom left to import\ncustom images or videos to your library.',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _ActionButton(
          icon: LucideIcons.plus,
          label: 'Add Background',
          onTap: _showImportOptionsModal,
          colors: const [_kAccent, _kAccent2],
        ),
      ],
    );
  }
}

// ─── Modal Import Option ───────────────────────────────────────────────────

class _ModalImportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModalImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  color: Colors.white.withValues(alpha: 0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 5),
          Text(value,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(
              fontSize: 10, color: Colors.white.withValues(alpha: 0.35),
            )),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  const _ActionButton({
    required this.icon, required this.label,
    required this.onTap, required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.4),
                blurRadius: 14, spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 17),
              const SizedBox(width: 9),
              Text(label, style: const TextStyle(
                color: Colors.black, fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Background Card ─────────────────────────────────────────────────────────

class _BackgroundCard extends StatelessWidget {
  final BackgroundItem item;
  final bool isActive;
  final VoidCallback onApply;
  final VoidCallback? onDelete;
  final VoidCallback? onPreview;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;

  const _BackgroundCard({
    required this.item,
    required this.isActive,
    required this.onApply,
    required this.onDelete,
    required this.onPreview,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onApply,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive
              ? typeColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? typeColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(
                  color: typeColor.withValues(alpha: 0.25),
                  blurRadius: 10, spreadRadius: 1,
                )]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnail(),
                    // Top-left type icon badge
                    Positioned(
                      top: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(typeIcon, size: 9, color: typeColor),
                      ),
                    ),
                    // Active check overlay on top right
                    if (isActive)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: typeColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.check,
                              color: Colors.black, size: 9),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer info - compact for 5-column grid
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? typeColor : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(LucideIcons.trash2,
                            size: 10, color: Colors.red.shade400),
                      ),
                    ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.star,
                color: const Color(0xFF22D3EE).withValues(alpha: 0.7), size: 20),
            const SizedBox(height: 3),
            const Text('Default', style: TextStyle(
                color: Colors.white54, fontSize: 8.5,
                fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (item.type == BackgroundType.customImage) {
      return Image.file(File(item.path), fit: BoxFit.cover, cacheWidth: 150);
    }
    if (item.type == BackgroundType.assetImage) {
      return Image.asset(item.path, fit: BoxFit.cover, cacheWidth: 150);
    }
    // Video placeholder
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A0A2E),
            Color(0xFF0D0520),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.film,
              color: Color(0xFFC084FC), size: 20),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.name,
              style: const TextStyle(color: Colors.white54, fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}
