import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  final File? initialImage;
  const CreatePostScreen({super.key, this.initialImage});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentCtrl = TextEditingController();
  File? _selectedImage;
  String _selectedTag = 'General';
  bool _isPosting = false;

  final List<String> _tags = ['General', 'Quantum', 'Sci-Fi', 'Art', 'Dev', 'AI'];

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _submitPost() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write something or attach an image',
              style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF135BEC),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'guest',
      userName: user?.name ?? 'Neural Nexus',
      userAvatar: user?.avatarUrl ??
          'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
      isVerified: true,
      content: text.isEmpty ? 'Shared a new memory ⚡' : text,
      imageUrl: _selectedImage != null
          ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800'
          : null,
      timeAgo: 'Just now',
    );

    if (mounted) {
      Provider.of<FeedProvider>(context, listen: false).addPost(newPost);
      setState(() => _isPosting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post published to Nexal feed! 🚀',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00E5FF),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Dark Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D0015), Colors.black, Color(0xFF000A14)],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Glass Top Header
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.x,
                                color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            'NEW POST',
                            style: GoogleFonts.rye(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135BEC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                            ),
                            onPressed: _isPosting ? null : _submitPost,
                            child: _isPosting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'POST',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                user?.avatarUrl ??
                                    'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Neural Nexus',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '@${user?.username ?? "neuralnexus"}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Multiline Input
                        TextField(
                          controller: _contentCtrl,
                          maxLines: 6,
                          minLines: 3,
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "What's happening in your universe?",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                          ),
                        ),

                        // Attached Image Preview
                        if (_selectedImage != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.x,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Category Chips
                        Text(
                          'CATEGORY TAG',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _tags.map((tag) {
                            final isSel = _selectedTag == tag;
                            return ChoiceChip(
                              label: Text(tag,
                                  style: TextStyle(
                                      color: isSel
                                          ? Colors.black
                                          : Colors.white70)),
                              selected: isSel,
                              selectedColor: const Color(0xFF00E5FF),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              onSelected: (_) =>
                                  setState(() => _selectedTag = tag),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar (Attach Media)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.image,
                            color: Color(0xFF00E5FF)),
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.mapPin,
                            color: Colors.white54),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location tagged: Digital Space Station',
                                  style: GoogleFonts.outfit()),
                              backgroundColor: const Color(0xFF135BEC),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.smile,
                            color: Colors.white54),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
