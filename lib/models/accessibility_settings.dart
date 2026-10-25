import 'package:flutter/material.dart';

class AccessibilitySettings {
  const AccessibilitySettings({
    this.themeMode = ThemeMode.system,
    this.paletteId = 'aurora',
    this.captionScale = 1,
    this.highContrast = false,
    this.reduceMotion = false,
    this.vibration = false,
    this.retainHistory = true,
    this.categories = const {
      'Doorbell': true,
      'Alarm': true,
      'Siren': true,
      'Knocking': true,
      'Timer': true,
      'Other': true,
    },
  });

  final ThemeMode themeMode;
  final String paletteId;
  final double captionScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool vibration;
  final bool retainHistory;
  final Map<String, bool> categories;

  AccessibilitySettings copyWith({
    ThemeMode? themeMode,
    String? paletteId,
    double? captionScale,
    bool? highContrast,
    bool? reduceMotion,
    bool? vibration,
    bool? retainHistory,
    Map<String, bool>? categories,
  }) => AccessibilitySettings(
        themeMode: themeMode ?? this.themeMode,
        paletteId: paletteId ?? this.paletteId,
        captionScale: captionScale ?? this.captionScale,
        highContrast: highContrast ?? this.highContrast,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        vibration: vibration ?? this.vibration,
        retainHistory: retainHistory ?? this.retainHistory,
        categories: categories ?? this.categories,
      );
}
