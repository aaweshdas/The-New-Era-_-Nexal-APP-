import 'package:flutter/material.dart';
import '../../screens/monthly_timeline_view.dart';

class TimelineEntry {
  final String year;
  final String title;
  final String description;
  final String imageUrl;
  final String category;

  TimelineEntry({
    required this.year,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
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
  TimelineEntry(
    year: '2019',
    title: 'Orbital Expansion',
    description:
        'The first commercial space station achieved full operational capacity.',
    imageUrl:
        'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=2000&auto=format&fit=crop',
    category: 'Space & Tech',
  ),
  TimelineEntry(
    year: '2018',
    title: 'Neural Link',
    description:
        'Breakthroughs in brain-computer interfaces allowed direct digital communication.',
    imageUrl:
        'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=2000&auto=format&fit=crop',
    category: 'AI & Future',
  ),
  TimelineEntry(
    year: '2017',
    title: 'Crypto Renaissance',
    description:
        'Decentralized systems integrated into mainstream financial infrastructure globally.',
    imageUrl:
        'https://images.unsplash.com/photo-1639762681485-074b7f4ec651?q=80&w=2000&auto=format&fit=crop',
    category: 'Culture & Web3',
  ),
  TimelineEntry(
    year: '2016',
    title: 'Virtual Awakening',
    description:
        'High-fidelity immersive reality became indistinguishable from the physical world.',
    imageUrl:
        'https://images.unsplash.com/photo-1617802690992-15d93263d3a9?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2015',
    title: 'Algorithmic Art',
    description:
        'Machine learning models began creating celebrated works of digital art.',
    imageUrl:
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=2000&auto=format&fit=crop',
    category: 'AI & Future',
  ),
  TimelineEntry(
    year: '2014',
    title: 'The Data Boom',
    description:
        'Global data creation surpassed zettabyte milestones, redefining information storage.',
    imageUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2013',
    title: 'Mobile Dominance',
    description: 'Mobile internet usage overtook desktop computing worldwide.',
    imageUrl:
        'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2012',
    title: 'God Particle',
    description:
        'Discovery of the Higgs boson fundamental particle confirmed by the large hadron collider.',
    imageUrl:
        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?q=80&w=2000&auto=format&fit=crop',
    category: 'Space & Tech',
  ),
  TimelineEntry(
    year: '2011',
    title: 'Cloud Computing',
    description:
        'The foundation of modern scalable internet architectures was solidified.',
    imageUrl:
        'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2010',
    title: 'Social Era',
    description:
        'Social networks connected billions, reshaping communication and culture.',
    imageUrl:
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=2000&auto=format&fit=crop',
    category: 'Culture & Web3',
  ),
  TimelineEntry(
    year: '2009',
    title: 'The Genesis Block',
    description:
        'The first cryptographic decentralized ledger was brought online.',
    imageUrl:
        'https://images.unsplash.com/photo-1621416894569-0f39ed31d247?q=80&w=2000&auto=format&fit=crop',
    category: 'Culture & Web3',
  ),
  TimelineEntry(
    year: '2008',
    title: 'Digital Pocket',
    description:
        'App ecosystems launched, putting supercomputers in every pocket.',
    imageUrl:
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2007',
    title: 'Touch Revolution',
    description:
        'The first modern multi-touch smartphones entered the consumer market.',
    imageUrl:
        'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2006',
    title: 'Global Stream',
    description:
        'High-speed internet allowed real-time video streaming across the globe.',
    imageUrl:
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2005',
    title: 'Video Boom',
    description:
        'User-generated video content disrupted traditional media broadcasting.',
    imageUrl:
        'https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
  TimelineEntry(
    year: '2004',
    title: 'The Beginning',
    description:
        'The early foundation of interconnected digital identities took shape.',
    imageUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=2000&auto=format&fit=crop',
    category: 'Science & Nature',
  ),
];

class PremiumTimelineGallery extends StatelessWidget {
  final bool isGridLayout;
  final bool isNewestFirst;
  final String selectedCategory;
  final String searchQuery;

  const PremiumTimelineGallery({
    super.key,
    this.isGridLayout = false,
    this.isNewestFirst = true,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter entries
    final entries = mockTimelineData.where((entry) {
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
              Icons.manage_search,
              size: 64,
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
              'Try clearing search or changing filters.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonthlyTimelineView(year: entry.year),
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
                    Image.network(
                      entry.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),
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
                            color: Color(0xFF135BEC),
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
            color: const Color(0xFF135BEC),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF135BEC).withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF135BEC).withValues(alpha: 0.4),
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
              color: Color(0xFF135BEC),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: align,
          ),
          const SizedBox(height: 12),
          Text(
            entry.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.6,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonthlyTimelineView(year: entry.year),
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
              child: Image.network(
                entry.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF135BEC),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
