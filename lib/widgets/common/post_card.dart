import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PostComment {
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  PostComment({
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
  });
}

class Post {
  final String id;
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final bool isOnline;
  final String content;
  final String? image;
  final bool isVideo;
  final String timeAgo;
  int likes;
  int comments;
  int shares;
  final int views;
  bool isLiked;
  String? selectedReaction;
  final List<PostComment> sampleComments;

  Post({
    required this.id,
    required this.userName,
    required this.userAvatar,
    this.isVerified = false,
    this.isOnline = true,
    required this.content,
    this.image,
    this.isVideo = false,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
    this.isLiked = false,
    this.selectedReaction,
    List<PostComment>? sampleComments,
  }) : sampleComments = sampleComments ?? [
          PostComment(
            userName: 'Aria Storm',
            userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
            text: 'This is absolutely incredible! 🔥',
            timeAgo: '12m ago',
          ),
          PostComment(
            userName: 'Kai Cyber',
            userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
            text: 'Future is now. Mind blown 🚀',
            timeAgo: '5m ago',
          ),
        ];
}

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarked;
  final VoidCallback? onOptionsTap;

  const PostCard({
    super.key,
    required this.post,
    this.onBookmarkToggle,
    this.isBookmarked = false,
    this.onOptionsTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;
  bool _isExpanded = false;
  bool _showDoubleTapHeart = false;
  Offset _heartPos = Offset.zero;
  String? _currentReaction;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _commentCount = widget.post.comments;
    _shareCount = widget.post.shares;
    _currentReaction = widget.post.selectedReaction;
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
        _currentReaction ??= '❤️';
      } else {
        _likeCount--;
        _currentReaction = null;
      }
      widget.post.isLiked = _isLiked;
      widget.post.likes = _likeCount;
      widget.post.selectedReaction = _currentReaction;
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    HapticFeedback.mediumImpact();
    final localPos = details.localPosition;
    setState(() {
      _heartPos = localPos;
      _showDoubleTapHeart = true;
      if (!_isLiked) {
        _isLiked = true;
        _likeCount++;
        _currentReaction = '❤️';
        widget.post.isLiked = true;
        widget.post.likes = _likeCount;
        widget.post.selectedReaction = '❤️';
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });
  }

  void _showReactionPicker(Offset globalPos) {
    HapticFeedback.selectionClick();
    final reactions = ['❤️', '🔥', '🚀', '😮', '👏', '⚡'];

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            top: globalPos.dy - 60,
            left: (MediaQuery.of(context).size.width - 260) / 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF180033),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: reactions.map((r) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _currentReaction = r;
                          if (!_isLiked) {
                            _isLiked = true;
                            _likeCount++;
                          }
                          widget.post.selectedReaction = r;
                          widget.post.isLiked = true;
                          widget.post.likes = _likeCount;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(r, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0022),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundImage: CachedNetworkImageProvider(widget.post.userAvatar),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.post.userName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (widget.post.isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.checkCircle, size: 16, color: AppTheme.blue500),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text('@${widget.post.userName.toLowerCase().replaceAll(' ', '')}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _profileStat('Posts', '142'),
                _profileStat('Followers', '24.8K'),
                _profileStat('Following', '482'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Following ${widget.post.userName}')),
                );
              },
              child: Text('Follow', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  void _showImageZoom(String imageUrl) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsModal() {
    HapticFeedback.lightImpact();
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0018),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Comments ($_commentCount)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.post.sampleComments.length,
                  itemBuilder: (_, i) {
                    final c = widget.post.sampleComments[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 18, backgroundImage: CachedNetworkImageProvider(c.userAvatar)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(c.userName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(c.timeAgo, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.text, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.87), fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: const BoxDecoration(color: Color(0xFF140026), border: Border(top: BorderSide(color: Colors.white10))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.send, color: AppTheme.purple500, size: 20),
                      onPressed: () {
                        if (commentCtrl.text.trim().isNotEmpty) {
                          HapticFeedback.lightImpact();
                          setModalState(() {
                            widget.post.sampleComments.add(
                              PostComment(userName: 'You', userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100', text: commentCtrl.text.trim(), timeAgo: 'Just now'),
                            );
                            _commentCount++;
                            widget.post.comments = _commentCount;
                          });
                          setState(() {});
                          commentCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0022),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('Share Post', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(LucideIcons.copy, 'Copy Link', AppTheme.cyan500, () {
                  Clipboard.setData(ClipboardData(text: 'https://nexal.app/post/${widget.post.id}'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                }),
                _shareOption(LucideIcons.send, 'Send Message', AppTheme.pink500, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared to messages!')));
                }),
                _shareOption(LucideIcons.aperture, 'To Story', AppTheme.purple500, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to your story!')));
                }),
                _shareOption(LucideIcons.share2, 'More', Colors.white70, () {
                  Navigator.pop(context);
                  setState(() { _shareCount++; widget.post.shares = _shareCount; });
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLongText = widget.post.content.length > 110;
    final displayText = !_isExpanded && hasLongText
        ? '${widget.post.content.substring(0, 110)}...'
        : widget.post.content;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showProfileModal,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500]),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(widget.post.userAvatar),
                          ),
                        ),
                        if (widget.post.isOnline)
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showProfileModal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(widget.post.userName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              if (widget.post.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(LucideIcons.checkCircle, size: 14, color: AppTheme.blue500),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Text(widget.post.timeAgo, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 4),
                              const Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.eye, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_formatCount(widget.post.views), style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Content with #hashtag & @mention highlights
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _parseFormattedText(displayText),
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.5, height: 1.4),
                    ),
                  ),
                  if (hasLongText)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: GoogleFonts.outfit(color: AppTheme.cyan500, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Image / Video with Double-Tap to Like
            if (widget.post.image != null)
              GestureDetector(
                onDoubleTapDown: _handleDoubleTap,
                onDoubleTap: () {},
                onTap: () => _showImageZoom(widget.post.image!),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 280,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.post.image!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    if (widget.post.isVideo)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.play, color: Colors.white, size: 30),
                      ),
                    if (_showDoubleTapHeart)
                      Positioned(
                        left: _heartPos.dx - 40,
                        top: _heartPos.dy - 40,
                        child: Icon(LucideIcons.heart, size: 80, color: AppTheme.pink500)
                            .animate()
                            .scale(duration: 300.ms, curve: Curves.elasticOut)
                            .fadeOut(delay: 500.ms, duration: 300.ms),
                      ),
                  ],
                ),
              ),

            // Actions row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Like button with long press reaction
                      GestureDetector(
                        onTap: _toggleLike,
                        onLongPressStart: (d) => _showReactionPicker(d.globalPosition),
                        child: Row(
                          children: [
                            Text(_currentReaction ?? '', style: const TextStyle(fontSize: 16)),
                            if (_currentReaction == null)
                              Icon(_isLiked ? LucideIcons.heart : LucideIcons.heart, size: 20, color: _isLiked ? AppTheme.pink500 : Colors.grey),
                            const SizedBox(width: 6),
                            Text('${_likeCount}', style: GoogleFonts.outfit(color: _isLiked ? AppTheme.pink500 : Colors.grey, fontSize: 13.5, fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Comment button
                      GestureDetector(
                        onTap: _showCommentsModal,
                        child: Row(
                          children: [
                            const Icon(LucideIcons.messageCircle, size: 20, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${_commentCount}', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Share button
                      GestureDetector(
                        onTap: _showShareModal,
                        child: Row(
                          children: [
                            const Icon(LucideIcons.share2, size: 20, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${_shareCount}', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ColorfulThreeDots(
                    dotSize: 6,
                    spacing: 4,
                    onTap: widget.onOptionsTap,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final words = text.split(' ');
    final spans = <TextSpan>[];

    for (var w in words) {
      if (w.startsWith('#')) {
        spans.add(TextSpan(text: '$w ', style: TextStyle(color: AppTheme.purple500, fontWeight: FontWeight.bold)));
      } else if (w.startsWith('@')) {
        spans.add(TextSpan(text: '$w ', style: TextStyle(color: AppTheme.cyan500, fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(text: '$w '));
      }
    }
    return spans;
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class ColorfulThreeDots extends StatelessWidget {
  final double dotSize;
  final double spacing;
  final VoidCallback? onTap;

  const ColorfulThreeDots({
    super.key,
    this.dotSize = 6.0,
    this.spacing = 4.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(const Color(0xFFC084FC)), // Glowing Purple dot
            SizedBox(width: spacing),
            _dot(const Color(0xFFEC4899)), // Glowing Pink dot
            SizedBox(width: spacing),
            _dot(const Color(0xFF3B82F6)), // Glowing Blue dot
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.85),
            blurRadius: 6,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }
}

