import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pre-allocated text styles to avoid GoogleFonts.xxx() allocation on every build.
/// Every style used more than once across the app should be cached here.
class CachedStyles {
  CachedStyles._(); // prevent instantiation

  // ═══════════════════════════════════════════════════════
  // OUTFIT FONT STYLES
  // ═══════════════════════════════════════════════════════

  static final TextStyle outfitNormal = GoogleFonts.outfit();

  // --- White ---
  static final TextStyle outfitW400Size14L1White54 = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 1, color: Colors.white54,
  );
  static final TextStyle outfitW700Size13White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
  );
  static final TextStyle outfitW500Size12White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500,
  );
  static final TextStyle outfitW700Size8White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700,
  );
  static final TextStyle outfitW600Size11White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
  );
  static final TextStyle outfitW600Size12L1_2White54 = GoogleFonts.outfit(
    color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2,
  );
  static final TextStyle outfitNormalSize10White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal,
  );
  static final TextStyle outfitW500Size13L1_5White54 = GoogleFonts.outfit(
    color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.5,
  );
  static final TextStyle outfitBoldSize120White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitBoldSize12White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitBoldSize12WhiteAlpha80L1 = GoogleFonts.outfit(
    color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
  );

  // --- PostCard & Feed (post_card.dart, home_view.dart) ---
  static final TextStyle outfitBoldSize15White = GoogleFonts.outfit(
    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
  );
  static final TextStyle outfitSize12Grey = GoogleFonts.outfit(
    color: Colors.grey, fontSize: 12,
  );
  static final TextStyle outfitSize14_5White90H1_4 = GoogleFonts.outfit(
    color: Colors.white.withValues(alpha: 0.9), fontSize: 14.5, height: 1.4,
  );
  static final TextStyle outfitBoldSize12_5Cyan = GoogleFonts.outfit(
    color: const Color(0xFF06B6D4), fontSize: 12.5, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitSize13_5Grey = GoogleFonts.outfit(
    color: Colors.grey, fontSize: 13.5,
  );
  static final TextStyle outfitBoldSize13White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitSize13White87 = GoogleFonts.outfit(
    color: Colors.white.withValues(alpha: 0.87), fontSize: 13,
  );
  static final TextStyle outfitSize11White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 11,
  );
  static final TextStyle outfitSize14White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 14,
  );
  static final TextStyle outfitSize14White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 14,
  );
  static final TextStyle outfitBoldSize16White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitBoldSize18White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitSize12White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 12,
  );
  static final TextStyle outfitSize13White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 13,
  );
  static final TextStyle outfitW600Size13White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
  );
  static final TextStyle outfitSize11White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 11,
  );
  static final TextStyle outfitW500Size11White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500,
  );
  static final TextStyle outfitW600Size12White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
  );
  static final TextStyle outfitW500Size12White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500,
  );
  static final TextStyle outfitW400Size13White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w400,
  );
  static final TextStyle outfitBoldSize20White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitSize13White60H1_4 = GoogleFonts.outfit(
    color: Colors.white60, fontSize: 13, height: 1.4,
  );
  static final TextStyle outfitW600Size14White60L0_3 = GoogleFonts.outfit(
    color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3,
  );
  static final TextStyle outfitW600Size13White54L0_2 = GoogleFonts.outfit(
    color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static final TextStyle outfitW400Size13White54L0_2 = GoogleFonts.outfit(
    color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.2,
  );
  static final TextStyle outfitW600Size14White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
  );
  static final TextStyle outfitW500Size14White70L0_3 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3,
  );
  static final TextStyle outfitSize24White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 24,
  );
  static final TextStyle outfitW500Size12White38 = GoogleFonts.outfit(
    color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500,
  );
  static final TextStyle outfitBoldSize14White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitW700Size12White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
  );
  static final TextStyle outfitW500Size11White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500,
  );

  // --- Header (home_view.dart) ---
  static final TextStyle outfitW800Size26White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5,
  );

  // --- Quantum Arc Menu ---
  static final TextStyle outfitW700Size28L6White = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 6, color: Colors.white,
  );
  static final TextStyle outfitBoldSize9L1_5Cyan = GoogleFonts.outfit(
    fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF06B6D4), letterSpacing: 1.5, height: 1.1,
  );
  static final TextStyle outfitW400Size9L1_5White54 = GoogleFonts.outfit(
    fontSize: 9, fontWeight: FontWeight.w400, color: Colors.white54, letterSpacing: 1.5, height: 1.1,
  );

  // --- Feels View ---
  static final TextStyle outfitBoldSize14White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold,
  );
  static final TextStyle outfitW600Size10White70 = GoogleFonts.outfit(
    color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600,
  );

  // --- Search View ---
  static final TextStyle outfitSize16White = GoogleFonts.outfit(
    color: Colors.white, fontSize: 16,
  );

  // ═══════════════════════════════════════════════════════
  // RYE FONT STYLES
  // ═══════════════════════════════════════════════════════

  static final TextStyle ryeBoldSize32L4White = GoogleFonts.rye(
    fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.white,
  );
  static final TextStyle ryeW700Size18White = GoogleFonts.rye(
    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
  );
  static final TextStyle ryeBoldSize20White = GoogleFonts.rye(
    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
  );

  // ═══════════════════════════════════════════════════════
  // SHARE TECH MONO FONT STYLES
  // ═══════════════════════════════════════════════════════

  static final TextStyle shareTechMonoBoldSize10Cyan = GoogleFonts.shareTechMono(
    color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold,
  );
  static final TextStyle shareTechMonoNormalSize10L1_5White30 = GoogleFonts.shareTechMono(
    color: Colors.white30, fontSize: 10, letterSpacing: 1.5,
  );
  static final TextStyle shareTechMonoNormalSize9White54 = GoogleFonts.shareTechMono(
    color: Colors.white54, fontSize: 9,
  );

  // ═══════════════════════════════════════════════════════
  // BANGERS FONT STYLES
  // ═══════════════════════════════════════════════════════

  static final TextStyle bangersBoldSize16Red = GoogleFonts.bangers(
    color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold,
  );
}
