import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../theme/cached_styles.dart';
import '../widgets/common/post_card.dart';
import 'package:shimmer/shimmer.dart';
import 'messages_view.dart';
import '../widgets/notifications/notification_view.dart';
import 'create_post_screen.dart';
import 'story_viewer_screen.dart';
import 'post_detail_screen.dart';
import '../models/post_model.dart';

// ── Feed Filter Enum ─────────────────────────────────────────────────────────
enum FeedFilter { forYou, trending, following, aiPicks, global }

extension FeedFilterExt on FeedFilter {
  String get label {
    switch (this) {
      case FeedFilter.forYou:     return '✦ For You';
      case FeedFilter.trending:   return '🔥 Trending';
      case FeedFilter.following:  return '👥 Following';
      case FeedFilter.aiPicks:    return '🧠 AI Picks';
      case FeedFilter.global:     return '🌐 Global';
    }
  }
}

// ── Data Models ──────────────────────────────────────────────────────────────
class _Story {
  final String name;
  final String avatarUrl;
  final bool isOwn;
  bool isSeen;
  _Story({
    required this.name,
    required this.avatarUrl,
    this.isOwn = false,
    this.isSeen = false,
  });
}

class _SuggestedUser {
  final String name;
  final String handle;
  final String avatarUrl;
  final String bio;
  final int followers;
  bool isFollowing;
  _SuggestedUser({
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.bio,
    required this.followers,
    this.isFollowing = false,
  });
}

