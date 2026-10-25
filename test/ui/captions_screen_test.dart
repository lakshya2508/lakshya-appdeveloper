import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/ui/captions_screen.dart';

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

Widget buildCaptionsTest(HearAssistController controller) {
  return ChangeNotifierProvider<HearAssistController>.value(
    value: controller,
    child: const MaterialApp(
      home: Scaffold(body: CaptionsScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('displays ready status and speech session limitation note', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildCaptionsTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('Ready to listen'), findsOneWidget);
    expect(find.text('Start listening'), findsOneWidget);
    expect(find.textContaining('intermittent speech (up to 55s)'), findsOneWidget);
  });

  testWidgets('shows error banner and sample caption button on error', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    controller.captionState = CaptionState.error;
    controller.errorMessage = 'Microphone permission was denied. Enable it in device settings to try again.';

    await tester.pumpWidget(buildCaptionsTest(controller));
    await tester.pumpAndSettle();

    expect(find.textContaining('permission was denied'), findsOneWidget);
    expect(find.text('Show sample caption · DEMO'), findsOneWidget);

    await tester.tap(find.text('Show sample caption · DEMO'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A sample caption: Welcome to your conversation.'), findsOneWidget);
    expect(find.textContaining('DEMO SAMPLE'), findsOneWidget);
  });

  testWidgets('adjusts caption text scale via quick buttons', (tester) async {
    final store = LocalStore();
    await store.initialize();
    final controller = HearAssistController(store: store, recognizer: StubSpeechRecognizer());
    await controller.load();

    await tester.pumpWidget(buildCaptionsTest(controller));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.text_increase));
    await tester.pumpAndSettle();

    expect(find.text('110%'), findsOneWidget);
    expect(controller.settings.captionScale, 1.1);
  });
}
