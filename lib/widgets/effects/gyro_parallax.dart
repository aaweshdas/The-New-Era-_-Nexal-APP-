import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class GyroParallax extends StatefulWidget {
  final Widget child;
  final double intensity;

  const GyroParallax({super.key, required this.child, this.intensity = 1.0});

  @override
  State<GyroParallax> createState() => _GyroParallaxState();
}

class _GyroParallaxState extends State<GyroParallax> {
  double _x = 0;
  double _y = 0;
  double _targetX = 0;
  double _targetY = 0;
  bool _dirty = false;
  StreamSubscription? _subscription;

  // Smoothing factor
  final double _alpha = 0.1;

  @override
  void initState() {
    super.initState();
    // Using accelerometer for tilt detection
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;

      // Calculate target tilt (normalized somewhat)
      // x usually ranges -10 to 10.
      _targetX = -event.x * widget.intensity;
      _targetY =
          -(event.y - 7.0) *
          widget
              .intensity; // -7 offset assumes ~45 deg usage angle or similar natural holding

      // Throttle: schedule a single frame callback instead of setState per event
      if (!_dirty) {
        _dirty = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            // Low-pass filter for smoothing
            _x = _x + _alpha * (_targetX - _x);
            _y = _y + _alpha * (_targetY - _y);
            _dirty = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateX(_y * 0.01) // Tilt up/down
        ..rotateY(_x * 0.01), // Tilt left/right
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}
