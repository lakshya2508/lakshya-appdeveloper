import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/state/virtual_tryon_controller.dart';
import 'package:hearassist/ui/home_screen.dart';
import 'package:hearassist/ui/settings_screen.dart';

class TestSpeechRecognizer implements SpeechRecognizer {
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

Widget buildTestApp(HearAssistController controller, [VirtualTryOnController? tryOnController]) {
  final tryOn = tryOnController ?? VirtualTryOnController();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HearAssistController>.value(value: controller),
      ChangeNotifierProvider<VirtualTryOnController>.value(value: tryOn),
    ],
    child: MaterialApp(
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('displays welcome onboarding on first launch and completes it', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: TestSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to HearAssist.'), findsOneWidget);
    expect(find.text('Let’s get started'), findsOneWidget);

    await tester.tap(find.text('Let’s get started'));
    await tester.pumpAndSettle();

    expect(find.text('Stay in the moment.\nCatch every word.'), findsOneWidget);
    expect(controller.onboarded, isTrue);
  });

  testWidgets('switches between bottom navigation tabs smoothly', (tester) async {
    final store = LocalStore();
    await store.initialize();
    await store.setOnboarded();
    final controller = HearAssistController(store: store, recognizer: TestSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Live captions'), findsNWidgets(2)); // Card and nav destination

    // Switch to Alerts tab (index 2)
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();
    expect(find.text('Sound alerts'), findsOneWidget);
    expect(find.text('Enable demo listener'), findsOneWidget);

    // Switch to History tab (index 3)
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsWidgets);

    // Switch back to Home tab (index 0)
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('YOUR COMPANION IS READY'), findsOneWidget);
  });

  testWidgets('Start listening hero action switches to Captions tab', (tester) async {
    final store = LocalStore();
    await store.initialize();
    await store.setOnboarded();
    final controller = HearAssistController(store: store, recognizer: TestSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildTestApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start listening'));
    await tester.pumpAndSettle();

    // Now on Captions screen
    expect(find.text('Ready to listen'), findsOneWidget);
  });
}
