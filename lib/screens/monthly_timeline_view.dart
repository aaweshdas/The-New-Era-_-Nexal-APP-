import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'immersive_dome_gallery_view.dart';

class MonthlyEntry {
  final String month;
  final String captures;
  final String imageUrl;

  MonthlyEntry({
    required this.month,
    required this.captures,
    required this.imageUrl,
  });
}

List<MonthlyEntry> generateMockMonthlyData(String year) {
  return [
    MonthlyEntry(
      month: 'December',
      captures: '124 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'November',
      captures: '89 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'October',
      captures: '215 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'September',
      captures: '167 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'August',
      captures: '312 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'July',
      captures: '95 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'June',
      captures: '150 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'May',
      captures: '182 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1433086966358-54859d0ed716?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'April',
      captures: '210 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'March',
      captures: '134 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'February',
      captures: '98 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2000&auto=format&fit=crop',
    ),
    MonthlyEntry(
      month: 'January',
      captures: '241 CAPTURES',
      imageUrl:
          'https://images.unsplash.com/photo-1506744626753-1fa7604d412e?q=80&w=2000&auto=format&fit=crop',
    ),
  ];
}

class MonthlyTimelineView extends StatefulWidget {
  final String year;

  const MonthlyTimelineView({super.key, required this.year});

  @override
  State<MonthlyTimelineView> createState() => _MonthlyTimelineViewState();
}

class _MonthlyTimelineViewState extends State<MonthlyTimelineView> {
  bool _isSearching = false;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  late List<MonthlyEntry> _allData;
  late List<MonthlyEntry> _filteredData;

  @override
  void initState() {
    super.initState();
    _allData = generateMockMonthlyData(widget.year);
    _filteredData = List.from(_allData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = List.from(_allData);
      } else {
        _filteredData = _allData
            .where((e) => e.month.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
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
                  '${widget.year} Timeline Settings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsTile(
                  icon: LucideIcons.arrowUpDown,
                  label: 'Reverse Order',
                  subtitle: 'Show January first',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filteredData = _filteredData.reversed.toList();
                    });
                    _showSnackBar('Order reversed', LucideIcons.arrowUpDown);
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.sparkles,
                  label: 'Highlight Top Months',
                  subtitle: 'Show months with most captures',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnackBar(
                      'Top months highlighted',
                      LucideIcons.sparkles,
                    );
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.folderOpen,
                  label: 'Select Multiple',
                  subtitle: 'Batch select months for export',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnackBar(
                      'Multi-select mode enabled',
                      LucideIcons.folderOpen,
                    );
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.download,
                  label: 'Download All Photos',
                  subtitle: 'Save all ${widget.year} photos',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnackBar(
                      'Downloading ${widget.year} photos...',
                      LucideIcons.download,
                    );
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.share2,
                  label: 'Share Year Album',
                  subtitle: 'Share as a collective album',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnackBar(
                      'Sharing ${widget.year} album...',
                      LucideIcons.share2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131826),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/gallery/timeline_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),

            // Main content: either timeline or grid
            _isGridView ? _buildGridView() : _buildTimelineView(),

            // Search Overlay
            if (_isSearching)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _filteredData = List.from(_allData);
                    });
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Column(
                      children: [
                        const SizedBox(height: 90),
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
                                          hintText: 'Search months...',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: _filterData,
                                        onSubmitted: (value) {
                                          setState(() {
                                            _isSearching = false;
                                          });
                                          if (_filteredData.isEmpty) {
                                            _showSnackBar(
                                              'No months found for "$value"',
                                              LucideIcons.searchX,
                                            );
                                          } else {
                                            _showSnackBar(
                                              'Showing ${_filteredData.length} months',
                                              LucideIcons.search,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchController.clear();
                                          _filteredData = List.from(_allData);
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
                        const SizedBox(height: 16),
                        // Quick month chips
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allData.map((entry) {
                              final isMatch = _filteredData.contains(entry);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchController.clear();
                                    _filteredData = [entry];
                                  });
                                  _showSnackBar(
                                    'Showing ${entry.month}',
                                    LucideIcons.calendar,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMatch
                                        ? const Color(
                                            0xFF135BEC,
                                          ).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isMatch
                                          ? const Color(
                                              0xFF135BEC,
                                            ).withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Text(
                                    entry.month.substring(0, 3),
                                    style: TextStyle(
                                      color: isMatch
                                          ? const Color(0xFF135BEC)
                                          : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ═══════════════════════════════════════════════════
            // Premium 4-Pod Floating Glass Header (Matches Year-Wise Timeline)
            // ═══════════════════════════════════════════════════
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

                  // Pod 2: Standalone Floating Title Pod (Nexal Gallery + Year Timeline)
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
                                "Timeline • ${widget.year}",
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
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
                                _filteredData = List.from(_allData);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isGridView = !_isGridView;
          });
          _showSnackBar(
            _isGridView ? 'Grid view enabled' : 'Timeline view enabled',
            _isGridView ? LucideIcons.grid : LucideIcons.list,
          );
        },
        backgroundColor: const Color(0xFF135BEC),
        elevation: 12,
        child: Icon(
          _isGridView ? LucideIcons.list : LucideIcons.grid,
          color: Colors.white,
        ),
      ),
    );
  }

  // ═══ TIMELINE VIEW ═══
  Widget _buildTimelineView() {
    return Stack(
      children: [
        // Central vertical line
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.only(top: 110, bottom: 120),
          itemCount: _filteredData.length + 1,
          itemBuilder: (context, index) {
            if (index == _filteredData.length) {
              return _buildEndOfTimelineIndicator();
            }
            final entry = _filteredData[index];
            final isLeftAligned = index % 2 == 0;
            return _buildMonthlyRow(context, entry, isLeftAligned, index);
          },
        ),
      ],
    );
  }

  // ═══ GRID VIEW ═══
  Widget _buildGridView() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: 110,
        bottom: 120,
        left: 16,
        right: 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final entry = _filteredData[index];
        return _buildGridCard(context, entry);
      },
    );
  }

  Widget _buildGridCard(BuildContext context, MonthlyEntry entry) {
    return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ImmersiveDomeGalleryView(
                      title: '${entry.month} ${widget.year}',
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    entry.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF135BEC),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.month,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.captures,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildMonthlyRow(
    BuildContext context,
    MonthlyEntry entry,
    bool isLeftAligned,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: isLeftAligned
                ? _buildTextContent(entry, TextAlign.right)
                : _buildImageContent(context, entry, index),
          ),
          _buildCenterNode(),
          Expanded(
            child: isLeftAligned
                ? _buildImageContent(context, entry, index)
                : _buildTextContent(entry, TextAlign.left),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNode() {
    return SizedBox(
      width: 48,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF131826), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF135BEC).withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(MonthlyEntry entry, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: align,
          ),
          const SizedBox(height: 4),
          Text(
            entry.captures,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 1.0,
            ),
            textAlign: align,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    MonthlyEntry entry,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ImmersiveDomeGalleryView(
                  title: '${entry.month} ${widget.year}',
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Hero(
        tag: 'gallery_image_${index + 1000}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Image.network(
                entry.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF135BEC),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndOfTimelineIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Text(
            "Scroll for earlier memories",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            LucideIcons.chevronsDown,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
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
