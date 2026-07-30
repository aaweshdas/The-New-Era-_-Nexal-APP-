import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../services/permission_service.dart';

class PermissionBottomSheet extends StatefulWidget {
  const PermissionBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final hasShown = await PermissionService.instance.hasShownOnboarding();
    if (hasShown) return;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const PermissionBottomSheet(),
    );

    // Mark as shown once sheet is dismissed or completed
    await PermissionService.instance.markOnboardingShown();
  }

  @override
  State<PermissionBottomSheet> createState() => _PermissionBottomSheetState();
}

class _PermissionBottomSheetState extends State<PermissionBottomSheet> {
  PermissionStatusModel? _status;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    final res = await PermissionService.instance.checkAllPermissions();
    if (mounted) {
      setState(() {
        _status = res;
      });
    }
  }

  Future<void> _handleGrantAll() async {
    setState(() => _isRequesting = true);
    final res = await PermissionService.instance.requestAllPermissions();
    if (mounted) {
      setState(() {
        _status = res;
        _isRequesting = false;
      });

      // Auto dismiss after a brief delay if permissions granted
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final allGranted = status?.allGranted ?? false;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0C20).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Subtitle Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.shield_check, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nexal App Permissions',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Allow access to import gallery & unlock features',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal Row of 5 Permission Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PermissionBadge(
                    icon: LucideIcons.image,
                    label: 'Gallery',
                    isGranted: status?.photos ?? false,
                  ),
                  _PermissionBadge(
                    icon: LucideIcons.camera,
                    label: 'Camera',
                    isGranted: status?.camera ?? false,
                  ),
                  _PermissionBadge(
                    icon: LucideIcons.mic,
                    label: 'Mic',
                    isGranted: status?.microphone ?? false,
                  ),
                  _PermissionBadge(
                    icon: LucideIcons.map_pin,
                    label: 'Location',
                    isGranted: status?.location ?? false,
                  ),
                  _PermissionBadge(
                    icon: LucideIcons.bell,
                    label: 'Alerts',
                    isGranted: status?.notifications ?? false,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Grant / Done Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: _isRequesting ? null : _handleGrantAll,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: allGranted
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFF7C3AED), const Color(0xFF00E5FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (allGranted ? const Color(0xFF10B981) : const Color(0xFF7C3AED))
                              .withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isRequesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 Icon(
                                  allGranted ? LucideIcons.circle_check : LucideIcons.sparkles,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  allGranted ? 'All Permissions Granted' : 'Grant Required Permissions',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Skip text button
              if (!allGranted)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGranted;

  const _PermissionBadge({
    required this.icon,
    required this.label,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGranted
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withValues(alpha: 0.15),
                  width: isGranted ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isGranted ? const Color(0xFF00E5FF) : Colors.white60,
                  size: 20,
                ),
              ),
            ),
            if (isGranted)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isGranted ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
