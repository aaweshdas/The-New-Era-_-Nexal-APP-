import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common/glass_empty_state.dart';
import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with TickerProviderStateMixin {
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
  int  _activeTab      = 0;
  bool _isLoading      = false;
  bool _hasError       = false;
  String _baseUrl      = AppConfig.apiBaseUrl;
  Timer? _debounce;
  final http.Client _client = http.Client();

  List<String>  _suggestions    = [];
  List<String>  _liveSuggestions = [];
  List<dynamic> _latestNews     = [];
  List<dynamic> _searchResults  = [];

  // ─── Design tokens ───────────────────────────────────────────────────────
  static const Color _bg       = Color(0xFF050510);
  static const Color _card     = Color(0xFF111128);
  static const Color _cardHi   = Color(0xFF191932);
  static const Color _purple   = Color(0xFFB07EFF);
  static const Color _purpleD  = Color(0xFF7B2FFF);
  static const Color _pink     = Color(0xFFFF6BAD);
  static const Color _cyan     = Color(0xFF22D3EE);
  static const Color _textPri  = Color(0xFFF1ECFF);
  static const Color _textSec  = Color(0xFF9090B0);
  static const Color _textDim  = Color(0xFF50506A);
  static const Color _border   = Color(0xFF1D1D38);

  // ─── Categories ──────────────────────────────────────────────────────────
  static const _cats = [
    ('WORLD',         LucideIcons.globe,       Color(0xFF22D3EE)),
    ('TECHNOLOGY',    LucideIcons.cpu,          Color(0xFFB07EFF)),
    ('BUSINESS',      LucideIcons.trendingUp,   Color(0xFF10B981)),
    ('SCIENCE',       LucideIcons.beaker,       Color(0xFF60A5FA)),
    ('HEALTH',        LucideIcons.activity,     Color(0xFFFF6BAD)),
    ('SPORTS',        LucideIcons.trophy,       Color(0xFFF59E0B)),
    ('ENTERTAINMENT', LucideIcons.film,         Color(0xFFC084FC)),
  ];

  static const _tabs = ['WEB', 'NEWS'];

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

  // ─── Network ──────────────────────────────────────────────────────────────

  Future<http.Response> _get(String path) =>
      _client.get(Uri.parse('$_baseUrl$path')).timeout(8.seconds);

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
    } catch (_) { if (mounted) setState(() => _hasError = true); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final r = await _get('/api/news?category=${_cats[_selectedCat].$1}');
      if (r.statusCode == 200 && mounted) {
        setState(() => _latestNews = jsonDecode(r.body) as List);
      } else if (mounted) { setState(() => _hasError = true); }
    } catch (_) { if (mounted) setState(() => _hasError = true); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _hasSubmitted = false;
        _liveSuggestions = [];
      });
      return;
    }
    // Fast debounced fetch of autocomplete suggestions as the user types
    _debounce = Timer(150.ms, () => _fetchLiveSuggestions(q));
  }

  Future<void> _fetchLiveSuggestions(String q) async {
    if (q.isEmpty) return;
    // 1. Try search backend suggest route
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

    // 2. Direct Google Autocomplete client fallback if backend is offline/sleeping
    try {
      final fallbackUrl = 'https://suggestqueries.google.com/complete/search?client=chrome&q=${Uri.encodeComponent(q)}';
      final r = await _client.get(Uri.parse(fallbackUrl)).timeout(1500.ms);
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        if (decoded is List && decoded.length > 1 && decoded[1] is List) {
          final list = List<String>.from(decoded[1]);
          if (mounted && _searchCtrl.text.trim() == q && !_hasSubmitted) {
            setState(() => _liveSuggestions = list);
          }
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
    _doSearch();
  }

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
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

    // 1. Try backend search endpoint
    try {
      final r = await _get('/api/search?q=${Uri.encodeComponent(q)}&filter=${_tabs[_activeTab]}');
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _searchResults = jsonDecode(r.body) as List;
        });
        return;
      }
    } catch (_) {}

    // 2. Fallback: Direct Wikipedia Query for Web Search
    if (_activeTab == 0 && mounted) {
      try {
        final wikiUrl = 'https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=${Uri.encodeComponent(q)}&prop=pageimages|extracts&piprop=thumbnail&pithumbsize=600&exintro&explaintext&exsentences=2&format=json&origin=*';
        final r = await _client.get(Uri.parse(wikiUrl)).timeout(4.seconds);
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          if (data != null && data['query'] != null && data['query']['pages'] != null) {
            final pages = Map<String, dynamic>.from(data['query']['pages']).values.toList();
            pages.sort((a, b) => (a['index'] ?? 0) - (b['index'] ?? 0));
            final results = pages.map((page) {
              final cleanSnippet = page['extract'] ?? '';
              final link = 'https://en.wikipedia.org/?curid=${page['pageid']}';
              final imageUrl = page['thumbnail']?.containsKey('source') == true ? page['thumbnail']['source'] : '';
              return {
                'id': 'wiki_${page['pageid']}',
                'category': 'ALL',
                'title': page['title'] ?? '',
                'subtitle': cleanSnippet,
                'tag': '#Wikipedia',
                'author': 'wikipedia.org',
                'imageUrl': imageUrl,
                'coordinates': link,
              };
            }).toList();
            if (mounted && _searchCtrl.text.trim() == q) {
              setState(() {
                _searchResults = results;
                _hasError = false;
              });
              return;
            }
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: Direct Google News RSS Query for News Search
    if (_activeTab == 1 && mounted) {
      try {
        final rssUrl = 'https://news.google.com/rss/search?q=${Uri.encodeComponent(q)}&hl=en-US&gl=US&ceid=US:en';
        final r = await _client.get(Uri.parse(rssUrl)).timeout(4.seconds);
        if (r.statusCode == 200) {
          final xml = r.body;
          final parts = xml.split('<item>');
          final rawItems = parts.skip(1).take(12).toList();
          final results = rawItems.map((part) {
            final titleRaw = _extractTagContent(part, 'title');
            final link = _extractTagContent(part, 'link');
            const sourceName = 'Google News';

            var title = titleRaw.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>'), r'$1').trim();
            title = title.replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&#39;', "'");

            return {
              'id': 'rss_${DateTime.now().microsecondsSinceEpoch}',
              'category': 'NEWS',
              'title': title,
              'subtitle': 'Read the latest story on Google News.',
              'tag': '#googlenews',
              'author': sourceName,
              'imageUrl': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
              'coordinates': link,
              'pubDate': 'Recently'
            };
          }).toList();

          if (mounted && _searchCtrl.text.trim() == q) {
            setState(() {
              _searchResults = results;
              _hasError = false;
            });
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  String _extractTagContent(String xml, String tag) {
    final regex = RegExp('<$tag[^>]*>([\\s\\S]*?)</$tag>', caseSensitive: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/search_background.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Color(0xBB000000), BlendMode.darken),
              ),
            ),
          ),
        ),
        // Ambient glow
        Positioned(
          top: -100, right: -80,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _orbCtrl,
              builder: (context, child) => Transform.rotate(
                angle: _orbCtrl.value * 2 * math.pi,
                child: Container(
                  width: 320, height: 320,
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
        // Content
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),

              // Suggestions
              if (_isSearchFocused && _searchCtrl.text.isEmpty && _suggestions.isNotEmpty)
                SliverToBoxAdapter(child: _buildSuggestions())
              else if (_isSearchFocused && _searchCtrl.text.isNotEmpty && !_hasSubmitted)
                SliverToBoxAdapter(child: _buildLiveSuggestions()),

              if (_isSearchMode) ...[
                SliverToBoxAdapter(child: _buildSearchTabs()),
                if (_isLoading && _searchResults.isEmpty)
                  SliverToBoxAdapter(child: _buildShimmer())
                else if (_hasError)
                  SliverToBoxAdapter(child: _buildError())
                else ...[
                  SliverToBoxAdapter(child: _buildResultsHeader()),
                  _buildResultsList(),
                ],
              ] else ...[
                SliverToBoxAdapter(child: _buildCategoryTabs()),
                if (_isLoading && _latestNews.isEmpty)
                  SliverToBoxAdapter(child: _buildShimmer())
                else if (_hasError)
                  SliverToBoxAdapter(child: _buildError())
                else if (_latestNews.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildHeroSection()),
                  SliverToBoxAdapter(child: _buildSectionLabel('LATEST NEWS')),
                  _buildNewsList(),
                ] else
                  SliverToBoxAdapter(
                    child: GlassEmptyState(
                      icon: LucideIcons.newspaper, title: 'No news',
                      subtitle: 'Could not load news for this category.',
                      ctaLabel: 'Reload', onCtaTap: _fetchNews,
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER  (no avatar, clean) — UNCHANGED
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); },
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _card, shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(LucideIcons.chevronLeft, color: Colors.white70, size: 20),
          ),
        ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.15),

        const SizedBox(width: 14),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                _isSearchMode ? 'SEARCH RESULTS' : 'GLOBAL PULSE',
                style: GoogleFonts.rye(
                  color: Colors.white, fontSize: 19,
                  fontWeight: FontWeight.w700, letterSpacing: 2.5,
                ),
              ),
            ),
            Text(
              _isSearchMode
                  ? '${_searchResults.length} results'
                  : 'Stay informed · Stay ahead',
              style: GoogleFonts.outfit(color: _textDim, fontSize: 11),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms, delay: 60.ms),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH BAR — pill-shaped, icon bubble, no extra buttons
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
                      _purpleD.withValues(alpha: 0.10),
                      _pink.withValues(alpha: 0.04),
                    ])
                  : null,
              color: f ? null : _card.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: f
                    ? _purple.withValues(alpha: 0.5 + 0.12 * p)
                    : _border,
                width: f ? 1.5 : 1,
              ),
              boxShadow: f
                  ? [BoxShadow(
                      color: _purple.withValues(alpha: 0.08 + 0.05 * p),
                      blurRadius: 18, spreadRadius: -2,
                    )]
                  : [],
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _submitSearch(_searchCtrl.text),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: f
                        ? _purple.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.search,
                    color: f ? _purple : _textDim, size: 16),
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
                    hintText: 'Search news, topics, articles…',
                    hintStyle: GoogleFonts.outfit(color: _textDim, fontSize: 14),
                    border: InputBorder.none, isDense: true,
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
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white60, size: 13),
                  ),
                ),
              const SizedBox(width: 14),
            ]),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08);
  }

  // ---------------------------------------------------------------------------
  // AI SUGGESTIONS — horizontal scrollable chips
  // ---------------------------------------------------------------------------

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FFF), Color(0xFFFF6BAD)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Text('AI SUGGESTS', style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 9,
                fontWeight: FontWeight.w800, letterSpacing: 1.5,
              )),
            ]),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _suggestions.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _searchCtrl.text = _suggestions[i].replaceAll(RegExp(r'[^\w\s-]'), '').trim();
                _doSearch();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _purple.withValues(alpha: 0.22)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.search, size: 11,
                    color: _purple.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(_suggestions[i], style: GoogleFonts.outfit(
                    color: _textPri, fontSize: 12, fontWeight: FontWeight.w500,
                  )),
                ]),
              ),
            ).animate(delay: Duration(milliseconds: 40 * i))
                .fadeIn(duration: 300.ms).slideX(begin: 0.08),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06);
  }

  // ---------------------------------------------------------------------------
  // LIVE AUTOCOMPLETE SUGGESTIONS
  // ---------------------------------------------------------------------------

  Widget _buildLiveSuggestions() {
    if (_liveSuggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _liveSuggestions.length,
          separatorBuilder: (context, i) => Divider(color: _border.withValues(alpha: 0.5), height: 1),
          itemBuilder: (context, i) {
            final suggestion = _liveSuggestions[i];
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _searchCtrl.text = suggestion;
                _submitSearch(suggestion);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 14, color: _purple.withValues(alpha: 0.7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: GoogleFonts.outfit(
                          color: _textPri,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(LucideIcons.arrowUpLeft, size: 14, color: _textDim),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05);
  }

  // ---------------------------------------------------------------------------
  // CATEGORY TABS — rounded rectangles
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: _cats.length,
          separatorBuilder: (context, i) => const SizedBox(width: 7),
          itemBuilder: (context, i) {
            final active = i == _selectedCat;
            final cat = _cats[i];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCat = i);
                _fetchNews();
              },
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: active
                      ? LinearGradient(colors: [
                          cat.$3.withValues(alpha: 0.25),
                          cat.$3.withValues(alpha: 0.08),
                        ])
                      : null,
                  color: active ? null : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? cat.$3.withValues(alpha: 0.5)
                        : _border.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cat.$2, size: 13, color: active ? cat.$3 : _textDim),
                  const SizedBox(width: 6),
                  Text(cat.$1, style: GoogleFonts.outfit(
                    color: active ? cat.$3 : _textSec,
                    fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
                ]),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 120.ms);
  }

  // ---------------------------------------------------------------------------
  // HERO SECTION — featured card + 2 side-by-side mini cards
  // ---------------------------------------------------------------------------

  Widget _buildHeroSection() {
    if (_latestNews.isEmpty) return const SizedBox.shrink();
    final featured = _latestNews[0] as Map<String, dynamic>;

    return Column(children: [
      // ── Main featured card ──
      GestureDetector(
        onTap: () => _open(featured['coordinates'] ?? ''),
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [BoxShadow(
              color: _purpleD.withValues(alpha: 0.12),
              blurRadius: 24, offset: const Offset(0, 8),
            )],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(child: _img(featured['imageUrl'] ?? '')),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.92)],
                stops: const [0.25, 1.0],
              ),
            ))),
            Positioned(bottom: 16, left: 16, right: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _tag('TOP STORY'),
                  const SizedBox(width: 8),
                  Text(featured['pubDate'] ?? '',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                ]),
                const SizedBox(height: 8),
                Text(featured['title'] ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800, height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                _source(featured['author'] ?? 'News'),
              ]),
            ),
          ]),
        ),
      ).animate().fadeIn(duration: 450.ms, delay: 150.ms).slideY(begin: 0.05),

      // ── Two mini cards side by side ──
      if (_latestNews.length >= 3)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Row(children: [
            Expanded(child: _miniCard(_latestNews[1] as Map<String, dynamic>)),
            const SizedBox(width: 10),
            Expanded(child: _miniCard(_latestNews[2] as Map<String, dynamic>)),
          ]),
        ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.04),
    ]);
  }

  Widget _miniCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _open(item['coordinates'] ?? ''),
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(child: _img(item['imageUrl'] ?? '')),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
              stops: const [0.2, 1.0],
            ),
          ))),
          Positioned(bottom: 12, left: 12, right: 12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['pubDate'] ?? '',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 4),
              Text(item['title'] ?? '',
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 12.5,
                  fontWeight: FontWeight.w700, height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(item['author'] ?? 'News',
                style: GoogleFonts.outfit(
                  color: _purple, fontSize: 10.5, fontWeight: FontWeight.w600,
                )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEWS LIST (items 3+) — image-left cards with staggered feature
  // ---------------------------------------------------------------------------

  Widget _buildNewsList() {
    final items = _latestNews.skip(3).toList();
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _newsCard(items[i] as Map<String, dynamic>, i)
              .animate()
              .fadeIn(duration: 320.ms, delay: Duration(milliseconds: i * 35))
              .slideY(begin: 0.05),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _newsCard(Map<String, dynamic> item, int idx) {
    final title    = item['title']       ?? '';
    final snippet  = item['subtitle']    ?? '';
    final source   = item['author']      ?? 'News';
    final imageUrl = item['imageUrl']    ?? '';
    final link     = item['coordinates'] ?? '';
    final relTime  = item['pubDate']     ?? '';

    // Every 5th card is full-bleed with image background
    final isFeature = idx % 5 == 1 && imageUrl.isNotEmpty;

    if (isFeature) {
      return GestureDetector(
        onTap: () => _open(link),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12), height: 195,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned.fill(child: _img(imageUrl)),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.92)],
                stops: const [0.3, 1.0],
              ),
            ))),
            Positioned(bottom: 14, left: 14, right: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(source, style: GoogleFonts.outfit(
                    color: _purple, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('·', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  const SizedBox(width: 6),
                  Text(relTime, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                ]),
                const SizedBox(height: 5),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, height: 1.35,
                  )),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(snippet, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                ],
              ]),
            ),
          ]),
        ),
      );
    }

    // ── Standard row card: image LEFT, text right ──
    return GestureDetector(
      onTap: () => _open(link),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image thumbnail on the LEFT
          if (imageUrl.isNotEmpty)
            Container(
              width: 86, height: 86,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _img(imageUrl),
            ),
          // Text content
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(source, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: _purple, fontSize: 10.5, fontWeight: FontWeight.w600))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text('·', style: TextStyle(
                    color: _textDim.withValues(alpha: 0.6), fontSize: 10)),
                ),
                Text(relTime, style: GoogleFonts.outfit(color: _textDim, fontSize: 10.5)),
              ]),
              const SizedBox(height: 5),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: _textPri, fontSize: 13.5,
                  fontWeight: FontWeight.w700, height: 1.35,
                )),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(snippet, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: _textSec, fontSize: 11.5, height: 1.4)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH TABS — segmented control style
  // ---------------------------------------------------------------------------

  Widget _buildSearchTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(children: List.generate(_tabs.length, (i) {
          final active = i == _activeTab;
          return Expanded(child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeTab = i);
              _doSearch();
            },
            child: AnimatedContainer(
              duration: 200.ms,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFFB07EFF)])
                    : null,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(i == 0 ? LucideIcons.globe : LucideIcons.newspaper,
                  size: 13, color: active ? Colors.white : _textSec),
                const SizedBox(width: 7),
                Text(i == 0 ? 'Web' : 'News', style: GoogleFonts.outfit(
                  color: active ? Colors.white : _textSec,
                  fontSize: 13, fontWeight: FontWeight.w700,
                )),
              ])),
            ),
          ));
        })),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(children: [
        _sectionLabel('RESULTS'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purple.withValues(alpha: 0.2)),
          ),
          child: Text('${_searchResults.length} found',
            style: GoogleFonts.outfit(
              color: _purple, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: GlassEmptyState(
          icon: LucideIcons.searchX, title: 'No results',
          subtitle: 'Nothing matched "${_searchCtrl.text}".',
          ctaLabel: 'Clear',
          onCtaTap: () { _searchCtrl.clear(); setState(() => _isSearchMode = false); },
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final item = _searchResults[i] as Map<String, dynamic>;
            return (_activeTab == 1 ? _newsCard(item, i) : _webCard(item, i))
                .animate().fadeIn(duration: 280.ms, delay: Duration(milliseconds: i * 28));
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  // ─── Web result card with numbered index ────────────────────────────────

  Widget _webCard(Map<String, dynamic> item, int index) {
    final title    = item['title']       ?? '';
    final snippet  = item['subtitle']    ?? '';
    final url      = item['coordinates'] ?? '';
    final host     = item['author']      ?? 'web';
    final imageUrl = item['imageUrl']    ?? '';
    final hasImg = imageUrl.isNotEmpty &&
        !imageUrl.contains('photo-1506744038136-46273834b3fb');

    return GestureDetector(
      onTap: () => _open(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Index badge
          Container(
            width: 24, height: 24,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _purple.withValues(alpha: 0.2)),
            ),
            child: Center(child: Text('${index + 1}',
              style: GoogleFonts.outfit(
                color: _purple, fontSize: 11, fontWeight: FontWeight.w700))),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Domain chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _cyan.withValues(alpha: 0.18)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.link2, color: _cyan, size: 9),
                  const SizedBox(width: 4),
                  Text(host, style: GoogleFonts.outfit(
                    color: _cyan, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 6),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: _textPri, fontSize: 14,
                  fontWeight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 4),
              Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: _textSec, fontSize: 12, height: 1.5)),
            ]),
          ),
          if (hasImg) ...[
            const SizedBox(width: 10),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              clipBehavior: Clip.antiAlias,
              child: _img(imageUrl),
            ),
          ],
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------------------------

  Widget _img(String url) {
    if (url.isEmpty) {
      return Container(color: _cardHi,
        child: const Center(child: Icon(LucideIcons.image, color: _textDim, size: 24)));
    }
    return CachedNetworkImage(
      imageUrl: url, fit: BoxFit.cover,
      placeholder: (ctx, u) => Container(color: _cardHi),
      errorWidget: (ctx, u, e) => Container(color: _cardHi,
        child: const Center(child: Icon(LucideIcons.image, color: _textDim, size: 24))),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFF6BAD), Color(0xFFB07EFF)]),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: GoogleFonts.outfit(
      color: Colors.white, fontSize: 9,
      fontWeight: FontWeight.w800, letterSpacing: 1.5)),
  );

  Widget _source(String name) => Row(children: [
    Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Icon(LucideIcons.globe, color: _purple, size: 10),
    ),
    const SizedBox(width: 6),
    Text(name, style: GoogleFonts.outfit(
      color: _purple, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  // ─── Shimmer ──────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(children: [
        Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
        ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: _purple.withValues(alpha: 0.06)),
        ...List.generate(3, (i) => Container(
          height: 90, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Container(
              width: 72, height: 72, margin: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _cardHi, borderRadius: BorderRadius.circular(12)),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: double.infinity,
                  decoration: BoxDecoration(
                    color: _cardHi, borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 10),
                Container(height: 10, width: 100,
                  decoration: BoxDecoration(
                    color: _cardHi, borderRadius: BorderRadius.circular(4))),
              ]),
            )),
          ]),
        ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms,
              delay: Duration(milliseconds: 120 * i),
              color: _purple.withValues(alpha: 0.06))),
      ]),
    );
  }

  Widget _buildError() => GlassEmptyState(
    icon: LucideIcons.wifiOff, title: 'Connection Error',
    subtitle: 'Could not reach the search service.',
    ctaLabel: 'Retry', onCtaTap: _fetchInitialData,
  );

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
    child: _sectionLabel(text),
  );

  Widget _sectionLabel(String text) => Row(children: [
    Text(text, style: GoogleFonts.outfit(
      color: _textDim, fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 3)),
    const SizedBox(width: 10),
    Expanded(child: Container(
      height: 0.5,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [
        _purple.withValues(alpha: 0.3), Colors.transparent,
      ])),
    )),
  ]).animate().fadeIn(duration: 400.ms, delay: 180.ms);
}
