import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsNavItem {
  final IconData icon;
  final String label;

  const SettingsNavItem({required this.icon, required this.label});
}

const List<SettingsNavItem> kSettingsNavItems = [
  SettingsNavItem(icon: LucideIcons.cpu,         label: 'System'),
  SettingsNavItem(icon: LucideIcons.palette,     label: 'Visuals'),
  SettingsNavItem(icon: LucideIcons.shieldCheck, label: 'Security'),
  SettingsNavItem(icon: LucideIcons.activity,    label: 'Diagn.'),
  SettingsNavItem(icon: LucideIcons.bell,        label: 'Notifs'),
  SettingsNavItem(icon: LucideIcons.info,        label: 'About'),
];

class SettingsNavRail extends StatelessWidget {
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onLogoutTap;
  final String username;

  const SettingsNavRail({
    super.key,
    required this.selectedIndex,
    required this.accentColor,
    required this.onDestinationSelected,
    this.onLogoutTap,
    this.username = 'User',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 98,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            children: [
              // User Avatar Section
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.4),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.45),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'N',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      username.length > 9
                          ? '${username.substring(0, 8)}…'
                          : username,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 10),

              // Navigation Rail Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  itemCount: kSettingsNavItems.length,
                  itemBuilder: (context, i) {
                    final item = kSettingsNavItems[i];
                    final isActive = selectedIndex == i;
                    return _NavRailItem(
                      icon: item.icon,
                      label: item.label,
                      isActive: isActive,
                      accentColor: accentColor,
                      onTap: () => onDestinationSelected(i),
                    );
                  },
                ),
              ),

              // Logout Button at Bottom of Rail
              if (onLogoutTap != null) ...[
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: GestureDetector(
                    onTap: onLogoutTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(height: 4),
                          Text(
                            'Logout',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavRailItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.70)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.30),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 21,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
