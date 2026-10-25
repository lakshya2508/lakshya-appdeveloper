import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/ui/history_screen.dart';

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

Widget buildHistoryTest(HearAssistController controller) {
  return ChangeNotifierProvider<HearAssistController>.value(
    value: controller,
    child: const MaterialApp(
      home: Scaffold(body: HistoryScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows empty state when history is empty', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildHistoryTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('Your history starts here'), findsOneWidget);
    expect(find.text('Saved captions and demo alerts will appear here.'), findsOneWidget);
  });

  testWidgets('filters history and clears it with confirmation dialog', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    controller.setDemoAlerts(true);
    await controller.createDemoAlert('Doorbell');
    controller.addSampleCaption();

    await tester.pumpWidget(buildHistoryTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Captions'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);

    // Filter to Captions only
    await tester.tap(find.text('Captions'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO SAMPLE'), findsOneWidget);
    expect(find.text('Doorbell'), findsNothing);

    // Tap clear history action chip
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Clear history?'), findsOneWidget);
    expect(find.text('Delete history'), findsOneWidget);

    await tester.tap(find.text('Delete history'));
    await tester.pumpAndSettle();

    expect(controller.history, isEmpty);
    expect(find.text('Your history starts here'), findsOneWidget);
  });
}
