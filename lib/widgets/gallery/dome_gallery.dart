import 'dart:math' as math;
import 'package:flutter/material.dart';

class DomeGallery extends StatefulWidget {
  final List<String> images;
  final double radius;
  final Function(String url, int index)? onImageTap;

  const DomeGallery({
    super.key,
    required this.images,
    this.radius = 520,
    this.onImageTap,
  });

  @override
  State<DomeGallery> createState() => _DomeGalleryState();
}

class _TransformedImage {
  final int index;
  final String url;
  final double worldZ;
  final Matrix4 transform;
  final double opacity;

  _TransformedImage({
    required this.index,
    required this.url,
    required this.worldZ,
    required this.transform,
    required this.opacity,
  });
}

class _DomeGalleryState extends State<DomeGallery>
    with SingleTickerProviderStateMixin {
  double _rotationX = 0;
  double _rotationY = 0;

  late AnimationController _frictionController;
  double _velocityX = 0;
  double _velocityY = 0;

  @override
  void initState() {
    super.initState();
    _frictionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps step
    )..addListener(_applyFriction);
  }

  void _applyFriction() {
    if (_velocityX.abs() < 0.001 && _velocityY.abs() < 0.001) {
      _frictionController.stop();
      return;
    }

    setState(() {
      _rotationX += _velocityX;
      _rotationY += _velocityY;
    });

    // Dampen velocity
    _velocityX *= 0.92;
    _velocityY *= 0.92;
  }

  @override
  void dispose() {
    _frictionController.dispose();
    super.dispose();
  }

  List<Widget> _buildImages() {
    int n = widget.images.length;
    if (n == 0) return [];

    final phi = math.pi * (3 - math.sqrt(5)); // Golden angle

    // Base transform for interactive rotation and perspective
    Matrix4 baseTransform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // Subtle perspective distortion
      ..rotateX(_rotationX)
      ..rotateY(_rotationY);

    List<_TransformedImage> items = [];

    for (int i = 0; i < n; i++) {
      // Fibonacci sphere point distribution
      double y = 1 - (i / (n - 1)) * 2; // y goes from 1 to -1
      double radiusAtY = math.sqrt(1 - y * y);
      double theta = phi * i;

      double x = math.cos(theta) * radiusAtY;
      double z = math.sin(theta) * radiusAtY;

      double tx = x * widget.radius;
      double ty = y * widget.radius;
      double tz = z * widget.radius;

      // How the image itself should be rotated to face outwards from the center of the sphere
      Matrix4 itemTransform = Matrix4.identity()
        ..translate(tx, ty, tz)
        ..multiply(Matrix4.rotationY(math.atan2(x, z)))
        ..multiply(Matrix4.rotationX(-math.asin(y))); // Tilt up/down

      // Calculate world Z to determine depth sorting and opacity fading.
      // Multiply translation vector by the base rotation transform.
      double m02 = baseTransform.entry(2, 0);
      double m12 = baseTransform.entry(2, 1);
      double m22 = baseTransform.entry(2, 2);
      double m32 = baseTransform.entry(2, 3);

      double worldZ = tx * m02 + ty * m12 + tz * m22 + m32;

      // Opacity fading for images facing away or far back
      double opacity = 1.0;
      if (worldZ < -widget.radius * 0.2) {
        double fadeVal =
            (worldZ + widget.radius * 0.2) / (-widget.radius * 0.8);
        opacity = (1.0 - fadeVal).clamp(0.05, 1.0);
      }

      items.add(
        _TransformedImage(
          index: i,
          url: widget.images[i],
          worldZ: worldZ,
          transform: itemTransform,
          opacity: opacity,
        ),
      );
    }

    // Painter's algorithm: sort by depth (Z) ascending so furthest objects draw first
    items.sort((a, b) => a.worldZ.compareTo(b.worldZ));

    return items.map((item) {
      return Transform(
        transform: baseTransform * item.transform,
        alignment: Alignment.center,
        child: Opacity(
          opacity: item.opacity,
          child: Container(
            width: 160,
            height: 240,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onTap: widget.onImageTap != null
                  ? () => widget.onImageTap!(item.url, item.index)
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Hero(
                tag: 'gallery_image_${item.index}',
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        Container(color: Colors.grey[900]),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.cyan,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _frictionController.stop();
          // Drag scales to rotation
          _rotationY += details.delta.dx * 0.008;
          _rotationX += details.delta.dy * 0.008;

          // Clamp vertical rotation
          _rotationX = _rotationX.clamp(-math.pi / 2.2, math.pi / 2.2);
        });
      },
      onPanEnd: (details) {
        _velocityX = details.velocity.pixelsPerSecond.dy * 0.000015;
        _velocityY = details.velocity.pixelsPerSecond.dx * 0.000015;
        if (_velocityX.abs() > 0.001 || _velocityY.abs() > 0.001) {
          _frictionController.repeat();
        }
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        child: Stack(alignment: Alignment.center, children: _buildImages()),
      ),
    );
  }
}
