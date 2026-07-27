import 'dart:math' as math;
import 'package:flutter/material.dart';

enum _ParticleTier { backgroundStar, midstreamRiver, foregroundSparkle }

/// Photorealistic, 3-tiered cosmic fluid particle simulation that flows along
/// the directional curves of cosmic pathway backgrounds (assets/backgrounds/12.jpg).
class ParticleBackground extends StatefulWidget {
  final int maxParticles;
  const ParticleBackground({super.key, this.maxParticles = 110});

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
      duration: const Duration(seconds: 14),
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
      final t = (1.0 - normY) / 0.35;
      return 0.45 + 0.30 * math.sin(t * math.pi / 2);
    } else if (normY > 0.40) {
      final t = (0.65 - normY) / 0.25;
      return 0.75 - 0.30 * math.sin(t * math.pi / 2);
    } else {
      final t = (0.40 - normY) / 0.40;
      return 0.45 - 0.25 * math.sin(t * math.pi / 2);
    }
  }

  /// Evaluates the directional flow angle (in radians) along the cosmic pathway at (x, y).
  double _getFlowAngle(double x, double y, Size size) {
    final normY = (y / size.height).clamp(0.0, 1.0);
    const sampleDist = 0.02;
    final y1 = (normY - sampleDist).clamp(0.0, 1.0);
    final y2 = (normY + sampleDist).clamp(0.0, 1.0);

    final x1 = _getPathX(y1) * size.width;
    final x2 = _getPathX(y2) * size.width;

    final dy = (y1 - y2) * size.height;
    final dx = x1 - x2;

    return math.atan2(dy, dx);
  }

  _CosmicParticle _createParticle(Size size, {bool randomY = false}) {
    final double normY = randomY
        ? 0.02 + _random.nextDouble() * 0.96
        : 0.86 + _random.nextDouble() * 0.12;

    final double pathCenterX = _getPathX(normY) * size.width;

    // Assign particle tier for multi-depth parallax
    final double tierRoll = _random.nextDouble();
    _ParticleTier tier;
    if (tierRoll < 0.40) {
      tier = _ParticleTier.backgroundStar;
    } else if (tierRoll < 0.85) {
      tier = _ParticleTier.midstreamRiver;
    } else {
      tier = _ParticleTier.foregroundSparkle;
    }

    double spreadMultiplier;
    double speed;
    double pSize;
    double baseOpacity;

    switch (tier) {
      case _ParticleTier.backgroundStar:
        spreadMultiplier = 0.35; // Fanned wide across background space
        speed = 0.3 + _random.nextDouble() * 0.5;
        pSize = 0.6 + _random.nextDouble() * 0.8;
        baseOpacity = 0.15 + _random.nextDouble() * 0.30;
        break;
      case _ParticleTier.midstreamRiver:
        spreadMultiplier = 0.18; // Focused strictly inside the river channel
        speed = 0.8 + _random.nextDouble() * 1.2;
        pSize = 1.2 + _random.nextDouble() * 1.2;
        baseOpacity = 0.30 + _random.nextDouble() * 0.45;
        break;
      case _ParticleTier.foregroundSparkle:
        spreadMultiplier = 0.22; // Floating foreground lens sparkles
        speed = 1.4 + _random.nextDouble() * 1.6;
        pSize = 2.4 + _random.nextDouble() * 2.2;
        baseOpacity = 0.50 + _random.nextDouble() * 0.45;
        break;
    }

    final double spread = spreadMultiplier * size.width;
    final double x = pathCenterX + (_random.nextDouble() * 2.0 - 1.0) * spread;
    final double y = normY * size.height;

    // Dynamic color selection matching Cosmic Pathway image color zones
    Color color;
    final double cRoll = _random.nextDouble();
    if (normY > 0.65) {
      // Lower stream: Amber gold & Cyan
      color = cRoll < 0.50 ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);
    } else if (normY > 0.35) {
      // Mid stream: Electric Magenta & Violet
      color = cRoll < 0.50 ? const Color(0xFFEC4899) : const Color(0xFFC084FC);
    } else {
      // Upper burst: Luminous Cyan & Brilliant White
      color = cRoll < 0.60 ? const Color(0xFF38BDF8) : Colors.white;
    }

    final double initialAngle = _getFlowAngle(x, y, size);

    return _CosmicParticle(
      x: x,
      y: y,
      speed: speed,
      size: pSize,
      color: color,
      opacity: baseOpacity,
      maxOpacity: baseOpacity,
      angle: initialAngle,
      tier: tier,
      phase: _random.nextDouble() * math.pi * 2,
      wobbleFreq: 0.8 + _random.nextDouble() * 1.4,
      wobbleAmp: 0.2 + _random.nextDouble() * 0.6,
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

          final double time = _controller.value * math.pi * 2;

          // Update fluid particle dynamics
          for (int i = 0; i < _particles.length; i++) {
            final p = _particles[i];

            final double targetAngle = _getFlowAngle(p.x, p.y, size);
            p.angle = p.angle * 0.85 + targetAngle * 0.15;

            // Organic wave turbulence perpendicular to angle
            final double perpAngle = p.angle + math.pi / 2;
            final double wave = math.sin(p.y * 0.015 + time * p.wobbleFreq + p.phase) * p.wobbleAmp;

            p.x += math.cos(p.angle) * p.speed + math.cos(perpAngle) * wave;
            p.y += math.sin(p.angle) * p.speed + math.sin(perpAngle) * wave;

            // Twinkle pulsation for background stars & sparkles
            if (p.tier != _ParticleTier.midstreamRiver) {
              final twinkle = 0.70 + 0.30 * math.sin(time * 2.0 + p.phase);
              p.opacity = (p.maxOpacity * twinkle).clamp(0.0, 1.0);
            }

            // Fade out as particles exit upper burst boundary
            if (p.y < size.height * 0.08 || p.x < size.width * 0.03) {
              p.opacity -= 0.03;
            }

            // Reset when out of bounds or fully faded
            if (p.y <= 0 || p.y > size.height || p.x < 0 || p.x > size.width || p.opacity <= 0) {
              _particles[i] = _createParticle(size);
            }
          }

          return CustomPaint(
            painter: _RealisticCosmicPathwayPainter(
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
  double maxOpacity;
  double angle;
  _ParticleTier tier;
  double phase;
  double wobbleFreq;
  double wobbleAmp;

  _CosmicParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.opacity,
    required this.maxOpacity,
    required this.angle,
    required this.tier,
    required this.phase,
    required this.wobbleFreq,
    required this.wobbleAmp,
  });
}

