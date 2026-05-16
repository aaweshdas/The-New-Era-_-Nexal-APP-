import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../theme/app_theme.dart';
import 'chat_screen.dart'; // To use ChatScreen

class MessageItem {
  final String name, avatar, message, time;
  final int unreadCount;
  final bool isOnline, isMedia;
  MessageItem({required this.name, required this.avatar, required this.message, required this.time, this.unreadCount = 0, this.isOnline = false, this.isMedia = false});
}

class ChatMessage {
  final String text;
  final bool isSent;
  final DateTime time;
  ChatMessage({required this.text, required this.isSent, required this.time});
}

class RequestItem {
  final String name, avatar;
  final int mutualConnections;
  RequestItem({required this.name, required this.avatar, required this.mutualConnections});
}

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});
  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  double _gyroX = 0;
  double _gyroY = 0;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final List<MessageItem> _primary = [
    MessageItem(name: 'Aria Storm', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', message: 'Sent a photo', time: '2m ago', unreadCount: 2, isOnline: true, isMedia: true),
    MessageItem(name: 'Kai Cyber', avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100', message: 'Did you see the new quantum engine update? 🚀', time: '14m ago', isOnline: true),
    MessageItem(name: 'Nova Glitch', avatar: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=100', message: 'Let\'s meet at the digital plaza tonight.', time: '1h ago'),
    MessageItem(name: 'Zenith Prime', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', message: 'Project nebula is ready for launch.', time: '3h ago', unreadCount: 1),
    MessageItem(name: 'Echo Vibe', avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100', message: 'Listening to Deep Space Mix 🎵', time: '5h ago', isOnline: true),
    MessageItem(name: 'Luna Ray', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', message: 'See you tomorrow!', time: '1d ago'),
  ];

  final List<RequestItem> _requests = [
    RequestItem(name: 'Orion Seeker', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', mutualConnections: 12),
    RequestItem(name: 'Sol Flare', avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100', mutualConnections: 5),
    RequestItem(name: 'Lyra Star', avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', mutualConnections: 24),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _gyroX += event.y * 0.5;
        _gyroY += event.x * 0.5;
        _gyroX = _gyroX.clamp(-15.0, 15.0);
        _gyroY = _gyroY.clamp(-15.0, 15.0);
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _gyroSub?.cancel();
    super.dispose();
  }

  void _openChat(MessageItem m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
      item: m,
      initialMessages: const [],
      onMessageSent: (msg) {},
    )));
  }

  void _acceptRequest(int index) {
    final req = _requests[index];
    setState(() {
      _requests.removeAt(index);
      _primary.insert(0, MessageItem(name: req.name, avatar: req.avatar, message: 'Connection accepted.', time: 'Just now', isOnline: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black background
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
            boxShadow: [
              BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: const Icon(LucideIcons.edit2, color: Colors.white),
        ),
      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut, delay: 400.ms),
      body: CustomScrollView(
        slivers: [
          // ── PREMIUM HEADER ──
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: Offset(_gyroX * 0.3, _gyroY * 0.3),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 48, 0, 8),
                child: Stack(
                  children: [
                    // Ambient glow orbs behind header
                    Positioned(left: -40, top: -20, child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.purple500.withValues(alpha: 0.15), Colors.transparent])),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.8, end: 1.2, duration: 3.seconds)),
                    Positioned(right: -30, top: -10, child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.cyan500.withValues(alpha: 0.1), Colors.transparent])),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 0.7, duration: 4.seconds)),

                    // Main header content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: back + action icons
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: const Icon(LucideIcons.arrowLeft, color: Colors.white70, size: 20),
                                ),
                              ),
                              const Spacer(),
                              // Search pill
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                  child: Row(children: [
                                    Icon(LucideIcons.search, color: AppTheme.cyan500.withValues(alpha: 0.6), size: 16),
                                    const SizedBox(width: 8),
                                    Text('Search chats', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Filter icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: const Icon(LucideIcons.slidersHorizontal, color: Colors.white70, size: 20),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0),

                          const SizedBox(height: 20),

                          // Title row with gradient shimmer
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Messages', style: GoogleFonts.rye(fontSize: 28, color: Colors.white, height: 1.1))
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .shimmer(duration: 3.seconds, colors: [Colors.white, AppTheme.purple500, AppTheme.cyan500, AppTheme.pink500, Colors.white]),
                                    const SizedBox(height: 6),
                                    Text('Your conversations', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14, letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                              // Unread badge — large and eye-catching
                              () {
                                final unread = _primary.fold<int>(0, (sum, m) => sum + m.unreadCount);
                                if (unread == 0) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.8), AppTheme.pink500.withValues(alpha: 0.6)]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.3)),
                                    boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 2)],
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(LucideIcons.messageCircle, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text('$unread new', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ]),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut);
                              }(),
                            ],
                          ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          // Decorative divider line
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                AppTheme.purple500.withValues(alpha: 0.3),
                                AppTheme.cyan500.withValues(alpha: 0.2),
                                Colors.transparent,
                              ]),
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scaleX(begin: 0.0, end: 1.0, duration: 700.ms, alignment: Alignment.centerLeft),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stories Row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _primary.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFA855F7), width: 2, style: BorderStyle.solid), // Dashed simulated by border
                            ),
                            child: const CircleAvatar(radius: 28, backgroundColor: Colors.black, child: Icon(LucideIcons.plus, color: Color(0xFFA855F7))),
                          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 8.seconds), // Simplified dash animation
                          const SizedBox(height: 6),
                          Text('Your Story', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  final user = _primary[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing ${user.name}\'s story'), backgroundColor: Colors.grey[900])),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF06B6D4)]),
                            ),
                            child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(user.avatar)),
                          ).animate(target: user.isOnline ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 1.seconds),
                          const SizedBox(height: 6),
                          Text(user.name.split(' ')[0], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: [
                    const Tab(text: 'Primary'),
                    Tab(text: 'Requests (${_requests.length})'),
                  ],
                ),
              ),
            ),
          ),

          // Tab View (Using AnimatedBuilder to allow sliver scrolling underneath)
          SliverFillRemaining(
            child: AnimatedBuilder(
              animation: _tabCtrl.animation!,
              builder: (ctx, child) {
                // Determine which tab to show based on animation value
                final isPrimary = _tabCtrl.animation!.value < 0.5;
                // Calculate opacity for fade effect (1.0 at centers, 0.0 at middle)
                final opacity = isPrimary 
                    ? 1.0 - (_tabCtrl.animation!.value * 2) 
                    : (_tabCtrl.animation!.value - 0.5) * 2;
                
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: isPrimary ? _buildPrimaryList() : _buildRequestsList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryList() {
    if (_primary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.rocket, color: Color(0xFF06B6D4), size: 64),
            const SizedBox(height: 16),
            Text('Your galaxy is quiet', style: GoogleFonts.rye(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {},
              child: Text('Find people', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _primary.length,
      itemBuilder: (ctx, i) {
        final m = _primary[i];
        return Dismissible(
          key: ValueKey(m.name),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.archive, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.trash2, color: Colors.white),
          ),
          onDismissed: (dir) => setState(() => _primary.removeAt(i)),
          child: GestureDetector(
            onTap: () => _openChat(m),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.fromBorderSide(BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                blur: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(radius: 26, backgroundImage: NetworkImage(m.avatar)),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: m.isOnline ? const Color(0xFF06B6D4) : Colors.grey,
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (m.isMedia) ...[const Icon(LucideIcons.image, size: 14, color: Colors.grey), const SizedBox(width: 4)],
                                Expanded(child: Text(m.message, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(m.time, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 6),
                          if (m.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                              ),
                              child: Text('${m.unreadCount}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.seconds),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.2, end: 0, duration: 300.ms),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final req = _requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.fromBorderSide(BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            blur: 8,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundImage: NetworkImage(req.avatar)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${req.mutualConnections} mutual connections', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _requests.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Decline', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _acceptRequest(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Accept', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.2, end: 0, duration: 300.ms);
      },
    );
  }
}
