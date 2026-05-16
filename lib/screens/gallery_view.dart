import 'package:flutter/material.dart';
import '../widgets/gallery/premium_timeline_gallery.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GalleryView extends StatefulWidget {
  const GalleryView({super.key});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSettingsSheet() {
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
                Text(
                  'Gallery Settings',
                  style: GoogleFonts.rye(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsOption(
                  icon: LucideIcons.layoutGrid,
                  label: 'Change Timeline Layout',
                  subtitle: 'Alternate between grid and list',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Layout changed', LucideIcons.layoutGrid);
                  },
                ),
                _SettingsOption(
                  icon: LucideIcons.arrowDownUp,
                  label: 'Sort Order',
                  subtitle: 'Newest first',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Sort order updated',
                      LucideIcons.arrowDownUp,
                    );
                  },
                ),
                _SettingsOption(
                  icon: LucideIcons.filter,
                  label: 'Filter by Category',
                  subtitle: 'All categories',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Filters applied', LucideIcons.filter);
                  },
                ),
                _SettingsOption(
                  icon: LucideIcons.cloud,
                  label: 'Cloud Sync',
                  subtitle: 'Last synced: Just now',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Syncing with cloud...', LucideIcons.cloud);
                  },
                ),
                _SettingsOption(
                  icon: LucideIcons.settings,
                  label: 'Gallery Preferences',
                  subtitle: 'Themes, animations, storage',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Opening preferences...',
                      LucideIcons.settings,
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

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00E5FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/gallery/gallery_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay for readability
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            // The Premium Timeline Gallery
            const Positioned.fill(child: PremiumTimelineGallery()),

            // Search Overlay
            if (_isSearching)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF135BEC,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.search,
                                      color: Color(0xFF135BEC),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search years, events...',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (value) {
                                          _showSnackBar(
                                            'Searching for "$value"...',
                                            LucideIcons.search,
                                          );
                                          setState(() {
                                            _isSearching = false;
                                            _searchController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchController.clear();
                                        });
                                      },
                                      child: const Icon(
                                        LucideIcons.x,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Recent searches
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECENT SEARCHES',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _RecentSearchChip(
                                label: '2024',
                                onTap: () {
                                  _showSnackBar(
                                    'Jumping to 2024...',
                                    LucideIcons.calendar,
                                  );
                                  setState(() => _isSearching = false);
                                },
                              ),
                              _RecentSearchChip(
                                label: 'Quantum Launch',
                                onTap: () {
                                  _showSnackBar(
                                    'Found: Quantum Launch',
                                    LucideIcons.search,
                                  );
                                  setState(() => _isSearching = false);
                                },
                              ),
                              _RecentSearchChip(
                                label: 'Neon Synchrony',
                                onTap: () {
                                  _showSnackBar(
                                    'Found: Neon Synchrony',
                                    LucideIcons.search,
                                  );
                                  setState(() => _isSearching = false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Premium Floating Pill Header
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Section
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Icon(
                                LucideIcons.arrowLeft,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              child: const Icon(
                                LucideIcons.home,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              height: 16,
                              width: 1,
                              color: Colors.white24,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Text(
                                "TIMELINE",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Center Section
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "NEXAL",
                              style: GoogleFonts.rye(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF135BEC),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF135BEC,
                                    ).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Right Section
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSearching = !_isSearching;
                                    });
                                  },
                                  child: Icon(
                                    _isSearching
                                        ? LucideIcons.x
                                        : LucideIcons.search,
                                    color: _isSearching
                                        ? const Color(0xFF135BEC)
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                                if (!_isSearching)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF135BEC),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF135BEC,
                                            ).withValues(alpha: 0.8),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _showSettingsSheet,
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ],
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

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsOption({
    required this.icon,
    required this.label,
    required this.subtitle,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

class _RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RecentSearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
