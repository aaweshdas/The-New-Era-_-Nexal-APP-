import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class Feel {
  final String id, userName, userAvatar, videoImage, caption, sound;
  final int likes, comments, shares;
  final bool isVerified;
  Feel({required this.id, required this.userName, required this.userAvatar, required this.videoImage, required this.caption, required this.sound, required this.likes, required this.comments, required this.shares, this.isVerified = false});
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
  bool _isMuted = false;

  final _feels = [
    Feel(id: '1', userName: 'Aria Storm', userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', videoImage: 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1080', caption: 'Living in the moment ✨ #nexal #vibes', sound: 'Midnight Drive – NeoPulse', likes: 45620, comments: 892, shares: 234, isVerified: true),
    Feel(id: '2', userName: 'Neo Sync', userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', videoImage: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=1080', caption: 'Energy never lies 🔥 #trending', sound: 'Starlight – Cosmic', likes: 38940, comments: 654, shares: 189),
    Feel(id: '3', userName: 'Luna Nova', userAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', videoImage: 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?w=1080', caption: 'Chasing dreams 🌙 #moonlight', sound: 'Dreamscape – Luna', likes: 52310, comments: 1023, shares: 345, isVerified: true),
    Feel(id: '4', userName: 'Kai Zen', userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', videoImage: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1080', caption: 'Cyberpunk vibes only 🤖 #cyber', sound: 'Neon City – ZenBeats', likes: 12400, comments: 340, shares: 56),
    Feel(id: '5', userName: 'Zara Void', userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', videoImage: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1080', caption: 'Lost in the nebula 🌌 #space', sound: 'Orbit – Astro', likes: 89200, comments: 2100, shares: 890, isVerified: true),
    Feel(id: '6', userName: 'Orion Pax', userAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100', videoImage: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1080', caption: 'Midnight drive 🏎️ #night', sound: 'Turbo – Drift', likes: 32100, comments: 560, shares: 120),
    Feel(id: '7', userName: 'Lyra Star', userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100', videoImage: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1080', caption: 'Coding the future 💻 #dev', sound: 'Binary – Lyra', likes: 67800, comments: 1500, shares: 670, isVerified: true),
    Feel(id: '8', userName: 'Kael Drift', userAvatar: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=100', videoImage: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1080', caption: 'Orbiting... 🚀 #launch', sound: 'Countdown – Kael', likes: 4500, comments: 120, shares: 30),
  ];

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF1a1a2e), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollUpdateNotification>(
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
          return Stack(fit: StackFit.expand, children: [
            // ── Background image ──
            CachedNetworkImage(imageUrl: feel.videoImage, fit: BoxFit.cover, errorWidget: (c, url, error) => Container(color: Colors.grey[900], child: const Center(child: Icon(LucideIcons.film, color: Colors.white24, size: 48)))),

            // ── Gradient overlays ──
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent]))),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)]))),

            // ── Play indicator (center) ──
            Center(child: GestureDetector(
              onDoubleTap: () => setState(() { _likedIndices.add(index); _snack('❤️ Liked!'); }),
              child: Container(width: double.infinity, height: double.infinity, color: Colors.transparent),
            )),

            // ── Top bar ──
            Positioned(top: 0, left: 0, right: 0, child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                _glassBtn(LucideIcons.arrowLeft, () { if (Navigator.canPop(context)) Navigator.pop(context); }),
                const Spacer(),
                Text('Reels', style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                _glassBtn(_isMuted ? LucideIcons.volumeX : LucideIcons.volume2, () => setState(() => _isMuted = !_isMuted)),
              ]),
            ).animate().fadeIn(duration: 400.ms))),

            // ── Right sidebar ──
            Positioned(right: 12, bottom: 160, child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Avatar + follow
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500])),
                  child: CircleAvatar(radius: 20, backgroundImage: CachedNetworkImageProvider(feel.userAvatar), backgroundColor: Colors.grey[900]),
                ),
                if (!isFollowed) Positioned(bottom: -6, left: 0, right: 0, child: Center(child: GestureDetector(
                  onTap: () => setState(() { _followedIndices.add(index); _snack('Following ${feel.userName}'); }),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: AppTheme.cyan500, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 10),
                  ),
                ))),
              ]),
              const SizedBox(height: 22),

              // Like
              _sideAction(isLiked ? LucideIcons.heart : LucideIcons.heart, _fmtNum(feel.likes + (isLiked ? 1 : 0)), isLiked ? AppTheme.pink500 : Colors.white, () => setState(() { if (isLiked) _likedIndices.remove(index); else _likedIndices.add(index); })),
              const SizedBox(height: 18),

              // Comment
              _sideAction(LucideIcons.messageCircle, _fmtNum(feel.comments), Colors.white, () => _showComments(feel)),
              const SizedBox(height: 18),

              // Share
              _sideAction(LucideIcons.share2, _fmtNum(feel.shares), Colors.white, () => _showShareSheet(feel)),
              const SizedBox(height: 18),

              // Bookmark
              _sideAction(LucideIcons.bookmark, 'Save', Colors.white, () => _snack('Saved to collection')),
              const SizedBox(height: 18),

              // More
              _sideAction(LucideIcons.moreHorizontal, '', Colors.white, () => _showMoreOptions(feel)),
            ]).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.3, end: 0, duration: 400.ms)),

            // ── Bottom info ──
            Positioned(left: 14, right: 70, bottom: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Username
              Row(children: [
                CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider(feel.userAvatar), backgroundColor: Colors.grey[900]),
                const SizedBox(width: 8),
                Text(feel.userName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, shadows: [const Shadow(color: Colors.black, blurRadius: 4)])),
                if (feel.isVerified) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyan500), child: const Icon(LucideIcons.check, color: Colors.white, size: 10))],
                if (isFollowed) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('Following', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)))],
              ]),
              const SizedBox(height: 8),
              // Caption
              Text(feel.caption, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.3, shadows: [const Shadow(color: Colors.black, blurRadius: 4)])),
              const SizedBox(height: 10),
              // Sound
              GestureDetector(
                onTap: () => _snack('🎵 ${feel.sound}'),
                child: Row(children: [
                  const Icon(LucideIcons.music, color: Colors.white54, size: 12),
                  const SizedBox(width: 6),
                  Expanded(child: Text(feel.sound, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ]).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms)),

            // ── Progress bar ──
            Positioned(bottom: 76, left: 0, right: 0, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: 0.65, minHeight: 2, backgroundColor: Colors.white.withValues(alpha: 0.15), color: AppTheme.cyan500)),
            )),

            // ── Page indicator ──
            Positioned(right: 4, top: MediaQuery.paddingOf(context).top + 50, child: Column(children: List.generate(_feels.length, (i) => Container(
              width: 3, height: i == _currentPage ? 16 : 6,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(color: i == _currentPage ? AppTheme.cyan500 : Colors.white24, borderRadius: BorderRadius.circular(2)),
            )))),
          ]);
        },
      ),
      ),
    );
  }

  // ── SIDE ACTION ──
  Widget _sideAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 26, color: color, shadows: const [Shadow(color: Colors.black, blurRadius: 6)]),
        if (label.isNotEmpty) ...[const SizedBox(height: 3), Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, shadows: [const Shadow(color: Colors.black, blurRadius: 4)]))],
      ]),
    );
  }

  // ── GLASS BUTTON ──
  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Icon(icon, color: Colors.white, size: 20),
      ))),
    );
  }

  // ── COMMENTS SHEET ──
  void _showComments(Feel feel) {
    final mockComments = [
      {'user': 'CyberWolf', 'text': 'This is fire 🔥🔥', 'likes': '2.3K', 'time': '2h'},
      {'user': 'PixelDust', 'text': 'Absolutely stunning visuals!', 'likes': '1.1K', 'time': '3h'},
      {'user': 'NeonDream', 'text': 'Can\'t stop watching this 😍', 'likes': '890', 'time': '5h'},
      {'user': 'VoidRunner', 'text': 'Song name please? 🎵', 'likes': '456', 'time': '7h'},
      {'user': 'StarChild', 'text': 'Making this my wallpaper', 'likes': '234', 'time': '12h'},
    ];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55, minChildSize: 0.3, maxChildSize: 0.85,
      builder: (c, ctrl) => Container(
        decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(16), child: Text('${_fmtNum(feel.comments)} Comments', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
          Expanded(child: ListView.builder(
            controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: mockComments.length,
            itemBuilder: (ctx, i) {
              final c = mockComments[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 16, backgroundColor: AppTheme.purple500.withValues(alpha: 0.3), child: Text(c['user']![0], style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(c['user']!, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)), const Spacer(), Text(c['time']!, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10))]),
                    const SizedBox(height: 4),
                    Text(c['text']!, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(children: [Icon(LucideIcons.heart, color: Colors.white30, size: 12), const SizedBox(width: 4), Text(c['likes']!, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)), const SizedBox(width: 16), GestureDetector(onTap: () => _snack('Reply to ${c['user']}'), child: Text('Reply', style: GoogleFonts.outfit(color: AppTheme.cyan500.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)))]),
                  ])),
                ]),
              );
            },
          )),
          // Comment input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
            child: Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                child: Text('Add a comment...', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
              )),
              const SizedBox(width: 10),
              GestureDetector(onTap: () => _snack('Comment posted!'), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.purple500, AppTheme.cyan500]), shape: BoxShape.circle), child: const Icon(LucideIcons.send, color: Colors.white, size: 16))),
            ]),
          ),
        ]),
      ),
    ));
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
