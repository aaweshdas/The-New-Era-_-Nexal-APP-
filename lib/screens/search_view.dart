import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/common/glass_empty_state.dart';

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
  late AnimationController _nebulaCtrl;
  late AnimationController _searchPulseCtrl;
  late AnimationController _ariaPulseCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isSearchFocused = false;
  int _activeFilter = 0;

  // ─── Design Tokens (matching AI page) ───────────────────────────────────
  static const Color _bg = Color(0xFF020105);
  static const Color _primary = Color(0xFFCC97FF);
  static const Color _primaryDim = Color(0xFF9C48EA);
  static const Color _secondary = Color(0xFFFF67AD);
  static const Color _tertiary = Color(0xFF8CE7FF);
  static const Color _surfaceContainer = Color(0xFF1C1823);
  static const Color _surfaceContainerHigh = Color(0xFF221D2A);
  static const Color _surfaceBright = Color(0xFF2F2A38);
  static const Color _onSurface = Color(0xFFF6EEFC);
  static const Color _onSurfaceVariant = Color(0xFFAFA8B5);
  static const Color _outlineVariant = Color(0xFF4B4651);

  // ─── Static Data ─────────────────────────────────────────────────────────
  static const List<String> _filters = [
    'ALL',
    'PEOPLE',
    'PHOTOS',
    'VIDEOS',
    'PLACES',
    'LIVE',
  ];

  static const List<String> _ariaSuggestions = [
    '⚛  Quantum Physics',
    '🎨  Neural Art',
    '🚀  Space Exploration',
    '🧬  Bio-Hacking',
  ];

  static const List<_TrendingItem> _trending = [
    _TrendingItem(
      rank: 1,
      topic: 'Dyson Sphere Architecture',
      category: 'Technology',
      postCount: 48200,
    ),
    _TrendingItem(
      rank: 2,
      topic: 'Neural Interface v4',
      category: 'AI & Tech',
      postCount: 31700,
    ),
    _TrendingItem(
      rank: 3,
      topic: 'Digital Consciousness',
      category: 'Philosophy',
      postCount: 27500,
    ),
    _TrendingItem(
      rank: 4,
      topic: 'Exoplanet Colonies',
      category: 'Space',
      postCount: 19900,
    ),
    _TrendingItem(
      rank: 5,
      topic: 'Quantum Entanglement',
      category: 'Science',
      postCount: 15400,
    ),
  ];

  static final List<_DiscoveryCard> _discoveryCards = [
    _DiscoveryCard(
      tag: '#CyberPunk',
      tagColor: const Color(0xFF8CE7FF),
      title: 'Neon Dystopia Series',
      author: '@void_walker',
      height: 200,
      gradientColors: [
        const Color(0xFF0D0D2B),
        const Color(0xFF1A0533),
        const Color(0xFF06B6D4),
      ],
    ),
    _DiscoveryCard(
      tag: '#AIArt',
      tagColor: const Color(0xFFFF67AD),
      title: 'Machine Dreams',
      author: '@aria.mind',
      height: 250,
      gradientColors: [
        const Color(0xFF1A0820),
        const Color(0xFF3D1050),
        const Color(0xFFFF67AD),
      ],
    ),
    _DiscoveryCard(
      tag: '#SpaceX',
      tagColor: const Color(0xFFCC97FF),
      title: 'Mars at Dawn',
      author: '@stellar_eye',
      height: 170,
      gradientColors: [
        const Color(0xFF0A0516),
        const Color(0xFF2A1060),
        const Color(0xFF9C48EA),
      ],
    ),
    _DiscoveryCard(
      tag: '#FutureFreq',
      tagColor: const Color(0xFFF59E0B),
      title: 'Temporal Echoes',
      author: '@chrono_nexus',
      height: 220,
      gradientColors: [
        const Color(0xFF150B00),
        const Color(0xFF3D2200),
        const Color(0xFFF59E0B),
      ],
    ),
    _DiscoveryCard(
      tag: '#BioHack',
      tagColor: const Color(0xFF34D399),
      title: 'Hybrid Organisms',
      author: '@gen_splice',
      height: 190,
      gradientColors: [
        const Color(0xFF001A10),
        const Color(0xFF003D25),
        const Color(0xFF34D399),
      ],
    ),
    _DiscoveryCard(
      tag: '#QuantumArt',
      tagColor: const Color(0xFFFF67AD),
      title: 'Infinite Loop',
      author: '@quanta_kai',
      height: 240,
      gradientColors: [
        const Color(0xFF1A0820),
        const Color(0xFF400D4A),
        const Color(0xFFCC97FF),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      setState(() {});
    });

    _nebulaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

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
  }

  @override
  void dispose() {
    _nebulaCtrl.dispose();
    _searchPulseCtrl.dispose();
    _ariaPulseCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
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
          // 1. Nebula Background
          _NebulaBackground(controller: _nebulaCtrl),

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

                // Trending section
                SliverToBoxAdapter(child: _buildTrendingSection()),

                // 4. Discovery header
                SliverToBoxAdapter(child: _buildDiscoveryHeader()),

                // 5. Discovery grid (contains empty state logic)
                _buildDiscoveryGrid(),
                  
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
          // Left: Icon button
          _GlassIconButton(
            icon: LucideIcons.search,
            onTap: () {},
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.3),

          // Center: EXPLORE label
          Text(
            'EXPLORE',
            style: GoogleFonts.rye(
              color: _onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
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
                  builder: (_, __) => Icon(
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
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final isActive = i == _activeFilter;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = i),
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
}

// ===========================================================================
// NEBULA BACKGROUND PAINTER
// ===========================================================================

class _NebulaBackground extends StatelessWidget {
  final AnimationController controller;

  const _NebulaBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _NebulaPainter(t: controller.value),
        );
      },
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final double t;
  _NebulaPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep space background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF020105),
    );

    // Top-left purple nebula glow
    final topLeftRadius = size.width * (0.7 + t * 0.1);
    canvas.drawCircle(
      Offset(-size.width * 0.1, -size.height * 0.05),
      topLeftRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.18 + t * 0.06),
            const Color(0xFF020105).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(-size.width * 0.1, -size.height * 0.05),
          radius: topLeftRadius,
        )),
    );

    // Bottom-right pink nebula glow
    final bottomRightRadius = size.width * (0.65 + (1 - t) * 0.1);
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 1.05),
      bottomRightRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: 0.14 + (1 - t) * 0.06),
            const Color(0xFF020105).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 1.1, size.height * 1.05),
          radius: bottomRightRadius,
        )),
    );

    // Scattered stars
    final rng = math.Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.0 + 0.3;
      final alpha = (0.2 + rng.nextDouble() * 0.5 +
              math.sin(t * math.pi * 2 + i) * 0.15)
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        r,
        starPaint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.t != t;
}

// ===========================================================================
// REUSABLE WIDGETS
// ===========================================================================

// ── Glass Icon Button ────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1823),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF4B4651).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, color: const Color(0xFFAFA8B5), size: 18),
      ),
    );
  }
}

// ── Avatar With Notification Dot ─────────────────────────────────────────────

class _AvatarWithDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C48EA), Color(0xFFFF67AD)],
            ),
            border: Border.all(
              color: const Color(0xFF4B4651).withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: const Icon(
            LucideIcons.user,
            color: Colors.white,
            size: 18,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF34D399),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF020105), width: 1.5),
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

  const _SuggestionChip({required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
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
