import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/post_model.dart';
import '../widgets/common/comment_tile.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await ApiService.instance.get('/api/posts/${widget.post.id}/comments');
      if (res.statusCode == 200 && res.data is List && mounted) {
        final list = (res.data as List).map((c) => CommentModel(
          id: c['id'] ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
          userName: c['userName'] ?? 'User',
          userAvatar: c['userAvatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          text: c['text'] ?? '',
          timeAgo: c['timeAgo'] ?? 'Just now',
          likes: c['likes'] ?? 0,
        )).toList();
        setState(() {
          _comments.clear();
          _comments.addAll(list);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final curUser = AuthService.instance.currentUser;
    final name = (curUser?.name.isNotEmpty == true) ? curUser!.name : ((curUser?.username.isNotEmpty == true) ? '@${curUser!.username}' : 'You');
    final avatar = (curUser?.avatarUrl.isNotEmpty == true) ? curUser!.avatarUrl : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

    setState(() {
      _comments.insert(
        0,
        CommentModel(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          userName: name,
          userAvatar: avatar,
          text: text,
          timeAgo: 'Just now',
        ),
      );
      widget.post.commentsCount++;
      _commentCtrl.clear();
    });
    ApiService.instance.post('/api/posts/${widget.post.id}/comments', {'text': text}).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'POST THREAD',
                        style: GoogleFonts.rye(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Card Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(p.userAvatar),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          p.userName,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (p.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            LucideIcons.checkCircle2,
                                            color: Color(0xFF00E5FF),
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      p.timeAgo,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white
                                            .withValues(alpha: 0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Content text
                            Text(
                              p.content,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Post Image
                            if (p.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  p.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            const SizedBox(height: 14),

                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      p.isLiked
                                          ? LucideIcons.heart
                                          : LucideIcons.heart,
                                      color: p.isLiked
                                          ? const Color(0xFFFF6BAD)
                                          : Colors.white38,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p.likes}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.messageSquare,
                                        color: Colors.white38, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p.commentsCount}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.eye,
                                        color: Colors.white38, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p.viewsCount}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10),

                    // Comments Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'COMMENTS (${_comments.length})',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    // Comment List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return CommentTile(comment: _comments[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Comment Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.send,
                        color: Color(0xFF00E5FF), size: 18),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
