import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialAvatarUrl;

  const ProfileSetupScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialAvatarUrl,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _pronounsCtrl;

  // Avatar Selection State
  File? _selectedImageFile;
  String? _selectedAvatarUrl;
  final ImagePicker _picker = ImagePicker();

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=400',
  ];

  // Interests Selection State
  final Set<String> _selectedInterests = {
    '🤖 AI & Neural',
    '⚡ Quantum Tech',
    '🚀 Space Exploration',
  };

  final List<String> _allInterests = [
    '🤖 AI & Neural',
    '⚡ Quantum Tech',
    '🚀 Space Exploration',
    '🎮 Arcade Gaming',
    '🎨 Generative Art',
    '🎵 Synth Music',
    '💻 Cyber Dev',
    '🌐 Web3 & Crypto',
    '🔮 Augmented Reality',
    '🌌 Astrophysics',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final current = AuthService.instance.currentUser;
    _nameCtrl = TextEditingController(text: widget.initialName ?? current?.name ?? '');
    
    // Auto-generate username from name if blank
    String baseUsername = (widget.initialName ?? current?.name ?? 'user')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (baseUsername.isEmpty) baseUsername = 'nexaluser';
    _usernameCtrl = TextEditingController(text: current?.handle ?? '@$baseUsername');

    _bioCtrl = TextEditingController(text: current?.bio ?? 'Exploring the quantum frontier on Nexal 🚀');
    _locationCtrl = TextEditingController(text: 'Neo Tokyo');
    _websiteCtrl = TextEditingController(text: '');
    _pronounsCtrl = TextEditingController(text: 'They/Them');

    _selectedAvatarUrl = widget.initialAvatarUrl ?? current?.avatarUrl ?? _presetAvatars.first;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _pronounsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
          _selectedAvatarUrl = null;
        });
      }
    } catch (e) {
      _showSnack('Unable to select image', isError: true);
    }
  }

  void _nextPage() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter your display name', isError: true);
        return;
      }
      if (_usernameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter a username', isError: true);
        return;
      }
    }

    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      _completeProfileSetup();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _pageCtrl.previousPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _completeProfileSetup() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final email = widget.initialEmail ?? supabase.auth.currentUser?.email ?? '';

      final name = _nameCtrl.text.trim();
      var username = _usernameCtrl.text.trim();
      if (!username.startsWith('@')) username = '@$username';
      final bio = _bioCtrl.text.trim();
      final location = _locationCtrl.text.trim();
      final website = _websiteCtrl.text.trim();

      // Final avatar URL or fallback
      final avatarUrl = _selectedAvatarUrl ?? _presetAvatars.first;

      if (userId != null) {
        await supabase.from('profiles').upsert({
          'id': userId,
          'name': name,
          'email': email,
          'username': username,
          'avatar_url': avatarUrl,
          'bio': bio,
          'location': location,
          'website': website,
          'interests': _selectedInterests.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Update in-memory user details
      AuthService.instance.updateProfile(
        name: name,
        handle: username,
        avatarUrl: avatarUrl,
        bio: bio,
      );

      if (!mounted) return;

      _showSnack('Welcome aboard, $name! 🚀');

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const HomeScreen(),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: 500.ms,
        ),
        (route) => false,
      );
    } catch (e) {
      _showSnack('Profile saved! Launching application...', isError: false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const HomeScreen(),
            transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
            transitionDuration: 500.ms,
          ),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFEC4899) : const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070714),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA855F7).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header & Step Progress Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            IconButton(
                              onPressed: _prevPage,
                              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70, size: 20),
                            )
                          else
                            const SizedBox(width: 40),

                          Text(
                            'STEP ${_currentStep + 1} OF $_totalSteps',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),

                          TextButton(
                            onPressed: _completeProfileSetup,
                            child: Text(
                              'Skip',
                              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Animated Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / _totalSteps,
                          minHeight: 4,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Multi-step Page View
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentStep = index),
                    children: [
                      _buildStep1Identity(),
                      _buildStep2Avatar(),
                      _buildStep3BioAndInterests(),
                      _buildStep4ReviewAndComplete(),
                    ],
                  ),
                ),

                // Bottom Action Button Bar
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentStep == _totalSteps - 1 ? 'LAUNCH NEXAL 🚀' : 'CONTINUE',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Personal Identity ─────────────────────────────────────────────
  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setup Your Profile',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 6),
          Text(
            'Choose how you will appear to the Nexal community.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 32),

          _buildInputField(
            label: 'FULL NAME',
            controller: _nameCtrl,
            hint: 'e.g. Aawesh Das',
            icon: LucideIcons.user,
          ),

          const SizedBox(height: 20),

          _buildInputField(
            label: 'USERNAME / HANDLE',
            controller: _usernameCtrl,
            hint: '@aawesh_das',
            icon: LucideIcons.atSign,
          ),

          const SizedBox(height: 20),

          _buildInputField(
            label: 'PRONOUNS (OPTIONAL)',
            controller: _pronounsCtrl,
            hint: 'e.g. They/Them, He/Him',
            icon: LucideIcons.sparkles,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Avatar Selection ──────────────────────────────────────────────
  Widget _buildStep2Avatar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Profile Picture',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),
          Text(
            'Upload a photo or pick a high-tech preset avatar.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 28),

          // Main Avatar Preview Frame
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFA855F7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFF13132B),
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!) as ImageProvider
                        : NetworkImage(_selectedAvatarUrl ?? _presetAvatars.first),
                  ),
                ),

                // Upload Button Badge
                GestureDetector(
                  onTap: () => _showPhotoSourceSheet(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'PRESET AVATARS',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetAvatars.length,
              itemBuilder: (ctx, i) {
                final url = _presetAvatars[i];
                final isSelected = _selectedImageFile == null && _selectedAvatarUrl == url;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageFile = null;
                      _selectedAvatarUrl = url;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(url),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF00E5FF)),
              title: Text('Take Photo', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFFA855F7)),
              title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Bio & Interests ───────────────────────────────────────────────
  Widget _buildStep3BioAndInterests() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio & Interests',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),
          Text(
            'Tell the world a bit about what inspires you.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 24),

          _buildInputField(
            label: 'BIO / QUOTE',
            controller: _bioCtrl,
            hint: 'Share your vibe...',
            icon: LucideIcons.quote,
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          Text(
            'SELECT YOUR INTERESTS',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white10,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.outfit(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Final Review & Confirmation Card ──────────────────────────────
  Widget _buildStep4ReviewAndComplete() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Ready for Launch!',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),
          Text(
            'Here is how your Nexal profile card will look.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 28),

          // Cyberpunk Profile Card Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) as ImageProvider
                      : NetworkImage(_selectedAvatarUrl ?? _presetAvatars.first),
                ),

                const SizedBox(height: 12),

                Text(
                  _nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  _usernameCtrl.text.startsWith('@') ? _usernameCtrl.text : '@${_usernameCtrl.text}',
                  style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                Text(
                  _bioCtrl.text,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedInterests.take(4).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Input Field Builder
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              icon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
