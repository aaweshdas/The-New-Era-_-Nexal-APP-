import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RiverOfTimeGallery extends StatefulWidget {
  final List<String> images;
  final Function(String, int)? onImageTap;

  const RiverOfTimeGallery({super.key, required this.images, this.onImageTap});

  @override
  State<RiverOfTimeGallery> createState() => _RiverOfTimeGalleryState();
}

class _RiverOfTimeGalleryState extends State<RiverOfTimeGallery> {
  late ScrollController _scrollController;
  final double _itemSpacing = 220.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    // The entire scrollable height needs to be long enough to fit all items.
    // Each item takes up '_itemSpacing' amount of vertical scrolling distance.
    // We add extra buffer so the last item can reach the bottom.
    final double maxScrollExtent =
        widget.images.length * _itemSpacing +
        MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Background Image Layer (Cinematic Cosmic River)
        Positioned.fill(
          child: Image.asset(
            'assets/gallery/river_of_time_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // Deep Space Overlay to ensure UI text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8), // Singularity is darker
                  Colors.transparent,
                  Colors.black.withOpacity(0.5), // Foreground grounding
                ],
              ),
            ),
          ),
        ),

        // Scrollable Area (Invisible List that provides the physics engine)
        Positioned.fill(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: 1, // Single gigantic invisible area
            itemBuilder: (context, index) {
              return SizedBox(height: maxScrollExtent);
            },
          ),
        ),

        // Rendering the Gallery Items overlay
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Size size = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final double currentScrollOffset = _scrollController.hasClients
                  ? _scrollController.offset
                  : 0.0;

              return Stack(
                // We map backwards so the earlier images (bottom foreground)
                // render ON TOP of the later images (upper background/singularity)
                children: List.generate(widget.images.length, (index) {
                  return _buildInterpolatedGalleryCard(
                    context,
                    index,
                    size,
                    currentScrollOffset,
                  );
                }).reversed.toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInterpolatedGalleryCard(
    BuildContext context,
    int index,
    Size size,
    double scrollOffset,
  ) {
    // Position of this item in the "river flow".
    // A value of 0 means it's exactly at the singularity start point (top far away).
    // As it increases, it flows down towards the user.
    // We normalize it based on screen height so the S-curve feels consistent.
    final double itemDistance = (index * _itemSpacing) - scrollOffset;

    // Offset the starting appearance point to somewhere high up.
    // t = 0 (far away in singularity) -> t = 1 (exiting screen at bottom)
    // t > 1 means it's passed the screen.
    // t < 0 means it hasn't spawned yet.
    double t = 1.0 - ((itemDistance + size.height * 0.4) / (size.height * 1.5));

    // Cull items that are off-screen or faded out
    if (t < -0.1 || t > 1.2) {
      return const SizedBox.shrink();
    }

    // Y mapping: Start near top (0.1) and ease out past the bottom (1.2)
    // We use a curve (t*t) so it seems to accelerate towards the camera
    double yPos = ui.lerpDouble(
      size.height * 0.05,
      size.height * 1.1,
      Curves.easeInCubic.transform(t.clamp(0.0, 1.0)),
    )!;

    // X mapping: A sweeping S-Curve.
    // Starts centered in singularity, sweeps right, then left, then exits.
    double sinWave = math.sin(t * math.pi * 3.5); // 1.5 full weaves
    double maxWidthSwerve = size.width * 0.35;
    double xPos = (size.width / 2) + (sinWave * maxWidthSwerve);

    // Scale mapping (Depth perspective): Starts tiny, ends huge.
    double scale = ui.lerpDouble(
      0.05,
      1.8,
      Curves.easeInQuint.transform(t.clamp(0.0, 1.0)),
    )!;

    // Opacity mapping: Fade in slowly from singularity, fade out quickly as passing camera
    double opacity = 1.0;
    if (t < 0.15) {
      opacity = t / 0.15; // Slow fade in from 0..0.15
    } else if (t > 0.9) {
      opacity = (1.0 - t) / 0.1; // Quick fade out past 0.9
    }
    opacity = opacity.clamp(0.0, 1.0);

    // Rotation: tilt as it moves along the curve
    double zRotation = math.cos(t * math.pi * 3.5) * 0.2; // Bank into the turn

    // Determine the card dimensions.
    final cardWidth = size.width * 0.45;
    final cardHeight = cardWidth * 1.4;

    return Positioned(
      left: xPos - (cardWidth / 2),
      top: yPos - (cardHeight / 2),
      width: cardWidth,
      height: cardHeight,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..scale(scale, scale)
            ..rotateZ(zRotation),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              if (widget.onImageTap != null) {
                widget.onImageTap!(widget.images[index], index);
              }
            },
            child: Hero(
              tag: 'gallery_image_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.cover,
                    // If image fails to load, show a sleek fallback
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
