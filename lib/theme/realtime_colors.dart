import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realtime Palette definition with light/dark adaptive tokens and WCAG metrics.
class RealtimePalette {
  const RealtimePalette({
    required this.id,
    required this.name,
    required this.tag,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.lightCanvas,
    required this.lightPaper,
    required this.lightInk,
    required this.lightMuted,
    required this.lightLine,
    required this.darkCanvas,
    required this.darkPaper,
    required this.darkInk,
    required this.darkMuted,
    required this.darkLine,
  });

  final String id;
  final String name;
  final String tag;
  final Color primary;
  final Color secondary;
  final Color accent;

  final Color lightCanvas;
  final Color lightPaper;
  final Color lightInk;
  final Color lightMuted;
  final Color lightLine;

  final Color darkCanvas;
  final Color darkPaper;
  final Color darkInk;
  final Color darkMuted;
  final Color darkLine;

  Color canvas(bool isDark) => isDark ? darkCanvas : lightCanvas;
  Color paper(bool isDark) => isDark ? darkPaper : lightPaper;
  Color ink(bool isDark) => isDark ? darkInk : lightInk;
  Color muted(bool isDark) => isDark ? darkMuted : lightMuted;
  Color line(bool isDark) => isDark ? darkLine : lightLine;

  ColorScheme toColorScheme(bool isDark, bool highContrast) {
    if (highContrast) {
      return ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: isDark ? const Color(0xff90caf9) : const Color(0xff002f6c),
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: isDark ? const Color(0xff80cbc4) : const Color(0xff004d40),
        onSecondary: isDark ? Colors.black : Colors.white,
        error: isDark ? const Color(0xffef9a9a) : const Color(0xffb71c1c),
        onError: isDark ? Colors.black : Colors.white,
        surface: isDark ? Colors.black : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black,
        outline: isDark ? Colors.white : Colors.black,
        outlineVariant: isDark ? const Color(0xff999999) : const Color(0xff444444),
      );
    }

    final bg = canvas(isDark);
    final cardBg = paper(isDark);
    final textColor = ink(isDark);

    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withAlpha(isDark ? 55 : 35),
      onPrimaryContainer: isDark ? const Color(0xffe0f2f1) : primary,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondary.withAlpha(isDark ? 50 : 30),
      onSecondaryContainer: textColor,
      tertiary: accent,
      onTertiary: Colors.black,
      error: const Color(0xffba1a1a),
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xff491212) : const Color(0xffffdad6),
      onErrorContainer: isDark ? const Color(0xffffb4ab) : const Color(0xff410002),
      surface: cardBg,
      onSurface: textColor,
      surfaceContainerHighest: bg,
      outline: line(isDark),
      outlineVariant: line(isDark).withAlpha(120),
    );
  }
}

