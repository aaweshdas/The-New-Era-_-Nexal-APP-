import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import '../../theme/app_theme.dart';
import '../../utils/filter_generator.dart';

class CameraPreviewScreen extends StatelessWidget {
  final XFile imageFile;
  final int selectedFilterIndex;

  const CameraPreviewScreen({
    super.key,
    required this.imageFile,
    this.selectedFilterIndex = 0,
  });

  ColorFilter _getFilter() {
    if (selectedFilterIndex >= 0 &&
        selectedFilterIndex < FilterGenerator.filters.length) {
      return FilterGenerator.filters[selectedFilterIndex];
    }
    return const ColorFilter.mode(Colors.transparent, BlendMode.srcOver);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: _getFilter(),
            child: Image.file(File(imageFile.path), fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context), // Discard
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Bar
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Save button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.download,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to Gallery! (Mocked)'),
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      // Next/Post Button
                      FloatingActionButton.extended(
                        backgroundColor: AppTheme.cyan500,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proceeding to Post! (Mocked)'),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(LucideIcons.send, color: Colors.black),
                        label: Text(
                          "Next",
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
