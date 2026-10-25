import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/models/accessibility_settings.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/ui/settings_screen.dart';

class StubSpeechRecognizer implements SpeechRecognizer {
  @override
  bool isListening = false;
  @override
  String? lastError;
  @override
  bool hasPermission = true;
  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async => true;

  @override
  Future<void> listen({required SpeechResultCallback onResult}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

Widget buildSettingsTest(HearAssistController controller) {
  return ChangeNotifierProvider<HearAssistController>.value(
    value: controller,
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders all preference groups and updates high contrast', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildSettingsTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('High contrast'), findsOneWidget);
    expect(find.text('Reduce motion'), findsOneWidget);
    expect(find.text('Reading comfort'), findsOneWidget);
    expect(find.text('Sound alert categories'), findsOneWidget);

    // Toggle high contrast switch
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();

    expect(controller.settings.highContrast, isTrue);

    await tester.scrollUntilVisible(find.text('Privacy & history'), 300);
    expect(find.text('Privacy & history'), findsOneWidget);
  });

  testWidgets('resets preferences with confirmation dialog', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await controller.updateSettings(
      const AccessibilitySettings(themeMode: ThemeMode.dark, captionScale: 1.4, highContrast: true),
    );

    await tester.pumpWidget(buildSettingsTest(controller));
    await tester.pumpAndSettle();

    // Scroll down to the reset button
    await tester.scrollUntilVisible(find.text('Reset preferences to defaults'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Reset preferences to defaults'), findsOneWidget);
    await tester.tap(find.text('Reset preferences to defaults'));
    await tester.pumpAndSettle();

    expect(find.text('Reset all preferences?'), findsOneWidget);
    await tester.tap(find.text('Reset defaults'));
    await tester.pumpAndSettle();

    expect(controller.settings.themeMode, ThemeMode.system);
    expect(controller.settings.captionScale, 1.0);
    expect(controller.settings.highContrast, isFalse);
  });
}
