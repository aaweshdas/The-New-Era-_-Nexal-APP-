import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class FullScreenImageView extends StatefulWidget {
  final String imageUrl;
  final int index;

  const FullScreenImageView({
    super.key,
    required this.imageUrl,
    required this.index,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  bool _isFavorited = false;
  bool _showInfo = true;

  void _showSnackBar(String message, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: color ?? const Color(0xFF00E5FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Share Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ShareOption(
                      icon: LucideIcons.copy,
                      label: 'Copy Link',
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(ClipboardData(text: widget.imageUrl));
                        _showSnackBar(
                          'Link copied to clipboard!',
                          icon: LucideIcons.copy,
                        );
                      },
                    ),
                    _ShareOption(
                      icon: LucideIcons.messageCircle,
                      label: 'Message',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar(
                          'Opening messages...',
                          icon: LucideIcons.messageCircle,
                        );
                      },
                    ),
                    _ShareOption(
                      icon: LucideIcons.instagram,
                      label: 'Stories',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar(
                          'Sharing to Stories...',
                          icon: LucideIcons.instagram,
                        );
                      },
                    ),
                    _ShareOption(
                      icon: LucideIcons.download,
                      label: 'Save',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar(
                          'Photo saved to device!',
                          icon: LucideIcons.download,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });
    HapticFeedback.mediumImpact();
    _showSnackBar(
      _isFavorited ? 'Added to favorites ❤️' : 'Removed from favorites',
      icon: _isFavorited ? LucideIcons.heart : LucideIcons.heartOff,
    );
  }

  void _handleEdit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _EditOption(
                  icon: LucideIcons.crop,
                  label: 'Crop & Rotate',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Crop tool opened', icon: LucideIcons.crop);
                  },
                ),
                _EditOption(
                  icon: LucideIcons.sliders,
                  label: 'Adjust (Brightness, Contrast, Saturation)',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Adjustments panel opened',
                      icon: LucideIcons.sliders,
                    );
                  },
                ),
                _EditOption(
                  icon: LucideIcons.sparkles,
                  label: 'Apply Filter',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Filters gallery opened',
                      icon: LucideIcons.sparkles,
                    );
                  },
                ),
                _EditOption(
                  icon: LucideIcons.type,
                  label: 'Add Text / Watermark',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Text editor opened', icon: LucideIcons.type);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Photo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this photo? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back from full screen
              // Use a post-frame callback to show snackbar on the previous screen
              WidgetsBinding.instance.addPostFrameCallback((_) {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Photo Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _EditOption(
                  icon: LucideIcons.info,
                  label: 'Photo Details',
                  onTap: () {
                    Navigator.pop(context);
                    _showPhotoDetails();
                  },
                ),
                _EditOption(
                  icon: LucideIcons.image,
                  label: 'Set as Wallpaper',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Setting as wallpaper...',
                      icon: LucideIcons.image,
                    );
                  },
                ),
                _EditOption(
                  icon: LucideIcons.copy,
                  label: 'Copy Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Photo copied to clipboard!',
                      icon: LucideIcons.copy,
                    );
                  },
                ),
                _EditOption(
                  icon: LucideIcons.printer,
                  label: 'Print',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Opening print dialog...',
                      icon: LucideIcons.printer,
                    );
                  },
                ),
                _EditOption(
                  icon: LucideIcons.eyeOff,
                  label: 'Hide Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Photo hidden from gallery',
                      icon: LucideIcons.eyeOff,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: Color(0xFF00E5FF), size: 22),
            SizedBox(width: 10),
            Text(
              'Photo Details',
              style: TextStyle(
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
            _DetailRow(
              'Type',
              widget.imageUrl.startsWith('http')
                  ? 'Network Image'
                  : 'Local File',
            ),
            _DetailRow('Resolution', '2000 × 1333 px'),
            _DetailRow('Format', 'JPEG'),
            _DetailRow('Size', '2.4 MB'),
            _DetailRow('Date', 'March 9, 2026'),
            _DetailRow('Camera', 'Nexal Camera v2.1'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showInfo = !_showInfo;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. The Interactive Image with Hero
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 300) {
                  Navigator.pop(context);
                }
              },
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: 'gallery_image_${widget.index}',
                  child: widget.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.cyan500,
                            ),
                          ),
                        )
                      : Image.file(File(widget.imageUrl), fit: BoxFit.contain),
                ),
              ),
            ),

            // 2. Glass Top Bar (animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showInfo ? 0 : -120,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 10,
                      right: 10,
                    ),
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            LucideIcons.chevronLeft,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          "PHOTO",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.moreHorizontal,
                            color: Colors.white,
                          ),
                          onPressed: _handleMoreOptions,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Glass Bottom Action Row (animated)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showInfo ? 30 : -100,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: LucideIcons.share2,
                          label: "Share",
                          onTap: _handleShare,
                        ),
                        _ActionButton(
                          icon: _isFavorited
                              ? Icons.favorite
                              : LucideIcons.heart,
                          label: "Favorite",
                          color: _isFavorited ? Colors.redAccent : Colors.white,
                          onTap: _handleFavorite,
                        ),
                        _ActionButton(
                          icon: LucideIcons.edit2,
                          label: "Edit",
                          onTap: _handleEdit,
                        ),
                        _ActionButton(
                          icon: LucideIcons.trash2,
                          label: "Delete",
                          color: Colors.redAccent,
                          onTap: _handleDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EditOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EditOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: Colors.white70, size: 20)),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const Spacer(),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
