import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/ui/alerts_screen.dart';

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

Widget buildAlertsTest(HearAssistController controller) {
  return ChangeNotifierProvider<HearAssistController>.value(
    value: controller,
    child: const MaterialApp(
      home: Scaffold(body: AlertsScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders DEMO MODE warning and disables trigger when switch is off', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildAlertsTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('Visual awareness · Demo mode'), findsOneWidget);
    expect(find.textContaining('DEMO MODE: Sample events are manually triggered'), findsOneWidget);

    final triggerFinder = find.widgetWithText(FilledButton, 'Trigger random sample alert');
    final button = tester.widget<FilledButton>(triggerFinder);
    expect(button.onPressed, isNull); // Disabled because demo listener is OFF
  });

  testWidgets('enables trigger and adds sample alert when demo listener is switched on', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildAlertsTest(controller));
    await tester.pumpAndSettle();

    // Toggle switch on
    await tester.tap(find.text('Enable demo listener'));
    await tester.pumpAndSettle();

    expect(controller.demoAlertsEnabled, isTrue);

    // Tap trigger sample alert
    await tester.tap(find.text('Trigger random sample alert'));
    await tester.pumpAndSettle();

    expect(controller.history, isNotEmpty);
    expect(controller.history.first.kind, 'alert');
  });
}
