import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/common/glass_empty_state.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'video_player_screen.dart';
import 'home_screen.dart';

// ---------------------------------------------------------------------------
// MAIN SEARCH VIEW
// ---------------------------------------------------------------------------

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with TickerProviderStateMixin {
  // ─── Controllers ────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PageController _carouselCtrl = PageController();

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isSearchFocused = false;
  bool _isSearchMode   = false;
  bool _hasSubmitted    = false;
  int  _selectedCat    = 0;
  int  _activeTab      = 0; // 0 = USERS, 1 = REELS & VIDEOS, 2 = NEWS & WEB
  bool _isLoading      = false;
  bool _hasError       = false;
  String _baseUrl      = AppConfig.apiBaseUrl;
  Timer? _debounce;
  final http.Client _client = http.Client();

  List<String>  _suggestions     = [];
  List<String>  _liveSuggestions  = [];
  List<dynamic> _latestNews      = [];
  List<dynamic> _searchResults   = [];

  // ─── User Search State ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _userSearchResults = [];
  final Map<String, bool> _followingState = {};

  // ─── Design Tokens ───────────────────────────────────────────────────────
  static const Color _bg       = Color(0xFF050510);
  static const Color _card     = Color(0xFF111128);
  static const Color _purple   = Color(0xFFB07EFF);
  static const Color _purpleD  = Color(0xFF7B2FFF);
  static const Color _pink     = Color(0xFFFF6BAD);
  static const Color _cyan     = Color(0xFF22D3EE);
  static const Color _textPri  = Color(0xFFF1ECFF);
  static const Color _textSec  = Color(0xFF9090B0);
  static const Color _textDim  = Color(0xFF50506A);
  static const Color _border   = Color(0xFF1D1D38);

  // ─── Categories & Tabs ────────────────────────────────────────────────────
  static const _cats = [
    ('ALL',          LucideIcons.sparkles,     Color(0xFF06B6D4)),
    ('REELS',        LucideIcons.play,         Color(0xFFEC4899)),
    ('VIDEOS',       LucideIcons.tv,           Color(0xFFA855F7)),
    ('TRENDING',     LucideIcons.flame,        Color(0xFFF59E0B)),
    ('TECHNOLOGY',   LucideIcons.cpu,          Color(0xFFB07EFF)),
    ('ENTERTAINMENT',LucideIcons.film,         Color(0xFFC084FC)),
  ];

  static const _tabs = ['USERS 👥', 'REELS & VIDEOS 🎬', 'NEWS & WEB 🌐'];

  // ─── Default Sample Media Data ──────────────────────────────────────────
  final List<Map<String, dynamic>> _trendingReels = [
    {
      'id': 'r1',
      'title': 'Exploring Quantum Neural Horizons ✨',
      'creator': 'Aria Storm',
      'handle': '@aria_storm',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
      'views': '248.5K',
      'likes': '42.1K',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-futuristic-robotic-face-animation-41555-large.mp4',
    },
    {
      'id': 'r2',
      'title': 'Raytraced Cyberpunk City 🌆',
      'creator': 'Kai Cyber',
      'handle': '@kai_cyber',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=800',
      'views': '189.2K',
      'likes': '38.4K',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-glowing-digital-network-lines-animation-41558-large.mp4',
    },
    {
      'id': 'r3',
      'title': 'VR Flight 120FPS Ultra Resolution 🎮',
      'creator': 'Luna Ray',
      'handle': '@luna_ray',
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800',
      'views': '95.4K',
      'likes': '18.9K',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-abstract-glowing-neon-lines-41552-large.mp4',
    },
    {
      'id': 'r4',
      'title': 'Synthwave AI Audio Producer 🎵',
      'creator': 'Nova Chen',
      'handle': '@nova_chen',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
      'views': '310.8K',
      'likes': '78.2K',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-digital-animation-of-screens-41550-large.mp4',
    },
  ];

  final List<Map<String, dynamic>> _latestVideos = [
    {
      'id': 'v1',
      'title': 'Next-Gen AI Assistant Deep Dive — Building ARIA 2.0 Engine',
      'creator': 'Aria Tech Lab',
      'handle': '@aria_storm',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1000',
      'duration': '14:28',
      'views': '124K views',
      'timeAgo': '2 hours ago',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-futuristic-robotic-face-animation-41555-large.mp4',
    },
    {
      'id': 'v2',
      'title': 'Unreal Engine 5 vs WebGL Shader Pipeline Architecture 2026',
      'creator': 'Kai Studio',
      'handle': '@kai_cyber',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1000',
      'duration': '22:15',
      'views': '89K views',
      'timeAgo': '5 hours ago',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-glowing-digital-network-lines-animation-41558-large.mp4',
    },
    {
      'id': 'v3',
      'title': 'Full Stack Flutter 3.29 + Supabase Realtime System',
      'creator': 'Max Code',
      'handle': '@max_neon',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      'thumbnail': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1000',
      'duration': '18:40',
      'views': '210K views',
      'timeAgo': '1 day ago',
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-digital-animation-of-screens-41550-large.mp4',
    },
  ];

  // ─── Init ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);

    _pulseCtrl = AnimationController(vsync: this, duration: 1600.ms)
      ..repeat(reverse: true);

    _orbCtrl = AnimationController(vsync: this, duration: 10.seconds)
      ..repeat();

    _focusNode.addListener(() => setState(() => _isSearchFocused = _focusNode.hasFocus));

    _fetchInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _carouselCtrl.dispose();
    _client.close();
    super.dispose();
  }

  // ─── Network & Search ────────────────────────────────────────────────────

  Future<http.Response> _get(String path) {
    final uri = Uri.tryParse('$_baseUrl$path') ?? Uri.parse('http://127.0.0.1:10000$path');
    return _client.get(uri).timeout(8.seconds);
  }

  Future<void> _resolveBaseUrl() async {
    _baseUrl = await AppConfig.resolveGatewayUrl();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });
    await _resolveBaseUrl();
    try {
      final rs = await Future.wait([
        _get('/api/suggestions'),
        _get('/api/news?category=${_cats[_selectedCat].$1}'),
      ]);
      if (rs[0].statusCode == 200 && mounted) {
        setState(() => _suggestions = List<String>.from(jsonDecode(rs[0].body)));
      }
      if (rs[1].statusCode == 200 && mounted) {
        setState(() => _latestNews = jsonDecode(rs[1].body) as List);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [
            'Quantum Neural Mesh 2.0',
            'Raytraced WebGL Engine',
            'Aria Autonomous AI Agent',
            'Cyberpunk Voxel Realm',
            'Decentralized Social Feed',
          ];
          _latestNews = [
            {
              'title': 'Nexal Releases Next-Gen Autonomous AI Engine ARIA',
              'description': 'Real-time neural intelligence and spatial 3D interaction integrated into mobile & web app.',
              'url': 'https://nexal.app',
              'source': 'Nexal Tech Briefing',
              'time': '10 mins ago',
              'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
            },
            {
              'title': 'Unreal WebGL Graphics in Browser Arcade',
              'description': 'Experience zero-latency 3D gaming inside Nexal Voxel & Wordl interactive spaces.',
              'url': 'https://nexal.app',
              'source': 'Cyber Arcade Weekly',
              'time': '1 hour ago',
              'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800',
            },
          ];
          _hasError = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _hasSubmitted = false;
        _liveSuggestions = [];
        _userSearchResults = [];
      });
      return;
    }
    // Fast debounced user search & suggestion lookup
    _debounce = Timer(150.ms, () {
      _fetchLiveSuggestions(q);
      _executeSearch(q);
    });
  }

  Future<void> _fetchLiveSuggestions(String q) async {
    if (q.isEmpty) return;
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/api/suggest?q=${Uri.encodeComponent(q)}')).timeout(1200.ms);
      if (r.statusCode == 200) {
        final list = List<String>.from(jsonDecode(r.body));
        if (mounted && _searchCtrl.text.trim() == q && !_hasSubmitted) {
          setState(() => _liveSuggestions = list);
          return;
        }
      }
    } catch (_) {}
  }

  void _submitSearch(String val) {
    final q = val.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    setState(() {
      _hasSubmitted = true;
      _isSearchMode = true;
    });
    _executeSearch(q);
  }

  Future<void> _executeSearch(String q) async {
    if (q.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _hasSubmitted = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSearchMode = true;
      _isLoading = true;
      _hasError = false;
    });

    // Execute User Search & Content Search concurrently
    await Future.wait([
      _searchUsers(q),
      _searchContent(q),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  /// ── USER SEARCH LOGIC ───────────────────────────────────────────────────
  Future<void> _searchUsers(String query) async {
    final cleanQ = query.trim().replaceAll('@', '').toLowerCase();
    final List<Map<String, dynamic>> results = [];

    // 1. Supabase Profiles query
    try {
      final currentUid = AuthService.instance.currentUser?.uid ?? '';
      final List<dynamic> res = await Supabase.instance.client
          .from('profiles')
          .select('id, name, username, avatar_url, bio, followers_count, is_verified')
          .or('username.ilike.%$cleanQ%,name.ilike.%$cleanQ%')
          .neq('id', currentUid)
          .limit(20);

      if (res.isNotEmpty) {
        for (final u in res) {
          results.add({
            'id': u['id']?.toString() ?? '',
            'name': (u['name'] ?? u['username'] ?? 'Nexal User').toString(),
            'username': (u['username'] ?? 'user').toString().replaceAll('@', ''),
            'avatar': (u['avatar_url'] ?? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200').toString(),
            'bio': (u['bio'] ?? 'Nexal Community Creator ✨').toString(),
            'followers': u['followers_count'] ?? 1420,
            'isVerified': u['is_verified'] ?? true,
          });
        }
      }
    } catch (_) {}

    // 2. Directory fallback matchers
    final sampleUsers = [
      {
        'id': 'u1',
        'name': 'Aria Storm',
        'username': 'aria_storm',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        'bio': 'Exploring quantum dimensions & neural AI ✨ #NexalCreator',
        'followers': 142000,
        'isVerified': true,
      },
      {
        'id': 'u2',
        'name': 'Kai Cyber',
        'username': 'kai_cyber',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        'bio': 'Cyberpunk 3D graphics & WebGL shaders developer 🌆⚡',
        'followers': 98500,
        'isVerified': true,
      },
      {
        'id': 'u3',
        'name': 'Luna Ray',
        'username': 'luna_ray',
        'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        'bio': 'Virtual reality pilot & 120FPS ultra stream creator 🎮✨',
        'followers': 65200,
        'isVerified': false,
      },
      {
        'id': 'u4',
        'name': 'Nova Chen',
        'username': 'nova_chen',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        'bio': 'Digital art & AI generative music producer 🎵🔮',
        'followers': 112000,
        'isVerified': true,
      },
      {
        'id': 'u5',
        'name': 'Max Neon',
        'username': 'max_neon',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        'bio': 'Futuristic UI designer & mobile developer 📱⚡',
        'followers': 43100,
        'isVerified': false,
      },
    ];

    for (final s in sampleUsers) {
      final sName = (s['name'] as String).toLowerCase();
      final sUser = (s['username'] as String).toLowerCase();
      if (cleanQ.isEmpty || sName.contains(cleanQ) || sUser.contains(cleanQ)) {
        if (!results.any((r) => r['username'] == s['username'])) {
          results.add(s);
        }
      }
    }

    if (mounted) {
      setState(() => _userSearchResults = results);
    }
  }

  /// ── CONTENT SEARCH LOGIC ───────────────────────────────────────────────
  Future<void> _searchContent(String q) async {
    try {
      final r = await _get('/api/search?q=${Uri.encodeComponent(q)}');
      if (r.statusCode == 200 && mounted) {
        setState(() => _searchResults = jsonDecode(r.body) as List);
        return;
      }
    } catch (_) {}

    // Fallback Wiki & News search
    try {
      final wikiUrl = 'https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=${Uri.encodeComponent(q)}&prop=pageimages|extracts&piprop=thumbnail&pithumbsize=600&exintro&explaintext&exsentences=2&format=json&origin=*';
      final r = await _client.get(Uri.parse(wikiUrl)).timeout(4.seconds);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data != null && data['query'] != null && data['query']['pages'] != null) {
          final pages = Map<String, dynamic>.from(data['query']['pages']).values.toList();
          final results = pages.map((page) {
            return {
              'id': 'wiki_${page['pageid']}',
              'category': 'ARTICLE',
              'title': page['title'] ?? '',
              'subtitle': page['extract'] ?? '',
              'tag': '#Wikipedia',
              'author': 'wikipedia.org',
              'imageUrl': page['thumbnail']?['source'] ?? 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
              'coordinates': 'https://en.wikipedia.org/?curid=${page['pageid']}',
            };
          }).toList();
          if (mounted) setState(() => _searchResults = results);
        }
      }
    } catch (_) {}
  }

  void _openUrl(String url) async {
    if (url.isEmpty) return;
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
  }

  // ---------------------------------------------------------------------------
  // BUILD SCREEN
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/backgrounds/search_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color(0xBB000000), BlendMode.darken),
                ),
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -100,
            right: -80,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _orbCtrl,
                builder: (context, child) => Transform.rotate(
                  angle: _orbCtrl.value * 2 * math.pi,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _purpleD.withValues(alpha: 0.14),
                        _pink.withValues(alpha: 0.04),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Scroll View
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Live Suggestions overlay while typing
                if (_isSearchFocused && _searchCtrl.text.isEmpty && _suggestions.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSuggestions())
                else if (_isSearchFocused && _searchCtrl.text.isNotEmpty && !_hasSubmitted)
                  SliverToBoxAdapter(child: _buildLiveSuggestions()),

                // SEARCH MODE (When user types query or searches)
                if (_isSearchMode) ...[
                  SliverToBoxAdapter(child: _buildSearchTabs()),
                  if (_isLoading && _userSearchResults.isEmpty && _searchResults.isEmpty)
                    SliverToBoxAdapter(child: _buildShimmer())
                  else if (_hasError && _userSearchResults.isEmpty && _searchResults.isEmpty)
                    SliverToBoxAdapter(child: _buildError())
                  else if (_activeTab == 0)
                    _buildUserResultsSliver()
                  else if (_activeTab == 1)
                    _buildMediaResultsSliver()
                  else
                    _buildWebResultsSliver(),
                ]
                // DEFAULT NORMAL VIEW (Shows Latest Videos, Reels & Trends)
                else ...[
                  SliverToBoxAdapter(child: _buildCategoryTabs()),
                  SliverToBoxAdapter(child: _buildTrendingReelsSection()),
                  SliverToBoxAdapter(child: _buildLatestVideosSection()),
                  SliverToBoxAdapter(child: _buildSectionLabel('LATEST DISCOVERIES & ARTICLES')),
                  _buildNewsList(),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 20),
            ),
          ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.15),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final t = _pulseCtrl.value;
                    return ShaderMask(
                      shaderCallback: (b) => LinearGradient(colors: [
                        Color.lerp(_purple, _cyan, t)!,
                        Color.lerp(_cyan, _pink, t)!,
                      ]).createShader(b),
                      child: child,
                    );
                  },
                  child: Text(
                    _isSearchMode ? 'DISCOVER & SEARCH' : 'EXPLORE & REELS',
                    style: GoogleFonts.rye(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                Text(
                  _isSearchMode
                      ? 'Search users by @username or explore media'
                      : 'Trending Reels · Latest HD Videos · Global Pulse',
                  style: GoogleFonts.outfit(color: _textDim, fontSize: 11),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 60.ms),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH BAR
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final f = _isSearchFocused;
          final p = _pulseCtrl.value;
          return Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: f
                  ? LinearGradient(colors: [
                      _purpleD.withValues(alpha: 0.12),
                      _pink.withValues(alpha: 0.05),
                    ])
                  : null,
              color: f ? null : _card.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: f ? _purple.withValues(alpha: 0.6 + 0.1 * p) : _border,
                width: f ? 1.5 : 1,
              ),
              boxShadow: f
                  ? [
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.1),
                        blurRadius: 18,
                        spreadRadius: -2,
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _submitSearch(_searchCtrl.text),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: f ? _purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.search, color: f ? _purple : _textDim, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    style: GoogleFonts.outfit(color: _textPri, fontSize: 14.5),
                    cursorColor: _purple,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) => _submitSearch(val),
                    decoration: InputDecoration(
                      hintText: 'Search users (@username), videos, reels…',
                      hintStyle: GoogleFonts.outfit(color: _textDim, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchCtrl.clear();
                      setState(() {
                        _isSearchMode = false;
                        _hasSubmitted = false;
                        _liveSuggestions = [];
                        _userSearchResults = [];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white60, size: 14),
                    ),
                  ),
                const SizedBox(width: 14),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08);
  }

  // ---------------------------------------------------------------------------
  // SUGGESTIONS
  // ---------------------------------------------------------------------------

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: _purple, size: 14),
              const SizedBox(width: 6),
              Text(
                'TRENDING SEARCHES',
                style: GoogleFonts.outfit(color: _textSec, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final item = _suggestions[index];
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = item;
                  _submitSearch(item);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: _purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.trendingUp, color: _cyan, size: 12),
                      const SizedBox(width: 6),
                      Text(item, style: GoogleFonts.outfit(color: _textPri, fontSize: 12.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSuggestions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: _liveSuggestions.take(5).map((item) {
          return ListTile(
            dense: true,
            leading: const Icon(LucideIcons.search, color: _textDim, size: 14),
            title: Text(item, style: GoogleFonts.outfit(color: _textPri, fontSize: 13.5)),
            onTap: () {
              _searchCtrl.text = item;
              _submitSearch(item);
            },
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY TABS (Default View)
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _cats.length,
        itemBuilder: (context, index) {
          final cat = _cats[index];
          final sel = _selectedCat == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCat = index);
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? cat.$3.withValues(alpha: 0.2) : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? cat.$3 : _border),
              ),
              child: Row(
                children: [
                  Icon(cat.$2, color: sel ? cat.$3 : _textSec, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    cat.$1,
                    style: GoogleFonts.outfit(
                      color: sel ? Colors.white : _textSec,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH TABS (User mode vs Video mode vs Web mode)
  // ---------------------------------------------------------------------------

  Widget _buildSearchTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      height: 42,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(_tabs.length, (idx) {
          final sel = _activeTab == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeTab = idx);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(colors: [_purpleD, _pink])
                      : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _tabs[idx],
                    style: GoogleFonts.outfit(
                      color: sel ? Colors.white : _textDim,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEFAULT VIEW: TRENDING REELS CAROUSEL
  // ---------------------------------------------------------------------------

  Widget _buildTrendingReelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.flame, color: _pink, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'TRENDING REELS',
                    style: GoogleFonts.rye(color: Colors.white, fontSize: 15, letterSpacing: 1.5),
                  ),
                ],
              ),
              Text('Swipe for more →', style: GoogleFonts.outfit(color: _cyan, fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _trendingReels.length,
            itemBuilder: (context, index) {
              final reel = _trendingReels[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => VideoPlayerScreen(
                        title: reel['title'],
                        category: 'REELS',
                        videoUrl: reel['videoUrl'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _purple.withValues(alpha: 0.3)),
                    image: DecorationImage(
                      image: NetworkImage(reel['thumbnail']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play Icon Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 12),
                        ),
                      ),
                      // Reel Title & Creator Handle
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 9,
                                  backgroundImage: NetworkImage(reel['avatar']),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reel['handle'],
                                    style: GoogleFonts.outfit(color: _cyan, fontSize: 10, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reel['title'],
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.heart, color: _pink, size: 10),
                                const SizedBox(width: 3),
                                Text(reel['likes'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DEFAULT VIEW: LATEST HD VIDEOS FEED
  // ---------------------------------------------------------------------------

  Widget _buildLatestVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Row(
            children: [
              const Icon(LucideIcons.tv, color: _cyan, size: 18),
              const SizedBox(width: 6),
              Text(
                'LATEST HD VIDEOS',
                style: GoogleFonts.rye(color: Colors.white, fontSize: 15, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: _latestVideos.length,
          itemBuilder: (context, index) {
            final video = _latestVideos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => VideoPlayerScreen(
                      title: video['title'],
                      category: 'HD VIDEO',
                      videoUrl: video['videoUrl'],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Thumbnail with Duration Badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              video['thumbnail'],
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => Container(
                                color: const Color(0xFF1E1E2E),
                                child: const Center(
                                  child: Icon(LucideIcons.film, color: Colors.white38),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Dark Overlay Play Button
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.2),
                            child: const Center(
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0x99000000),
                                child: Icon(LucideIcons.play, color: _cyan, size: 24),
                              ),
                            ),
                          ),
                        ),
                        // Duration Badge
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              video['duration'],
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Video Info Bar
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(video['avatar']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['title'],
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(video['creator'], style: GoogleFonts.outfit(color: _textSec, fontSize: 11.5)),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.checkCircle, color: _cyan, size: 12),
                                    const SizedBox(width: 8),
                                    Text('· ${video['views']}', style: GoogleFonts.outfit(color: _textDim, fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // USER SEARCH RESULTS SLIVER (When user searches for usernames/handles)
  // ---------------------------------------------------------------------------

  Widget _buildUserResultsSliver() {
    if (_userSearchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassEmptyState(
          icon: LucideIcons.userX,
          title: 'No users found',
          subtitle: 'Try searching for "@aria_storm" or "Kai"',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = _userSearchResults[index];
            final uid = user['id'] ?? '';
            final isFollowing = _followingState[uid] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purple.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  // Avatar with Active Indicator
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user['avatar']),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // User Handle & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user['name'],
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (user['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.checkCircle, color: _cyan, size: 13),
                            ],
                          ],
                        ),
                        Text(
                          '@${user['username']}',
                          style: GoogleFonts.outfit(color: _purple, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user['bio'],
                          style: GoogleFonts.outfit(color: _textSec, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Follow / Following Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _followingState[uid] = !isFollowing;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            !isFollowing ? 'Following @${user['username']}! 🌟' : 'Unfollowed @${user['username']}',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: !isFollowing ? const Color(0xFF00E5FF) : Colors.orange,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: isFollowing
                            ? null
                            : const LinearGradient(colors: [_purpleD, _pink]),
                        color: isFollowing ? Colors.white.withValues(alpha: 0.1) : null,
                        borderRadius: BorderRadius.circular(18),
                        border: isFollowing ? Border.all(color: Colors.white30) : null,
                      ),
                      child: Text(
                        isFollowing ? 'Following ✓' : 'Follow',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _userSearchResults.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MEDIA RESULTS SLIVER (Reels & Videos search result grid)
  // ---------------------------------------------------------------------------

  Widget _buildMediaResultsSliver() {
    final allMedia = [..._trendingReels, ..._latestVideos];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = allMedia[index % allMedia.length];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => VideoPlayerScreen(
                      title: item['title'],
                      category: 'SEARCH RESULT',
                      videoUrl: item['videoUrl'] ?? 'https://assets.mixkit.co/videos/preview/mixkit-futuristic-robotic-face-animation-41555-large.mp4',
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  image: DecorationImage(
                    image: NetworkImage(item['thumbnail']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0x99000000),
                        child: Icon(LucideIcons.play, color: _cyan, size: 20),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Text(
                        item['title'],
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: allMedia.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEB RESULTS SLIVER (Wikipedia / Web Search Results)
  // ---------------------------------------------------------------------------

  Widget _buildWebResultsSliver() {
    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassEmptyState(
          icon: LucideIcons.searchX,
          title: 'No web results',
          subtitle: 'Try searching for topics like "AI", "Quantum", "Cyberpunk"',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _searchResults[index];
            return GestureDetector(
              onTap: () => _openUrl(item['coordinates'] ?? ''),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['imageUrl'] != null && (item['imageUrl'] as String).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item['imageUrl'],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            width: 70,
                            height: 70,
                            color: const Color(0xFF1E1E2E),
                            child: const Icon(LucideIcons.newspaper, color: Colors.white38, size: 24),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _purpleD.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.globe, color: _cyan, size: 28),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['subtitle'] ?? '',
                            style: GoogleFonts.outfit(color: _textSec, fontSize: 11.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['tag'] ?? '#Web',
                            style: GoogleFonts.outfit(color: _cyan, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS: SECTION LABEL, SHIMMER & NEWS LIST
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Text(
        label,
        style: GoogleFonts.rye(color: _textSec, fontSize: 13, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildNewsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _latestNews[index % _latestNews.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item['imageUrl'] ?? 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=200',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF1E1E2E),
                        child: const Icon(LucideIcons.image, color: Colors.white38, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? '',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['tag'] ?? '#Trending',
                          style: GoogleFonts.outfit(color: _pink, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _latestNews.isEmpty ? 0 : _latestNews.length,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: const Center(
        child: CircularProgressIndicator(color: _purple),
      ),
    );
  }

  Widget _buildError() {
    return GlassEmptyState(
      icon: LucideIcons.alertCircle,
      title: 'Search connection issue',
      subtitle: 'Unable to connect to search network. Tap retry below.',
      ctaLabel: 'Retry Search',
      onCtaTap: () => _executeSearch(_searchCtrl.text),
    );
  }
}
