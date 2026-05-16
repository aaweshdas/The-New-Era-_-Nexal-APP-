import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class Post {
  final String id;
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final String content;
  final String? image;
  final String timeAgo;
  final int likes;
  final int comments;
  final int shares;
  final int views;

  Post({
    required this.id,
    required this.userName,
    required this.userAvatar,
    this.isVerified = false,
    required this.content,
    this.image,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
  });
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        color: Colors.black.withValues(alpha: 0.4),
        blur: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.purple500, AppTheme.pink500],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(post.userAvatar),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                        Row(
                          children: [
                            Text(
                              post.timeAgo,
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "•",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.eye, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${post.views}",
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Image
            if (post.image != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(post.image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _ActionButton(
                        icon: LucideIcons.heart,
                        label: "${post.likes}",
                        color: AppTheme.pink500,
                      ),
                      const SizedBox(width: 24),
                      _ActionButton(
                        icon: LucideIcons.messageCircle,
                        label: "${post.comments}",
                        color: AppTheme.blue500,
                      ),
                      const SizedBox(width: 24),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        label: "${post.shares}",
                        color: AppTheme.purple500,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _PulseDot(color: AppTheme.purple500),
                      const SizedBox(width: 4),
                      _PulseDot(color: AppTheme.pink500),
                      const SizedBox(width: 4),
                      _PulseDot(color: AppTheme.blue500),
                    ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }
}
