import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileAnalyticsScreen extends StatelessWidget {
  const ProfileAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        'ANALYTICS DASHBOARD',
                        style: GoogleFonts.rye(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERFORMANCE METRICS (LAST 30 DAYS)',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metric Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Impressions',
                            '142.8K',
                            '+18.4%',
                            const Color(0xFF00E5FF),
                            LucideIcons.eye,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Profile Visits',
                            '34.2K',
                            '+24.1%',
                            const Color(0xFFFF6BAD),
                            LucideIcons.userCheck,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Engagement',
                            '8.9%',
                            '+3.2%',
                            const Color(0xFFB07EFF),
                            LucideIcons.zap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Shares',
                            '4.1K',
                            '+12.0%',
                            const Color(0xFF10B981),
                            LucideIcons.share2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Audience Breakdown
                    Text(
                      'TOP SECTOR AUDIENCE',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildAudienceRow('Digital Metaverse', 0.45, const Color(0xFF00E5FF)),
                    _buildAudienceRow('Quantum Systems', 0.30, const Color(0xFFB07EFF)),
                    _buildAudienceRow('AI Research', 0.15, const Color(0xFFFF6BAD)),
                    _buildAudienceRow('Cyber Design', 0.10, const Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String val, String change, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: c, size: 18),
              Text(
                change,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceRow(String label, double pct, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              Text('${(pct * 100).toInt()}%', style: GoogleFonts.outfit(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(c),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
