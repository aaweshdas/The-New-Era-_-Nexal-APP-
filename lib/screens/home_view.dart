import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/cached_styles.dart';
import '../widgets/common/post_card.dart';
import 'package:shimmer/shimmer.dart';
import 'messages_view.dart';
import '../widgets/notifications/notification_view.dart';
// ignore: unused_import
import 'create_post_screen.dart';
import 'story_viewer_screen.dart';
import 'post_detail_screen.dart';
import 'home_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../services/auth_service.dart';
// ignore: unused_import
import '../providers/messages_provider.dart';

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
    // ignore: unused_element_parameter
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
  int _pendingNewPostsCount = 0;
  final Set<String> _bookmarkedPosts = {};

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _headerGlowController;

  final List<Post> _pendingNewPosts = [];
  
  List<_Story> get _stories {
    final cur = AuthService.instance.currentUser;
    final avatar = cur?.avatarUrl.isNotEmpty == true ? cur!.avatarUrl : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';
    return [
      _Story(name: 'Your Story', avatarUrl: avatar, isOwn: true),
    ];
  }

  final List<_SuggestedUser> _suggestedUsers = [];
  final List<Post> _forYouPosts = [];

  /// Converts live PostModel objects from FeedProvider to local Post objects
  List<Post> _postModelsToLocal(List<PostModel> models) {
    return models.map((m) => Post(
      id: m.id,
      userName: m.userName,
      userAvatar: m.userAvatar,
      isVerified: m.isVerified,
      content: m.content,
      image: m.imageUrl,
      timeAgo: m.timeAgo,
      likes: m.likes,
      comments: m.commentsCount,
      shares: m.sharesCount,
      views: m.viewsCount,
      isLiked: m.isLiked,
    )).toList();
  }

  List<Post> get _currentPosts {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final livePosts = _postModelsToLocal(feedProvider.posts);
    if (_searchQuery.isEmpty) return livePosts;
    final lowerQuery = _searchQuery.toLowerCase();
    return livePosts.where((p) =>
      p.userName.toLowerCase().contains(lowerQuery) ||
      p.content.toLowerCase().contains(lowerQuery),
    ).toList();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    Future.microtask(() {
      if (!feedProvider.isLoading) {
        if (mounted) setState(() => _isLoading = false);
      } else {
        feedProvider.addListener(_onFeedLoaded);
      }
    });
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _headerGlowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _scrollController.addListener(_onScroll);
  }

  void _onFeedLoaded() {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (!feedProvider.isLoading && mounted) {
      setState(() => _isLoading = false);
      feedProvider.removeListener(_onFeedLoaded);
    }
  }

  int _lastScrollCheckMs = 0;

  void _onScroll() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastScrollCheckMs < 50) return; // Check at most 20 times per second
    _lastScrollCheckMs = now;

    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  void _injectNewPosts() {
    // Prepend pending posts to the currently-active filter list
    final count = math.min(_pendingNewPostsCount, _pendingNewPosts.length);
    final toAdd = _pendingNewPosts.sublist(0, count);
    setState(() {
      _forYouPosts.insertAll(0, toAdd);
      _pendingNewPostsCount = 0;
      _showNewPostsBanner = false;
    });
    _scrollToTop();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() { _showNewPostsBanner = false; });
    // Pull fresh posts from backend via FeedProvider
    if (mounted) {
      await Provider.of<FeedProvider>(context, listen: false).refreshFeed();
    }
    if (mounted) {
      if (_pendingNewPostsCount > 0) _injectNewPosts();
      setState(() {});
    }
  }

  Future<void> _addOwnStory() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publishing story to Nexal...', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppTheme.purple500,
          ),
        );
      }

      final storyUrl = file.path;
      ApiService.instance.post('/api/posts/stories', {'mediaUrl': storyUrl}).catchError((_) => null);

      if (mounted) {
        setState(() {
          _stories.insert(1, _Story(name: 'Your Story', avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100', isOwn: false, isSeen: false));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story published to Nexal! 🌟', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.cyan500,
          ),
        );
      }
    } catch (e) {
      debugPrint('[HomeView] Add story error: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pulseController.dispose();
    _headerGlowController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
        children: [
          // 1. Lightweight gradient background (no duplicate video player)
          // The parent HomeScreen already runs SmartBackground — creating
          // another one here would double the video decoder & GPU load.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0015),
                    Color(0xFF050510),
                    Color(0xFF000008),
                    Color(0xFF000000),
                  ],
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
                          addAutomaticKeepAlives: true,
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
            child: RepaintBoundary(
              child: _showScrollToTop ? _buildScrollToTopButton() : _buildFloatingCreateButton(),
            ),
          ),
        ],
      ),
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
              onTap: () {
                HapticFeedback.lightImpact();
                if (_showSearch) {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                } else {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                }
              },
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
        _injectNewPosts();
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
            Text('$_pendingNewPostsCount new post${_pendingNewPostsCount != 1 ? 's' : ''} • tap to load', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() { _showNewPostsBanner = false; _pendingNewPostsCount = 0; }),
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
            onTap: () {
              // Show all stories in the full viewer from the first unseen story
              final mockStories = _stories.map((s) => StoryItem(
                userName: s.name,
                userAvatar: s.avatarUrl,
                imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
                caption: 'Quantum vibes in deep space 🌌 ✨',
                timeAgo: '2h ago',
              )).toList();
              Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(stories: mockStories, initialIndex: 0)));
            },
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
                if (story.isOwn) {
                  _addOwnStory();
                  return;
                }
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
                            ClipOval(child: CachedNetworkImage(imageUrl: story.avatarUrl, width: 55, height: 55, fit: BoxFit.cover, memCacheWidth: 110, errorWidget: (ctx, url, err) => Container(color: AppTheme.purple500.withValues(alpha: 0.3)))),
                            Positioned(right: 0, bottom: 0, child: Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(color: AppTheme.purple500, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                              child: const Icon(LucideIcons.plus, color: Colors.white, size: 11),
                            )),
                          ])
                        : ClipOval(child: CachedNetworkImage(imageUrl: story.avatarUrl, width: 55, height: 55, fit: BoxFit.cover, memCacheWidth: 110, errorWidget: (ctx, url, err) => Container(color: AppTheme.cyan500.withValues(alpha: 0.3)))),
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
            onTap: () {
              // Navigate to MessagesView as the suggested users are potential connections
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesView()));
            },
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
        ClipOval(child: CachedNetworkImage(imageUrl: user.avatarUrl, width: 44, height: 44, fit: BoxFit.cover, memCacheWidth: 90, errorWidget: (ctx, url, err) => Container(width: 44, height: 44, color: AppTheme.purple500.withValues(alpha: 0.3)))),
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
    // Use FeedProvider for persisted bookmarks
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final isBookmarked = feedProvider.bookmarkedIds.contains(post.id);


    return RepaintBoundary(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              // Toggle through FeedProvider → persisted in SharedPreferences
              Provider.of<FeedProvider>(context, listen: false).toggleBookmark(post.id);
              setState(() {}); // Rebuild to reflect new state
            },
          ),
        ),
      ]),
    ]));
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



  // ignore: unused_element
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
                      Provider.of<FeedProvider>(context, listen: false).toggleBookmark(post.id);
                      if (mounted) {
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
                      }
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
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Alex Quantum';
    final userHandle = user?.username ?? 'alex_quantum';
    final userAvatar = user?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

    final textCtrl = TextEditingController();
    String selectedAudience = 'Public Broadcast 🌐';
    bool isAiEnhancing = false;
    bool isPhotoAttached = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF090518).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage('assets/normal_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
                border: Border.all(
                  color: AppTheme.purple500.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.purple500.withValues(alpha: 0.4),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
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

                    // User Header Row with Real User Details & Privacy Dropdown Selector
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: CachedNetworkImageProvider(userAvatar),
                              backgroundColor: AppTheme.purple500,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final options = ['Public Broadcast 🌐', 'Followers Only 🔒', 'Close Friends ⭐️', 'AI Assistant 🤖'];
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: const Color(0xFF14092B),
                                    builder: (sheetCtx) => Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: options.map((opt) => ListTile(
                                          title: Text(opt, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                                          trailing: selectedAudience == opt ? const Icon(LucideIcons.check, color: AppTheme.cyan500) : null,
                                          onTap: () {
                                            setModalState(() => selectedAudience = opt);
                                            Navigator.pop(sheetCtx);
                                          },
                                        )).toList(),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '@$userHandle • $selectedAudience',
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.cyan500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.chevronDown, color: AppTheme.cyan500, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    const SizedBox(height: 18),

                    // Interactive Quick Post Composer Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14092B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.purple500.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: textCtrl,
                            maxLines: 3,
                            minLines: 1,
                            onChanged: (_) => setModalState(() {}),
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                          if (isPhotoAttached) ...[
                            const SizedBox(height: 10),
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(
                                      color: Colors.white10,
                                      height: 100,
                                      child: const Icon(LucideIcons.image, color: Colors.white38),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6, right: 6,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => isPhotoAttached = false),
                                    child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), shape: BoxShape.circle), child: const Icon(LucideIcons.x, color: Colors.white, size: 14)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Quick Attach Pills
                              _quickToolChip(
                                icon: LucideIcons.image,
                                label: isPhotoAttached ? 'Photo ✓' : 'Photo',
                                color: AppTheme.cyan500,
                                onTap: () => setModalState(() => isPhotoAttached = !isPhotoAttached),
                              ),
                              const SizedBox(width: 8),
                              _quickToolChip(
                                icon: LucideIcons.sparkles,
                                label: isAiEnhancing ? 'Refining...' : 'AI Refine',
                                color: AppTheme.pink500,
                                onTap: () {
                                  setModalState(() => isAiEnhancing = true);
                                  Future.delayed(const Duration(milliseconds: 600), () {
                                    if (mounted) {
                                      setModalState(() {
                                        isAiEnhancing = false;
                                        if (textCtrl.text.isEmpty) {
                                          textCtrl.text = "Exploring quantum frontiers in AI architecture ✨ #Nexal";
                                        } else {
                                          textCtrl.text = "${textCtrl.text} ✨ #Nexal #AI";
                                        }
                                      });
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _quickToolChip(
                                icon: LucideIcons.hash,
                                label: 'Tags',
                                color: AppTheme.purple500,
                                onTap: () {
                                  setModalState(() {
                                    textCtrl.text = "${textCtrl.text} #Nexal #Cyber";
                                  });
                                },
                              ),
                              const Spacer(),
                              // Working Submit Post Button
                              GestureDetector(
                                onTap: () {
                                  final content = textCtrl.text.trim();
                                  if (content.isEmpty && !isPhotoAttached) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Please write a message or attach media first!', style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    return;
                                  }
                                  // Dispatch new post to FeedProvider
                                  Provider.of<FeedProvider>(context, listen: false).addPost(
                                    PostModel(
                                      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                                      userId: user?.uid ?? 'user_1',
                                      userName: userName,
                                      userAvatar: userAvatar,
                                      content: content.isNotEmpty ? content : 'New photo update ✨',
                                      imageUrl: isPhotoAttached ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600' : null,
                                      timeAgo: 'Just now',
                                      isVerified: true,
                                    ),
                                  );
                                  setState(() {
                                    _forYouPosts.insert(
                                      0,
                                      Post(
                                        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                                        userName: userName,
                                        userAvatar: userAvatar,
                                        content: content.isNotEmpty ? content : 'New photo update ✨',
                                        image: isPhotoAttached ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600' : null,
                                        timeAgo: 'Just now',
                                        likes: 0,
                                        comments: 0,
                                        shares: 0,
                                        views: 1,
                                        isVerified: true,
                                      ),
                                    );
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(LucideIcons.checkCircle2, color: AppTheme.cyan500, size: 20),
                                        const SizedBox(width: 10),
                                        Text('Post published to Nexal Feed! 🚀', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF14092B),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ));
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: textCtrl.text.isNotEmpty || isPhotoAttached ? AppTheme.purple500 : AppTheme.purple500.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.purple500.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Post',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feature-Packed Action Suite Banners (All 5 Fully Interactive)
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
                    const SizedBox(height: 10),

                    // NEW FEATURE: AI Art Studio Generator
                    _buildActionBanner(
                      icon: LucideIcons.wand2,
                      title: 'AI Art Generator',
                      subtitle: 'Create futuristic digital artwork from text',
                      accentColor: const Color(0xFFA855F7),
                      buttonText: 'Generate',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAiArtGeneratorModal();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
  // 5. AI ART STUDIO GENERATOR MODAL
  // ═══════════════════════════════════════════════════════
  void _showAiArtGeneratorModal() {
    final promptCtrl = TextEditingController(text: 'Cyberpunk futuristic metropolis floating in deep space');
    String selectedStyle = 'Cyberpunk 🌃';
    bool isGenerating = false;
    String generatedImageUrl = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setArtState) {
          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              left: 14,
              right: 14,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0B061A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.3),
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
                            color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.wand2, color: Color(0xFFA855F7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI Neural Art Studio',
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

                // Prompt Input Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14092B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: promptCtrl,
                    maxLines: 2,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Describe your artwork prompt...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Style Selector Chips
                Text('Select Art Style', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Cyberpunk 🌃', 'Sci-Fi Neon ⚡', 'Neural Dream 🔮', 'Hyper-Realistic 📸', 'Anime Glow ✨'].map((style) {
                      final isSel = selectedStyle == style;
                      return GestureDetector(
                        onTap: () => setArtState(() => selectedStyle = style),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFA855F7).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSel ? const Color(0xFFA855F7) : Colors.white10),
                          ),
                          child: Text(style, style: GoogleFonts.outfit(color: isSel ? Colors.white : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Live Art Preview Frame
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                    ),
                    child: isGenerating
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFFA855F7)),
                                const SizedBox(height: 12),
                                Text('Synthesizing Neural Art...', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : Image.network(
                            generatedImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Icon(LucideIcons.sparkles, color: Color(0xFFA855F7), size: 40),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons Row: Generate / Publish
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFA855F7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setArtState(() => isGenerating = true);
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (mounted) {
                              setArtState(() {
                                isGenerating = false;
                                generatedImageUrl = 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=800';
                              });
                            }
                          });
                        },
                        child: Text('Re-Generate 🪄', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final user = AuthService.instance.currentUser;
                          final userName = user?.name ?? 'Alex Quantum';
                          final userAvatar = user?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

                          Provider.of<FeedProvider>(context, listen: false).addPost(
                            PostModel(
                              id: 'ai_art_${DateTime.now().millisecondsSinceEpoch}',
                              userId: user?.uid ?? 'user_1',
                              userName: userName,
                              userAvatar: userAvatar,
                              content: 'Generated AI Art [$selectedStyle]: ${promptCtrl.text}',
                              imageUrl: generatedImageUrl,
                              timeAgo: 'Just now',
                              isVerified: true,
                            ),
                          );
                          setState(() {
                            _forYouPosts.insert(
                              0,
                              Post(
                                id: 'ai_art_${DateTime.now().millisecondsSinceEpoch}',
                                userName: userName,
                                userAvatar: userAvatar,
                                content: 'Generated AI Art [$selectedStyle]: ${promptCtrl.text}',
                                image: generatedImageUrl,
                                timeAgo: 'Just now',
                                likes: 0,
                                comments: 0,
                                shares: 0,
                                views: 1,
                                isVerified: true,
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF2C0B4D),
                              content: Text('AI Artwork published to Nexal Feed! 🎨✨', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                        child: Text('Publish Art 🚀', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quickToolChip({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 1. POST COMPOSER STUDIO (New Post)
  // ═══════════════════════════════════════════════════════
  // ignore: unused_element
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


