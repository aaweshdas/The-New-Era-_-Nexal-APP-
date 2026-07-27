import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart'; // To use ChatScreen
import 'story_viewer_screen.dart'; // To view stories

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
  String _searchQuery = '';
  bool _isSearching = false;
  String _filterMode = 'All'; // All, Unread, Online
  final TextEditingController _searchCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Active Stories List
  final List<StoryItem> _activeStories = [
    StoryItem(
      userName: 'Aria Storm',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      caption: '⚡ Quantum update live in the plaza!',
      timeAgo: '12m ago',
    ),
    StoryItem(
      userName: 'Kai Cyber',
      userAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100',
      imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      caption: '🚀 Shipping the new engine build today.',
      timeAgo: '45m ago',
    ),
    StoryItem(
      userName: 'Nova Glitch',
      userAvatar: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=100',
      imageUrl: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800',
      caption: '🌌 Midnight vibes from the cyber grid.',
      timeAgo: '2h ago',
    ),
  ];

  Future<void> _uploadMyStory() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null || !mounted) return;

      final myStory = StoryItem(
        userName: 'Your Story',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        imageUrl: file.path,
        caption: 'My story update ✨',
        timeAgo: 'Just now',
      );

      setState(() {
        _activeStories.insert(0, myStory);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Story uploaded successfully! ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Failed to pick story image', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _openStoryViewer(int index) {
    if (_activeStories.isEmpty) return;
    final targetIndex = index.clamp(0, _activeStories.length - 1);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: _activeStories,
          initialIndex: targetIndex,
        ),
      ),
    );
  }

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
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openChat(MessageItem m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
      item: m,
      initialMessages: const [],
      onMessageSent: (msg) {},
    )));
  }

  List<MessageItem> get _filteredPrimary {
    var list = List<MessageItem>.from(_primary);
    if (_filterMode == 'Unread') list = list.where((m) => m.unreadCount > 0).toList();
    if (_filterMode == 'Online') list = list.where((m) => m.isOnline).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) => m.name.toLowerCase().contains(q) || m.message.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<RequestItem> get _filteredRequests {
    var list = List<RequestItem>.from(_requests);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) => r.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _showNewConversationSheet() {
    final newSearchCtrl = TextEditingController();
    String newSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allContacts = [
            ..._primary,
            MessageItem(name: 'Orion Seeker', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', message: 'Suggested connection', time: 'Online', isOnline: true),
            MessageItem(name: 'Sol Flare', avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100', message: 'Suggested connection', time: 'Offline'),
            MessageItem(name: 'Lyra Star', avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', message: 'Suggested connection', time: 'Online', isOnline: true),
            MessageItem(name: 'Cyber Pulse', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', message: 'New connection', time: 'Online', isOnline: true),
          ];

          final filtered = newSearchQuery.isEmpty
              ? allContacts
              : allContacts.where((c) => c.name.toLowerCase().contains(newSearchQuery.toLowerCase())).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0d0d1a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('New Message', style: GoogleFonts.rye(color: Colors.white, fontSize: 20)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(modalCtx),
                              child: const Icon(LucideIcons.x, color: Colors.white54, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: newSearchCtrl,
                            autofocus: true,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search contact name...',
                              hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
                              border: InputBorder.none,
                              prefixIcon: const Icon(LucideIcons.search, color: Colors.white38, size: 18),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (v) => setModalState(() => newSearchQuery = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty && newSearchQuery.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.userPlus, color: Color(0xFFA855F7), size: 42),
                              const SizedBox(height: 12),
                              Text('Start chat with "$newSearchQuery"', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA855F7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                                label: Text('Start Conversation', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.pop(modalCtx);
                                  final newContact = MessageItem(
                                    name: newSearchQuery,
                                    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                    message: 'Started a new conversation',
                                    time: 'Just now',
                                    isOnline: true,
                                  );
                                  setState(() => _primary.insert(0, newContact));
                                  _openChat(newContact);
                                },
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  if (!_primary.any((item) => item.name == m.name)) {
                                    setState(() => _primary.insert(0, m));
                                  }
                                  _openChat(m);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(radius: 24, backgroundImage: NetworkImage(m.avatar)),
                                          if (m.isOnline)
                                            Positioned(bottom: 0, right: 0, child: Container(
                                              width: 12, height: 12,
                                              decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0d0d1a), width: 2)),
                                            )),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(m.message, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const Icon(LucideIcons.chevronRight, color: Colors.white30, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF0d0d1a),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Filter Messages', style: GoogleFonts.rye(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 16),
              ...['All', 'Unread', 'Online'].map((mode) => GestureDetector(
                onTap: () {
                  setState(() => _filterMode = mode);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _filterMode == mode
                        ? const Color(0xFFA855F7).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _filterMode == mode
                        ? const Color(0xFFA855F7).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == 'All' ? LucideIcons.list : mode == 'Unread' ? LucideIcons.mail : LucideIcons.wifi,
                        color: _filterMode == mode ? const Color(0xFFA855F7) : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(mode, style: GoogleFonts.outfit(
                        color: _filterMode == mode ? Colors.white : Colors.white70,
                        fontWeight: _filterMode == mode ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 15,
                      )),
                      if (_filterMode == mode) ...[
                        const Spacer(),
                        const Icon(LucideIcons.check, color: Color(0xFFA855F7), size: 18),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
        onPressed: _showNewConversationSheet,
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
                          // Top header row — switches smoothly into full-width search input when active
                          _isSearching
                              ? Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchCtrl.clear();
                                          _searchQuery = '';
                                        });
                                      },
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.search, color: const Color(0xFFA855F7), size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller: _searchCtrl,
                                                autofocus: true,
                                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                                decoration: InputDecoration(
                                                  hintText: 'Search chats or contacts...',
                                                  hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                onChanged: (v) => setState(() => _searchQuery = v),
                                              ),
                                            ),
                                            if (_searchQuery.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  _searchCtrl.clear();
                                                  setState(() => _searchQuery = '');
                                                },
                                                child: const Icon(LucideIcons.x, color: Colors.white54, size: 18),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Filter icon
                                    GestureDetector(
                                      onTap: _showFilterSheet,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _filterMode != 'All'
                                              ? const Color(0xFFA855F7).withValues(alpha: 0.15)
                                              : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: _filterMode != 'All'
                                              ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                                              : Colors.white.withValues(alpha: 0.08)),
                                        ),
                                        child: Icon(LucideIcons.slidersHorizontal,
                                            color: _filterMode != 'All' ? const Color(0xFFA855F7) : Colors.white70, size: 19),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 250.ms)
                              : Row(
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
                                    const SizedBox(width: 14),
                                    // Headline right next to back button with original Rye font & shimmer effect
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Messages',
                                            style: GoogleFonts.rye(
                                              fontSize: 24,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          )
                                          .animate(onPlay: (c) => c.repeat(reverse: true))
                                          .shimmer(
                                            duration: 3.seconds,
                                            colors: [
                                              Colors.white,
                                              AppTheme.purple500,
                                              AppTheme.cyan500,
                                              AppTheme.pink500,
                                              Colors.white
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Your conversations',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white30,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Unread badge chip if unread > 0
                                    () {
                                      final unread = _primary.fold<int>(0, (sum, m) => sum + m.unreadCount);
                                      if (unread == 0) return const SizedBox.shrink();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.8), AppTheme.pink500.withValues(alpha: 0.6)]),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.25), blurRadius: 10)],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.messageCircle, color: Colors.white, size: 12),
                                            const SizedBox(width: 4),
                                            Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      );
                                    }(),
                                    // Search trigger icon
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _isSearching = true);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                        ),
                                        child: Icon(LucideIcons.search, color: AppTheme.cyan500.withValues(alpha: 0.8), size: 19),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Filter icon
                                    GestureDetector(
                                      onTap: _showFilterSheet,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _filterMode != 'All'
                                              ? const Color(0xFFA855F7).withValues(alpha: 0.15)
                                              : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: _filterMode != 'All'
                                              ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                                              : Colors.white.withValues(alpha: 0.08)),
                                        ),
                                        child: Icon(LucideIcons.slidersHorizontal,
                                            color: _filterMode != 'All' ? const Color(0xFFA855F7) : Colors.white70, size: 19),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 300.ms),

                          const SizedBox(height: 14),

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
                itemCount: _activeStories.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: _uploadMyStory,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFA855F7), width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.black,
                                child: Icon(LucideIcons.plus, color: Color(0xFFA855F7), size: 22),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                            const SizedBox(height: 6),
                            Text('Your Story', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }
                  final story = _activeStories[i - 1];
                  final isFileImage = story.imageUrl.startsWith('/');
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => _openStoryViewer(i - 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF06B6D4)]),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: isFileImage
                                  ? FileImage(File(story.imageUrl)) as ImageProvider
                                  : NetworkImage(story.userAvatar),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 1.seconds),
                          const SizedBox(height: 6),
                          Text(story.userName.split(' ')[0], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
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
      itemCount: _filteredPrimary.length,
      itemBuilder: (ctx, i) {
        final m = _filteredPrimary[i];
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
    final requests = _filteredRequests;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: requests.length,
      itemBuilder: (ctx, i) {
        final req = requests[i];
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
