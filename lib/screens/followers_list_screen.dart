import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/supabase_service.dart';

class FollowersListScreen extends StatefulWidget {
  final String title;
  const FollowersListScreen({super.key, this.title = 'Connections'});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<Map<String, String>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final res = await SupabaseService.client.from('profiles').select().limit(20);
      if (mounted) {
        setState(() {
          _users.clear();
          for (var item in res) {
            _users.add({
              'id': item['id']?.toString() ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
              'name': item['name']?.toString() ?? 'Nexal User',
              'handle': '@${item['username'] ?? "user"}',
              'avatar': item['avatar_url']?.toString() ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
            });
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CONNECTIONS',
                        style: GoogleFonts.rye(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF00E5FF),
              labelColor: const Color(0xFF00E5FF),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'Followers (12.5K)'),
                Tab(text: 'Following (340)'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildUserList(userProvider),
                  _buildUserList(userProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(UserProvider userProvider) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        final isFollowing = userProvider.isFollowing(u['id']!);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(u['avatar']!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['name']!,
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      u['handle']!,
                      style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF135BEC),
                  side: BorderSide(
                      color: isFollowing
                          ? Colors.white24
                          : const Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => userProvider.toggleFollow(u['id']!),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
