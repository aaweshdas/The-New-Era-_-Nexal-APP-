import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';
import 'home_screen.dart';

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

  final List<VideoItem> _continueWatching = [
    VideoItem(id: 'v1', title: 'Quantum Neural Computing 2.0', category: 'Sci-Fi', imageUrl: 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=800', duration: '14:20', progress: 65, creator: 'Quantum Labs', rating: 4.9, views: '1.2M'),
    VideoItem(id: 'v2', title: 'Deep Space Galaxy Exploration', category: 'Documentary', imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800', duration: '28:15', progress: 30, creator: 'Cosmo Horizon', rating: 4.8, views: '840K'),
  ];
  final List<VideoItem> _trending = [
    VideoItem(id: 'v3', title: 'Metaverse VR World Build', category: 'Gaming', imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800', duration: '19:45', progress: 0, creator: 'Neo Nexus', rating: 4.9, views: '2.4M'),
    VideoItem(id: 'v4', title: 'Cyberpunk Soundscapes Live', category: 'Music', imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800', duration: '45:00', progress: 0, creator: 'Synth Audio', rating: 4.7, views: '512K'),
  ];
  final List<VideoItem> _recommended = [
    VideoItem(id: 'v5', title: 'AI Autonomous Agents Guide', category: 'Technology', imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800', duration: '12:10', progress: 0, creator: 'Aria Tech', rating: 5.0, views: '3.1M'),
  ];

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
        final nowBookmarked = !_bookmarked.contains(v.id);
        setState(() {
          if (nowBookmarked) {
            _bookmarked.add(v.id);
          } else {
            _bookmarked.remove(v.id);
          }
        });
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nowBookmarked ? 'Added to watchlist' : 'Removed from watchlist', style: GoogleFonts.outfit(color: Colors.white)),
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
          _headerIcon(LucideIcons.arrowLeft, () {
            HapticFeedback.lightImpact();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }),
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
          image: CachedNetworkImageProvider('https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800'),
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
                onTap: () => _showVideoDetail(VideoItem(id: 'hero', title: 'Cosmic Origins: The Beginning', category: 'Documentary', imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800', duration: '45m', views: '5.2M', rating: 4.9, creator: 'Nexal Originals')),
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
class _VideoDetailSheet extends StatefulWidget {
  final VideoItem video;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const _VideoDetailSheet({
    required this.video,
    required this.isBookmarked,
    required this.onBookmark,
  });

  @override
  State<_VideoDetailSheet> createState() => _VideoDetailSheetState();
}

class _VideoDetailSheetState extends State<_VideoDetailSheet> {
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isDownloaded = false;
  int _userRating = 5;
  int _likesCount = 1420;
  bool _isLiked = false;

  String _selectedQuality = '1080p HD';
  String _selectedSpeed = '1.0x';
  int _activeTab = 0; // 0: Overview, 1: Comments, 2: Related

  final TextEditingController _commentCtrl = TextEditingController();
  final List<Map<String, String>> _comments = [
    {'user': 'Alex Rivers', 'text': 'Quantum computing logic explained so clearly! 🔥', 'time': '10m ago'},
    {'user': 'Elena Rostova', 'text': 'The rendering speed on this is unbelievable.', 'time': '1h ago'},
    {'user': 'Dr. Marcus Vance', 'text': 'Subscribed! Looking forward to part 3.', 'time': '3h ago'},
  ];

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _startDownload() {
    if (_isDownloading || _isDownloaded) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return false;
      setState(() {
        _downloadProgress += 0.15;
      });
      if (_downloadProgress >= 1.0) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppTheme.cyan500, size: 20),
              const SizedBox(width: 10),
              Text('Video downloaded for offline playback! 📥', style: GoogleFonts.outfit(color: Colors.white)),
            ],
          ),
          backgroundColor: const Color(0xFF14092B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
        return false;
      }
      return true;
    });
  }

  void _showShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F0B1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Share Content', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Broadcast "${widget.video.title}" across networks', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(LucideIcons.copy, 'Copy Link', AppTheme.purple500, () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link copied to clipboard! 📋', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF1a1a2e)));
                }),
                _shareOption(LucideIcons.send, 'Direct Chat', AppTheme.cyan500, () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to direct messages! 💬', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF1a1a2e)));
                }),
                _shareOption(LucideIcons.qrCode, 'QR Code', AppTheme.pink500, () {
                  Navigator.pop(ctx);
                  _showQrCodeDialog();
                }),
                _shareOption(LucideIcons.repeat, 'Repost Feed', const Color(0xFF22C55E), () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reposted to your Nexal Feed! 🚀', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF1a1a2e)));
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14092B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.pink500, width: 1.2)),
        title: Text('Scan & Share Video', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Icon(LucideIcons.qrCode, size: 140, color: Colors.black),
            ),
            const SizedBox(height: 14),
            Text(widget.video.title, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.outfit(color: AppTheme.cyan500, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _postComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'user': 'You',
        'text': text,
        'time': 'Just now',
      });
      _commentCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0B1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF2A1C4D), width: 1.2)),
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

              // Enhanced Thumbnail with Live Play & Specs Badges
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.video.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (c, url, error) => Container(height: 200, color: Colors.grey[900]),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.8)],
                          ),
                        ),
                      ),
                    ),
                    // Center Play Overlay
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(
                                  title: widget.video.title,
                                  category: widget.video.category,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.purple500.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4),
                              ],
                            ),
                            child: const Icon(LucideIcons.play, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                    ),
                    // Top Specs Pills
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.sparkles, color: AppTheme.cyan500, size: 12),
                            const SizedBox(width: 4),
                            Text(_selectedQuality, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // Bottom Duration Badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(widget.video.duration, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(widget.video.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              // Creator Profile Bar with Working Follow Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.purple500,
                      child: Text(
                        (widget.video.creator ?? 'N')[0],
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.video.creator ?? widget.video.category,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: AppTheme.cyan500, size: 14),
                            ],
                          ),
                          Text('1.2M Subscribers', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isFollowing = !_isFollowing);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(_isFollowing ? 'Subscribed to ${widget.video.creator}!' : 'Unsubscribed', style: GoogleFonts.outfit()),
                          backgroundColor: const Color(0xFF1a1a2e),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isFollowing ? Colors.white.withValues(alpha: 0.1) : AppTheme.purple500,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isFollowing ? Colors.white24 : AppTheme.purple500),
                        ),
                        child: Text(
                          _isFollowing ? 'Subscribed ✓' : 'Subscribe',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Interactive 4-Grid Action Buttons (All Fully Functional)
              Row(
                children: [
                  Expanded(
                    child: _actionTile(
                      label: 'Play Now',
                      icon: LucideIcons.play,
                      color: AppTheme.purple500,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              title: widget.video.title,
                              category: widget.video.category,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionTile(
                      label: _isBookmarked ? 'Saved' : 'Save',
                      icon: _isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                      color: AppTheme.cyan500,
                      isActive: _isBookmarked,
                      onTap: () {
                        setState(() => _isBookmarked = !_isBookmarked);
                        widget.onBookmark();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _actionTile(
                      label: 'Share',
                      icon: LucideIcons.share2,
                      color: AppTheme.pink500,
                      onTap: _showShareModal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionTile(
                      label: _isDownloaded ? 'Downloaded' : (_isDownloading ? '${(_downloadProgress * 100).toInt()}%' : 'Download'),
                      icon: _isDownloaded ? LucideIcons.check : (_isDownloading ? LucideIcons.loader2 : LucideIcons.download),
                      color: _isDownloaded ? const Color(0xFF22C55E) : Colors.white70,
                      isActive: _isDownloaded,
                      onTap: _startDownload,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Download Live Animated Bar
              if (_isDownloading) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Downloading 4K Stream...', style: GoogleFonts.outfit(color: AppTheme.cyan500, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${(_downloadProgress * 100).toInt()}% (4.2 MB/s)', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan500),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Interactive Reaction Bar & 5-Star Rating Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                          _likesCount += _isLiked ? 1 : -1;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(LucideIcons.heart, size: 18, color: _isLiked ? Colors.redAccent : Colors.white54),
                          const SizedBox(width: 6),
                          Text('$_likesCount', style: GoogleFonts.outfit(color: _isLiked ? Colors.redAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Star Rating Picker
                    Row(
                      children: List.generate(5, (index) {
                        final starNum = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _userRating = starNum);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Rated $starNum Stars! ⭐', style: GoogleFonts.outfit()),
                              backgroundColor: const Color(0xFF1a1a2e),
                              duration: const Duration(seconds: 1),
                            ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              LucideIcons.star,
                              size: 16,
                              color: starNum <= _userRating ? const Color(0xFFFBBF24) : Colors.white24,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Bar (Overview | Comments | Specs & Quality)
              Row(
                children: [
                  _tabChip('Overview', 0),
                  const SizedBox(width: 8),
                  _tabChip('Comments (${_comments.length})', 1),
                  const SizedBox(width: 8),
                  _tabChip('Playback Specs', 2),
                ],
              ),
              const SizedBox(height: 16),

              // Tab View Contents
              if (_activeTab == 0) ...[
                // Overview Tab
                Text(
                  'Explore deep space rendering, neural computing models, and high-performance quantum algorithms in this comprehensive video guide.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _hashtagChip('#Quantum'),
                    _hashtagChip('#NeuralAI'),
                    _hashtagChip('#NexalStream'),
                    _hashtagChip('#FutureTech'),
                  ],
                ),
              ] else if (_activeTab == 1) ...[
                // Comments Tab with Real Inline Posting!
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a public comment...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _postComment,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.purple500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: _comments.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.cyan500.withValues(alpha: 0.3),
                          child: Text(c['user']![0], style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c['user']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(c['time']!, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(c['text']!, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ] else if (_activeTab == 2) ...[
                // Playback Specs & Settings Tab
                Text('Quality Preset', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['1080p HD', '4K HDR', '720p Auto'].map((q) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(q, style: GoogleFonts.outfit(color: _selectedQuality == q ? Colors.white : Colors.white54, fontSize: 12)),
                      selected: _selectedQuality == q,
                      selectedColor: AppTheme.purple500,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      onSelected: (val) { if (val) setState(() => _selectedQuality = q); },
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 14),
                Text('Speed Control', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['1.0x', '1.25x', '1.5x', '2.0x'].map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s, style: GoogleFonts.outfit(color: _selectedSpeed == s ? Colors.white : Colors.white54, fontSize: 12)),
                      selected: _selectedSpeed == s,
                      selectedColor: AppTheme.cyan500,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      onSelected: (val) { if (val) setState(() => _selectedSpeed = s); },
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : color.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.purple500 : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.purple500 : Colors.white12),
        ),
        child: Text(label, style: GoogleFonts.outfit(color: active ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _hashtagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.purple500.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(tag, style: GoogleFonts.outfit(color: AppTheme.purple500, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
