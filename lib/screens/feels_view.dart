import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class Feel {
  final String id, userName, userAvatar, videoImage, caption, sound;
  final int likes, comments, shares;
  final bool isVerified;
  Feel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.videoImage,
    required this.caption,
    required this.sound,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isVerified = false,
  });
}

class FeelsView extends StatefulWidget {
  const FeelsView({super.key});

  @override
  State<FeelsView> createState() => _FeelsViewState();
}

class _FeelsViewState extends State<FeelsView> {
  int _currentPage = 0;
  final Set<int> _likedIndices = {};
  final Set<int> _followedIndices = {};
  final Set<String> _savedFeelIds = {};
  bool _isMuted = false;

  bool _showHeart = false;
  Offset _heartPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadSavedFeels();
  }

  SharedPreferences? _prefs;

  Future<void> _loadSavedFeels() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getStringList('saved_feels') ?? [];
    if (mounted) {
      setState(() => _savedFeelIds.addAll(saved));
    }
  }

  Future<void> _toggleSaveFeel(String feelId) async {
    setState(() {
      if (_savedFeelIds.contains(feelId)) {
        _savedFeelIds.remove(feelId);
      } else {
        _savedFeelIds.add(feelId);
      }
    });
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList('saved_feels', _savedFeelIds.toList());
  }

  final List<Feel> _feels = [
    Feel(
      id: 'f1',
      userName: 'Aria Storm',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      videoImage: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1000',
      caption: 'Exploring quantum dimensions in the neural space ✨ #Nexal #AI',
      sound: 'Original Audio - Aria Storm 🎵',
      likes: 14200,
      comments: 382,
      shares: 124,
      isVerified: true,
    ),
    Feel(
      id: 'f2',
      userName: 'Kai Cyber',
      userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      videoImage: 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=1000',
      caption: 'Cyberpunk cityscape rendering test with raytracing enabled 🌃🚀',
      sound: 'Cyberpunk Beats 2077 ⚡',
      likes: 28900,
      comments: 912,
      shares: 430,
      isVerified: true,
    ),
    Feel(
      id: 'f3',
      userName: 'Luna Ray',
      userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      videoImage: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1000',
      caption: 'Virtual reality flight dynamics in 120FPS ultra resolution 🎮✨',
      sound: 'Deep Space Soundscape 🌌',
      likes: 9500,
      comments: 210,
      shares: 88,
    ),
  ];

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF1a1a2e),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _sideAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: color, shadows: const [Shadow(color: Colors.black, blurRadius: 6)]),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, shadows: [const Shadow(color: Colors.black, blurRadius: 4)])),
          ],
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _feels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.film, color: Colors.white24, size: 56),
                      const SizedBox(height: 16),
                      Text('No Feels Reels Yet', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Tap camera to record & share your first video reel!', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                )
              : NotificationListener<ScrollUpdateNotification>(
                  onNotification: (notif) {
                    final newPage = (notif.metrics.pixels / screenHeight).round();
                    if (newPage != _currentPage && newPage >= 0 && newPage < _feels.length) {
                      setState(() => _currentPage = newPage);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const PageScrollPhysics(),
                    itemExtent: screenHeight,
                    itemCount: _feels.length,
                    itemBuilder: (context, index) {
                      final feel = _feels[index];
                      final isLiked = _likedIndices.contains(index);
                      final isFollowed = _followedIndices.contains(index);
                      return RepaintBoundary(child: Stack(fit: StackFit.expand, children: [
                        // ── Background image ──
                        CachedNetworkImage(imageUrl: feel.videoImage, fit: BoxFit.cover, errorWidget: (c, url, error) => Container(color: Colors.grey[900], child: const Center(child: Icon(LucideIcons.film, color: Colors.white24, size: 48)))),

                        // ── Gradient overlays ──
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent]))),
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)]))),

                        // ── Double-tap to like ──
                        Positioned.fill(child: GestureDetector(
                          onDoubleTapDown: (details) {
                            HapticFeedback.mediumImpact();
                            final pos = details.localPosition;
                            setState(() {
                              _likedIndices.add(index);
                              _heartPos = pos;
                              _showHeart = true;
                            });
                            Future.delayed(const Duration(milliseconds: 800), () {
                              if (mounted) setState(() => _showHeart = false);
                            });
                          },
                          onDoubleTap: () {},
                          child: Container(color: Colors.transparent),
                        )),

                        // ── Heart burst animation ──
                        if (_showHeart && _currentPage == index)
                          Positioned(
                            left: _heartPos.dx - 40,
                            top: _heartPos.dy - 40,
                            child: const Icon(LucideIcons.heart, color: Colors.redAccent, size: 80)
                                .animate()
                                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.3, 1.3), duration: 300.ms, curve: Curves.easeOut)
                                .then()
                                .fadeOut(duration: 400.ms),
                          ),

                        // ── Right sidebar ──
                        Positioned(right: 12, bottom: 160, child: Column(mainAxisSize: MainAxisSize.min, children: [
                          _avatarWithFollow(feel, isFollowed, index),
                          const SizedBox(height: 20),
                          _sideAction(isLiked ? LucideIcons.heart : LucideIcons.heart, _fmtNum(feel.likes + (isLiked ? 1 : 0)), isLiked ? Colors.redAccent : Colors.white, () {
                            setState(() { isLiked ? _likedIndices.remove(index) : _likedIndices.add(index); });
                          }),
                          const SizedBox(height: 18),
                          _sideAction(LucideIcons.messageCircle, _fmtNum(feel.comments), Colors.white, () => _showComments(feel)),
                          const SizedBox(height: 18),
                          _sideAction(LucideIcons.send, _fmtNum(feel.shares), Colors.white, () => _showShareSheet(feel)),
                          const SizedBox(height: 18),
                          _sideAction(_savedFeelIds.contains(feel.id) ? LucideIcons.bookmarkCheck : LucideIcons.bookmark, 'Save', _savedFeelIds.contains(feel.id) ? AppTheme.cyan500 : Colors.white, () => _toggleSaveFeel(feel.id)),
                          const SizedBox(height: 18),
                          _sideAction(LucideIcons.ellipsis, 'More', Colors.white, () => _showMoreOptions(feel)),
                        ])),

                        // ── Bottom left caption & audio ──
                        Positioned(left: 16, right: 80, bottom: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            Text('@${feel.userName}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            if (feel.isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, color: AppTheme.cyan500, size: 16)],
                          ]),
                          const SizedBox(height: 8),
                          Text(feel.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(LucideIcons.music2, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Expanded(child: Text(feel.sound, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                          ]),
                        ])),
                      ]));
                    },
                  ),
                ),

          // ── Persistent Always-Visible Top Bar with Guaranteed Back Button ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _glassBtn(LucideIcons.arrowLeft, () {
                      HapticFeedback.lightImpact();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    }),
                    const Spacer(),
                    Text('Feels Reels', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _glassBtn(_isMuted ? LucideIcons.volumeX : LucideIcons.volume2, () => setState(() => _isMuted = !_isMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWithFollow(Feel feel, bool isFollowed, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500])),
          child: CircleAvatar(radius: 20, backgroundImage: CachedNetworkImageProvider(feel.userAvatar), backgroundColor: Colors.grey[900]),
        ),
        if (!isFollowed)
          Positioned(
            bottom: -6,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _followedIndices.add(index);
                  _snack('Following ${feel.userName}');
                }),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: AppTheme.cyan500, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── COMMENTS SHEET ──
  void _showComments(Feel feel) {
    final TextEditingController commentCtrl = TextEditingController();
    final List<Map<String, String>> localComments = [
      {'user': feel.userName, 'text': feel.caption, 'likes': '0', 'time': '1h'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (c, ctrl) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0d0d1a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${localComments.length} Comments',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: localComments.length,
                    itemBuilder: (ctx, i) {
                      final c = localComments[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.purple500.withValues(alpha: 0.3),
                              child: Text(
                                c['user']!.isNotEmpty ? c['user']![0].toUpperCase() : 'N',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(
                                      c['user']!,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      c['time']!,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white24,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    c['text']!,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 13,
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
                ),
                // Comment input
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: commentCtrl,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final text = commentCtrl.text.trim();
                        if (text.isNotEmpty) {
                          setSheetState(() {
                            localComments.insert(0, {
                              'user': 'You',
                              'text': text,
                              'likes': '0',
                              'time': 'Just now',
                            });
                            commentCtrl.clear();
                          });
                          _snack('Comment posted! 💬');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.purple500, AppTheme.cyan500],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── SHARE SHEET ──
  void _showShareSheet(Feel feel) {
    final actions = [
      {'icon': LucideIcons.send, 'label': 'Send to...', 'color': AppTheme.cyan500},
      {'icon': LucideIcons.copy, 'label': 'Copy Link', 'color': AppTheme.purple500},
      {'icon': LucideIcons.repeat2, 'label': 'Repost', 'color': const Color(0xFF34D399)},
      {'icon': LucideIcons.download, 'label': 'Save Video', 'color': AppTheme.pink500},
      {'icon': LucideIcons.link, 'label': 'Share to...', 'color': Colors.white54},
    ];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Share', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: actions.map((a) => GestureDetector(
          onTap: () { Navigator.pop(ctx); _snack('${a['label']}'); },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (a['color'] as Color).withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.2))),
              child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22)),
            const SizedBox(height: 8),
            Text(a['label'] as String, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
          ]),
        )).toList()),
        const SizedBox(height: 16),
      ]),
    ));
  }

  // ── MORE OPTIONS ──
  void _showMoreOptions(Feel feel) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        _optionItem(LucideIcons.flag, 'Report', Colors.redAccent, () { Navigator.pop(ctx); _snack('Reported'); }),
        _optionItem(LucideIcons.eyeOff, 'Not Interested', Colors.white54, () { Navigator.pop(ctx); _snack('We\'ll show fewer like this'); }),
        _optionItem(LucideIcons.userX, 'Block ${feel.userName}', AppTheme.pink500, () { Navigator.pop(ctx); _snack('${feel.userName} blocked'); }),
        _optionItem(LucideIcons.download, 'Download', AppTheme.cyan500, () { Navigator.pop(ctx); _snack('Downloading...'); }),
        _optionItem(LucideIcons.link, 'Copy Link', AppTheme.purple500, () { Navigator.pop(ctx); _snack('Link copied!'); }),
        const SizedBox(height: 12),
      ]),
    ));
  }

  Widget _optionItem(IconData icon, String label, Color c, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [Icon(icon, color: c, size: 20), const SizedBox(width: 14), Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)), const Spacer(), Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18)]),
    ),
  );
}
