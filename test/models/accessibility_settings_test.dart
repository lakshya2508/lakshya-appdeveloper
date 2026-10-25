import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearassist/models/accessibility_settings.dart';

void main() {
  test('copyWith preserves defaults and replaces selected preferences', () {
    const defaults = AccessibilitySettings();
    final updated = defaults.copyWith(themeMode: ThemeMode.dark, captionScale: 1.4, highContrast: true);

    expect(updated.themeMode, ThemeMode.dark);
    expect(updated.captionScale, 1.4);
    expect(updated.highContrast, isTrue);
    expect(updated.retainHistory, isTrue);
    expect(updated.categories['Doorbell'], isTrue);
  });
}
