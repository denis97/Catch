import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDefaultAccent = Color(0xFF2AA198);

const Map<String, Color> kLineColors = {
  '14B': Color(0xFF2D6CDF),
  '2':   Color(0xFF2AA198),
  'M3':  Color(0xFF7A52CC),
  'RX':  Color(0xFFC24A3B),
  'F1':  Color(0xFF1E88C7),
};

class AppTheme {
  final Color accent;
  final bool dark;

  const AppTheme({required this.accent, required this.dark});

  // ── Accent softs ──
  Color get accentSoft => accent.withValues(alpha: dark ? 0.22 : 0.12);
  Color get accentSoftStrong => accent.withValues(alpha: dark ? 0.30 : 0.16);

  // ── Urgency colours ──
  Color get amber => dark ? const Color(0xFFF2A93B) : const Color(0xFFD9850A);
  Color get amberSoft => amber.withValues(alpha: dark ? 0.18 : 0.12);
  Color get missed => dark ? const Color(0xFF727B85) : const Color(0xFF98A2AD);

  // ── Surfaces ──
  Color get pageBg   => dark ? const Color(0xFF0C0E11) : const Color(0xFFF1F3F5);
  Color get card     => dark ? const Color(0xFF16191D) : Colors.white;
  Color get cardAlt  => dark ? const Color(0xFF1F2429) : const Color(0xFFF6F7F9);
  Color get chipBg   => dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF101418).withValues(alpha: 0.05);

  // ── Text ──
  Color get text    => dark ? const Color(0xFFF2F4F6) : const Color(0xFF101418);
  Color get textSec => dark ? const Color(0xFF9AA3AD) : const Color(0xFF5B6570);
  Color get textTer => dark ? const Color(0xFF69727C) : const Color(0xFF9AA3AD);

  // ── Structural ──
  Color get border    => dark ? Colors.white.withValues(alpha: 0.09)   : const Color(0xFF101418).withValues(alpha: 0.07);
  Color get separator => dark ? Colors.white.withValues(alpha: 0.07)   : const Color(0xFF101418).withValues(alpha: 0.06);

  List<BoxShadow> get shadow => dark
      ? [const BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
         const BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 10))]
      : [const BoxShadow(color: Color(0x0D101418), blurRadius: 2, offset: Offset(0, 1)),
         const BoxShadow(color: Color(0x0D101418), blurRadius: 24, offset: Offset(0, 8))];

  // ── Radii ──
  static const double radius   = 22;
  static const double radiusSm = 14;

  Color urgencyColor(int leaveIn) {
    if (leaveIn <= 0) return missed;
    if (leaveIn <= 3) return amber;
    return accent;
  }

  Color urgencyBg(int leaveIn) {
    if (leaveIn <= 0) return chipBg;
    if (leaveIn <= 3) return amberSoft;
    return accentSoft;
  }

  TextStyle get bodyFont => GoogleFonts.hankenGrotesk();

  TextTheme get textTheme => GoogleFonts.hankenGroteskTextTheme().copyWith(
    bodyLarge: GoogleFonts.hankenGrotesk(color: text),
    bodyMedium: GoogleFonts.hankenGrotesk(color: text),
  );
}
