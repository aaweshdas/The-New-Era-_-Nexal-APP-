import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/common/glass_empty_state.dart';
import '../services/aria_config.dart';

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class _TrendingItem {
  final int rank;
  final String topic;
  final String category;
  final int postCount;

  const _TrendingItem({
    required this.rank,
    required this.topic,
    required this.category,
    required this.postCount,
  });
}

class _DiscoveryCard {
  final String tag;
  final Color tagColor;
  final String title;
  final String author;
  final double height;
  final List<Color> gradientColors;

  const _DiscoveryCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.author,
    required this.height,
    required this.gradientColors,
  });
}

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with TickerProviderStateMixin {
  // ─── Controllers ────────────────────────────────────────────────────────
  late AnimationController _searchPulseCtrl;
  late AnimationController _ariaPulseCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isSearchFocused = false;
  int _activeFilter = 0;
  bool _isLoading = false;
  bool _hasError = false;
  String _activeBaseUrl = 'http://localhost:3004';
  Timer? _debounceTimer;

  List<String> _ariaSuggestions = [];
  List<_TrendingItem> _trending = [];
  List<_DiscoveryCard> _discoveryCards = [];
  List<dynamic> _searchResults = [];

  // ─── Design Tokens (matching AI page) ───────────────────────────────────
  static const Color _bg = Color(0xFF020105);
  static const Color _primary = Color(0xFFCC97FF);
  static const Color _primaryDim = Color(0xFF9C48EA);
  static const Color _secondary = Color(0xFFFF67AD);
  static const Color _surfaceContainer = Color(0xFF1C1823);
  static const Color _surfaceContainerHigh = Color(0xFF221D2A);
  static const Color _onSurface = Color(0xFFF6EEFC);
  static const Color _onSurfaceVariant = Color(0xFFAFA8B5);

  // ─── Static Data ─────────────────────────────────────────────────────────
  static const List<String> _filters = [
    'ALL',
    'PEOPLE',
    'PHOTOS',
    'VIDEOS',
    'PLACES',
    'LIVE',
  ];

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(_onSearchChanged);

    _searchPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _ariaPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _focusNode.addListener(() {
      setState(() => _isSearchFocused = _focusNode.hasFocus);
    });

    _fetchInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchPulseCtrl.dispose();
    _ariaPulseCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Net Methods ─────────────────────────────────────────────────────────

  Future<http.Response> _makeGetRequest(String path) async {
    final uri = Uri.parse('$_activeBaseUrl$path');
    return await http.get(uri).timeout(const Duration(seconds: 4));
  }

  Future<bool> _testConnection(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1000));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _determineActiveBaseUrl() async {
    // ── 1. Check if AriaConfig has a custom backend URL (local dev) ──
    try {
      final config = await AriaConfig.load();
      final backendUri = Uri.parse(config.backendUrl);
      // If user has set a non-Render custom host, build the search URL from it
      if (backendUri.host.isNotEmpty && !backendUri.host.contains('onrender.com')) {
        final settingsBaseUrl = 'http://${backendUri.host}:3004';
        if (await _testConnection(settingsBaseUrl)) {
          _activeBaseUrl = settingsBaseUrl;
          debugPrint('[SearchView] Using settings-configured base URL: $_activeBaseUrl');
          return;
        }
      }
    } catch (e) {
      debugPrint('[SearchView] Error checking AriaConfig: $e');
    }

    // ── 2. Try all candidates in order (Render gateway first) ──
    final candidates = [
      'https://nexal-backend.onrender.com', // Render gateway (search routes via /api/*)
      'http://localhost:3004',              // local dev direct
      'http://10.0.2.2:3004',              // Android emulator
      'http://192.168.100.70:3004',         // LAN dev
    ];

    for (final candidate in candidates) {
      if (await _testConnection(candidate)) {
        _activeBaseUrl = candidate;
        debugPrint('[SearchView] Selected working base URL: $_activeBaseUrl');
        return;
      }
    }

    // ── 3. Last resort ──
    _activeBaseUrl = 'https://nexal-backend.onrender.com';
    debugPrint('[SearchView] No connection found. Defaulting to Render gateway.');
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _determineActiveBaseUrl();

    try {
      final responses = await Future.wait([
        _makeGetRequest('/api/suggestions'),
        _makeGetRequest('/api/trending'),
        _makeGetRequest('/api/discovery'),
      ]);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          responses[2].statusCode == 200) {
        final suggestions = List<String>.from(jsonDecode(responses[0].body));
        
        final trendingList = (jsonDecode(responses[1].body) as List).map((e) => _TrendingItem(
          rank: e['rank'] as int,
          topic: e['topic'] as String,
          category: e['category'] as String,
          postCount: e['postCount'] as int,
        )).toList();

        final discoveryList = (jsonDecode(responses[2].body) as List).map((e) {
          final tagColorStr = e['tagColor'] as String;
          final tagColorVal = int.parse(tagColorStr.replaceFirst('0x', ''), radix: 16);
          final gradientColorsList = (e['gradientColors'] as List).map((c) {
            return Color(int.parse((c as String).replaceFirst('0x', ''), radix: 16));
          }).toList();
          return _DiscoveryCard(
            tag: e['tag'] as String,
            tagColor: Color(tagColorVal),
            title: e['title'] as String,
            author: e['author'] as String,
            height: (e['height'] as num).toDouble(),
            gradientColors: gradientColorsList,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _ariaSuggestions = suggestions;
            _trending = trendingList;
            _discoveryCards = discoveryList;
          });
        }
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('[SearchView] Error fetching data: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _performSearch();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = Uri.encodeComponent(_searchCtrl.text.trim());
    final filter = _filters[_activeFilter];

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _makeGetRequest('/api/search?q=$query&filter=$filter');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _searchResults = decoded;
          });
        }
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint('[SearchView] Error performing search: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  List<_TrendingItem> get _filteredTrending {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _trending;
    return _trending.where((item) => item.topic.toLowerCase().contains(query) || item.category.toLowerCase().contains(query)).toList();
  }

  List<_DiscoveryCard> get _filteredDiscovery {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _discoveryCards;
    return _discoveryCards.where((card) => card.title.toLowerCase().contains(query) || card.tag.toLowerCase().contains(query) || card.author.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isFilteringOrSearching = _searchCtrl.text.trim().isNotEmpty || _activeFilter != 0;

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
          // 1. Image Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/search_background.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0x99000000), // 60% black overlay to ensure readability
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          // 2. Main scrollable content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),

                // Search bar
                SliverToBoxAdapter(child: _buildSearchBar()),

                // ARIA Suggestions
                SliverToBoxAdapter(child: _buildAriaSuggestions()),

                // Filter tabs
                SliverToBoxAdapter(child: _buildFilterTabs()),

                // If loading and we have no results yet, show loading shimmer
                if (_isLoading && _searchResults.isEmpty)
                  SliverToBoxAdapter(child: _buildShimmerLoading())
                else if (_hasError)
                  SliverToBoxAdapter(child: _buildErrorState())
                else if (isFilteringOrSearching) ...[
                  // Dynamic Search Results
                  SliverToBoxAdapter(child: _buildSearchResultsHeader()),
                  _buildSearchResultsGrid(),
                ] else ...[
                  // Default/Home exploration view
                  // Trending section
                  SliverToBoxAdapter(child: _buildTrendingSection()),

                  // Discovery header
                  SliverToBoxAdapter(child: _buildDiscoveryHeader()),

                  // Discovery grid
                  _buildDiscoveryGrid(),
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
  // SECTION: HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Premium chevron back button
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFCC97FF).withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.3),

          // Center: EXPLORE label with breathing color gradient animation
          AnimatedBuilder(
            animation: _ariaPulseCtrl,
            builder: (context, child) {
              final t = _ariaPulseCtrl.value;
              final color1 = Color.lerp(const Color(0xFFCC97FF), const Color(0xFFFF67AD), t)!;
              final color2 = Color.lerp(const Color(0xFFFF67AD), const Color(0xFF8CE7FF), t)!;
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: child,
              );
            },
            child: Text(
              'EXPLORE',
              style: GoogleFonts.rye(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          // Right: Avatar with notification dot
          _AvatarWithDot().animate().fadeIn(duration: 400.ms).slideX(begin: 0.3),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: SEARCH BAR
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AnimatedBuilder(
        animation: _searchPulseCtrl,
        builder: (context, child) {
          final glowOpacity = _isSearchFocused
              ? 0.3 + _searchPulseCtrl.value * 0.2
              : 0.0 + _searchPulseCtrl.value * 0.08;
          return Container(
            height: 58,
            decoration: BoxDecoration(
              color: _surfaceContainerHigh,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: glowOpacity),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // Pulsing search icon
                AnimatedBuilder(
                  animation: _searchPulseCtrl,
                  builder: (context, child) => Icon(
                    LucideIcons.search,
                    color: _primary.withValues(
                      alpha: 0.6 + _searchPulseCtrl.value * 0.4,
                    ),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    style: GoogleFonts.outfit(
                      color: _onSurface,
                      fontSize: 15,
                    ),
                    cursorColor: _primary,
                    decoration: InputDecoration(
                      hintText: 'Search the cosmos…',
                      hintStyle: GoogleFonts.outfit(
                        color: _onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                // Mic icon
                Icon(
                  LucideIcons.mic,
                  color: _onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                // AI sparkle icon
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_primary, _secondary],
                  ).createShader(bounds),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 150.ms)
        .slideY(begin: 0.2, curve: Curves.easeOut);
  }

  // ---------------------------------------------------------------------------
  // SECTION: ARIA SUGGESTIONS
  // ---------------------------------------------------------------------------

  Widget _buildAriaSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AnimatedBuilder(
        animation: _ariaPulseCtrl,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primary.withValues(
                  alpha: 0.08 + _ariaPulseCtrl.value * 0.08,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(
                    alpha: 0.04 + _ariaPulseCtrl.value * 0.04,
                  ),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_primary, _secondary],
                      ).createShader(b),
                      child: const Icon(
                        LucideIcons.brain,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ARIA SUGGESTS',
                      style: GoogleFonts.outfit(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Suggestion chips
                 Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ariaSuggestions.asMap().entries.map((e) {
                    return _SuggestionChip(
                      label: e.value,
                      delay: Duration(milliseconds: 300 + e.key * 80),
                      onTap: () {
                        // Strip emoji, e.g. "⚛  Quantum Physics" -> "Quantum Physics"
                        final cleanQuery = e.value.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
                        _searchCtrl.text = cleanQuery;
                        _performSearch();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, curve: Curves.easeOut);
  }

  // ---------------------------------------------------------------------------
  // SECTION: FILTER TABS
  // ---------------------------------------------------------------------------

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final isActive = i == _activeFilter;
            return GestureDetector(
              onTap: () {
                setState(() => _activeFilter = i);
                _performSearch();
              },
              child: AnimatedContainer(
                duration: 250.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [_primary, _primaryDim],
                        )
                      : null,
                  color: isActive ? null : _surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filters[i],
                  style: GoogleFonts.outfit(
                    color: isActive ? const Color(0xFF020105) : _onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 250.ms);
  }

  // ---------------------------------------------------------------------------
  // SECTION: TRENDING
  // ---------------------------------------------------------------------------

  Widget _buildTrendingSection() {
    final items = _filteredTrending;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          _SectionTitle(label: 'TRENDING NOW'),
          const SizedBox(height: 16),
          // Trending list
          ...{
            for (int i = 0; i < items.length; i++)
              _TrendingRow(
                item: items[i],
                delay: Duration(milliseconds: 350 + i * 60),
              ),
          },
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: NEURAL DISCOVERY HEADER
  // ---------------------------------------------------------------------------

  Widget _buildDiscoveryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: _SectionTitle(label: 'NEURAL DISCOVERY'),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: DISCOVERY MASONRY GRID
  // ---------------------------------------------------------------------------

  Widget _buildDiscoveryGrid() {
    final items = _filteredDiscovery;
    
    if (items.isEmpty && _filteredTrending.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassEmptyState(
          icon: LucideIcons.searchX,
          title: 'No results found',
          subtitle: 'We couldn\'t find anything matching "${_searchCtrl.text}". Try a different term.',
          ctaLabel: 'Clear Search',
          onCtaTap: () => _searchCtrl.clear(),
        ),
      );
    }
    
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Manual 2-column layout without external package dependency
    final leftCards = <_DiscoveryCard>[];
    final rightCards = <_DiscoveryCard>[];
    for (int i = 0; i < items.length; i++) {
      if (i.isEven) {
        leftCards.add(items[i]);
      } else {
        rightCards.add(items[i]);
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftCards.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DiscoveryCardWidget(
                      card: e.value,
                      delay: Duration(milliseconds: 400 + e.key * 80),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            // Right column
            Expanded(
              child: Column(
                children: [
                  // Offset right column slightly
                  const SizedBox(height: 40),
                  ...rightCards.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DiscoveryCardWidget(
                        card: e.value,
                        delay: Duration(milliseconds: 460 + e.key * 80),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Result UI Helpers ──────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(3, (index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        color: Colors.white.withValues(alpha: 0.05),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
                      const SizedBox(height: 10),
                      Container(
                        width: 90,
                        height: 10,
                        color: Colors.white.withValues(alpha: 0.05),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildErrorState() {
    return GlassEmptyState(
      icon: LucideIcons.wifiOff,
      title: 'Connection Error',
      subtitle: 'Could not connect to the search service. Make sure the backend is running.',
      ctaLabel: 'Try Again',
      onCtaTap: _fetchInitialData,
    );
  }

  Widget _buildSearchResultsHeader() {
    final count = _searchResults.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SectionTitle(label: 'SEARCH RESULTS'),
          Text(
            '$count items found',
            style: GoogleFonts.outfit(
              color: _onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassEmptyState(
          icon: LucideIcons.searchX,
          title: 'No results found',
          subtitle: 'We couldn\'t find anything matching "${_searchCtrl.text}". Try a different term.',
          ctaLabel: 'Clear Search',
          onCtaTap: () => _searchCtrl.clear(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _searchResults[index] as Map<String, dynamic>;
            return _buildResultCard(item);
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final category = item['category'] as String;

    switch (category) {
      case 'PEOPLE':
        return _buildPeopleCard(item);
      case 'PHOTOS':
        return _buildPhotoCard(item);
      case 'VIDEOS':
        return _buildVideoCard(item);
      case 'PLACES':
        return _buildPlaceCard(item);
      case 'LIVE':
        return _buildLiveCard(item);
      default:
        return _buildDefaultCard(item);
    }
  }

  Widget _buildPeopleCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: 52,
              color: _surfaceContainer,
              child: Image.network(
                item['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _surfaceContainer,
                  child: const Icon(LucideIcons.user, color: _onSurfaceVariant, size: 20),
                ),
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
                  style: GoogleFonts.outfit(
                    color: _onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['tag'] ?? '',
                  style: GoogleFonts.outfit(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['followers'] ?? '0'} followers • ${item['subtitle'] ?? ''}',
                  style: GoogleFonts.outfit(
                    color: _onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary.withValues(alpha: 0.15),
              foregroundColor: _primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _primary.withValues(alpha: 0.3)),
              ),
            ),
            child: Text(
              'Follow',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                item['imageUrl'] ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: _surfaceContainer,
                  child: const Icon(LucideIcons.image, color: _onSurfaceVariant, size: 32),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item['tag'] ?? '',
                    style: GoogleFonts.outfit(
                      color: _secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.outfit(
                        color: _onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'by ${item['author'] ?? ''}',
                      style: GoogleFonts.outfit(
                        color: _onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.heart, color: _secondary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      item['likes'] ?? '0',
                      style: GoogleFonts.outfit(
                        color: _onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                item['imageUrl'] ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: _surfaceContainer,
                  child: const Icon(LucideIcons.video, color: _onSurfaceVariant, size: 32),
                ),
              ),
              Container(
                height: 180,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['duration'] ?? '',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? '',
                        style: GoogleFonts.outfit(
                          color: _onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'by ${item['author'] ?? ''}',
                        style: GoogleFonts.outfit(
                          color: _onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item['views'] ?? '0 views',
                  style: GoogleFonts.outfit(
                    color: _onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: _surfaceContainer,
              child: Image.network(
                item['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _surfaceContainer,
                  child: const Icon(LucideIcons.mapPin, color: _onSurfaceVariant, size: 24),
                ),
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
                  style: GoogleFonts.outfit(
                    color: _onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: _primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      item['distance'] ?? '',
                      style: GoogleFonts.outfit(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['coordinates'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: _onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                item['imageUrl'] ?? '',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: _surfaceContainer,
                  child: const Icon(LucideIcons.tv, color: _onSurfaceVariant, size: 32),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['viewers'] ?? '0 watching',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: GoogleFonts.outfit(
                    color: _onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Stream by ${item['author'] ?? ''}',
                  style: GoogleFonts.outfit(
                    color: _onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        item['title'] ?? '',
        style: GoogleFonts.outfit(color: _onSurface),
      ),
    );
  }
}

// ===========================================================================
// REUSABLE WIDGETS
// ===========================================================================

// ── Avatar With Notification Dot ─────────────────────────────────────────────

class _AvatarWithDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Outer glowing border ring
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCC97FF).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9C48EA), Color(0xFFFF67AD)],
              ),
            ),
            child: const Icon(
              LucideIcons.user,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF34D399),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF020105), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Suggestion Chip ──────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final Duration delay;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.delay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2A38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFCC97FF).withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFF6EEFC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, curve: Curves.easeOut);
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFAFA8B5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFCC97FF).withValues(alpha: 0.3),
                  const Color(0xFFCC97FF).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }
}

// ── Trending Row ─────────────────────────────────────────────────────────────

class _TrendingRow extends StatelessWidget {
  final _TrendingItem item;
  final Duration delay;

  const _TrendingRow({required this.item, required this.delay});

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1823).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${item.rank}',
              style: GoogleFonts.outfit(
                color: const Color(0xFF9C48EA),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Topic + category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.topic,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFF6EEFC),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} · ${_formatCount(item.postCount)} posts',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFAFA8B5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Trending arrow
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFCC97FF), Color(0xFFFF67AD)],
            ).createShader(b),
            child: const Icon(
              LucideIcons.trendingUp,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 450.ms)
        .slideX(begin: -0.1, curve: Curves.easeOut);
  }
}

// ── Discovery Card ────────────────────────────────────────────────────────────

class _DiscoveryCardWidget extends StatelessWidget {
  final _DiscoveryCard card;
  final Duration delay;

  const _DiscoveryCardWidget({required this.card, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: card.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: card.gradientColors,
        ),
        border: Border.all(
          color: const Color(0xFFCC97FF).withValues(alpha: 0.12),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: card.gradientColors.last.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background pattern: subtle orbit circles
            Positioned(
              top: -20,
              right: -20,
              child: _OrbitDecoration(color: card.gradientColors.last),
            ),
            // Content at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: card.tagColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: card.tagColor.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        card.tag,
                        style: GoogleFonts.outfit(
                          color: card.tagColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      card.title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF6EEFC),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Author
                    Text(
                      card.author,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFAFA8B5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }
}

// ── Orbit Decoration ─────────────────────────────────────────────────────────

class _OrbitDecoration extends StatelessWidget {
  final Color color;

  const _OrbitDecoration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(painter: _OrbitPainter(color: color)),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  _OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        size.width * (0.25 + i * 0.2),
        Paint()
          ..color = color.withValues(alpha: 0.08 - i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}
