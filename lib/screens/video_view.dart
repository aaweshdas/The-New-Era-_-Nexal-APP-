import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';

class VideoItem {
  final String id, title, category, imageUrl, duration;
  final int progress;
  final String? creator;
  final double? rating;
  final String? views;

  VideoItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.duration,
    this.progress = 0,
    this.creator,
    this.rating,
    this.views,
  });
}

class VideoView extends StatefulWidget {
  const VideoView({super.key});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with TickerProviderStateMixin {
  int _selectedCategory = 0;
  late AnimationController _pulseCtrl;
  final Set<String> _bookmarked = {};
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();

  final _categories = ['🔥 Trending', '🎬 Sci-Fi', '📚 Documentary', '🔴 Live', '🎮 Gaming', '🎵 Music'];

  final List<VideoItem> _continueWatching = [];
  final List<VideoItem> _trending = [];
  final List<VideoItem> _recommended = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showVideoDetail(VideoItem v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VideoDetailSheet(video: v, isBookmarked: _bookmarked.contains(v.id), onBookmark: () {
        setState(() {
          _bookmarked.contains(v.id) ? _bookmarked.remove(v.id) : _bookmarked.add(v.id);
        });
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_bookmarked.contains(v.id) ? 'Added to watchlist' : 'Removed from watchlist', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFF1a1a2e),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }),
    );
  }

  void _showCastPicker() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(LucideIcons.cast, color: AppTheme.cyan500, size: 18),
        const SizedBox(width: 10),
        Text('Scanning for nearby devices...', style: GoogleFonts.outfit(color: Colors.white)),
      ]),
      backgroundColor: const Color(0xFF1a1a2e),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF0a0012), Colors.black, Color(0xFF000a14), Colors.black],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (_showSearch) SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildHeroBanner()),
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(child: _buildSectionHeader('Continue Watching', LucideIcons.history, AppTheme.purple500)),
                SliverToBoxAdapter(child: _buildContinueWatching()),
                SliverToBoxAdapter(child: _buildSectionHeader('Trending Now', LucideIcons.trendingUp, AppTheme.pink500)),
                SliverToBoxAdapter(child: _buildTrendingList()),
                SliverToBoxAdapter(child: _buildSectionHeader('Recommended', LucideIcons.sparkles, AppTheme.cyan500)),
                SliverToBoxAdapter(child: _buildRecommendedList()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _headerIcon(LucideIcons.arrowLeft, () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Videos', style: GoogleFonts.rye(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                Text('Immersive streaming', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          _headerIcon(LucideIcons.search, () => setState(() => _showSearch = !_showSearch)),
          const SizedBox(width: 10),
          _headerIcon(LucideIcons.cast, _showCastPicker),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ── SEARCH BAR ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(BorderSide(color: AppTheme.cyan500.withValues(alpha: 0.15))),
        color: Colors.white.withValues(alpha: 0.04),
        blur: 8,
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search videos, creators, genres...',
            hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
            prefixIcon: Icon(LucideIcons.search, color: AppTheme.cyan500.withValues(alpha: 0.5), size: 18),
            suffixIcon: GestureDetector(
              onTap: () => setState(() { _searchCtrl.clear(); _showSearch = false; }),
              child: const Icon(LucideIcons.x, color: Colors.white30, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0, duration: 300.ms);
  }

  // ── HERO BANNER ──
  Widget _buildHeroBanner() {
    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: CachedNetworkImageProvider('https://images.unsplash.com/photo-1535016120720-40c6874c3b1c?w=800'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          // Play button center
          Center(
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: () => _showVideoDetail(VideoItem(id: 'hero', title: 'Cosmic Origins: The Beginning', category: 'Documentary', imageUrl: 'https://images.unsplash.com/photo-1535016120720-40c6874c3b1c?w=800', duration: '45m', views: '5.2M', rating: 4.9, creator: 'Nexal Originals')),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (ctx, child) {
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.purple500.withValues(alpha: 0.15 + _pulseCtrl.value * 0.2),
                            blurRadius: 20 + _pulseCtrl.value * 10,
                            spreadRadius: _pulseCtrl.value * 4,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.play, color: Colors.white, size: 28),
                    );
                  },
                ),
              ),
            ),
          ),
          // Info bottom
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _infoBadge('4K', AppTheme.purple500),
                    const SizedBox(width: 8),
                    _infoBadge('HDR', AppTheme.cyan500),
                    const SizedBox(width: 8),
                    _infoBadge('DOLBY', AppTheme.pink500),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Cosmic Origins: The Beginning', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Documentary • 45m • Nexal Originals', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          // Bookmark
          Positioned(
            top: 14, right: 14,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _bookmarked.contains('hero') ? _bookmarked.remove('hero') : _bookmarked.add('hero');
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bookmarked.contains('hero') ? AppTheme.purple500.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _bookmarked.contains('hero') ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
                  color: _bookmarked.contains('hero') ? Colors.white : Colors.white70, size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1), duration: 500.ms);
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }

  // ── CATEGORIES ──
  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final sel = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel ? LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.6), AppTheme.cyan500.withValues(alpha: 0.4)]) : null,
                color: sel ? null : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sel ? AppTheme.purple500.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08)),
                boxShadow: sel ? [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.2), blurRadius: 12)] : [],
              ),
              child: Text(_categories[i], style: GoogleFonts.outfit(color: sel ? Colors.white : Colors.white54, fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          Text('See all', style: GoogleFonts.outfit(color: AppTheme.cyan500.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── CONTINUE WATCHING ── Circular progress ring cards
  Widget _buildContinueWatching() {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _continueWatching.length,
        itemBuilder: (ctx, i) {
          final v = _continueWatching[i];
          return GestureDetector(
            onTap: () => _showVideoDetail(v),
            child: Container(
            width: 260,
            margin: const EdgeInsets.only(right: 14),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(20),
              border: Border.fromBorderSide(BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              color: Colors.white.withValues(alpha: 0.03),
              blur: 6,
              child: Stack(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(imageUrl: v.imageUrl, width: 260, height: 185, fit: BoxFit.cover,
                      errorWidget: (c, url, error) => Container(width: 260, height: 185, color: Colors.grey[900], child: const Icon(LucideIcons.video, color: Colors.white24, size: 32)),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                  // Progress ring + play
                  Positioned(
                    top: 12, right: 12,
                    child: SizedBox(
                      width: 36, height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: v.progress / 100,
                            strokeWidth: 2.5,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.purple500),
                          ),
                          const Icon(LucideIcons.play, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                      child: Text(v.duration, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  // Bottom info
                  Positioned(
                    left: 14, right: 14, bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(v.creator ?? v.category, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                            const Spacer(),
                            Text('${v.progress}%', style: GoogleFonts.outfit(color: AppTheme.purple500.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).animate().fadeIn(delay: (400 + i * 100).ms, duration: 400.ms).slideX(begin: 0.08, end: 0, duration: 400.ms);
        },
      ),
    );
  }

  // ── TRENDING ── Ranked cards with numbers
  Widget _buildTrendingList() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trending.length,
        itemBuilder: (ctx, i) {
          final v = _trending[i];
          return GestureDetector(
            onTap: () => _showVideoDetail(v),
            child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Card
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: CachedNetworkImageProvider(v.imageUrl), fit: BoxFit.cover),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.eye, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(v.views ?? '', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                            const Spacer(),
                            Icon(LucideIcons.star, size: 12, color: const Color(0xFFFBBF24)),
                            const SizedBox(width: 3),
                            Text('${v.rating}', style: GoogleFonts.outfit(color: const Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Rank number
                Positioned(
                  left: 0, bottom: 8,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 52, fontWeight: FontWeight.w900, height: 1,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.5
                        ..color = AppTheme.pink500.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          )).animate().fadeIn(delay: (500 + i * 120).ms, duration: 400.ms).slideX(begin: 0.1, end: 0, duration: 400.ms);
        },
      ),
    );
  }

  // ── RECOMMENDED ── Vertical list with glassmorphic cards
  Widget _buildRecommendedList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(_recommended.length, (i) {
          final v = _recommended[i];
          return GestureDetector(
            onTap: () => _showVideoDetail(v),
            child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(18),
              border: Border.fromBorderSide(BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              color: Colors.white.withValues(alpha: 0.03),
              blur: 6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          CachedNetworkImage(imageUrl: v.imageUrl, width: 120, height: 80, fit: BoxFit.cover,
                            errorWidget: (c, url, error) => Container(width: 120, height: 80, color: Colors.grey[900], child: const Icon(LucideIcons.video, color: Colors.white24)),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4, right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                              child: Text(v.duration, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(v.creator ?? '', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.eye, size: 12, color: Colors.white24),
                              const SizedBox(width: 4),
                              Text(v.views ?? '', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.star, size: 12, color: const Color(0xFFFBBF24).withValues(alpha: 0.7)),
                              const SizedBox(width: 3),
                              Text('${v.rating}', style: GoogleFonts.outfit(color: const Color(0xFFFBBF24).withValues(alpha: 0.7), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _bookmarked.contains(v.id) ? _bookmarked.remove(v.id) : _bookmarked.add(v.id);
                            });
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _bookmarked.contains(v.id) ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
                              key: ValueKey(_bookmarked.contains(v.id)),
                              color: _bookmarked.contains(v.id) ? AppTheme.purple500 : Colors.white24,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.purple500.withValues(alpha: 0.15),
                            border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.3)),
                          ),
                          child: Icon(LucideIcons.play, color: AppTheme.purple500, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )).animate().fadeIn(delay: (600 + i * 120).ms, duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms);
        }),
      ),
    );
  }
}

// ── VIDEO DETAIL BOTTOM SHEET ──
class _VideoDetailSheet extends StatelessWidget {
  final VideoItem video;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const _VideoDetailSheet({required this.video, required this.isBookmarked, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0d0d1a),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    CachedNetworkImage(imageUrl: video.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                      errorWidget: (c, url, error) => Container(height: 180, color: Colors.grey[900]),
                    ),
                    Positioned.fill(child: Container(decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
                    ))),
                    Positioned(bottom: 12, right: 12, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                      child: Text(video.duration, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(video.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              // Meta
              Row(children: [
                Text(video.creator ?? video.category, style: GoogleFonts.outfit(color: AppTheme.purple500, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                if (video.views != null) ...[
                  Icon(LucideIcons.eye, size: 13, color: Colors.white30),
                  const SizedBox(width: 4),
                  Text(video.views!, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ],
                if (video.rating != null) ...[
                  const SizedBox(width: 12),
                  Icon(LucideIcons.star, size: 13, color: const Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text('${video.rating}', style: GoogleFonts.outfit(color: const Color(0xFFFBBF24), fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 20),
              // Action buttons
              Row(children: [
                Expanded(
                  child: _sheetButton('Play Now', LucideIcons.play, AppTheme.purple500, () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          title: video.title,
                          category: video.category,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(child: _sheetButton(isBookmarked ? 'Saved' : 'Save', isBookmarked ? LucideIcons.bookmarkMinus : LucideIcons.bookmark, AppTheme.cyan500, onBookmark)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _sheetButton('Share', LucideIcons.share2, AppTheme.pink500, () { Navigator.pop(context); })),
                const SizedBox(width: 12),
                Expanded(child: _sheetButton('Download', LucideIcons.download, Colors.white54, () { Navigator.pop(context); })),
              ]),
              const SizedBox(height: 20),
              // Progress if applicable
              if (video.progress > 0) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Progress', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                  Text('${video.progress}%', style: GoogleFonts.outfit(color: AppTheme.purple500, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: video.progress / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(AppTheme.purple500.withValues(alpha: 0.8)),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sheetButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
