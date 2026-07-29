import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/socket_service.dart';

class StoryItem {
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final String caption;
  final String timeAgo;

  StoryItem({
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.caption,
    required this.timeAgo,
  });
}

class StoryViewerScreen extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;
  final TextEditingController _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image PageView
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.stories[index].imageUrl,
                  fit: BoxFit.cover,
                );
              },
            ),

            // Top & Bottom Gradient Overlays
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.2, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Top Controls Bar (Progress Bars + User Header)
            Positioned(
              top: 48,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Progress Bar Indicators
                  Row(
                    children: List.generate(
                      widget.stories.length,
                      (idx) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              double val = 0.0;
                              if (idx < _currentIndex) {
                                val = 1.0;
                              } else if (idx == _currentIndex) {
                                val = _animController.value;
                              }
                              return LinearProgressIndicator(
                                value: val,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00E5FF)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(story.userAvatar),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        story.userName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        story.timeAgo,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(LucideIcons.x, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Caption & Reply Bar
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        story.caption,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _replyCtrl,
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Send message...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.send,
                            color: Color(0xFF00E5FF)),
                        onPressed: () {
                          final replyText = _replyCtrl.text.trim();
                          if (replyText.isNotEmpty) {
                            if (SocketService.instance.isConnected) {
                              SocketService.instance.sendMessage(story.userName, 'Replied to story: "$replyText"');
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reply sent to ${story.userName}',
                                    style: GoogleFonts.outfit()),
                                backgroundColor: const Color(0xFF135BEC),
                              ),
                            );
                            _replyCtrl.clear();
                          }
                        },
                      ),
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