class _RealisticCosmicPathwayPainter extends CustomPainter {
  final List<_CosmicParticle> particles;
  final double animValue;

  _RealisticCosmicPathwayPainter({
    required this.particles,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()..style = PaintingStyle.stroke;

    // Render by depth layer: Background -> Midstream -> Foreground Sparkles
    for (int layerIdx = 0; layerIdx < 3; layerIdx++) {
      final targetTier = _ParticleTier.values[layerIdx];

      for (final p in particles) {
        if (p.tier != targetTier || p.opacity <= 0) continue;

        final Color baseColor = p.color;
        final double alpha = p.opacity.clamp(0.0, 1.0);

        if (p.tier == _ParticleTier.backgroundStar) {
          // Micro background twinkling star point
          fillPaint.color = baseColor.withValues(alpha: alpha);
          canvas.drawCircle(Offset(p.x, p.y), p.size * 0.7, fillPaint);
        } else if (p.tier == _ParticleTier.midstreamRiver) {
          // Midstream fluid filament stroke with directional tail
          final double tailLen = p.speed * 8.5;
          final double tailX = p.x - math.cos(p.angle) * tailLen;
          final double tailY = p.y - math.sin(p.angle) * tailLen;

          strokePaint
            ..color = baseColor.withValues(alpha: alpha * 0.80)
            ..strokeWidth = p.size
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(Offset(p.x, p.y), Offset(tailX, tailY), strokePaint);

          fillPaint.color = Colors.white.withValues(alpha: math.min(1.0, alpha * 1.3));
          canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, fillPaint);
        } else {
          // Foreground lens sparkle with soft glow halo & 4-point lens flare
          final double glowRadius = p.size * 2.8;

          // Soft ambient glow halo
          fillPaint.color = baseColor.withValues(alpha: alpha * 0.25);
          canvas.drawCircle(Offset(p.x, p.y), glowRadius, fillPaint);

          // Anamorphic 4-point cross sparkle flare
          if (alpha > 0.35) {
            final double flareLen = p.size * 4.2;
            strokePaint
              ..color = baseColor.withValues(alpha: alpha * 0.65)
              ..strokeWidth = 0.85
              ..strokeCap = StrokeCap.round;

            // Horizontal & Vertical flare arms
            canvas.drawLine(Offset(p.x - flareLen, p.y), Offset(p.x + flareLen, p.y), strokePaint);
            canvas.drawLine(Offset(p.x, p.y - flareLen), Offset(p.x, p.y + flareLen), strokePaint);

            // Diagonal sparkle accents
            final double diagLen = flareLen * 0.50;
            strokePaint
              ..color = baseColor.withValues(alpha: alpha * 0.35)
              ..strokeWidth = 0.5;
            canvas.drawLine(Offset(p.x - diagLen, p.y - diagLen), Offset(p.x + diagLen, p.y + diagLen), strokePaint);
            canvas.drawLine(Offset(p.x - diagLen, p.y + diagLen), Offset(p.x + diagLen, p.y - diagLen), strokePaint);
          }

          // Core bright center spot
          fillPaint.color = Colors.white.withValues(alpha: math.min(1.0, alpha * 1.4));
          canvas.drawCircle(Offset(p.x, p.y), p.size * 0.8, fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticCosmicPathwayPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}
