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

  // Functional Settings State
  bool _isGridLayout = false;
  bool _isNewestFirst = true;
  String _selectedCategory = 'All';
  String _lastSyncedTime = 'Just now';
  bool _isSyncing = false;

  // Gallery Preferences State
  bool _enableAnimations = true;
  bool _enableHDPreviews = true;
  bool _enableHaptics = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return ClipRRect(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gallery Settings',
                          style: GoogleFonts.rye(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedCategory != 'All')
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = 'All');
                              setModalState(() {});
                              _showSnackBar('Filters reset to All', LucideIcons.rotateCcw);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF135BEC).withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'Reset Filters',
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsOption(
                      icon: LucideIcons.layoutGrid,
                      label: 'Change Timeline Layout',
                      subtitle: _isGridLayout
                          ? 'Current: 2-Column Photo Grid'
                          : 'Current: Split Timeline',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _isGridLayout = !_isGridLayout;
                        });
                        _showSnackBar(
                          _isGridLayout
                              ? 'Layout: 2-Column Photo Grid'
                              : 'Layout: Split Timeline',
                          LucideIcons.layoutGrid,
                        );
                      },
                    ),
                    _SettingsOption(
                      icon: LucideIcons.arrowDownUp,
                      label: 'Sort Order',
                      subtitle: _isNewestFirst
                          ? 'Current: Newest First (2026 → 2004)'
                          : 'Current: Oldest First (2004 → 2026)',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _isNewestFirst = !_isNewestFirst;
                        });
                        _showSnackBar(
                          _isNewestFirst
                              ? 'Sorted: Newest First (2026 → 2004)'
                              : 'Sorted: Oldest First (2004 → 2026)',
                          LucideIcons.arrowDownUp,
                        );
                      },
                    ),
                    _SettingsOption(
                      icon: LucideIcons.filter,
                      label: 'Filter by Category',
                      subtitle: 'Active: $_selectedCategory',
                      onTap: () {
                        Navigator.pop(context);
                        _showCategoryFilterSheet();
                      },
                    ),
                    _SettingsOption(
                      icon: LucideIcons.cloud,
                      label: 'Cloud Sync',
                      subtitle: _isSyncing
                          ? 'Syncing in progress...'
                          : 'Last synced: $_lastSyncedTime',
                      onTap: () {
                        Navigator.pop(context);
                        _triggerCloudSync();
                      },
                    ),
                    _SettingsOption(
                      icon: LucideIcons.settings,
                      label: 'Gallery Preferences',
                      subtitle: 'Animations, HD previews & cache',
                      onTap: () {
                        Navigator.pop(context);
                        _showPreferencesSheet();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryFilterSheet() {
    final categories = ['All', 'Space & Tech', 'AI & Future', 'Culture & Web3', 'Science & Nature'];
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                const SizedBox(height: 16),
                Text(
                  'Filter by Category',
                  style: GoogleFonts.rye(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _showSnackBar('Filter applied: $cat', LucideIcons.filter);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF135BEC).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF135BEC)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isSelected)
                              const Icon(LucideIcons.check, color: Color(0xFF00E5FF), size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _triggerCloudSync() async {
    setState(() => _isSyncing = true);
    _showSnackBar('Syncing 23 gallery memories with cloud...', LucideIcons.cloud);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      final now = TimeOfDay.now();
      final formattedTime = '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';
      setState(() {
        _isSyncing = false;
        _lastSyncedTime = formattedTime;
      });
      _showSnackBar('Cloud Sync Complete! All memories updated.', LucideIcons.checkCircle);
    }
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPrefState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    const SizedBox(height: 16),
                    Text(
                      'Gallery Preferences',
                      style: GoogleFonts.rye(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF00E5FF),
                      title: const Text('Fluid Animations', style: TextStyle(color: Colors.white, fontSize: 15)),
                      subtitle: Text('Enable smooth timeline transitions', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      value: _enableAnimations,
                      onChanged: (val) {
                        setState(() => _enableAnimations = val);
                        setPrefState(() {});
                      },
                    ),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF00E5FF),
                      title: const Text('HD Image Previews', style: TextStyle(color: Colors.white, fontSize: 15)),
                      subtitle: Text('Load high-resolution preview images', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      value: _enableHDPreviews,
                      onChanged: (val) {
                        setState(() => _enableHDPreviews = val);
                        setPrefState(() {});
                      },
                    ),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF00E5FF),
                      title: const Text('Haptic Touch Effects', style: TextStyle(color: Colors.white, fontSize: 15)),
                      subtitle: Text('Vibrate subtly on timeline taps', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      value: _enableHaptics,
                      onChanged: (val) {
                        setState(() => _enableHaptics = val);
                        setPrefState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        label: const Text('Clear Gallery Cache (14.8 MB)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showSnackBar('Cleared 14.8 MB of cached gallery assets', LucideIcons.trash2);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
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
            Positioned.fill(
              child: PremiumTimelineGallery(
                isGridLayout: _isGridLayout,
                isNewestFirst: _isNewestFirst,
                selectedCategory: _selectedCategory,
                searchQuery: _searchController.text,
              ),
            ),

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
                                    color: const Color(0xFF135BEC).withValues(alpha: 0.3),
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
                                            color: Colors.white.withValues(alpha: 0.4),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (_) {
                                          setState(() {}); // Live filter search results
                                        },
                                        onSubmitted: (value) {
                                          _showSnackBar(
                                            'Searching for "$value"...',
                                            LucideIcons.search,
                                          );
                                          setState(() {
                                            _isSearching = false;
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
                                  _searchController.text = '2024';
                                  _showSnackBar('Filtered by 2024', LucideIcons.calendar);
                                  setState(() => _isSearching = false);
                                },
                              ),
                              _RecentSearchChip(
                                label: 'Quantum Launch',
                                onTap: () {
                                  _searchController.text = 'Quantum Launch';
                                  _showSnackBar('Filtered by Quantum Launch', LucideIcons.search);
                                  setState(() => _isSearching = false);
                                },
                              ),
                              _RecentSearchChip(
                                label: 'Neon Synchrony',
                                onTap: () {
                                  _searchController.text = 'Neon Synchrony';
                                  _showSnackBar('Filtered by Neon Synchrony', LucideIcons.search);
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

            // Premium 4-Pod Floating Glass Header
            Positioned(
              top: 24,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  // Pod 1: Standalone Floating Back Button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white70,
                            size: 19,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Pod 2: Standalone Floating Title Pod (Nexal Gallery + Timeline)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Nexal Gallery",
                                  style: GoogleFonts.rye(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _selectedCategory == 'All'
                                    ? "Timeline"
                                    : "Timeline • $_selectedCategory",
                                style: TextStyle(
                                  color: _selectedCategory == 'All' ? Colors.white54 : const Color(0xFF00E5FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Pod 3: Standalone Floating Search Button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isSearching || _searchController.text.isNotEmpty ? LucideIcons.x : LucideIcons.search,
                            color: _isSearching || _searchController.text.isNotEmpty
                                ? const Color(0xFF135BEC)
                                : Colors.white70,
                            size: 19,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_searchController.text.isNotEmpty) {
                                _searchController.clear();
                              }
                              _isSearching = !_isSearching;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Pod 4: Standalone Floating Three Dots Settings Button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: _showSettingsSheet,
                        ),
                      ),
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
