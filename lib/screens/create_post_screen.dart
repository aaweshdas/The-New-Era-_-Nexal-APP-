import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';

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
  String? _locationLabel;
  bool _isFetchingLocation = false;
  bool _showEmojiPanel = false;

  static const _emojis = [
    '🚀','✨','🔥','😍','🧠','👏','🌙','👾','🌌','⚡',
    '💜','😈','🌟','🙏','💥','🔮','🤖','🎨','🥏','📸',
    '👀','💛','💚','💙','❤️','💔','🏠','👍','🙌','🤙',
    '📝','🔓','💎','🎉','🌈','☂️','🌞','🌝','🌏','🎤',
  ];

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationLabel = 'Location services disabled'; _isFetchingLocation = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() { _locationLabel = 'Location permission denied'; _isFetchingLocation = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.locality, p.administrativeArea, p.country].whereType<String>().where((s) => s.isNotEmpty);
        setState(() => _locationLabel = parts.join(', '));
      } else {
        setState(() => _locationLabel = '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°');
      }
    } catch (_) {
      setState(() => _locationLabel = 'Location unavailable');
    } finally {
      setState(() => _isFetchingLocation = false);
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

    String? imageUrl;

    // Step 1: Upload image to Supabase Storage (if selected)
    if (_selectedImage != null) {
      try {
        final supabase = Supabase.instance.client;
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.path.split('.').last.toLowerCase();
        final fileName = 'posts/${user?.uid ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('media').uploadBinary(fileName, bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));
        imageUrl = supabase.storage.from('media').getPublicUrl(fileName);
      } catch (e) {
        debugPrint('[CreatePost] Storage upload failed: $e');
        if (!mounted) return;
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image. Please check your network.',
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'guest',
      userName: (user?.name.isNotEmpty == true) ? user!.name : ((user?.username.isNotEmpty == true) ? '@${user!.username}' : 'Nexal User'),
      userAvatar: (user?.avatarUrl.isNotEmpty == true) ? user!.avatarUrl : 'assets/images/default_avatar.png',
      isVerified: user?.isVerified ?? false,
      content: text,
      imageUrl: imageUrl,
      timeAgo: 'Just now',
      location: _locationLabel,
    );

    if (!mounted) return;

    // Step 2: Optimistic local update — feed appears instantly (like Instagram)
    Provider.of<FeedProvider>(context, listen: false).addPost(newPost);

    // Step 3: Persist to backend API (non-blocking, fire & forget)
    try {
      await ApiService.instance.post('/api/posts', {
        'userId': newPost.userId,
        'content': newPost.content,
        'imageUrl': imageUrl,
        'tag': _selectedTag,
        'location': _locationLabel,
      });
    } catch (e) {
      // Backend unavailable — post is already in local feed, nothing to roll back
      debugPrint('[CreatePost] Backend save failed (post is in local feed): $e');
    }

    if (mounted) {
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
                // Emoji Panel
                if (_showEmojiPanel)
                  Container(
                    height: 200,
                    color: Colors.white.withValues(alpha: 0.04),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, mainAxisSpacing: 4, crossAxisSpacing: 4),
                      itemCount: _emojis.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () {
                          final text = _contentCtrl.text;
                          final sel = _contentCtrl.selection;
                          final newText = text.replaceRange(
                            sel.start < 0 ? text.length : sel.start,
                            sel.end < 0 ? text.length : sel.end,
                            _emojis[i],
                          );
                          _contentCtrl.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: (sel.start < 0 ? text.length : sel.start) + _emojis[i].length),
                          );
                        },
                        child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 22))),
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        icon: const Icon(LucideIcons.image, color: Color(0xFF00E5FF)),
                        onPressed: _pickImage,
                      ),
                      // Location tag button — real GPS
                      GestureDetector(
                        onTap: _isFetchingLocation ? null : _fetchLocation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _isFetchingLocation
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.mapPin, color: _locationLabel != null ? const Color(0xFF00E5FF) : Colors.white54, size: 20),
                                    if (_locationLabel != null) ...[
                                      const SizedBox(width: 4),
                                      Text(_locationLabel!, style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                      const Spacer(),
                      // Emoji toggle button
                      IconButton(
                        icon: Icon(LucideIcons.smile,
                            color: _showEmojiPanel ? const Color(0xFF00E5FF) : Colors.white54),
                        onPressed: () {
                          setState(() => _showEmojiPanel = !_showEmojiPanel);
                          if (_showEmojiPanel) FocusScope.of(context).unfocus();
                        },
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
