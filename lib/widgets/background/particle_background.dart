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
  }

  @override
  void dispose() {
    _controller.dispose();
    _boostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
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
              random: _random,
            ),
            size: Size.infinite,
          );
        },
      ),
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

  // Pre-allocated paint objects to avoid GC churn
  static final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _linePaint = Paint()..strokeWidth = 1.0;
  static final Paint _particlePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8)
    ..style = PaintingStyle.fill;
  static final Paint _nodePaint = Paint()..style = PaintingStyle.fill;

  // Pre-computed layer colors
  static final Color _layerColor0 = Color.lerp(AppTheme.purple500, AppTheme.pink500, 0.5)!;
  static final Color _layerColor1 = Color.lerp(AppTheme.blue500, AppTheme.cyan500, 0.5)!;
  static final Color _layerColor2 = Color.lerp(AppTheme.pink500, AppTheme.purple500, 0.5)!;

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
      _pulsePaint.color = AppTheme.purple500.withValues(alpha: opacity * 0.3);
      canvas.drawCircle(Offset(pulse.x, pulse.y), pulse.radius, _pulsePaint);
    }
    pulses.removeWhere((p) => p.isDead);

    // 2. Build spatial grid for O(N) neighbour lookups instead of O(N²)
    const double cellSize = 100.0;
    final int gridCols = (size.width / cellSize).ceil() + 1;
    final int gridRows = (size.height / cellSize).ceil() + 1;
    final List<List<int>> grid = List.generate(gridCols * gridRows, (_) => <int>[]);

    // Speed multiplier: 1.0 (normal) to 5.0 (boosted)
    double speedMultiplier = 1.0 + (boostValue * 4.0);

    // Update positions and insert into grid
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // Move
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

      // Insert into grid
      final col = (node.x / cellSize).floor().clamp(0, gridCols - 1);
      final row = (node.y / cellSize).floor().clamp(0, gridRows - 1);
      grid[row * gridCols + col].add(i);
    }

    // 3. Draw connections using spatial grid (check only neighbouring cells)
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final col = (node.x / cellSize).floor().clamp(0, gridCols - 1);
      final row = (node.y / cellSize).floor().clamp(0, gridRows - 1);

      // Check the 3x3 neighbourhood of cells
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 || nr >= gridRows || nc < 0 || nc >= gridCols) continue;
          final cell = grid[nr * gridCols + nc];
          for (final j in cell) {
            if (j <= i) continue; // Avoid double-drawing and self
            final target = nodes[j];
            final dx = node.x - target.x;
            final dy = node.y - target.y;
            final distSq = dx * dx + dy * dy;

            if (distSq < 10000) { // 100*100 threshold
              final dist = math.sqrt(distSq);
              final opacity = (1.0 - (dist / 100)) * 0.5;

              Color color;
              if (node.layer == 0) {
                color = _layerColor0;
              } else if (node.layer == 1) {
                color = _layerColor1;
              } else {
                color = _layerColor2;
              }

              _linePaint.color = color.withValues(alpha: opacity);
              canvas.drawLine(
                Offset(node.x, node.y),
                Offset(target.x, target.y),
                _linePaint,
              );

              // Data Flow Particle on line (randomly)
              if (random.nextDouble() > 0.99) {
                final t = random.nextDouble();
                final lx = node.x + (target.x - node.x) * t;
                final ly = node.y + (target.y - node.y) * t;
                canvas.drawCircle(Offset(lx, ly), 1.5, _particlePaint);
              }
            }
          }
        }
      }
    }

    // 4. Draw Node Dots
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      double radius =
          2.0 + node.layer + math.sin(animValue * 2 * math.pi + i) * 0.5;

      Color baseColor;
      if (node.layer == 0) {
        baseColor = AppTheme.purple500;
      } else if (node.layer == 1) {
        baseColor = AppTheme.blue500;
      } else {
        baseColor = AppTheme.pink500;
      }

      // Glow
      _nodePaint.color = baseColor.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(node.x, node.y), radius * 2, _nodePaint);
      // Core
      _nodePaint.color = baseColor.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(node.x, node.y), radius, _nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.animValue != animValue ||
      oldDelegate.boostValue != boostValue;
}
