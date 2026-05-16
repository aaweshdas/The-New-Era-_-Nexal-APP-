import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'messages_view.dart';

// ─── ChatScreen ────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final MessageItem item;
  final List<ChatMessage> initialMessages;
  final void Function(ChatMessage) onMessageSent;

  const ChatScreen({
    super.key,
    required this.item,
    required this.initialMessages,
    required this.onMessageSent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late List<ChatMessage> _messages;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showEmoji = false;
  bool _showScrollDown = false;
  bool _isTyping = false;

  static const _emojis = [
    '😊','😂','❤️','🔥','👍','✨','🚀','🎵','😍','🙏',
    '💯','🤔','😎','🥳','💪','🌟','👏','😅','🎉','💫',
    '😢','🫶','😜','🤩','👋','💬','🌙','⚡','🦋','🌈',
    '🍀','🎯','🧠','👀','🫠','🥹','🤯','💥','🎨','🌸',
  ];

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialMessages);
    _scrollCtrl.addListener(() {
      final atBottom = _scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent - 80;
      if (atBottom != !_showScrollDown) setState(() => _showScrollDown = !atBottom);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final msg = ChatMessage(text: text, isSent: true, time: DateTime.now());
    setState(() {
      _messages.add(msg);
      _inputCtrl.clear();
      _showEmoji = false;
    });
    widget.onMessageSent(msg);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Simulate a reply after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final query = text.toLowerCase();
      String replyText = '';

      if (query.contains('photo') || query.contains('pic') || query.contains('image')) {
        final photoReplies = ['Send it over! 📸', 'I love photos!', 'Is it a good one?', 'Can\'t wait to see it! ✨'];
        photoReplies.shuffle();
        replyText = photoReplies.first;
      } else if (query.contains('hello') || query.contains('hi') || query.contains('hey')) {
        final greetReplies = ['Hey there! 👋', 'Hi!', 'Hello! How are you?', 'Hey, what\'s up?'];
        greetReplies.shuffle();
        replyText = greetReplies.first;
      } else if (query.contains('video') || query.contains('reel')) {
        final vidReplies = ['I watched it! So cool 🎬', 'Great video 🔥', 'Send the link!'];
        vidReplies.shuffle();
        replyText = vidReplies.first;
      } else if (query.contains('?')) {
        final questionReplies = ['Hmm, I need to think about that 🤔', 'Yes, absolutely!', 'Not sure, what do you think?', 'Maybe...'];
        questionReplies.shuffle();
        replyText = questionReplies.first;
      } else {
        final replies = [
          'That\'s cool! 🔥', 'Got it 👍', 'Sounds good!', 'Wow, really? ✨',
          'Haha 😂', 'Nice one!', 'On it 🚀', 'Let me check...',
          'Interesting perspective 🧠', 'Tell me more.', 'I completely agree 💯',
          'Whoa, mind blown 🤯', 'Love that energy ⚡', 'Classic! 🎯',
        ];
        replies.shuffle();
        replyText = replies.first;
      }

      final reply = ChatMessage(text: replyText, isSent: false, time: DateTime.now());
      setState(() => _messages.add(reply));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            const SizedBox(height: 20),
            Text('Share', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachOption(LucideIcons.camera, 'Camera', AppTheme.purple500),
                _attachOption(LucideIcons.image, 'Gallery', AppTheme.cyan500),
                _attachOption(LucideIcons.fileText, 'Document', AppTheme.pink500),
                _attachOption(LucideIcons.mic, 'Audio', const Color(0xFF22C55E)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label selected', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFF1a1a2e),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCallDialog(bool isVideo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CallDialog(item: widget.item, isVideo: isVideo),
    );
  }

  void _longPressMessage(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF0d0d1a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
              child: Text(msg.text, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            _msgAction(LucideIcons.copy, 'Copy', () {
              Clipboard.setData(ClipboardData(text: msg.text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Copied!', style: GoogleFonts.outfit(color: Colors.white)),
                backgroundColor: const Color(0xFF1a1a2e), behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 1),
              ));
            }),
            _msgAction(LucideIcons.reply, 'Reply', () => Navigator.pop(context)),
            if (msg.isSent) _msgAction(LucideIcons.trash2, 'Delete', () {
              setState(() => _messages.remove(msg));
              Navigator.pop(context);
            }, isDestructive: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _msgAction(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildMessageList()),
          if (_showEmoji) _buildEmojiPicker(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 8, right: 8, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d1a),
        border: Border(bottom: BorderSide(color: AppTheme.purple500.withValues(alpha: 0.12))),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.arrowLeft, color: Colors.white70, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Stack(children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.item.avatar)),
          if (widget.item.isOnline)
            Positioned(bottom: 0, right: 0, child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0d0d1a), width: 2)),
            )),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.item.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          _isTyping
              ? Text('typing...', style: GoogleFonts.outfit(color: AppTheme.cyan500, fontSize: 12))
              : Text(widget.item.isOnline ? 'Online now' : 'Last seen ${widget.item.time}',
                  style: GoogleFonts.outfit(color: widget.item.isOnline ? const Color(0xFF22C55E) : Colors.white38, fontSize: 12)),
        ])),
        _callBtn(LucideIcons.phone, AppTheme.cyan500, () => _showCallDialog(false)),
        const SizedBox(width: 8),
        _callBtn(LucideIcons.video, AppTheme.purple500, () => _showCallDialog(true)),
        const SizedBox(width: 4),
        _callBtn(LucideIcons.moreVertical, Colors.white38, _showMoreOptions),
      ]),
    );
  }

  Widget _callBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Icon(icon, color: color, size: 18),
    ),
  );

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          _msgAction(LucideIcons.bellOff, 'Mute Notifications', () => Navigator.pop(context)),
          _msgAction(LucideIcons.userX, 'Block User', () => Navigator.pop(context), isDestructive: true),
          _msgAction(LucideIcons.flag, 'Report', () => Navigator.pop(context), isDestructive: true),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildMessageList() {
    return Stack(children: [
      ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length,
        itemBuilder: (_, i) => _buildBubble(_messages[i], i),
      ),
      if (_showScrollDown)
        Positioned(
          bottom: 12, right: 16,
          child: GestureDetector(
            onTap: () => _scrollToBottom(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.purple500, AppTheme.cyan500]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.4), blurRadius: 10)],
              ),
              child: const Icon(LucideIcons.chevronsDown, color: Colors.white, size: 18),
            ),
          ).animate().fadeIn(duration: 200.ms).scale(),
        ),
    ]);
  }

  Widget _buildBubble(ChatMessage msg, int index) {
    final isSent = msg.isSent;
    final isFirst = index == 0 || _messages[index - 1].isSent != isSent;
    final timeStr = '${msg.time.hour.toString().padLeft(2,'0')}:${msg.time.minute.toString().padLeft(2,'0')}';

    return GestureDetector(
      onLongPress: () => _longPressMessage(msg),
      child: Padding(
        padding: EdgeInsets.only(bottom: 6, top: isFirst ? 8 : 0),
        child: Row(
          mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSent && isFirst) ...[
              CircleAvatar(radius: 14, backgroundImage: NetworkImage(widget.item.avatar)),
              const SizedBox(width: 8),
            ] else if (!isSent) const SizedBox(width: 36),
            Flexible(
              child: Column(
                crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                    decoration: BoxDecoration(
                      gradient: isSent
                          ? LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.8), AppTheme.pink500.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      color: isSent ? null : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isSent ? 18 : 4),
                        bottomRight: Radius.circular(isSent ? 4 : 18),
                      ),
                      border: isSent ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(msg.text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.4)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(LucideIcons.checkCheck, size: 12, color: AppTheme.cyan500.withValues(alpha: 0.8)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0, duration: 250.ms),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 240,
      color: const Color(0xFF0d0d1a),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: _emojis.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            _inputCtrl.text += _emojis[i];
            _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _inputCtrl.text.length));
          },
          child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 24))),
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d0d1a),
        border: Border(top: BorderSide(color: AppTheme.purple500.withValues(alpha: 0.1))),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() { _showEmoji = !_showEmoji; if (_showEmoji) FocusScope.of(context).unfocus(); }),
          child: Icon(_showEmoji ? LucideIcons.keyboard : LucideIcons.smile,
              color: _showEmoji ? AppTheme.cyan500 : Colors.white38, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _inputCtrl,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              onTap: () => setState(() => _showEmoji = false),
              onChanged: (v) {
                setState(() => _isTyping = v.isNotEmpty);
              },
              decoration: InputDecoration(
                hintText: 'Message ${widget.item.name.split(' ')[0]}...',
                hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showAttachmentOptions,
          child: const Icon(LucideIcons.paperclip, color: Colors.white38, size: 22),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500]),
              boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.4), blurRadius: 10)],
            ),
            child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ─── Call Dialog ────────────────────────────────────────────────────────────

