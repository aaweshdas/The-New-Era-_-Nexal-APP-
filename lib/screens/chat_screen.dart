import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';
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
  ChatMessage? _replyingTo; // for reply-thread feature
  File? _pendingImage; // for image attachment preview
  final _imagePicker = ImagePicker();

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

    // Subscribe to real-time incoming messages for this conversation
    _socketSub = SocketService.instance.onMessageReceived.listen((data) {
      final senderId = data['senderId'] as String?;
      final text = data['text'] as String?;
      if (senderId == widget.item.name && text != null && mounted) {
        final incoming = ChatMessage(text: text, isSent: false, time: DateTime.now());
        setState(() => _messages.add(incoming));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  StreamSubscription? _socketSub;

  @override
  void dispose() {
    _socketSub?.cancel();
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
    final hasImage = _pendingImage != null;
    if (text.isEmpty && !hasImage) return;

    final replyPrefix = _replyingTo != null ? '↩️ Replying to: "${_replyingTo!.text}"\n' : '';
    final fullText = hasImage ? '📷 Photo' : '$replyPrefix$text';

    final msg = ChatMessage(text: fullText, isSent: true, time: DateTime.now());
    setState(() {
      _messages.add(msg);
      _inputCtrl.clear();
      _showEmoji = false;
      _replyingTo = null;
      _pendingImage = null;
    });
    widget.onMessageSent(msg);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // ✓ Try real Socket.IO
    if (SocketService.instance.isConnected) {
      SocketService.instance.sendMessage(widget.item.name, fullText);
    }
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
                _attachOption(LucideIcons.camera, 'Camera', AppTheme.purple500, () async {
                  Navigator.pop(context);
                  final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (picked != null && mounted) {
                    setState(() => _pendingImage = File(picked.path));
                  }
                }),
                _attachOption(LucideIcons.image, 'Gallery', AppTheme.cyan500, () async {
                  Navigator.pop(context);
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null && mounted) {
                    setState(() => _pendingImage = File(picked.path));
                  }
                }),
                _attachOption(LucideIcons.fileText, 'Document', AppTheme.pink500, () async {
                  Navigator.pop(context);
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null && mounted) {
                    setState(() => _pendingImage = File(picked.path));
                  }
                }),
                _attachOption(LucideIcons.mic, 'Audio', const Color(0xFF22C55E), () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Recording voice note...', style: GoogleFonts.outfit(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ));
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Voice note sent!', style: GoogleFonts.outfit(color: Colors.white)),
                      backgroundColor: Colors.green,
                    ));
                  }
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
            _msgAction(LucideIcons.reply, 'Reply', () {
              setState(() => _replyingTo = msg);
              Navigator.pop(context);
              FocusScope.of(context).requestFocus(FocusNode()); // open keyboard
            }),
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Message Page Background Image (assets/backgrounds/active_screens/msg_bg.jpg)
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/active_screens/msg_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const SizedBox.shrink(),
            ),
          ),
          // Dark glass vignette overlay for message readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildMessageList()),
              // Pending image preview
              if (_pendingImage != null)
                Container(
                  color: const Color(0xFF0d0d1a),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pendingImage!, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Photo ready to send', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13))),
                      GestureDetector(
                        onTap: () => setState(() => _pendingImage = null),
                        child: const Icon(LucideIcons.x, color: Colors.white38, size: 20),
                      ),
                    ],
                  ),
                ),
              // Reply preview bar
              if (_replyingTo != null)
                Container(
                  color: const Color(0xFF0d0d1a),
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                  child: Row(
                    children: [
                      Container(width: 3, height: 36, decoration: BoxDecoration(color: AppTheme.cyan500, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Replying to ${_replyingTo!.isSent ? 'you' : widget.item.name}',
                                style: GoogleFonts.outfit(color: AppTheme.cyan500, fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(_replyingTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyingTo = null),
                        child: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
                      ),
                    ],
                  ),
                ),
              if (_showEmoji) _buildEmojiPicker(),
              _buildInputBar(),
            ],
          ),
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
