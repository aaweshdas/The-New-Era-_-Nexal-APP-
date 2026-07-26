import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CommentModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  int likes;
  bool isLiked;

  CommentModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
    this.isLiked = false,
  });
}

class CommentTile extends StatefulWidget {
  final CommentModel comment;
  const CommentTile({super.key, required this.comment});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(c.userAvatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.userName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      c.timeAgo,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.text,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                c.isLiked = !c.isLiked;
                if (c.isLiked) {
                  c.likes++;
                } else {
                  c.likes--;
                }
              });
            },
            child: Column(
              children: [
                Icon(
                  c.isLiked ? LucideIcons.heart : LucideIcons.heart,
                  color: c.isLiked ? const Color(0xFFFF6BAD) : Colors.white38,
                  size: 14,
                ),
                if (c.likes > 0)
                  Text(
                    '${c.likes}',
                    style: TextStyle(
                      color:
                          c.isLiked ? const Color(0xFFFF6BAD) : Colors.white38,
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
}
