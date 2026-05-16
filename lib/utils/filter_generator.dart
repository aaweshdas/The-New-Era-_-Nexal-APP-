import 'package:flutter/material.dart';

class FilterGenerator {
  static final List<ColorFilter> filters = _generateFilters();
  static final List<String> filterNames = [
    "Normal",
    "Vivid",
    "Mono",
    "Warm",
    "Cool",
  ];

  static List<ColorFilter> _generateFilters() {
    return [
      // 0: Normal
      const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),

      // 1: Vivid (Slight contrast/saturation boost)
      const ColorFilter.matrix(<double>[
        1.2,
        0,
        0,
        0,
        -0.1,
        0,
        1.2,
        0,
        0,
        -0.1,
        0,
        0,
        1.2,
        0,
        -0.1,
        0,
        0,
        0,
        1,
        0,
      ]),

      // 2: Mono (Grayscale)
      const ColorFilter.matrix(<double>[
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

      // 3: Warm (Sepia-ish)
      const ColorFilter.matrix(<double>[
        1.06,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.01,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.93,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ]),

      // 4: Cool (Blue-ish)
      const ColorFilter.matrix(<double>[
        0.99,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.93,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.08,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ]),
    ];
  }
}
