import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../theme/app_theme.dart';
import '../widgets/common/post_card.dart';
import 'package:shimmer/shimmer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  int _selectedFilter = 0;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _headerGlowController;

  final List<String> _filters = [
    '✦ For You',
    '🔥 Trending',
    '👥 Following',
    '🧠 AI Picks',
    '🌐 Global',
  ];

  final List<Map<String, dynamic>> _trendingTopics = [
    {'tag': '#QuantumArt', 'posts': '12.4K', 'color': AppTheme.purple500},
    {'tag': '#NeoTech', 'posts': '8.7K', 'color': AppTheme.cyan500},
    {'tag': '#FutureVisions', 'posts': '6.2K', 'color': AppTheme.pink500},
    {'tag': '#AICreative', 'posts': '15.1K', 'color': AppTheme.blue500},
  ];

  final posts = [
    Post(
      id: '1',
      userName: 'Nova Chen',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      isVerified: true,
      content: 'Witnessing the future unfold in real-time ✨',
      image:
          'https://images.unsplash.com/photo-1589017232573-9d001e5cb52c?w=800',
      timeAgo: '2h',
      likes: 2847,
      comments: 156,
      shares: 89,
      views: 15420,
    ),
    Post(
      id: '2',
      userName: 'Kai Nakamura',
      userAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      content: 'The intersection of art and technology creates magic',
      image:
          'https://images.unsplash.com/photo-1611086615542-635f48ae4656?w=800',
      timeAgo: '4h',
      likes: 1923,
      comments: 92,
      shares: 64,
      views: 9876,
    ),
    Post(
      id: '3',
      userName: 'Zara Williams',
      userAvatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      isVerified: true,
      content: 'Exploring uncharted territories 🚀',
      image:
          'https://images.unsplash.com/photo-1681118143075-5f5a10c9c092?w=800',
      timeAgo: '6h',
      likes: 3456,
      comments: 234,
      shares: 128,
      views: 21340,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _headerGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Subtle gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0015), // Deep purple-black
                    Color(0xFF000000),
                    Color(0xFF000a14), // Deep blue-black hint
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Live Status Bar ──
                SliverToBoxAdapter(child: _buildLiveStatusBar()),

                // ── Filter Chips ──
                SliverToBoxAdapter(child: _buildFilterChips()),

                // ── Trending Topics ──
                SliverToBoxAdapter(child: _buildTrendingSection()),

                // ── Divider ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.purple500.withValues(alpha: 0.3),
                            AppTheme.cyan500.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Feed Posts ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _isLoading
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Shimmer.fromColors(
                                baseColor: Colors.white.withValues(alpha: 0.05),
                                highlightColor: Colors.white.withValues(alpha: 0.1),
                                child: Container(
                                  height: 380,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                ),
                              ),
                            ),
                            childCount: 3,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == posts.length) {
                                return const SizedBox(height: 100);
                              }
                              final isAIPick = index == 0 || index == 2;
                              return _buildEnhancedPostCard(
                                posts[index],
                                index,
                                isAIPick: isAIPick,
                              );
                            },
                            childCount: posts.length + 1,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Floating Action Button ──
          Positioned(
            bottom: 24,
            right: 20,
            child: _buildFloatingCreateButton(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER — Animated title with glow
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with animated glow
                      AnimatedBuilder(
                        animation: _headerGlowController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              final offset = _headerGlowController.value * 2 - 0.5;
                              return LinearGradient(
                                begin: Alignment(-1.0 + offset, 0),
                                end: Alignment(1.0 + offset, 0),
                                colors: const [
                                  Color(0xFFC084FC),
                                  Color(0xFF06B6D4),
                                  Color(0xFFC084FC),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            child: Text(
                              "Quantum Feed",
                              style: GoogleFonts.rye(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "AI-curated content stream",
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Right side actions
          Row(
            children: [
              _buildHeaderAction(LucideIcons.sparkles, AppTheme.purple500),
              const SizedBox(width: 10),
              _buildHeaderAction(LucideIcons.bell, AppTheme.cyan500),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.1, end: 0, duration: 500.ms);
  }

  Widget _buildHeaderAction(IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 20),
    );
  }

  // ═══════════════════════════════════════════════
  // LIVE STATUS BAR — Animated activity indicator
  // ═══════════════════════════════════════════════
  Widget _buildLiveStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(
          BorderSide(color: AppTheme.cyan500.withValues(alpha: 0.1)),
        ),
        color: AppTheme.cyan500.withValues(alpha: 0.04),
        blur: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Pulse dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.3 + _pulseController.value * 0.4),
                          blurRadius: 6 + _pulseController.value * 4,
                          spreadRadius: _pulseController.value * 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                "LIVE",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF22C55E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 16,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "2.4K active • 847 new posts • 12 trending",
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                LucideIcons.activity,
                color: AppTheme.cyan500.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideX(begin: -0.05, end: 0, duration: 400.ms);
  }

  // ═══════════════════════════════════════════════
  // FILTER CHIPS — Glassmorphic scrollable row
  // ═══════════════════════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.purple500.withValues(alpha: 0.6),
                          AppTheme.cyan500.withValues(alpha: 0.4),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.purple500.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.purple500.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms);
  }

  // ═══════════════════════════════════════════════
  // TRENDING SECTION — Horizontal scrollable cards
  // ═══════════════════════════════════════════════
  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.trendingUp,
                    color: AppTheme.pink500.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Trending Now",
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Text(
                "See all",
                style: GoogleFonts.outfit(
                  color: AppTheme.cyan500.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingTopics.length,
            itemBuilder: (context, index) {
              final topic = _trendingTopics[index];
              final color = topic['color'] as Color;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.fromBorderSide(
                    BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  color: color.withValues(alpha: 0.06),
                  blur: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          topic['tag'] as String,
                          style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.flame,
                              size: 12,
                              color: Colors.white30,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${topic['posts']} posts",
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (400 + index * 100).ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0, duration: 400.ms);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ENHANCED POST CARD — with AI badge + animations
  // ═══════════════════════════════════════════════
  Widget _buildEnhancedPostCard(Post post, int index, {bool isAIPick = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Pick badge
        if (isAIPick)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6, left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.purple500.withValues(alpha: 0.25),
                    AppTheme.cyan500.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.purple500.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 12,
                    color: AppTheme.purple500.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "AI picked for you",
                    style: GoogleFonts.outfit(
                      color: AppTheme.purple500.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // The post card itself with gradient accent
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAIPick
                  ? AppTheme.purple500.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Stack(
            children: [
              // Gradient accent line on left
              if (isAIPick)
                Positioned(
                  left: 0,
                  top: 16,
                  bottom: 16,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.purple500.withValues(alpha: 0.6),
                          AppTheme.cyan500.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              PostCard(post: post),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: (500 + index * 150).ms, duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════════
  // FLOATING CREATE BUTTON — Pulsing glow
  // ═══════════════════════════════════════════════
  Widget _buildFloatingCreateButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.purple500
                    .withValues(alpha: 0.2 + _pulseController.value * 0.15),
                blurRadius: 16 + _pulseController.value * 8,
                spreadRadius: _pulseController.value * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          // Create post action
          debugPrint("Create new post");
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.purple500,
                AppTheme.pink500,
              ],
            ),
          ),
          child: const Icon(
            LucideIcons.plus,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 500.ms)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut);
  }
}