class RealtimeColors {
  static const curated = <String, RealtimePalette>{
    'aurora': RealtimePalette(
      id: 'aurora',
      name: 'Emerald Aurora',
      tag: 'Calm & Accessible',
      primary: Color(0xff0c7770),
      secondary: Color(0xff36b39b),
      accent: Color(0xff4ade80),
      lightCanvas: Color(0xfff4f8f7),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff143133),
      lightMuted: Color(0xff6f8584),
      lightLine: Color(0xffe3ece9),
      darkCanvas: Color(0xff0f2020),
      darkPaper: Color(0xff172c2b),
      darkInk: Color(0xffe3f2ef),
      darkMuted: Color(0xff8aa3a0),
      darkLine: Color(0xff27413f),
    ),
    'violet': RealtimePalette(
      id: 'violet',
      name: 'Cosmic Violet',
      tag: 'Modern & Electric',
      primary: Color(0xff7c3aed),
      secondary: Color(0xffa855f7),
      accent: Color(0xffec4899),
      lightCanvas: Color(0xfff8f6fd),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff1c1533),
      lightMuted: Color(0xff766e94),
      lightLine: Color(0xffebe5f7),
      darkCanvas: Color(0xff120d22),
      darkPaper: Color(0xff1c1533),
      darkInk: Color(0xfff3efff),
      darkMuted: Color(0xff968bb8),
      darkLine: Color(0xff2f2452),
    ),
    'coral': RealtimePalette(
      id: 'coral',
      name: 'Sunset Coral',
      tag: 'Warm & High-Energy',
      primary: Color(0xffe11d48),
      secondary: Color(0xfff59e0b),
      accent: Color(0xfffb7185),
      lightCanvas: Color(0xfffff7f5),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff2d141b),
      lightMuted: Color(0xff8d6d75),
      lightLine: Color(0xfffae6e8),
      darkCanvas: Color(0xff200c12),
      darkPaper: Color(0xff2e131b),
      darkInk: Color(0xffffecef),
      darkMuted: Color(0xffb38d97),
      darkLine: Color(0xff4a202c),
    ),
    'azure': RealtimePalette(
      id: 'azure',
      name: 'Oceanic Azure',
      tag: 'Crisp & Deep Marine',
      primary: Color(0xff0284c7),
      secondary: Color(0xff06b6d4),
      accent: Color(0xff38bdf8),
      lightCanvas: Color(0xfff0f8ff),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff0e243a),
      lightMuted: Color(0xff627c94),
      lightLine: Color(0xffe1effa),
      darkCanvas: Color(0xff0a1622),
      darkPaper: Color(0xff122334),
      darkInk: Color(0xffe5f3ff),
      darkMuted: Color(0xff85a4c0),
      darkLine: Color(0xff1c3750),
    ),
    'jade': RealtimePalette(
      id: 'jade',
      name: 'Forest Jade',
      tag: 'Botanical & Grounded',
      primary: Color(0xff15803d),
      secondary: Color(0xff22c55e),
      accent: Color(0xff84cc16),
      lightCanvas: Color(0xfff2fbf4),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff0e2817),
      lightMuted: Color(0xff5e7d67),
      lightLine: Color(0xffe0f3e5),
      darkCanvas: Color(0xff0b1b10),
      darkPaper: Color(0xff132c1b),
      darkInk: Color(0xffe7faec),
      darkMuted: Color(0xff7ba586),
      darkLine: Color(0xff1f4329),
    ),
    'highContrast': RealtimePalette(
      id: 'highContrast',
      name: 'Solar Hyper-Contrast',
      tag: 'WCAG AAA Maximum',
      primary: Color(0xff0052cc),
      secondary: Color(0xff00875a),
      accent: Color(0xffff9900),
      lightCanvas: Color(0xffffffff),
      lightPaper: Color(0xffffffff),
      lightInk: Color(0xff000000),
      lightMuted: Color(0xff333333),
      lightLine: Color(0xff777777),
      darkCanvas: Color(0xff000000),
      darkPaper: Color(0xff0a0a0a),
      darkInk: Color(0xffffffff),
      darkMuted: Color(0xffcccccc),
      darkLine: Color(0xff888888),
    ),
  };

  static double getRelativeLuminance(Color color) {
    double transform(double v) {
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double getContrastRatio(Color c1, Color c2) {
    final lum1 = getRelativeLuminance(c1);
    final lum2 = getRelativeLuminance(c2);
    final brightest = math.max(lum1, lum2);
    final darkest = math.min(lum1, lum2);
    return (brightest + 0.05) / (darkest + 0.05);
  }

  static ({double ratio, bool passAA, bool passAAA, String rating, String label}) evaluateContrast(Color fg, Color bg) {
    final raw = getContrastRatio(fg, bg);
    final ratio = (raw * 10).round() / 10;
    final passAA = ratio >= 4.5;
    final passAAA = ratio >= 7.0;
    final rating = passAAA ? 'AAA' : (passAA ? 'AA' : 'Fail');
    final label = '$ratio:1 $rating';
    return (ratio: ratio, passAA: passAA, passAAA: passAAA, rating: rating, label: label);
  }

  static RealtimePalette generateRandomHarmonicPalette() {
    final rand = math.Random();
    final baseHue = rand.nextInt(360).toDouble();
    final secondaryHue = (baseHue + 40) % 360;
    final accentHue = (baseHue + 160) % 360;

    Color hsl(double h, double s, double l) =>
        HSLColor.fromAHSL(1.0, h, (s / 100).clamp(0.0, 1.0), (l / 100).clamp(0.0, 1.0)).toColor();

    final primary = hsl(baseHue, 78, 38);
    final secondary = hsl(secondaryHue, 82, 48);
    final accent = hsl(accentHue, 88, 55);

    return RealtimePalette(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Harmonic #${baseHue.toInt()}°',
      tag: 'Realtime Generative',
      primary: primary,
      secondary: secondary,
      accent: accent,
      lightCanvas: hsl(baseHue, 22, 97),
      lightPaper: Colors.white,
      lightInk: hsl(baseHue, 45, 14),
      lightMuted: hsl(baseHue, 18, 48),
      lightLine: hsl(baseHue, 25, 91),
      darkCanvas: hsl(baseHue, 35, 8),
      darkPaper: hsl(baseHue, 30, 14),
      darkInk: hsl(baseHue, 15, 96),
      darkMuted: hsl(baseHue, 15, 65),
      darkLine: hsl(baseHue, 22, 24),
    );
  }

  static Color alertColorFor(String category) {
    return switch (category) {
      'Doorbell' => const Color(0xfff59e0b),
      'Alarm' => const Color(0xffef4444),
      'Siren' => const Color(0xffdc2626),
      'Knocking' => const Color(0xffeab308),
      'Timer' => const Color(0xff06b6d4),
      _ => const Color(0xff8b5cf6),
    };
  }
}
