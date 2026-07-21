import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../theme/cached_styles.dart';

class QuantumArcMenu extends StatefulWidget {
  final String activeTab;
  final Function(String) onTabChange;
  final VoidCallback onCameraOpen;
  final VoidCallback onSearchOpen;

  const QuantumArcMenu({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.onCameraOpen,
    required this.onSearchOpen,
  });

  @override
  State<QuantumArcMenu> createState() => _QuantumArcMenuState();
}

class _QuantumArcMenuState extends State<QuantumArcMenu>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late AnimationController _glowController;
  late AnimationController _labelController;
  double _scrollOffset = 0.0;
  int _centerIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(
      'home',
      'HOME',
      LucideIcons.home,
      imagePath: 'assets/nav_icons/home.png',
    ),
    _NavItem(
      'feels',
      'REEL',
      LucideIcons.play,
      imagePath: 'assets/nav_icons/reel.png',
    ),
    _NavItem(
      'video',
      'VIDEOS',
      LucideIcons.tv,
      imagePath: 'assets/nav_icons/Long Video.png',
    ),
    _NavItem(
      'profile',
      'PROFILE',
      LucideIcons.user,
      imagePath: 'assets/nav_icons/profile.png',
    ),
    _NavItem(
      'camera',
      'CAMERA',
      LucideIcons.camera,
      imagePath: 'assets/nav_icons/Camera.png',
    ),
    _NavItem('search', 'SEARCH', LucideIcons.search),
    _NavItem('ai', 'NEXAL AI', LucideIcons.cpu),
    _NavItem('arcade', 'ARCADE', LucideIcons.gamepad2),
    _NavItem(
      'messages',
      'MESSAGE',
      LucideIcons.messageSquare,
      imagePath: 'assets/nav_icons/Message.png',
    ),
    _NavItem(
      'gallery',
      'GALLERY',
      LucideIcons.image,
      imagePath: 'assets/nav_icons/Gallery.png',
    ),
    _NavItem(
      'maps',
      'MAPS',
      LucideIcons.map,
      imagePath: 'assets/nav_icons/map.png',
    ),
  ];

  String _displayLabel = '';
  String _targetLabel = '';

  static const _scrambleChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%&';
  final Random _rng = Random(); // Cached — avoid allocation per tick

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(_onScrollTick);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_onLabelTick);

    _centerIndex = _items.indexWhere((i) => i.id == widget.activeTab);
    if (_centerIndex < 0) _centerIndex = 0;
    _scrollOffset = _centerIndex.toDouble();
    _scrollController.value = _scrollOffset;

    _targetLabel = _items[_centerIndex].label;
    _displayLabel = _targetLabel;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glowController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _updateCenterIndex() {
    int newIndex =
        (_scrollOffset.round() % _items.length + _items.length) % _items.length;

    if (_centerIndex != newIndex) {
      _centerIndex = newIndex;
      HapticFeedback.lightImpact();
    }

    if (_targetLabel != _items[_centerIndex].label) {
      _targetLabel = _items[_centerIndex].label;
      _labelController.forward(from: 0);
    }
  }

  void _onScrollTick() {
    if (_scrollController.isAnimating) {
      setState(() {
        _scrollOffset = _scrollController.value;
        _updateCenterIndex();
      });
    }
  }

  void _onLabelTick() {
    final progress = _labelController.value;
    final targetLen = _targetLabel.length;
    final revealCount = (progress * targetLen).ceil();

    String result = '';
    for (int i = 0; i < targetLen; i++) {
      if (i < revealCount) {
        result += _targetLabel[i];
      } else {
        result += _scrambleChars[_rng.nextInt(_scrambleChars.length)];
      }
    }
    setState(() => _displayLabel = result);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _scrollController.stop();
    setState(() {
      _scrollOffset -= details.delta.dx / 120; // Smoothness factor
      _scrollController.value = _scrollOffset;
      _updateCenterIndex();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Match the delta divisor from onPanUpdate
    final velocity = -details.velocity.pixelsPerSecond.dx / 120;

    // Project target based on velocity
    final projectedDest = _scrollOffset + (velocity * 0.2);
    final targetOffset = projectedDest.roundToDouble();

    // Create a critically damped spring simulation
    final spring = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: 80.0, // Tension of the spring (lower = softer snap)
      ratio:
          1.0, // Damping ratio (1.0 = critically damped, smooth settle without bounce)
    );

    final simulation = SpringSimulation(
      spring,
      _scrollOffset,
      targetOffset,
      velocity,
    );
    _scrollController.animateWith(simulation);
  }

  void _selectItem(int index) {
    HapticFeedback.mediumImpact();
    final item = _items[index];
    if (item.id == 'camera') {
      widget.onCameraOpen();
    } else if (item.id == 'search') {
      widget.onSearchOpen();
    } else {
      widget.onTabChange(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final arcCenterX = size.width / 2;
    final arcCenterY = size.height * 0.6;
    const arcRadiusX = 220.0;
    const arcRadiusY = 80.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Holographic label
            Positioned(
              top: arcCenterY - 200,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayLabel,
                      style: CachedStyles.outfitW700Size28L6White.copyWith(
                        shadows: [
                          Shadow(
                            color: AppTheme.cyan500.withValues(alpha: 0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.cyan500.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // The Arc Track (decorative ellipse)
            Positioned(
              top: arcCenterY - arcRadiusY,
              left: arcCenterX - arcRadiusX,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  final glowOpacity = 0.1 + _glowController.value * 0.15;
                  return CustomPaint(
                    size: const Size(arcRadiusX * 2, arcRadiusY * 2),
                    painter: _ArcTrackPainter(opacity: glowOpacity),
                  );
                },
              ),
            ),

            // Arc Items
            ...List.generate(_items.length, (i) {
              final double rawOffset = i - _scrollOffset;
              final double halfLength = _items.length / 2.0;
              final double offset = ((rawOffset + halfLength) % _items.length) - halfLength;
              final angle = offset * (2 * pi / _items.length);

              // Position on ellipse
              final x = arcCenterX + sin(angle) * arcRadiusX;
              final y = arcCenterY + cos(angle) * arcRadiusY * 0.3;

              // Depth: items at front are larger
              final depthFactor = cos(angle);
              final scale = 0.5 + depthFactor * 0.5;
              final opacity = (0.2 + depthFactor * 0.8).clamp(0.0, 1.0);

              final isCentered = (offset.abs() < 0.5);

              return Positioned(
                left: x - 40,
                top: y - 40,
                child: RepaintBoundary(
                  child: Transform.scale(
                    scale: isCentered ? 1.4 : scale,
                    child: Opacity(
                      opacity: isCentered ? 1.0 : opacity,
                      child: GestureDetector(
                        onTap: () => _selectItem(i),
                        child: _ArcItemWidget(
                          item: _items[i],
                          isCentered: isCentered,
                          glowAnimation: _glowController,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final String? imagePath;
  const _NavItem(this.id, this.label, this.icon, {this.imagePath});
}

class _ArcItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isCentered;
  final AnimationController glowAnimation;

  const _ArcItemWidget({
    required this.item,
    required this.isCentered,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, _) {
        final glowIntensity = isCentered
            ? 0.4 + glowAnimation.value * 0.4
            : 0.0;

        return Container(
          width: isCentered ? 80 : 60,
          height: isCentered ? 80 : 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isCentered
                ? [
                    BoxShadow(
                      color: AppTheme.cyan500.withValues(
                        alpha: glowIntensity * 0.8,
                      ),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.cyan500.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.imagePath != null)
                Image.asset(
                  item.imagePath!,
                  width: isCentered ? 36 : 24,
                  height: isCentered ? 36 : 24,
                )
              else
                Icon(
                  item.icon,
                  color: isCentered ? Colors.white : Colors.white70,
                  size: isCentered ? 30 : 22,
                ),
              const SizedBox(height: 2),
              Text(
                item.id.toUpperCase(),
                style: isCentered
                    ? CachedStyles.outfitBoldSize9L1_5Cyan
                    : CachedStyles.outfitW400Size9L1_5White54,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcTrackPainter extends CustomPainter {
  final double opacity;
  _ArcTrackPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = AppTheme.cyan500.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(rect, paint);

    // Inner track
    final innerRect = rect.deflate(15);
    paint.color = AppTheme.purple500.withValues(alpha: opacity * 0.5);
    paint.strokeWidth = 1.0;
    canvas.drawOval(innerRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcTrackPainter old) => old.opacity != opacity;
}
