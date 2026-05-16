import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _boostController;
  final List<Node> _nodes = [];
  final List<EnergyPulse> _pulses = [];
  final math.Random _random = math.Random();
  final int _nodeCount = 150;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Arbitrary, drives the tick
    )..repeat();

    _boostController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slow down duration
      value: 1.0, // Start fully boosted
    );

    // Speed boost for first 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _boostController.animateTo(0.0, curve: Curves.easeInOut);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nodes.isEmpty) {
      _initNodes(MediaQuery.of(context).size);
    }
  }

  void _initNodes(Size size) {
    _nodes.clear();
    for (int i = 0; i < _nodeCount; i++) {
      final layer = _random.nextInt(3);
      final speed = 0.5 + layer * 0.3; // Layer based speed

      _nodes.add(
        Node(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          vx: (_random.nextDouble() - 0.5) * speed,
          vy: (_random.nextDouble() - 0.5) * speed,
          layer: layer,
          connections: [],
        ),
      );
    }

    // Pre-calculate connections (static graph structure, dynamic distances)
    // To match React logic, we just check distances in Paint,
    // but React code had a 'connections' array.
    // We'll stick to dynamic distance check for performance in Flutter
    // or implement a spatial grid if needed.
    // For 150 nodes, N^2 is 22500 checks, which is fine for 60fps in Dart usually.
  }

  @override
  void dispose() {
    _controller.dispose();
    _boostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _boostController]),
      builder: (context, child) {
        // Randomly add energy pulse
        if (_random.nextDouble() > 0.98) {
          final size = MediaQuery.of(context).size;
          _pulses.add(
            EnergyPulse(
              x: size.width / 2,
              y: size.height / 2,
              maxRadius: 300 + _random.nextDouble() * 200,
            ),
          );
        }

        return CustomPaint(
          painter: ParticlePainter(
            nodes: _nodes,
            pulses: _pulses,
            animValue: _controller.value,
            boostValue: _boostController.value,
            random: _random, // Pass random for flicker effects
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Node {
  double x, y;
  double vx, vy;
  int layer;
  List<int> connections;

  Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.layer,
    required this.connections,
  });
}

class EnergyPulse {
  double x, y;
  double radius = 0;
  double maxRadius;
  bool isDead = false;

  EnergyPulse({required this.x, required this.y, required this.maxRadius});
}

class ParticlePainter extends CustomPainter {
  final List<Node> nodes;
  final List<EnergyPulse> pulses;
  final double animValue;
  final double boostValue;
  final math.Random random;

  ParticlePainter({
    required this.nodes,
    required this.pulses,
    required this.animValue,
    required this.boostValue,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Update Pulses
    for (var pulse in pulses) {
      if (pulse.isDead) continue;
      pulse.radius += 2.0;
      if (pulse.radius >= pulse.maxRadius) {
        pulse.isDead = true;
        continue;
      }

      final opacity = 1.0 - (pulse.radius / pulse.maxRadius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppTheme.purple500.withValues(alpha: opacity * 0.3);

      canvas.drawCircle(Offset(pulse.x, pulse.y), pulse.radius, paint);
    }
    pulses.removeWhere((p) => p.isDead);

    // 2. Update and Draw Nodes
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // Move
      // Speed multiplier: 1.0 (normal) to 5.0 (boosted)
      double speedMultiplier = 1.0 + (boostValue * 4.0);
      node.x += node.vx * speedMultiplier;
      node.y += node.vy * speedMultiplier;

      // Bounce
      if (node.x < 0 || node.x > size.width) {
        node.vx *= -1;
        node.x = node.x.clamp(0.0, size.width);
      }
      if (node.y < 0 || node.y > size.height) {
        node.vy *= -1;
        node.y = node.y.clamp(0.0, size.height);
      }

      // Draw Connections
      // Optimization: Only check nodes with higher index to avoid double drawing
      // Limit connections to avoid clutter? React code had explicit connection list.
      // Let's use distance check for "dynamic" connections like the visual.
      for (int j = i + 1; j < nodes.length; j++) {
        final target = nodes[j];
        final dx = node.x - target.x;
        final dy = node.y - target.y;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 100) {
          // Threshold
          final opacity = (1.0 - (dist / 100)) * 0.5;

          Color color;
          if (node.layer == 0) {
            // Purple/Pink
            color = Color.lerp(AppTheme.purple500, AppTheme.pink500, 0.5)!;
          } else if (node.layer == 1) {
            // Blue/Green (Cyan)
            color = Color.lerp(AppTheme.blue500, AppTheme.cyan500, 0.5)!;
          } else {
            // Pink/Purple
            color = Color.lerp(AppTheme.pink500, AppTheme.purple500, 0.5)!;
          }

          final linePaint = Paint()
            ..color = color.withValues(alpha: opacity)
            ..strokeWidth = 1.0;

          canvas.drawLine(
            Offset(node.x, node.y),
            Offset(target.x, target.y),
            linePaint,
          );

          // 3. Data Flow Particle on line (randomly)
          if (random.nextDouble() > 0.99) {
            final t = random.nextDouble();
            // Correct logic: Lerp
            final lx = node.x + (target.x - node.x) * t;
            final ly = node.y + (target.y - node.y) * t;

            final particlePaint = Paint()
              ..color = Colors.white.withValues(alpha: 0.8)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(Offset(lx, ly), 1.5, particlePaint);
          }
        }
      }

      // Draw Node Dot
      double radius =
          2.0 + node.layer + math.sin(animValue * 2 * math.pi + i) * 0.5;

      Paint nodePaint = Paint()..style = PaintingStyle.fill;
      if (node.layer == 0) {
        nodePaint.color = AppTheme.purple500.withValues(alpha: 0.8);
      } else if (node.layer == 1) {
        nodePaint.color = AppTheme.blue500.withValues(alpha: 0.8);
      } else {
        nodePaint.color = AppTheme.pink500.withValues(alpha: 0.8);
      }

      // Glow
      canvas.drawCircle(
        Offset(node.x, node.y),
        radius * 2,
        nodePaint..color = nodePaint.color.withValues(alpha: 0.3),
      );
      // Core
      canvas.drawCircle(
        Offset(node.x, node.y),
        radius,
        nodePaint..color = nodePaint.color.withValues(alpha: 1.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
