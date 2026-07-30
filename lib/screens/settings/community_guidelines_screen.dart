import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CommunityGuidelinesScreen extends StatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  State<CommunityGuidelinesScreen> createState() => _CommunityGuidelinesScreenState();
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Set<int> _expandedSections = {0, 1, 2, 3, 4, 5};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                        'Rules & Regulations',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'v1.0',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search rules (e.g. harassment, ban, strike)...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.white38, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Guidelines Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(
                    index: 0,
                    icon: LucideIcons.checkCircle2,
                    color: const Color(0xFF00FF9D),
                    title: 'SECTION 1 — WHAT YOU ARE ALLOWED TO DO',
                    items: [
                      '1.1 CREATE A PERSONAL PROFILE: Set up your account with a real or creative username, profile photo, and bio.',
                      '1.2 POST ORIGINAL CONTENT: Share your photos, videos, text posts, and creative work freely.',
                      '1.3 FOLLOW AND INTERACT: Follow users, like posts, leave comments, and share content.',
                      '1.4 CONTROL YOUR PRIVACY: Set public or private status, block users, manage comments and data settings.',
                      '1.5 REPORT VIOLATIONS: Use the report feature to flag content or accounts violating rules.',
                      '1.6 SHARE WITH CREDIT: Repost or share others\' content with proper credit to original creators.',
                      '1.7 PROMOTE YOUR WORK: Share products, services, portfolio, or creative projects honestly without spam.',
                      '1.8 LIVE STREAMING: Stream live content following all community guidelines throughout.',
                      '1.9 PARTICIPATE IN DISCUSSIONS: Join public conversations and debates respectfully.',
                      '1.10 USE PLATFORM FEATURES: Access stories, reels, polls, DMs, and group chats.',
                    ],
                  ),
                  _buildSection(
                    index: 1,
                    icon: LucideIcons.shieldAlert,
                    color: const Color(0xFFEC4899),
                    title: 'SECTION 2 — WHAT IS STRICTLY NOT ALLOWED',
                    items: [
                      '2.1 HARASSMENT AND BULLYING: Do NOT target, threaten, humiliate, or harass any individual or group.',
                      '2.2 IMPERSONATION: Do NOT create accounts pretending to be another person, celebrity, or brand.',
                      '2.3 MISINFORMATION: Do NOT post false news, fake health advice, or fabricated statistics.',
                      '2.4 HATE SPEECH: Do NOT post content promoting hatred, violence, or discrimination.',
                      '2.5 BOT ACTIVITY & SPAM: Do NOT use automated bots or scripts to mass-follow or manipulate metrics.',
                      '2.6 HACKING: Do NOT attempt unauthorized account access or exploit platform vulnerabilities.',
                      '2.7 SCAMS & FRAUD: Do NOT conduct phishing, scams, pyramid schemes, or fake giveaways.',
                      '2.8 SELF-HARM: Do NOT share, promote, or glorify self-harm or dangerous challenges.',
                      '2.9 THREATS & VIOLENCE: Do NOT make threats of physical harm or incite violence.',
                      '2.10 DOXXING: Do NOT share private personal information of others without consent.',
                      '2.11 UNDERAGE EXPLOITATION: Do NOT share or distribute content exploiting or harming minors.',
                      '2.12 BAN EVASION: Do NOT create new accounts to bypass a suspension or permanent ban.',
                    ],
                  ),
                  _buildSection(
                    index: 2,
                    icon: LucideIcons.fileText,
                    color: const Color(0xFFA855F7),
                    title: 'SECTION 3 — CONTENT POLICY',
                    items: [
                      '3.1 PHOTOS & VIDEOS: Original media you own or clearly labeled AI-generated content.',
                      '3.2 NEWS & OPINIONS: Factual news, personal opinions, and public commentary.',
                      '3.3 CREATIVE WORK: Art, music, writing, and creative works with proper rights.',
                      '3.4 EDUCATIONAL & ENTERTAINMENT: Tutorials, memes, gaming, and lifestyle content.',
                      '3.5 PROHIBITED — ADULT CONTENT: Nudity or sexually explicit material is NOT permitted.',
                      '3.6 PROHIBITED — GRAPHIC VIOLENCE: Depictions of violence, gore, or animal cruelty are banned.',
                      '3.7 PROHIBITED — COPYRIGHT: Copyrighted material without authorization will trigger DMCA removal.',
                      '3.8 PROHIBITED — ILLEGAL ACTIVITY: Promoting drug sales, weapons trafficking, or crime is forbidden.',
                      '3.9 PROHIBITED — TERRORIST CONTENT: Content promoting or recruiting for extremist groups is banned.',
                    ],
                  ),
                  _buildSection(
                    index: 3,
                    icon: LucideIcons.scale,
                    color: const Color(0xFFFFB800),
                    title: 'SECTION 4 — ENFORCEMENT & BAN POLICY',
                    customWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadgeCard(
                          title: '🔴 ZERO TOLERANCE (IMMEDIATE PERMANENT BAN)',
                          subtitle: 'Immediate permanent ban with no warning and no appeal for:',
                          bulletPoints: [
                            'Sharing child sexual abuse material (CSAM)',
                            'Making credible threats of violence toward individuals or groups',
                            'Large-scale hacking, fraud, or coordinated platform attacks',
                            'Posting terrorist or extremist recruitment content',
                            'Creating a new account after a previous permanent ban',
                          ],
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 12),
                        _buildBadgeCard(
                          title: '⚡ STRIKE SYSTEM (STANDARD VIOLATIONS)',
                          subtitle: 'Progressive strike policy for community standard violations:',
                          bulletPoints: [
                            'STRIKE 1 — FORMAL WARNING: Post removed + written warning.',
                            'STRIKE 2 — TEMPORARY RESTRICTION: 7 to 30 days posting/DM restriction.',
                            'STRIKE 3 — 90-DAY SUSPENSION: Account suspended and content hidden for 90 days.',
                            'STRIKE 4 — PERMANENT BAN: Permanent deactivation and data removal after 30 days.',
                          ],
                          color: const Color(0xFFFFB800),
                        ),
                        const SizedBox(height: 12),
                        _buildSubInfoBox(
                          title: 'Appeals & Strike Reset',
                          text: '• Appeal rights: Users may appeal non-zero-tolerance decisions within 14 days.\n'
                              '• Strike Reset: Strikes older than 12 months with clean record may be removed.',
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    index: 4,
                    icon: LucideIcons.lock,
                    color: const Color(0xFF00E5FF),
                    title: 'SECTION 5 — PRIVACY AND DATA RULES',
                    items: [
                      '5.1 You must not collect, store, or misuse other users\' personal data.',
                      '5.2 You must not screenshot or record private DMs to share publicly without consent.',
                      '5.3 You must not use the platform to track or monitor another person without consent.',
                      '5.4 All user data collected by the platform is governed by our Privacy Policy.',
                    ],
                  ),
                  _buildSection(
                    index: 5,
                    icon: LucideIcons.info,
                    color: Colors.white54,
                    title: 'SECTION 6 — POLICY UPDATES',
                    items: [
                      '6.1 Rules may be updated periodically. Users will be notified 7 days prior to major changes.',
                      '6.2 Continued use of the platform after updates indicates acceptance of revised rules.',
                      'Last Updated: July 2026 | Version 1.0 | © Nexal App. All rights reserved.',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required IconData icon,
    required Color color,
    required String title,
    List<String>? items,
    Widget? customWidget,
  }) {
    final isExpanded = _expandedSections.contains(index);
    final filteredItems = items?.where((item) =>
        _searchQuery.isEmpty || item.toLowerCase().contains(_searchQuery)).toList();

    if (_searchQuery.isNotEmpty && (filteredItems == null || filteredItems.isEmpty) && customWidget == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(index);
                } else {
                  _expandedSections.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: customWidget ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (filteredItems ?? []).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 10),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String subtitle,
    required List<String> bulletPoints,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...bulletPoints.map((pt) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    Expanded(
                      child: Text(
                        pt,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubInfoBox({required String title, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
