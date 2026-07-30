import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'full_screen_image_view.dart';

class ImmersiveDomeGalleryView extends StatefulWidget {
  final String title;

  const ImmersiveDomeGalleryView({super.key, required this.title});

  @override
  State<ImmersiveDomeGalleryView> createState() =>
      _ImmersiveDomeGalleryViewState();
}

class _ImmersiveDomeGalleryViewState extends State<ImmersiveDomeGalleryView> {
  int _crossAxisCount = 3;
  bool _isGrayscale = true;
  bool _isSearching = false;

  final List<String> _baseUrls = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBBD3UQLhoB-HzYhJoQr_7QONHMwP4U-I-munacTq2iUZ940b0CvKVgSoAyI9l__uNo8ccXUHlFGsDcGj8k_o4aAmW6TBkkr9Tlwp_HflsQSUEx3NDEcQavxkOrNnBj8hy-xPq9_sTumBnCdczRKA7rXNy2cb213sFGE47UUom0qHZmY_jbX_oZEjTvUOzvLkwRTLNlixY03GlaqNH3XfXvRpCe-HJARec6OeRSjSWXk7SAA3kw4BtHNhNPSvb0VF1IpR28Pe5zNS4m',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA0GETcODSxh-nCHqbvpj95PvdrmnYw3Wzvj-fnbzjQcWuMIsdf2Ne-Nl_oaGRuzl_-Qg-2bfepWRMha2VVEVHosOW8igqrr-XxrJjLfVtih8J4ZxINAW3XlUpquQgkVjjs2LBqJNGOlywbq-3ROdJhTBUaH331rEAhdpnqefZ5MiOmsGaaD7KnFVvSqHULB-hRYgGrxa7esFD7yXeUYQn9Wyelrzv-RVlzfrv0ZMzlDFGEeRPgbqlXDxwSPoEHViQngc2Y_GEqAwhk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBSnw_6oG-Vm103uQ9BS0pPII5DQQVDoqwKGvP4FPTkyQl_1tBDUhfrWG-Z0TTSeRA7vJKsWaAZ6NEMboQdm_5WpR3xqSekEuE5-7X61FYi4NvhmHxpwP2o68a2ojoFuf3nJxcjkkJo-2OC-lur2GVdGLAxsMGclmMXAQfh75UEr-k_h7pxwR9tpi3AQ2rTQpTw9rv95KZSZyL9Ssr0lluRpD03EmvctEmbA0djjlNhfcUgGOiub5_l2LVj9Xnpd-wJjhs0P_2U27L4',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB_2ErhXmHxO18uF67TeMtnWClgG1UIHG4CrVKyPAitogpyVCK0FhE_8gQ2o-wUsWdKuwmTJuXKwbSTyCpLN-C2c7_pLa9pMxpIt8TBHVawpYd7p72-FdwBPU_4hXZoKlCUsK8KlInh6P6cqQiWz9Ak2dcOJVx5SpWNpkZEB5lxMK9P2JEIYcsKCCOfclsd_-b8Zyxhr8RQebZp4dCCg6gzLLdKiLsOkvZO84u0G9qy8s_XQDhX7m8mfW4sFCZM5VMB5_x0ANJPUQgi',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDL4Y-Ca-QlrOocWYnqgRglGdUON0XdiTlH5H-WvtLpHEQHIbSt1cSZvpQAZIc7MpyXn3FINBESfBrnbhab8YXnNLwrraHfTDuKept7S3TateShgxKP_HNRa1JSAlsrKklQ79Kcw2h242zk8tNdQrKYXAfb5bV5DIiLhMHUHVcpPrG0b8yGvJE5Rw5ySpRiKMvYxzCmBzbm7N-Iy5DDPwSqbz2KXKmG7Z6mxd1nBwSYBr-DHjdelYTcvLnhJg72YEb2Ip6BchrT5kPa',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDWe1KrbP59DSAUVkAtxxpE3_qgpngD2TvhuTpyYld-s60-va6ucvlUdPYh4uClaDiF7Tk4SGHRySvHMheFaMTW00Oy2_KmaANV7LcAtckr5lMpBFxcfJxNITsgdkGfXgNq3HD45hNh1qqLdFMIDn0Q3FXWnwbGhLbRdRnKfCqXfc1VF4vVCtY2umOXOzW1vbQMkNAsIDxeiI8xNCEcT4_Mku5BEUDKT9QVIay3W3sywaelXRVOSrKHzqBOI8bvGmv6UG2I3MRpNvxD',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDJ_eunzzJ2g8AV1Z9QUmJNIwKPclS3ap8Xe9oMw9ij66EtCCW5qL6MUllYalST6lbrWmVbxmviGUkUaxNPdUAqjbb_mVtge6cVzfYKBfD8dW6QIjV6HvyQyjMiogC27XtDozaNLZ31APQRg48V3nCLuaWyPGhHo7dJIlQG4Gh2XxbcmnLrh3ksCUCKUAfSn-2jmkFEfEZ03ihn-SBxA9DDfahLxyW813JEQCaWS7YQLDdPd81sbxb-oulDZpRD1uLmQrp6jhKYuoSB',
  ];
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = List.generate(36, (index) => _baseUrls[index % _baseUrls.length]);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _urls.insert(0, pickedFile.path);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Memory added to gallery!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF00E5FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/gallery/timeline_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay for readability
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),

            // 2D Photo Grid
            Positioned.fill(
              child: GridView.builder(
                padding: const EdgeInsets.only(
                  top: 70, // Space for top nav floating pods
                  bottom: 90, // Space for bottom nav
                  left: 16,
                  right: 16,
                ),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _urls.length,
                itemBuilder: (context, index) {
                  return _buildPhotoTile(index);
                },
              ),
            ),

            // Vignette / Blur mask
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Top Nav: Separated Floating Glass Pod Windows
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: _buildTopNav(),
            ),

            // Bottom Nav
            Positioned(
              bottom: 20,
              left: 32,
              right: 32,
              child: Center(child: _buildBottomNav()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Row(
      children: [
        // Pod 1: Standalone Floating Back Button (Arrow)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white70,
                  size: 19,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Pod 2: Standalone Floating Title Pod
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: _isSearching
                      ? TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search collection...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          autofocus: true,
                        )
                      : Text(
                          widget.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rye(
                            color: const Color(0xFF00E5FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              const Shadow(color: Color(0x9900E5FF), blurRadius: 10),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Pod 3: Standalone Floating Search Button
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isSearching ? LucideIcons.x : LucideIcons.search,
                  color: _isSearching ? const Color(0xFF135BEC) : Colors.white70,
                  size: 19,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Pod 4: Standalone Floating Grid Density Toggle Button
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _crossAxisCount == 2 ? LucideIcons.layoutGrid : LucideIcons.grid,
                  color: const Color(0xFF00E5FF),
                  size: 19,
                ),
                onPressed: () {
                  setState(() {
                    _crossAxisCount = _crossAxisCount == 3 ? 2 : 3;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavIconButton(
                icon: Icons.grid_view_rounded,
                isActive: _crossAxisCount == 2,
                onTap: () {
                  setState(() {
                    _crossAxisCount = _crossAxisCount == 3 ? 2 : 3;
                  });
                },
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),
              _NavIconButton(
                icon: Icons.collections_rounded,
                isActive: !_isGrayscale,
                onTap: () {
                  setState(() {
                    _isGrayscale = !_isGrayscale;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    if (index >= _urls.length) return const SizedBox();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageView(
              imageUrl: _urls[index],
              index: index + 5000,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'gallery_image_${index + 5000}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColorFiltered(
              colorFilter: _isGrayscale
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    ),
              child: _urls[index].startsWith('http')
                  ? Image.network(
                      _urls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    )
                  : Image.file(
                      File(_urls[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _NavIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(
            icon,
            color: isActive
                ? const Color(0xFF00E5FF)
                : Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      ),
    );
  }
}