// ── HomeView ─────────────────────────────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  // State
  bool _isLoading = true;
  bool _showNewPostsBanner = false;
  bool _showScrollToTop = false;
  bool _showSearch = false;
  FeedFilter _activeFilter = FeedFilter.forYou;
  String _searchQuery = '';
  final Set<String> _bookmarkedPosts = {};

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _headerGlowController;
  Timer? _newPostsTimer;

  // ── Stories ──────────────────────────────────────────────────────────────
  final List<_Story> _stories = [
    _Story(name: 'Your Story', avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100', isOwn: true),
    _Story(name: 'Aria',  avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
    _Story(name: 'Kai',   avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', isSeen: true),
    _Story(name: 'Nova',  avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100'),
    _Story(name: 'Zeph',  avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100'),
    _Story(name: 'Luna',  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', isSeen: true),
    _Story(name: 'Echo',  avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100'),
  ];

  // ── Suggested Users ──────────────────────────────────────────────────────
  final List<_SuggestedUser> _suggestedUsers = [
    _SuggestedUser(name: 'Lyra Vex',    handle: '@lyravex',    avatarUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100', bio: 'Digital artist & quantum thinker',        followers: 42300),
    _SuggestedUser(name: 'Orion Byte',  handle: '@orionbyte',  avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', bio: 'Building the future, one commit at a time', followers: 18700),
    _SuggestedUser(name: 'Sasha Neon',  handle: '@sashaneon',  avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100', bio: 'AI researcher & space enthusiast 🚀',      followers: 89100),
  ];

  // ── Post Data per Filter ─────────────────────────────────────────────────
  final _forYouPosts = [
    Post(id: 'fy1', userName: 'Nova Chen',     userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', isVerified: true, content: 'Witnessing the future unfold in real-time ✨ The quantum realm is closer than ever.', image: 'https://images.unsplash.com/photo-1589017232573-9d001e5cb52c?w=800', timeAgo: '2h', likes: 2847, comments: 156, shares: 89,  views: 15420),
    Post(id: 'fy2', userName: 'Kai Nakamura',  userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',                  content: 'The intersection of art and technology creates pure magic 🎨⚡',                    image: 'https://images.unsplash.com/photo-1611086615542-635f48ae4656?w=800', timeAgo: '4h', likes: 1923, comments:  92, shares: 64,  views:  9876),
    Post(id: 'fy3', userName: 'Zara Williams', userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200', isVerified: true, content: 'Exploring uncharted territories 🚀 No map, just instinct and pure curiosity.',         image: 'https://images.unsplash.com/photo-1681118143075-5f5a10c9c092?w=800', timeAgo: '6h', likes: 3456, comments: 234, shares: 128, views: 21340),
    Post(id: 'fy4', userName: 'Echo Vibe',     userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200', isVerified: true, content: 'New ambient mix dropping tonight 🎵 Pure quantum energy.',                              image: 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=800', timeAgo: '8h', likes: 1567, comments:  78, shares: 45,  views:  8900),
  ];

  final _trendingPosts = [
    Post(id: 'tr1', userName: 'Vega Prime',  userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', isVerified: true, content: '🔥 This just broke the internet. The new neural interface demo is insane!',              image: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800', timeAgo: '30m', likes: 48200, comments: 3891, shares: 12400, views: 2100000),
    Post(id: 'tr2', userName: 'Hex Storm',   userAvatar: 'https://images.unsplash.com/photo-1546961342-ea5f60b193e5?w=200',                  content: 'Trending: The future of quantum computing just shifted. Thread below 👇',                image: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800', timeAgo: '1h',  likes: 29100, comments: 1560, shares:  8700, views:  980000),
    Post(id: 'tr3', userName: 'Lyra Sol',    userAvatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200', isVerified: true, content: 'How I built an AI that can predict trends 3 days ahead 🤖📈',                           image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800', timeAgo: '2h',  likes: 15700, comments:  892, shares:  4300, views:  560000),
    Post(id: 'tr4', userName: 'Nova Chen',   userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', isVerified: true, content: 'Every major city is about to be re-designed around AI infrastructure 🏙️',              image: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800', timeAgo: '3h',  likes: 11200, comments:  634, shares:  2890, views:  340000),
  ];

  final _followingPosts = [
    Post(id: 'fl1', userName: 'Aria Storm',   userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', isVerified: true, content: 'Good morning from deep space 🌌 Just finished a 6-hour creative session.',               image: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=800', timeAgo: '1h',  likes:  892, comments:  41, shares: 12, views:  4320),
    Post(id: 'fl2', userName: 'Kai Cyber',    userAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',                  content: 'Just shipped the biggest update of my life. Years of work, now live 🚀',                  image: 'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?w=800', timeAgo: '3h',  likes: 2134, comments: 189, shares: 67, views: 11200),
    Post(id: 'fl3', userName: 'Echo Vibe',    userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200', isVerified: true, content: 'New ambient mix dropping tonight 🎵 The vibe is pure quantum energy.',                   image: 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=800', timeAgo: '5h',  likes: 1567, comments:  78, shares: 45, views:  8900),
    Post(id: 'fl4', userName: 'Luna Ray',     userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',                  content: 'Some days you ship code, some days code ships you. Still love it though 💙',             image: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800', timeAgo: '7h',  likes:  678, comments:  34, shares: 18, views:  3200),
  ];

  final _aiPicksPosts = [
    Post(id: 'ai1', userName: 'Neural Node',  userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', isVerified: true, content: '🧠 The singularity graph — fully visualized for the first time.',                        image: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800', timeAgo: '45m', likes: 5670, comments: 312, shares: 198, views: 34500),
    Post(id: 'ai2', userName: 'Quantum Flux', userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',                  content: 'The most beautiful nebula captured with next-gen quantum optics 🌌',                    image: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=800', timeAgo: '2h',  likes: 8920, comments: 445, shares: 267, views: 67000),
    Post(id: 'ai3', userName: 'Zara Williams',userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200', isVerified: true, content: 'Why quantum entanglement will redefine communication forever 🔮',                       image: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800', timeAgo: '4h',  likes: 4123, comments: 234, shares: 145, views: 28900),
    Post(id: 'ai4', userName: 'Vega Prime',   userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', isVerified: true, content: 'AI says you\'d love this: The architecture that powers every recommendation you see 📡',  image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800', timeAgo: '6h',  likes: 7800, comments: 489, shares: 234, views: 55000),
  ];

  final _globalPosts = [
    Post(id: 'gl1', userName: 'Tokyo Tech',   userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200', isVerified: true, content: '🌐 From Tokyo: City lights that look like a circuit board. We are the machine.',         image: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800', timeAgo: '1h',  likes:  7890, comments: 423, shares: 234, views:  89000),
    Post(id: 'gl2', userName: 'Berlin Grid',  userAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',                  content: '🌐 Berlin underground scene meets augmented reality. The future of nightlife.',         image: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800', timeAgo: '3h',  likes:  3456, comments: 178, shares:  89, views:  45600),
    Post(id: 'gl3', userName: 'Dubai Nexus',  userAvatar: 'https://images.unsplash.com/photo-1546961342-ea5f60b193e5?w=200', isVerified: true, content: '🌐 Dubai just opened the world\'s first quantum-powered skyscraper 🏙️',                 image: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800', timeAgo: '5h',  likes: 12300, comments: 891, shares: 567, views: 234000),
    Post(id: 'gl4', userName: 'Seoul AI Lab', userAvatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200', isVerified: true, content: '🌐 Korea\'s new brain-computer interface goes live. The age of telepathy begins 🧠',     image: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800', timeAgo: '8h',  likes:  9800, comments: 567, shares: 342, views: 120000),
  ];

  // ── Computed posts list (filter + search) — cached to avoid recompute ──
  List<Post>? _cachedPosts;
  FeedFilter? _cachedFilter;
  String? _cachedSearchQuery;

  List<Post> get _currentPosts {
    // Return cached result if inputs haven't changed
    if (_cachedPosts != null && _cachedFilter == _activeFilter && _cachedSearchQuery == _searchQuery) {
      return _cachedPosts!;
    }
    late List<Post> base;
    switch (_activeFilter) {
      case FeedFilter.forYou:    base = _forYouPosts;    break;
      case FeedFilter.trending:  base = _trendingPosts;  break;
      case FeedFilter.following: base = _followingPosts; break;
      case FeedFilter.aiPicks:   base = _aiPicksPosts;   break;
      case FeedFilter.global:    base = _globalPosts;    break;
    }
    if (_searchQuery.isEmpty) {
      _cachedPosts = base;
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _cachedPosts = base.where((p) =>
        p.userName.toLowerCase().contains(lowerQuery) ||
        p.content.toLowerCase().contains(lowerQuery),
      ).toList();
    }
    _cachedFilter = _activeFilter;
    _cachedSearchQuery = _searchQuery;
    return _cachedPosts!;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
    _newPostsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showNewPostsBanner = true);
    });
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _headerGlowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _showNewPostsBanner = false; });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pulseController.dispose();
    _headerGlowController.dispose();
    _searchController.dispose();
    _newPostsTimer?.cancel();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D0015), Color(0xFF000000), Color(0xFF000a14), Color(0xFF000000)],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.purple500,
              backgroundColor: const Color(0xFF1A0030),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_showSearch) SliverToBoxAdapter(child: _buildSearchBar()),
                  if (_showNewPostsBanner) SliverToBoxAdapter(child: _buildNewPostsBanner()),
                  SliverToBoxAdapter(child: _buildStoriesRow()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  if (_isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => _buildShimmerCard(), childCount: 3)),
                    )
                  else if (_currentPosts.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final posts = _currentPosts;
                            if (index == posts.length) return _buildLoadMoreIndicator();
                            // Inject suggested users after 1st post
                            if (index == 1 && posts.length > 1) {
                              return Column(children: [
                                _buildPostItem(posts[0], 0),
                                _buildSuggestedUsers(),
                                _buildPostItem(posts[1], 1),
                              ]);
                            }
                            if (index == 0 && posts.length == 1) {
                              return Column(children: [
                                _buildPostItem(posts[0], 0),
                                _buildSuggestedUsers(),
                              ]);
                            }
                            if (index < 2) return const SizedBox.shrink();
                            return _buildPostItem(posts[index], index);
                          },
                          childCount: _currentPosts.length + 1,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // FAB (scroll-to-top or create)
          Positioned(
            bottom: 24,
            right: 20,
            child: _showScrollToTop ? _buildScrollToTopButton() : _buildFloatingCreateButton(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white70, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _headerGlowController,
                  builder: (context, child) {
                    final offset = _headerGlowController.value * 2 - 0.5;
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment(-1.0 + offset, 0),
                        end: Alignment(1.0 + offset, 0),
                        colors: const [Color(0xFFC084FC), Color(0xFF06B6D4), Color(0xFFC084FC)],
                        stops: const [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: child,
                    );
                  },
                  child: Text("Quantum Feed", style: CachedStyles.ryeW700Size18White.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
              Text("AI-curated content stream", style: CachedStyles.outfitW400Size13White38),
            ]),
          ]),
          Row(children: [
            _buildHeaderBtn(LucideIcons.search, AppTheme.purple500, onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            }),
            const SizedBox(width: 8),
            _buildHeaderBtn(LucideIcons.messageSquare, AppTheme.pink500, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesView()));
            }),
            const SizedBox(width: 8),
            _buildHeaderBtn(LucideIcons.bell, AppTheme.cyan500, onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const NotificationView(),
              );
            }),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0, duration: 500.ms);
  }

  Widget _buildHeaderBtn(IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10)],
        ),
        child: Icon(icon, color: color.withValues(alpha: 0.85), size: 18),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.25)),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search posts, people...',
            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
            prefixIcon: Icon(LucideIcons.search, color: AppTheme.purple500.withValues(alpha: 0.6), size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                    child: Icon(LucideIcons.x, color: Colors.white38, size: 16),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0, duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════
  // NEW POSTS BANNER
  // ═══════════════════════════════════════════════════════
  Widget _buildNewPostsBanner() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _scrollToTop();
        setState(() => _showNewPostsBanner = false);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.85), AppTheme.cyan500.withValues(alpha: 0.75)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.arrowUp, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Text('3 new posts • tap to refresh', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showNewPostsBanner = false),
              child: const Icon(LucideIcons.x, color: Colors.white70, size: 14),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════
  // STORIES ROW
  // ═══════════════════════════════════════════════════════
  Widget _buildStoriesRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Stories', style: CachedStyles.outfitW600Size14White60L0_3),
          GestureDetector(
            onTap: () {},
            child: Text('See all', style: CachedStyles.outfitW500Size12White70.copyWith(color: AppTheme.cyan500.withValues(alpha: 0.7))),
          ),
        ]),
      ),
      SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _stories.length,
          itemBuilder: (context, i) {
            final story = _stories[i];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => story.isSeen = true);
                final mockStories = _stories.map((s) => StoryItem(
                  userName: s.name,
                  userAvatar: s.avatarUrl,
                  imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
                  caption: 'Quantum vibes in deep space 🌌 ✨',
                  timeAgo: '2h ago',
                )).toList();
                Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(stories: mockStories, initialIndex: i)));
              },
              child: Container(
                width: 66,
                margin: const EdgeInsets.only(right: 12),
                child: Column(children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: story.isSeen
                          ? null
                          : const LinearGradient(colors: [Color(0xFFC084FC), Color(0xFF22D3EE), Color(0xFFF472B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      color: story.isSeen ? Colors.white.withValues(alpha: 0.1) : null,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: story.isOwn
                        ? Stack(children: [
                            ClipOval(child: CachedNetworkImage(imageUrl: story.avatarUrl, width: 55, height: 55, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppTheme.purple500.withValues(alpha: 0.3)))),
                            Positioned(right: 0, bottom: 0, child: Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(color: AppTheme.purple500, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                              child: const Icon(LucideIcons.plus, color: Colors.white, size: 11),
                            )),
                          ])
                        : ClipOval(child: CachedNetworkImage(imageUrl: story.avatarUrl, width: 55, height: 55, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppTheme.cyan500.withValues(alpha: 0.3)))),
                  ),
                  const SizedBox(height: 6),
                  Text(story.name, style: story.isSeen ? CachedStyles.outfitW500Size11White38 : CachedStyles.outfitW500Size11White70, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ]),
              ),
            );
          },
        ),
      ),
    ]).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════
  // FILTER CHIPS (Functional — actually changes post list)
  // ═══════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: FeedFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _activeFilter = filter; _isLoading = true; });
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) setState(() => _isLoading = false);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.7), AppTheme.cyan500.withValues(alpha: 0.5)]) : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? AppTheme.purple500.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08)),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.25), blurRadius: 12)] : [],
              ),
              child: Text(filter.label, style: isSelected ? CachedStyles.outfitW600Size13White54L0_2.copyWith(color: Colors.white) : CachedStyles.outfitW400Size13White54L0_2),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════
  // SUGGESTED USERS
  // ═══════════════════════════════════════════════════════
  Widget _buildSuggestedUsers() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(LucideIcons.userPlus, color: AppTheme.purple500.withValues(alpha: 0.7), size: 15),
            const SizedBox(width: 8),
            Text('Suggested For You', style: CachedStyles.outfitW600Size14White.copyWith(color: Colors.white70)),
          ]),
          GestureDetector(
            onTap: () {},
            child: Text('See all', style: CachedStyles.outfitBoldSize12White.copyWith(color: AppTheme.cyan500.withValues(alpha: 0.7), fontWeight: FontWeight.normal)),
          ),
        ]),
        const SizedBox(height: 14),
        ..._suggestedUsers.map((user) => _buildSuggestedUserRow(user)),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.05, end: 0, duration: 400.ms);
  }

  Widget _buildSuggestedUserRow(_SuggestedUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        ClipOval(child: CachedNetworkImage(imageUrl: user.avatarUrl, width: 44, height: 44, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: AppTheme.purple500.withValues(alpha: 0.3)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.name, style: CachedStyles.outfitW600Size13White),
          Text('${user.handle} · ${_formatCount(user.followers)} followers', style: CachedStyles.outfitSize11White38),
        ])),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => user.isFollowing = !user.isFollowing);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: user.isFollowing ? null : LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500]),
              color: user.isFollowing ? Colors.white.withValues(alpha: 0.07) : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: user.isFollowing ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
            ),
            child: Text(user.isFollowing ? 'Following' : 'Follow', style: CachedStyles.outfitW600Size12White),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // POST ITEM (wraps PostCard + bookmark + context menu)
  // ═══════════════════════════════════════════════════════
  Widget _buildPostItem(Post post, int index) {
    final isBookmarked = _bookmarkedPosts.contains(post.id);


    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Post with action row overlay
      Stack(children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: GestureDetector(
            onTap: () {
              final model = PostModel(
                id: post.id,
                userId: 'user_1',
                userName: post.userName,
                userAvatar: post.userAvatar,
                isVerified: post.isVerified,
                content: post.content,
                imageUrl: post.image,
                timeAgo: post.timeAgo,
                likes: post.likes,
                commentsCount: post.comments,
                sharesCount: post.shares,
                viewsCount: post.views,
                isLiked: post.isLiked,
              );
              Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: model)));
            },
            child: PostCard(
              post: post,
              onOptionsTap: () => _showPostOptions(post),
            ),
          ),
        ),

        // Bookmark overlay (Top Right)
        Positioned(
          top: 12,
          right: 12,
          child: _buildSavedOverlayBtn(
            isBookmarked: isBookmarked,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isBookmarked) {
                  _bookmarkedPosts.remove(post.id);
                } else {
                  _bookmarkedPosts.add(post.id);
                }
              });
            },
          ),
        ),
      ]),
    ]);
  }

  Widget _buildSavedOverlayBtn({required bool isBookmarked, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 32,
        height: 32,
        decoration: isBookmarked
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan500.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: Image.asset(
          'assets/nav_icons/saved_icon.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }



  Widget _buildOverlayBtn(IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  void _showPostOptions(Post post) {
    HapticFeedback.mediumImpact();
    final isBookmarked = _bookmarkedPosts.contains(post.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0C001E).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.purple500.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.purple500.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppTheme.cyan500.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Grab Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Creator Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.purple500, AppTheme.cyan500],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(post.userAvatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.userName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.checkCircle,
                              size: 14,
                              color: AppTheme.blue500,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${post.userName.toLowerCase().replaceAll(' ', '')} · ${post.timeAgo}',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Action Grid (Save, Copy Link, Share)
            Row(
              children: [
                // Save Quick Action
                Expanded(
                  child: _buildQuickActionCard(
                    isCustomImage: true,
                    customImagePath: 'assets/nav_icons/saved_icon.png',
                    icon: LucideIcons.bookmark,
                    label: isBookmarked ? 'Bookmarked' : 'Save Post',
                    accentColor: isBookmarked ? AppTheme.cyan500 : AppTheme.purple500,
                    isActive: isBookmarked,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isBookmarked) {
                          _bookmarkedPosts.remove(post.id);
                        } else {
                          _bookmarkedPosts.add(post.id);
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1A0035),
                          content: Text(
                            isBookmarked ? 'Post removed from saved' : 'Post saved successfully ✨',
                            style: GoogleFonts.outfit(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Copy Link Quick Action
                Expanded(
                  child: _buildQuickActionCard(
                    icon: LucideIcons.link,
                    label: 'Copy Link',
                    accentColor: AppTheme.cyan500,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(
                        ClipboardData(text: 'https://nexal.app/post/${post.id}'),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF002838),
                          content: Text(
                            'Post link copied to clipboard 🔗',
                            style: GoogleFonts.outfit(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Share Quick Action
                Expanded(
                  child: _buildQuickActionCard(
                    icon: LucideIcons.share2,
                    label: 'Share',
                    accentColor: AppTheme.pink500,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF380020),
                          content: Text(
                            'Shared to your network 🚀',
                            style: GoogleFonts.outfit(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Secondary Action Rows (Mute, Report)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  _buildGlassOptionRow(
                    icon: LucideIcons.userX,
                    label: 'Mute ${post.userName}',
                    subtitle: 'Hide posts from this creator',
                    color: const Color(0xFFF97316),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Muted ${post.userName}'),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  _buildGlassOptionRow(
                    icon: LucideIcons.flag,
                    label: 'Report Post',
                    subtitle: 'Flag inappropriate or spam content',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // Close post options sheet
                      _showReportModal(post); // Open report flow modal
                    },
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
    bool isCustomImage = false,
    String? customImagePath,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.35),
                    accentColor.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: isCustomImage && customImagePath != null
                  ? Image.asset(
                      customImagePath,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportModal(Post post) {
    HapticFeedback.mediumImpact();
    int selectedReasonIndex = 0;
    bool isSubmitted = false;
    final detailsCtrl = TextEditingController();

    final reportReasons = [
      {'icon': LucideIcons.ban, 'title': 'Spam or Deceptive', 'desc': 'Fake content, bot posts, or scam links'},

      {'icon': LucideIcons.alertTriangle, 'title': 'Hate Speech & Bullying', 'desc': 'Harassment, hate speech, or personal attacks'},
      {'icon': LucideIcons.shieldAlert, 'title': 'Explicit or Violent Media', 'desc': 'Nudity, graphic violence, or dangerous acts'},
      {'icon': LucideIcons.cpu, 'title': 'AI Misinformation', 'desc': 'Unlabeled synthetic or misleading AI media'},
      {'icon': LucideIcons.lock, 'title': 'Copyright & Privacy', 'desc': 'Unconsented personal data or stolen media'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D001F).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: isSubmitted
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: Color(0xFF22C55E),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Report Received',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thank you for keeping Nexal safe. Our moderation team will review this post within 24 hours.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Muted ${post.userName}')),
                                );
                              },
                              child: Text(
                                'Mute Creator',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.purple500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Done',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.flag,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Post',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Select the main reason for reporting',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reasons List
                      ...List.generate(reportReasons.length, (idx) {
                        final r = reportReasons[idx];
                        final isSelected = selectedReasonIndex == idx;
                        final icon = r['icon'] as IconData;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedReasonIndex = idx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected ? const Color(0xFFEF4444) : Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['title'] as String,
                                        style: GoogleFonts.outfit(
                                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.87),
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),

                                      Text(
                                        r['desc'] as String,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                  color: isSelected ? const Color(0xFFEF4444) : Colors.white24,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // Optional Details Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: detailsCtrl,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Additional details (optional)...',
                            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setModalState(() => isSubmitted = true);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.flag, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Report',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }


  Widget _buildGlassOptionRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white24,
        size: 16,
      ),
      dense: true,
    );
  }



  // ═══════════════════════════════════════════════════════
  // SHIMMER PLACEHOLDER
  // ═══════════════════════════════════════════════════════
  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 380,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.searchX, color: Colors.white24, size: 48),
        const SizedBox(height: 16),
        Text('No results found', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try a different keyword or filter', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LOAD MORE INDICATOR
  // ═══════════════════════════════════════════════════════
  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.refreshCw, color: AppTheme.purple500.withValues(alpha: 0.6), size: 15),
            const SizedBox(width: 10),
            Text("You're all caught up 🎉", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SCROLL TO TOP BUTTON
  // ═══════════════════════════════════════════════════════
  Widget _buildScrollToTopButton() {
    return GestureDetector(
      onTap: _scrollToTop,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A0030),
            border: Border.all(color: AppTheme.cyan500.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: AppTheme.cyan500.withValues(alpha: 0.15 + _pulseController.value * 0.1), blurRadius: 16, spreadRadius: _pulseController.value * 2)],
          ),
          child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 20),
        ),
      ),
    ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 300.ms, curve: Curves.elasticOut);
  }

  // ═══════════════════════════════════════════════════════
  // FLOATING CREATE BUTTON
  // ═══════════════════════════════════════════════════════
  Widget _buildFloatingCreateButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.2 + _pulseController.value * 0.15), blurRadius: 16 + _pulseController.value * 8, spreadRadius: _pulseController.value * 3)],
        ),
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCreateContentModal();
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.purple500, AppTheme.pink500],
            ),
          ),
          child: const Center(
            child: Icon(LucideIcons.plus, color: Colors.white, size: 26),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 500.ms).scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut);
  }



  // ═══════════════════════════════════════════════════════
  // CREATE CONTENT MODAL (Triggered by + Floating Button)
  // ═══════════════════════════════════════════════════════
  void _showCreateContentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF070412).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            image: AssetImage('assets/normal_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.purple500.withValues(alpha: 0.35),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Header Row
            Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F0B1E), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Content',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '@alex_quantum • Public Broadcast',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Post Composer Bar (Primary Action)
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF14092B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.purple500.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.penTool, color: AppTheme.purple500, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's on your mind?",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.purple500,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.purple500.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        'Post',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3 Hand-Crafted Premium Action Banners
            _buildActionBanner(
              icon: LucideIcons.aperture,
              title: 'Add to Story',
              subtitle: 'Share 24-hour visual update or moment',
              accentColor: AppTheme.cyan500,
              buttonText: 'Create',
              onTap: () {
                Navigator.pop(ctx);
                _showAddStoryModal();
              },
            ),
            const SizedBox(height: 10),

            _buildActionBanner(
              icon: LucideIcons.playCircle,
              title: 'Create Reel',
              subtitle: 'Broadcast short video clip with audio',
              accentColor: AppTheme.pink500,
              buttonText: 'Record',
              onTap: () {
                Navigator.pop(ctx);
                _showCreateReelModal();
              },
            ),
            const SizedBox(height: 10),

            _buildActionBanner(
              icon: LucideIcons.radio,
              title: 'Go Live Stream',
              subtitle: 'Broadcast real-time stream to followers',
              accentColor: const Color(0xFFEF4444),
              buttonText: 'Go Live',
              onTap: () {
                Navigator.pop(ctx);
                _showGoLiveModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0821).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor, width: 1.2),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  // ═══════════════════════════════════════════════════════
  // 1. POST COMPOSER STUDIO (New Post)
  // ═══════════════════════════════════════════════════════
  void _showPostComposerModal() {
    final textCtrl = TextEditingController();
    String? selectedSampleImage;

    final sampleImages = [
      'https://images.unsplash.com/photo-1589017232573-9d001e5cb52c?w=800',
      'https://images.unsplash.com/photo-1611086615542-635f48ae4656?w=800',
      'https://images.unsplash.com/photo-1681118143075-5f5a10c9c092?w=800',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setComposerState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF070412).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage('assets/normal_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.35,
              ),
              border: Border.all(
                color: AppTheme.purple500.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.purple500.withValues(alpha: 0.35),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Alex Quantum',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.checkCircle2, color: AppTheme.cyan500, size: 14),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.purple500.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.globe, color: Colors.white70, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Public Broadcast',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Text Input Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0821).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14.5, height: 1.4),
                    decoration: InputDecoration(
                      hintText: "Share your vision with the realm... #quantum",
                      hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sample Image Selector Grid Preview
                Text('Add Media Visual', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: sampleImages.map((imgUrl) {
                    final isSelected = selectedSampleImage == imgUrl;
                    return GestureDetector(
                      onTap: () {
                        setComposerState(() {
                          selectedSampleImage = isSelected ? null : imgUrl;
                        });
                      },
                      child: Container(
                        height: 60,
                        width: 75,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.purple500 : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(imgUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: isSelected
                            ? Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.purple500.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Quick Action Toolbar
                Row(
                  children: [
                    _buildAttachBtn(LucideIcons.sparkles, 'AI Writer', AppTheme.cyan500, () {
                      setComposerState(() {
                        textCtrl.text = 'Pioneering artificial intelligence & quantum mechanics for the future 🚀 #QuantumRealm';
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildAttachBtn(LucideIcons.hash, 'Hashtags', AppTheme.pink500, () {
                      textCtrl.text = '${textCtrl.text} #FutureVision';
                    }),
                    const SizedBox(width: 8),
                    _buildAttachBtn(LucideIcons.barChart2, 'Poll', AppTheme.purple500, () {
                      textCtrl.text = 'Poll: Which quantum tech will dominate 2026? 1. AI 2. Quantum Computing';
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Publish Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 8,
                    shadowColor: AppTheme.purple500.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    final text = textCtrl.text.trim();
                    if (text.isNotEmpty || selectedSampleImage != null) {
                      HapticFeedback.mediumImpact();
                      final newPost = Post(
                        id: 'user_post_${DateTime.now().millisecondsSinceEpoch}',
                        userName: 'Alex Quantum',
                        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                        isVerified: true,
                        content: text.isEmpty ? 'Sharing new visual vision ✨' : text,
                        image: selectedSampleImage,
                        timeAgo: 'Just now',
                        likes: 1,
                        comments: 0,
                        shares: 0,
                        views: 1,
                        isLiked: true,
                      );

                      setState(() {
                        _forYouPosts.insert(0, newPost);
                      });

                      Navigator.pop(ctx);
                      _scrollToTop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1F0038),
                          content: Text(
                            'Post published to Quantum Feed! 🚀',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Publish to Quantum Feed',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 2. STORY STUDIO MODAL (Add Story)
  // ═══════════════════════════════════════════════════════
  void _showAddStoryModal() {
    final storyTextCtrl = TextEditingController();
    Color selectedBgColor = AppTheme.cyan500;
    String selectedSticker = '✨';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStoryState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF070412).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage('assets/normal_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.35,
              ),
              border: Border.all(
                color: AppTheme.cyan500.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cyan500.withValues(alpha: 0.3),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan500.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.aperture, color: AppTheme.cyan500, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Story Studio',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Story Phone Canvas Preview
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        selectedBgColor.withValues(alpha: 0.8),
                        AppTheme.purple500.withValues(alpha: 0.5),
                        Colors.black,
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: selectedBgColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your Story',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(selectedSticker, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                storyTextCtrl.text.isEmpty ? 'Your Story Message...' : storyTextCtrl.text,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Canvas Background Colors & Stickers
                Row(
                  children: [
                    Text('Color Vibe:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Row(
                      children: [AppTheme.cyan500, AppTheme.purple500, AppTheme.pink500, const Color(0xFF10B981), const Color(0xFFF59E0B)].map((c) {
                        final isSel = selectedBgColor == c;
                        return GestureDetector(
                          onTap: () => setStoryState(() => selectedBgColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stickers Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['✨', '🌌', '🚀', '🔥', '⚡', '💫', '💎', '👑'].map((sticker) {
                      final isSel = selectedSticker == sticker;
                      return GestureDetector(
                        onTap: () => setStoryState(() => selectedSticker = sticker),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.cyan500.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? AppTheme.cyan500 : Colors.white10),
                          ),
                          child: Text(sticker, style: const TextStyle(fontSize: 16)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Caption Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0821).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: TextField(
                    controller: storyTextCtrl,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Type your story message...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setStoryState(() {}),
                  ),
                ),
                const SizedBox(height: 20),

                // Post Story Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 8,
                    shadowColor: AppTheme.cyan500.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _stories.insert(
                        1,
                        _Story(
                          name: 'Your Story',
                          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                          isOwn: false,
                          isSeen: false,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF002A36),
                        content: Text(
                          'Story published to your profile! 📸',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Share to Your Story 📸',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 3. REEL STUDIO MODAL (Create Reel)
  // ═══════════════════════════════════════════════════════
  void _showCreateReelModal() {
    final reelTitleCtrl = TextEditingController();
    String selectedAudio = 'Quantum Beats 🎵';
    String selectedCategory = 'Tech 🚀';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setReelState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF070412).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage('assets/normal_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.35,
              ),
              border: Border.all(
                color: AppTheme.pink500.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pink500.withValues(alpha: 0.3),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.pink500.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.playCircle, color: AppTheme.pink500, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Quantum Reel Studio',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Video Thumbnail Card
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=800'),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),

                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('00:15 HD', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.pink500.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.pink500.withValues(alpha: 0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tech 🚀', 'AI & Future 🤖', 'Design 🎨', 'Gaming 🎮'].map((cat) {
                      final isSel = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setReelState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.pink500.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSel ? AppTheme.pink500 : Colors.white10),
                          ),
                          child: Text(cat, style: GoogleFonts.outfit(color: isSel ? Colors.white : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Audio Track Picker
                Text('Background Sound Track', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Quantum Beats 🎵', 'Deep Space Vibe 🌌', 'Synthwave Pulse ⚡', 'Cyber Ambient 🔮'].map((sound) {
                      final isSel = selectedAudio == sound;
                      return GestureDetector(
                        onTap: () => setReelState(() => selectedAudio = sound),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.pink500.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSel ? AppTheme.pink500 : Colors.white10),
                          ),
                          child: Text(sound, style: GoogleFonts.outfit(color: isSel ? Colors.white : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Reel Title Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0821).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: TextField(
                    controller: reelTitleCtrl,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Reel title & description...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Publish Reel Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pink500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 8,
                    shadowColor: AppTheme.pink500.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final title = reelTitleCtrl.text.trim();
                    final newReelPost = Post(
                      id: 'reel_${DateTime.now().millisecondsSinceEpoch}',
                      userName: 'Alex Quantum',
                      userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      isVerified: true,
                      content: title.isEmpty ? 'New Reel: $selectedAudio 🎬' : title,
                      image: 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=800',
                      isVideo: true,
                      timeAgo: 'Just now',
                      likes: 12,
                      comments: 3,
                      shares: 1,
                      views: 140,
                    );

                    setState(() {
                      _forYouPosts.insert(0, newReelPost);
                    });

                    Navigator.pop(ctx);
                    _scrollToTop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF3B0024),
                        content: Text(
                          'Reel published to Quantum Feed! 🎬',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Post Quantum Reel 🎬',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 4. LIVE STUDIO MODAL (Go Live)
  // ═══════════════════════════════════════════════════════
  void _showGoLiveModal() {
    final streamTitleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF070412).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            image: AssetImage('assets/normal_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              blurRadius: 36,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.radio, color: Color(0xFFEF4444), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Live Broadcast Studio',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera Viewfinder Box
            Container(
              height: 155,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800'),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.5),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.radio, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('LIVE PREVIEW', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),

                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('👁️ 142 Viewers • 60 FPS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stream Controls Bar
            Row(
              children: [
                _buildLiveControlChip(LucideIcons.mic, 'Mic ON', const Color(0xFF22C55E)),
                const SizedBox(width: 8),
                _buildLiveControlChip(LucideIcons.video, 'Cam ON', AppTheme.cyan500),
                const SizedBox(width: 8),
                _buildLiveControlChip(LucideIcons.messageSquare, 'Chat ON', AppTheme.purple500),
              ],
            ),
            const SizedBox(height: 14),

            // Stream Title Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0821).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: streamTitleCtrl,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Stream title (e.g. Quantum Q&A Broadcast 📡)...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Start Live Stream Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 8,
                shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF420000),
                    content: Text(
                      'Live Broadcast Started! 📡 (142 viewers connected)',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              child: Text(
                'Start Live Stream Now 📡',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveControlChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }



  Widget _buildAttachBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {

    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}


