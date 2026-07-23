import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HairParticle> _particles = [];
  final math.Random _random = math.Random();
  final int _maxParticles = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < _maxParticles; i++) {
        _particles.add(_createParticle(size, randomY: true));
      }
    }
  }

  _HairParticle _createParticle(Size size, {bool randomY = false}) {
    // Spawn particles in the bottom half / neck area of the cat representation
    final double x = size.width * 0.15 + _random.nextDouble() * size.width * 0.7;
    final double y = randomY 
        ? _random.nextDouble() * size.height 
        : size.height + _random.nextDouble() * 50;

    // Distribute colors matching the cat's fur and accents in 11.png
    Color color;
    final double r = _random.nextDouble();
    if (r < 0.60) {
      color = Colors.white; // Main white/silver neck fur
    } else if (r < 0.85) {
      color = const Color(0xFF80DEEA); // Luminous teal reflection matching background streaks
    } else {
      color = const Color(0xFFFBBF24); // Warm amber/yellow eye and inner ear accents
    }

    final double speed = 1.0 + _random.nextDouble() * 1.8;

    return _HairParticle(
      x: x,
      y: y,
      speed: speed,
      size: 1.2 + _random.nextDouble() * 1.8,
      color: color,
      opacity: 0.15 + _random.nextDouble() * 0.55,
      angle: -math.pi / 2, // Pointing upwards initially
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
          final size = MediaQuery.of(context).size;
          
          // Update particles
          for (int i = 0; i < _particles.length; i++) {
            final p = _particles[i];
            
            // Cat fur flow physics alignment field:
            // Cat's head is roughly situated around x = 0.45 * width, y = 0.35 * height.
            final double headX = size.width * 0.45;
            final double headY = size.height * 0.35;
            
            // Distance vector to cat's head region
            final double dx = headX - p.x;
            
            double targetAngle = -math.pi / 2; // Flows straight up by default
            
            if (p.y > headY) {
              // Below head (neck region): flow up along the neck profile, curving slightly inward
              targetAngle = -math.pi / 2 + (dx / size.width) * 0.45;
            } else {
              // Above head: flow outward to mimic whisker curves and ears tips outward angles
              targetAngle = -math.pi / 2 + (p.x < headX ? -0.4 : 0.4);
            }
            
            // Smoothly interpolate angle to prevent sharp direction changes
            p.angle = p.angle * 0.88 + targetAngle * 0.12;
            
            // Translate position along angle vector
            p.x += math.cos(p.angle) * p.speed;
            p.y += math.sin(p.angle) * p.speed;
            
            // Fade out as they reach the top screen edge
            if (p.y < size.height * 0.12) {
              p.opacity -= 0.015;
            }
            
            // Reset if out of viewport bounds or fully faded
            if (p.y < 0 || p.x < 0 || p.x > size.width || p.opacity <= 0) {
              _particles[i] = _createParticle(size);
            }
          }

          return CustomPaint(
            painter: _CatHairParticlePainter(particles: _particles),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _HairParticle {
  double x, y;
  double speed;
  double size;
  Color color;
  double opacity;
  double angle;

  _HairParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.opacity,
    required this.angle,
  });
}

class _CatHairParticlePainter extends CustomPainter {
  final List<_HairParticle> particles;

  _CatHairParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.opacity <= 0) continue;
      
      // Calculate trailing path to draw hair/droplet shape
      final double tailX = p.x - math.cos(p.angle) * (p.speed * 8.0);
      final double tailY = p.y - math.sin(p.angle) * (p.speed * 8.0);
      
      // Paint the hair stroke/capsule
      final strokePaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..strokeWidth = p.size
        ..strokeCap = StrokeCap.round;
        
      canvas.drawLine(Offset(p.x, p.y), Offset(tailX, tailY), strokePaint);
      
      // Add a bright core spot at the tip
      paint.color = p.color.withValues(alpha: math.min(1.0, p.opacity * 1.3));
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CatHairParticlePainter oldDelegate) => true;
}
