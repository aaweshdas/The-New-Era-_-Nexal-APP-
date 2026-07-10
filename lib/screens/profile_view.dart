import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _profileName = 'Neural Nexus';
  String _profileBio = 'Exploring the quantum realm of digital consciousness ✨';
  String _profileLink = 'nexal.space/neural';

  @override
  void initState() { 
    super.initState(); 
    _tabCtrl = TabController(length: 4, vsync: this); 
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileName = prefs.getString('profileName') ?? _profileName;
        _profileBio = prefs.getString('profileBio') ?? _profileBio;
        _profileLink = prefs.getString('profileLink') ?? _profileLink;
      });
    }
  }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: const Color(0xFF1a1a2e), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D0015), Colors.black, Color(0xFF000a14), Colors.black], stops: [0.0, 0.3, 0.7, 1.0])))),
        CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildCoverHeader()),
            SliverToBoxAdapter(child: _buildAvatarWithAchievements()),
            SliverToBoxAdapter(child: _buildCompactStats()),
            SliverToBoxAdapter(child: _buildProfileInfo()),
            SliverToBoxAdapter(child: _buildActionButtons()),
            SliverToBoxAdapter(child: _buildContentTabs()),
            SliverToBoxAdapter(child: _buildGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(bottom: false, child: _buildTopBar())),
      ]),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        _iconBtn(LucideIcons.arrowLeft, () => Navigator.maybePop(context)),
        const SizedBox(width: 12),
        Expanded(child: Center(child: Text(_profileName, style: GoogleFonts.rye(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        _iconBtn(LucideIcons.share2, () => _snack('Share profile link copied!')),
        const SizedBox(width: 10),
        _iconBtn(LucideIcons.settings, () => _showSettings()),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))), child: Icon(icon, color: Colors.white70, size: 20)));

  // ── COVER HEADER (banner only, no avatar) ──
  Widget _buildCoverHeader() {
    return SizedBox(
      height: 160,
      child: Stack(children: [
        Positioned.fill(child: CachedNetworkImage(imageUrl: 'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=800', fit: BoxFit.cover, errorWidget: (c, url, error) => Container(color: const Color(0xFF0D0015)))),
        Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.3), Colors.black])))),
      ]),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── AVATAR WITH ACHIEVEMENTS ON SIDES ──
  Widget _buildAvatarWithAchievements() {
    final leftBadges = [
      {'icon': LucideIcons.award, 'label': 'Top Creator', 'color': const Color(0xFFFBBF24)},
      {'icon': LucideIcons.flame, 'label': '30 Day Streak', 'color': AppTheme.pink500},
    ];
    final rightBadges = [
      {'icon': LucideIcons.star, 'label': '10K Likes', 'color': AppTheme.cyan500},
      {'icon': LucideIcons.rocket, 'label': 'Pioneer', 'color': AppTheme.purple500},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left achievements
          Expanded(child: Column(children: leftBadges.asMap().entries.map((e) => _badgeTile(e.value, e.key)).toList())),
          // Center avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppTheme.purple500, AppTheme.cyan500]), boxShadow: [BoxShadow(color: AppTheme.purple500.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
            child: CircleAvatar(radius: 48, backgroundColor: Colors.black, child: CircleAvatar(radius: 44, backgroundImage: const CachedNetworkImageProvider('https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200'), backgroundColor: Colors.grey[900])),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms),
          // Right achievements
          Expanded(child: Column(children: rightBadges.asMap().entries.map((e) => _badgeTile(e.value, e.key + 2)).toList())),
        ],
      ),
    );
  }

  Widget _badgeTile(Map<String, dynamic> b, int i) {
    return GestureDetector(
      onTap: () => _snack('${b['label']} - Earned!'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: (b['color'] as Color).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (b['color'] as Color).withValues(alpha: 0.12)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(b['icon'] as IconData, color: b['color'] as Color, size: 18),
          const SizedBox(height: 4),
          Text(b['label'] as String, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    ).animate().fadeIn(delay: (300 + i * 120).ms, duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms);
  }

  // ── COMPACT STATS (below avatar) ──
  Widget _buildCompactStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _compactStat('2.4K', 'Energy', LucideIcons.zap, AppTheme.purple500),
        Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.08)),
        _compactStat('12.5K', 'Connections', LucideIcons.users, AppTheme.cyan500),
        Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.08)),
        _compactStat('8.9K', 'Influence', LucideIcons.trendingUp, AppTheme.pink500),
      ]),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _compactStat(String value, String label, IconData icon, Color c) {
    return GestureDetector(
      onTap: () => _snack('$label details'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c, size: 13),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
      ]),
    );
  }

  // ── PROFILE INFO ──
  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.cyan500, AppTheme.purple500])), child: const Icon(LucideIcons.checkCircle, color: Colors.white, size: 14)),
          const SizedBox(width: 6),
          Text('@neuralnexus', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.purple500.withValues(alpha: 0.6), AppTheme.pink500.withValues(alpha: 0.4)]), borderRadius: BorderRadius.circular(20)),
          child: Text('ELITE CREATOR', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        Text(_profileBio, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, height: 1.4)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.mapPin, size: 13, color: AppTheme.cyan500.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text('Digital Metaverse', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
          const SizedBox(width: 14),
          Icon(LucideIcons.link, size: 13, color: AppTheme.cyan500.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          GestureDetector(onTap: () => _snack('Opening link...'), child: Text(_profileLink, style: GoogleFonts.outfit(color: AppTheme.cyan500.withValues(alpha: 0.7), fontSize: 12))),
        ]),
      ]),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ── ACTION BUTTONS (own profile = Edit + Share) ──
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => _showEditProfile(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(LucideIcons.edit3, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Edit Profile', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () => _snack('Profile link copied to clipboard!'),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.share2, color: AppTheme.cyan500, size: 16),
              const SizedBox(width: 8),
              Text('Share Profile', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ])),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showSettings(),
          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: const Icon(LucideIcons.moreHorizontal, color: Colors.white54, size: 20)),
        ),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // (Stats & Achievements are now built inline above)

  // ── CONTENT TABS (redesigned with icons) ──
  Widget _buildContentTabs() {
    final tabs = [
      {'icon': LucideIcons.sparkles, 'label': 'Creations', 'color': AppTheme.purple500},
      {'icon': LucideIcons.bookmark, 'label': 'Saved', 'color': AppTheme.cyan500},
      {'icon': LucideIcons.heart, 'label': 'Liked', 'color': AppTheme.pink500},
      {'icon': LucideIcons.repeat2, 'label': 'Repost', 'color': const Color(0xFF34D399)},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      child: Container(
        height: 50, padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Row(children: List.generate(4, (i) {
          final t = tabs[i];
          final selected = _tabCtrl.index == i;
          final c = t['color'] as Color;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _tabCtrl.index = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: selected ? LinearGradient(colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.08)]) : null,
                borderRadius: BorderRadius.circular(12),
                border: selected ? Border.all(color: c.withValues(alpha: 0.3), width: 1) : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(t['icon'] as IconData, size: 16, color: selected ? c : Colors.white24),
                const SizedBox(height: 3),
                Text(t['label'] as String, style: GoogleFonts.outfit(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? c : Colors.white24)),
              ]),
            ),
          ));
        })),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  // ── GRID ──
  Widget _buildGrid() {
    final tabMeta = [
      {'icon': LucideIcons.heart, 'metric': 'likes'},
      {'icon': LucideIcons.bookmark, 'metric': 'saves'},
      {'icon': LucideIcons.heart, 'metric': 'likes'},
      {'icon': LucideIcons.repeat2, 'metric': 'reposts'},
    ];
    final meta = tabMeta[_tabCtrl.index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: _tabCtrl.index == 3 ? 6 : 9,
        itemBuilder: (ctx, i) {
          return GestureDetector(
            onTap: () => _showImageDetail(i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(children: [
                Positioned.fill(child: CachedNetworkImage(imageUrl: 'https://picsum.photos/200/200?random=${i + _tabCtrl.index * 10}', fit: BoxFit.cover, errorWidget: (c, url, error) => Container(color: Colors.grey[900], child: const Icon(LucideIcons.image, color: Colors.white12)))),
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)])))),
                // tab-aware badge
                if (_tabCtrl.index == 3) Positioned(top: 6, left: 6, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF34D399).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.repeat2, color: Colors.white, size: 10), const SizedBox(width: 3), Text('Reposted', style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600))]),
                )),
                Positioned(bottom: 6, left: 6, child: Row(children: [
                  Icon(meta['icon'] as IconData, color: Colors.white54, size: 12),
                  const SizedBox(width: 3),
                  Text('${(i + 1) * 234}', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
                ])),
              ]),
            ),
          ).animate().fadeIn(delay: (700 + i * 60).ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms);
        },
      ),
    );
  }

  void _showImageDetail(int i) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8,
      builder: (c, ctrl) => Container(
        decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(18), child: CachedNetworkImage(imageUrl: 'https://picsum.photos/400/300?random=${i + _tabCtrl.index * 10}', height: 200, width: double.infinity, fit: BoxFit.cover, errorWidget: (c, url, error) => Container(height: 200, color: Colors.grey[900]))),
          const SizedBox(height: 16),
          Text('Post #${i + 1}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('A glimpse into the quantum realm...', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            _detailAction('Like', LucideIcons.heart, AppTheme.pink500),
            const SizedBox(width: 10),
            _detailAction('Comment', LucideIcons.messageCircle, AppTheme.cyan500),
            const SizedBox(width: 10),
            _detailAction('Share', LucideIcons.share2, AppTheme.purple500),
          ]),
        ]),
      ),
    ));
  }

  Widget _detailAction(String label, IconData icon, Color c) => Expanded(child: GestureDetector(
    onTap: () { Navigator.pop(context); _snack('$label tapped'); },
    child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: c, size: 16), const SizedBox(width: 6), Text(label, style: GoogleFonts.outfit(color: c, fontSize: 12, fontWeight: FontWeight.w600))])),
  ));

  void _showSettings() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Settings', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _settingsItem(LucideIcons.user, 'Edit Profile', AppTheme.purple500, () { Navigator.pop(ctx); _showEditProfile(); }),
        _settingsItem(LucideIcons.bell, 'Notifications', AppTheme.cyan500, () { Navigator.pop(ctx); _showNotifications(); }),
        _settingsItem(LucideIcons.lock, 'Privacy', AppTheme.pink500, () { Navigator.pop(ctx); _showPrivacy(); }),
        _settingsItem(LucideIcons.helpCircle, 'Help & Support', Colors.white54, () { Navigator.pop(ctx); _snack('Support: support@nexal.space'); }),
        _settingsItem(LucideIcons.logOut, 'Log Out', Colors.redAccent, () { Navigator.pop(ctx); _showLogoutConfirm(); }),
        const SizedBox(height: 16),
      ]),
    ));
  }

  Widget _settingsItem(IconData icon, String label, Color c, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [Icon(icon, color: c, size: 20), const SizedBox(width: 14), Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)), const Spacer(), Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18)]),
    ),
  );

  // ── EDIT PROFILE SHEET ──
  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _profileName);
    final bioCtrl = TextEditingController(text: _profileBio);
    final linkCtrl = TextEditingController(text: _profileLink);
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Edit Profile', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _editField('Display Name', nameCtrl, LucideIcons.user),
          const SizedBox(height: 12),
          _editField('Bio', bioCtrl, LucideIcons.alignLeft, maxLines: 3),
          const SizedBox(height: 12),
          _editField('Website', linkCtrl, LucideIcons.link),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('profileName', nameCtrl.text);
              await prefs.setString('profileBio', bioCtrl.text);
              await prefs.setString('profileLink', linkCtrl.text);

              if (mounted) {
                setState(() { _profileName = nameCtrl.text; _profileBio = bioCtrl.text; _profileLink = linkCtrl.text; });
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _snack('Profile updated!');
              }
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.purple500, AppTheme.pink500]), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('Save Changes', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    ));
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: TextField(controller: ctrl, maxLines: maxLines, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(prefixIcon: Icon(icon, color: AppTheme.purple500.withValues(alpha: 0.5), size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12))),
      ),
    ]);
  }

  // ── NOTIFICATIONS SHEET ──
  void _showNotifications() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setLocal) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Notifications', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _toggleItem('Push Notifications', true, (v) {}, AppTheme.cyan500),
            _toggleItem('Message Alerts', true, (v) {}, AppTheme.purple500),
            _toggleItem('Like Notifications', false, (v) {}, AppTheme.pink500),
            _toggleItem('Comment Alerts', true, (v) {}, Colors.white54),
            const SizedBox(height: 12),
          ]),
        );
      });
    });
  }

  Widget _toggleItem(String label, bool initial, ValueChanged<bool> onChanged, Color c) {
    return StatefulBuilder(builder: (ctx, setLocal) {
      bool val = initial;
      return Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(children: [
          Icon(LucideIcons.bell, color: c, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14))),
          Switch(value: val, onChanged: (v) { setLocal(() => val = v); _snack('$label ${v ? "enabled" : "disabled"}'); }, activeThumbColor: AppTheme.purple500, inactiveTrackColor: Colors.white12),
        ]),
      );
    });
  }

  // ── PRIVACY SHEET ──
  void _showPrivacy() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Privacy', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _toggleItem('Private Account', false, (v) {}, AppTheme.pink500),
          _toggleItem('Show Online Status', true, (v) {}, AppTheme.cyan500),
          _toggleItem('Show Activity Status', true, (v) {}, AppTheme.purple500),
          _toggleItem('Allow Messages from All', false, (v) {}, Colors.white54),
          const SizedBox(height: 12),
        ]),
      );
    });
  }

  // ── LOGOUT CONFIRM ──
  void _showLogoutConfirm() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 36),
        const SizedBox(height: 12),
        Text('Log Out?', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Are you sure you want to log out?', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Center(child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)))),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { Navigator.pop(ctx); _snack('Logged out successfully'); },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
              child: Center(child: Text('Log Out', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)))),
          )),
        ]),
        const SizedBox(height: 12),
      ]),
    ));
  }
}
