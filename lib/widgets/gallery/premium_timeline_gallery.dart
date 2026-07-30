import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../services/device_gallery_service.dart';
import '../../screens/full_screen_image_view.dart';

class TimelineEntry {
  final String year;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final AssetEntity? asset;

  TimelineEntry({
    required this.year,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.asset,
  });
}

final List<TimelineEntry> mockTimelineData = [
  TimelineEntry(
    year: '2026',
    title: 'The Interstellar Era',
    description:
        'First civilian flights to the Martian colonies began, opening the solar system to all.',
    imageUrl:
        'https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=2000&auto=format&fit=crop',
    category: 'Space & Tech',
  ),
  TimelineEntry(
    year: '2025',
    title: 'Quantum Resonance',
    description:
        'Global energy grid fully transitioned to zero-point quantum extraction.',
    imageUrl:
        'https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?q=80&w=2000&auto=format&fit=crop',
    category: 'AI & Future',
  ),
  TimelineEntry(
    year: '2024',
    title: 'Quantum Launch',
    description:
        'Historic first manned mission entering the outer rim territories. A monumental leap for humanity.',
    imageUrl:
        'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2000&auto=format&fit=crop',
    category: 'Space & Tech',
  ),
  TimelineEntry(
    year: '2023',
    title: 'Neon Synchrony',
    description:
        'The global initialization of the connected cyber-grid. Cities woke up in a wave of synchronous light.',
    imageUrl:
        'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2000&auto=format&fit=crop',
    category: 'Culture & Web3',
  ),
  TimelineEntry(
    year: '2022',
    title: 'Echoes of Earth',
    description:
        'Final environmental restoration phase completed prior to orbital migration.',
    imageUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=2000&auto=format&fit=crop',
    category: 'Culture & Web3',
  ),
  TimelineEntry(
    year: '2021',
    title: 'The Great Silence',
    description:
        'A year of rebuilding and preparing for the next frontier. Global energy network established.',
    imageUrl:
        'https://images.unsplash.com/photo-1614729939124-032f0b56c9ce?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2020',
    title: 'Dawn of AI',
    description:
        'First sentient algorithmic cluster awakens, beginning the new era of co-existence.',
    imageUrl:
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?q=80&w=2000&auto=format&fit=crop',
    category: 'AI & Future',
  ),
];

class PremiumTimelineGallery extends StatelessWidget {
  final bool isGridLayout;
  final bool isNewestFirst;
  final String selectedCategory;
  final String searchQuery;
  final List<DevicePhotoItem> devicePhotos;
  final bool isLoadingDevicePhotos;
  final VoidCallback? onRequestPermission;

  const PremiumTimelineGallery({
    super.key,
    this.isGridLayout = false,
    this.isNewestFirst = true,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.devicePhotos = const [],
    this.isLoadingDevicePhotos = false,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingDevicePhotos) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5FF)),
            SizedBox(height: 16),
            Text(
              'Importing Device Gallery...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Convert devicePhotos to TimelineEntry items if available
    final List<TimelineEntry> sourceData = devicePhotos.isNotEmpty
        ? devicePhotos.map((dp) => TimelineEntry(
              year: dp.year,
              title: dp.title,
              description: dp.description,
              imageUrl: '',
              category: dp.category,
              asset: dp.asset,
            )).toList()
        : mockTimelineData;

    // 1. Filter entries
    final entries = sourceData.where((entry) {
      final matchesCategory =
          selectedCategory == 'All' || entry.category == selectedCategory;
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          entry.year.contains(query) ||
          entry.title.toLowerCase().contains(query) ||
          entry.description.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    // 2. Sort entries
    if (!isNewestFirst) {
      entries.sort((a, b) => a.year.compareTo(b.year));
    } else {
      entries.sort((a, b) => b.year.compareTo(a.year));
    }

    // 3. Empty state
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.image_off,
              size: 56,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No memories found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing search or granting gallery permissions.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            if (onRequestPermission != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.shield_check, size: 16),
                label: const Text('Grant Access'),
                onPressed: onRequestPermission,
              ),
            ],
          ],
        ),
      );
    }

    // 4. Grid View Layout
    if (isGridLayout) {
      return GridView.builder(
        padding: const EdgeInsets.only(
          top: 100,
          bottom: 80,
          left: 16,
          right: 16,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildGridCard(context, entry, index);
        },
      );
    }

    // 5. Classic Split Timeline Layout
    return Stack(
      children: [
        // Central vertical line
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Timeline list content
        ListView.builder(
          padding: const EdgeInsets.only(
            top: 100,
            bottom: 80,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isLeftAligned = index % 2 == 0;
            return _buildTimelineRow(context, entry, isLeftAligned, index);
          },
        ),
      ],
    );
  }

  Widget _buildGridCard(BuildContext context, TimelineEntry entry, int index) {
    return GestureDetector(
      onTap: () async {
        final nav = Navigator.of(context);
        String targetUrl = entry.imageUrl;
        if (entry.asset != null) {
          final file = await entry.asset!.file;
          if (file != null) {
            targetUrl = file.path;
          }
        }
        nav.push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageView(
              imageUrl: targetUrl,
              index: index,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageWidget(entry),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          entry.year,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    TimelineEntry entry,
    bool isLeftAligned,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: isLeftAligned
                ? _buildTextContent(context, entry, TextAlign.right)
                : _buildImageContent(context, entry, index),
          ),
          _buildCenterNode(),
          Expanded(
            child: isLeftAligned
                ? _buildImageContent(context, entry, index)
                : _buildTextContent(context, entry, TextAlign.left),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNode() {
    return SizedBox(
      width: 48,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(
    BuildContext context,
    TimelineEntry entry,
    TextAlign align,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.year,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
            textAlign: align,
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: align,
          ),
          const SizedBox(height: 12),
          Text(
            entry.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: align,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    TimelineEntry entry,
    int index,
  ) {
    return GestureDetector(
      onTap: () async {
        final nav = Navigator.of(context);
        String targetUrl = entry.imageUrl;
        if (entry.asset != null) {
          final file = await entry.asset!.file;
          if (file != null) {
            targetUrl = file.path;
          }
        }
        nav.push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageView(
              imageUrl: targetUrl,
              index: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'gallery_image_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _buildImageWidget(entry),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(TimelineEntry entry) {
    if (entry.asset != null) {
      return FutureBuilder<Uint8List?>(
        future: DeviceGalleryService.instance.getThumbnail(entry.asset!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          return Container(
            color: Colors.black26,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          );
        },
      );
    }

    return Image.network(
      entry.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.white54),
      ),
    );
  }
}