class _CallDialog extends StatefulWidget {
  final MessageItem item;
  final bool isVideo;
  const _CallDialog({required this.item, required this.isVideo});

  @override
  State<_CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<_CallDialog> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isMuted = false, _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0d0d1a),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.isVideo ? 'Video Call' : 'Voice Call', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Container(
              padding: EdgeInsets.all(4 + _pulseCtrl.value * 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.purple500.withValues(alpha: 0.3 - _pulseCtrl.value * 0.2), width: 2),
              ),
              child: child,
            ),
            child: CircleAvatar(radius: 44, backgroundImage: NetworkImage(widget.item.avatar)),
          ),
          const SizedBox(height: 16),
          Text(widget.item.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Calling...', style: GoogleFonts.outfit(color: AppTheme.cyan500, fontSize: 14))
              .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _callAction(icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic, label: _isMuted ? 'Unmute' : 'Mute', color: Colors.white38,
                onTap: () => setState(() => _isMuted = !_isMuted)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 64, height: 64,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 28)),
            ),
            _callAction(icon: _isSpeaker ? LucideIcons.volume2 : LucideIcons.volumeX, label: 'Speaker', color: Colors.white38,
                onTap: () => setState(() => _isSpeaker = !_isSpeaker)),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut);
  }

  Widget _callAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}
