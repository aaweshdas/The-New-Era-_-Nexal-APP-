import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsNavItem {
  final IconData icon;
  final String label;

  const SettingsNavItem({required this.icon, required this.label});
}

const List<SettingsNavItem> kSettingsNavItems = [
  SettingsNavItem(icon: LucideIcons.cpu,        label: 'System'),
  SettingsNavItem(icon: LucideIcons.palette,    label: 'Visuals'),
  SettingsNavItem(icon: LucideIcons.shieldCheck,label: 'Security'),
  SettingsNavItem(icon: LucideIcons.activity,   label: 'Diagn.'),
  SettingsNavItem(icon: LucideIcons.bell,       label: 'Notifs'),
  SettingsNavItem(icon: LucideIcons.info,       label: 'About'),
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
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF080C18),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        children: [
          // Avatar section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  username.length > 9
                      ? '${username.substring(0, 8)}…'
                      : username,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 10),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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

          // Logout Button at bottom of rail
          if (onLogoutTap != null) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: GestureDetector(
                onTap: onLogoutTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.logOut, size: 18, color: Colors.redAccent),
                      SizedBox(height: 4),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
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
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isActive ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? accentColor : Colors.white30,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white30,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
