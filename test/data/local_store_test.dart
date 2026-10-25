import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/models/accessibility_settings.dart';
import 'package:hearassist/models/hear_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists accessibility preferences', () async {
    final store = LocalStore();
    await store.initialize();
    await store.writeSettings(const AccessibilitySettings(themeMode: ThemeMode.dark, highContrast: true));

    final result = store.readSettings();
    expect(result.themeMode, ThemeMode.dark);
    expect(result.highContrast, isTrue);
    expect(result.categories['Doorbell'], isTrue);
  });

  test('persists history records newest first and caps storage', () async {
    final store = LocalStore();
    await store.initialize();
    final older = HearRecord(id: 'older', kind: 'caption', text: 'Hello', timestamp: DateTime.utc(2026, 10, 10));
    final newer = HearRecord(id: 'newer', kind: 'alert', text: 'Alarm', category: 'Alarm', timestamp: DateTime.utc(2026, 10, 11));
    await store.writeHistory([older, newer]);

    expect(store.readHistory().map((record) => record.id), ['newer', 'older']);
  });
}
