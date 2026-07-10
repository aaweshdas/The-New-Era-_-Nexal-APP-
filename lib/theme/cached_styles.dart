import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CachedStyles {
  // Outfit Font Styles
  static final TextStyle outfitNormal = GoogleFonts.outfit();
  
  static final TextStyle outfitW400Size14L1White54 = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    color: Colors.white54,
  );

  static final TextStyle outfitW700Size13White = GoogleFonts.outfit(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle outfitW500Size12White70 = GoogleFonts.outfit(
    color: Colors.white70,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle outfitW700Size8White = GoogleFonts.outfit(
    color: Colors.white,
    fontSize: 8,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle outfitW600Size11White = GoogleFonts.outfit(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle outfitW600Size12L1_2White54 = GoogleFonts.outfit(
    color: Colors.white54,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static final TextStyle outfitNormalSize10White70 = GoogleFonts.outfit(
    color: Colors.white70,
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle outfitW500Size13L1_5White54 = GoogleFonts.outfit(
    color: Colors.white54,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  static final TextStyle outfitBoldSize120White = GoogleFonts.outfit(
    color: Colors.white,
    fontSize: 120,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle outfitBoldSize12White = GoogleFonts.outfit(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle outfitBoldSize12WhiteAlpha80L1 = GoogleFonts.outfit(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  // Rye Font Styles
  static final TextStyle ryeBoldSize32L4White = GoogleFonts.rye(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
    color: Colors.white,
  );

  static final TextStyle ryeW700Size18White = GoogleFonts.rye(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // ShareTechMono Font Styles
  static final TextStyle shareTechMonoBoldSize10Cyan = GoogleFonts.shareTechMono(
    color: const Color(0xFF00E5FF),
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle shareTechMonoNormalSize10L1_5White30 = GoogleFonts.shareTechMono(
    color: Colors.white30,
    fontSize: 10,
    letterSpacing: 1.5,
  );

  static final TextStyle shareTechMonoNormalSize9White54 = GoogleFonts.shareTechMono(
    color: Colors.white54,
    fontSize: 9,
  );

  // Bangers Font Style
  static final TextStyle bangersBoldSize16Red = GoogleFonts.bangers(
    color: Colors.red,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}
