import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive particle background overlay that flows seamlessly along the
/// directional curves of cosmic pathway backgrounds (assets/backgrounds/12.jpg).
class ParticleBackground extends StatefulWidget {
  final int maxParticles;
  const ParticleBackground({super.key, this.maxParticles = 90});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CosmicParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  Size _cachedSize = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedSize = MediaQuery.of(context).size;
    if (_particles.isEmpty && _cachedSize != Size.zero) {
      for (int i = 0; i < widget.maxParticles; i++) {
        _particles.add(_createParticle(_cachedSize, randomY: true));
      }
    }
  }

  /// Calculates the horizontal X-center of the cosmic pathway S-curve at a given normalized Y (0.0 = top, 1.0 = bottom).
  double _getPathX(double normY) {
    if (normY > 0.65) {
      // Lower curve: from 0.45 at bottom rightwards to 0.75 at y=0.65
      final t = (1.0 - normY) / 0.35;
      return 0.45 + 0.30 * math.sin(t * math.pi / 2);
    } else if (normY > 0.40) {
      // Mid curve: from 0.75 at y=0.65 sweeping leftwards to 0.45 at y=0.40
      final t = (0.65 - normY) / 0.25;
      return 0.75 - 0.30 * math.sin(t * math.pi / 2);
    } else {
      // Upper fan: from 0.45 at y=0.40 sweeping leftwards to 0.20 at y=0.0
      final t = (0.40 - normY) / 0.40;
      return 0.45 - 0.25 * math.sin(t * math.pi / 2);
    }
  }

  /// Evaluates the directional flow angle (in radians) along the cosmic pathway at (x, y).
  double _getFlowAngle(double x, double y, Size size) {
    final normY = (y / size.height).clamp(0.0, 1.0);
    
    // Sample path trajectory slightly above and below
    const sampleDist = 0.02;
    final y1 = (normY - sampleDist).clamp(0.0, 1.0);
    final y2 = (normY + sampleDist).clamp(0.0, 1.0);
    
    final x1 = _getPathX(y1) * size.width;
    final x2 = _getPathX(y2) * size.width;
    
    // Tangent vector pointing UPWARDS along the pathway (from y2 towards y1)
    final dy = (y1 - y2) * size.height;
    final dx = x1 - x2;
    
    return math.atan2(dy, dx);
  }

  _CosmicParticle _createParticle(Size size, {bool randomY = false}) {
    final double normY = randomY
        ? 0.05 + _random.nextDouble() * 0.90
        : 0.85 + _random.nextDouble() * 0.12;

    final double pathCenterX = _getPathX(normY) * size.width;
    // Spread particles across the width of the cosmic river band
    final double spread = (0.16 + _random.nextDouble() * 0.12) * size.width;
    final double x = pathCenterX + (_random.nextDouble() * 2.0 - 1.0) * spread;
    final double y = normY * size.height;

    // Palette aligned to the vibrant stardust in Cosmic Pathway
    Color color;
    final double r = _random.nextDouble();
    if (r < 0.38) {
      color = const Color(0xFF38BDF8); // Luminous cyan / sky blue
    } else if (r < 0.62) {
      color = const Color(0xFFFBBF24); // Radiant amber / gold
    } else if (r < 0.78) {
      color = const Color(0xFFEC4899); // Electric pink / magenta
    } else if (r < 0.90) {
      color = const Color(0xFFC084FC); // Lavender / purple
    } else {
      color = Colors.white;            // Brilliant white core
    }

    final double speed = 0.9 + _random.nextDouble() * 1.6;
    final double initialAngle = _getFlowAngle(x, y, size);

    return _CosmicParticle(
      x: x,
      y: y,
      speed: speed,
      size: 1.2 + _random.nextDouble() * 1.8,
      color: color,
      opacity: 0.20 + _random.nextDouble() * 0.65,
      angle: initialAngle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final size = _cachedSize;
          if (size == Size.zero) return const SizedBox.shrink();

          // Update particle dynamics along the vector flow field
          for (int i = 0; i < _particles.length; i++) {
            final p = _particles[i];

            final double targetAngle = _getFlowAngle(p.x, p.y, size);
            
            // Smoothly interpolate current angle towards pathway flow direction
            p.angle = p.angle * 0.84 + targetAngle * 0.16;

            // Advance particle along calculated directional angle
            p.x += math.cos(p.angle) * p.speed;
            p.y += math.sin(p.angle) * p.speed;

            // Fade out as particles approach the top-left cosmic burst edge
            if (p.y < size.height * 0.12 || p.x < size.width * 0.05) {
              p.opacity -= 0.025;
            }

            // Reset particle when out of bounds or fully faded
            if (p.y <= 0 || p.y > size.height || p.x < 0 || p.x > size.width || p.opacity <= 0) {
              _particles[i] = _createParticle(size);
            }
          }

          return CustomPaint(
            painter: _CosmicPathwayParticlePainter(
              particles: _particles,
              animValue: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _CosmicParticle {
  double x, y;
  double speed;
  double size;
  Color color;
  double opacity;
  double angle;

  _CosmicParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.opacity,
    required this.angle,
  });
}

class _CosmicPathwayParticlePainter extends CustomPainter {
  final List<_CosmicParticle> particles;
  final double animValue;

  _CosmicPathwayParticlePainter({
    required this.particles,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.opacity <= 0) continue;

      // Calculate directional tail vector along motion angle
      final double tailX = p.x - math.cos(p.angle) * (p.speed * 7.5);
      final double tailY = p.y - math.sin(p.angle) * (p.speed * 7.5);

      // Draw flowing stardust velocity stroke
      final strokePaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * 0.85)
        ..strokeWidth = p.size
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(p.x, p.y), Offset(tailX, tailY), strokePaint);

      // Draw bright glowing particle head
      paint.color = p.color.withValues(alpha: math.min(1.0, p.opacity * 1.4));
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPathwayParticlePainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}
