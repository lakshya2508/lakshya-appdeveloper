import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/models/accessibility_settings.dart';
import 'package:hearassist/state/hear_assist_controller.dart';

class FakeSpeechRecognizer implements SpeechRecognizer {
  @override
  bool isListening = false;

  @override
  String? lastError;

  @override
  bool hasPermission = true;

  @override
  Future<bool> checkPermission() async => hasPermission;

  bool shouldSucceedInit = true;
  void Function(String status)? statusCallback;
  void Function(String message)? errorCallback;
  SpeechResultCallback? resultCallback;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    statusCallback = onStatus;
    errorCallback = onError;
    return shouldSucceedInit;
  }

  @override
  Future<void> listen({required SpeechResultCallback onResult}) async {
    resultCallback = onResult;
  }

  @override
  Future<void> stop() async {
    isListening = false;
    statusCallback?.call('notListening');
  }

  @override
  Future<void> cancel() async {
    isListening = false;
  }

  void simulateListening() {
    isListening = true;
    statusCallback?.call('listening');
  }

  void simulateWords(String words, {bool isFinal = false}) {
    resultCallback?.call(words, isFinal);
  }

  void simulateError(String message) {
    errorCallback?.call(message);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStore store;
  late FakeSpeechRecognizer fakeRecognizer;
  late HearAssistController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore();
    await store.initialize();
    fakeRecognizer = FakeSpeechRecognizer();
    controller = HearAssistController(store: store, recognizer: fakeRecognizer);
    await controller.load();
  });

  tearDown(() {
    controller.dispose();
  });

  group('HearAssistController - Initialization & Settings', () {
    test('initializes with defaults and finishes onboarding', () async {
      expect(controller.initialized, isTrue);
      expect(controller.onboarded, isFalse);
      expect(controller.captionState, CaptionState.ready);

      await controller.finishOnboarding();
      expect(controller.onboarded, isTrue);
      expect(store.hasOnboarded, isTrue);
    });

    test('updates and resets settings', () async {
      await controller.updateSettings(
        const AccessibilitySettings(themeMode: ThemeMode.dark, captionScale: 1.5, highContrast: true),
      );
      expect(controller.settings.themeMode, ThemeMode.dark);
      expect(controller.settings.captionScale, 1.5);
      expect(controller.settings.highContrast, isTrue);

      await controller.resetSettings();
      expect(controller.settings.themeMode, ThemeMode.system);
      expect(controller.settings.captionScale, 1.0);
      expect(controller.settings.highContrast, isFalse);
    });
  });

  group('HearAssistController - Captions and Speech Recognition', () {
    test('startListening transitions from requesting to listening honestly', () async {
      final startFuture = controller.startListening();
      expect(controller.captionState, CaptionState.requesting);

      fakeRecognizer.simulateListening();
      await startFuture;
      expect(controller.captionState, CaptionState.listening);
    });

    test('handles speech recognition interim and final results', () async {
      await controller.startListening();
      fakeRecognizer.simulateListening();

      fakeRecognizer.simulateWords('Hello wor', isFinal: false);
      expect(controller.partialText, 'Hello wor');
      expect(controller.history, isEmpty);

      fakeRecognizer.simulateWords('Hello world', isFinal: true);
      expect(controller.partialText, isEmpty);
      expect(controller.history.length, 1);
      expect(controller.history.first.kind, 'caption');
      expect(controller.history.first.text, 'Hello world');
    });

    test('handles permission denied error message clearly', () async {
      await controller.startListening();
      fakeRecognizer.simulateError('error_permission_denied');

      expect(controller.captionState, CaptionState.error);
      expect(controller.errorMessage, contains('permission was denied'));
    });

    test('handles unavailable speech service gracefully', () async {
      fakeRecognizer.shouldSucceedInit = false;
      await controller.startListening();

      expect(controller.captionState, CaptionState.error);
      expect(controller.errorMessage, contains('unavailable'));
    });

    test('pauses and resumes listening', () async {
      await controller.startListening();
      fakeRecognizer.simulateListening();

      await controller.pauseListening();
      expect(controller.captionState, CaptionState.paused);

      final resumeFuture = controller.resumeListening();
      expect(controller.captionState, CaptionState.requesting);
      fakeRecognizer.simulateListening();
      await resumeFuture;
      expect(controller.captionState, CaptionState.listening);
    });

    test('stops listening and returns to ready', () async {
      await controller.startListening();
      fakeRecognizer.simulateListening();

      await controller.stopListening();
      expect(controller.captionState, CaptionState.ready);
      expect(controller.partialText, isEmpty);
    });

    test('adds sample caption marked as DEMO SAMPLE and clears error state', () {
      controller.captionState = CaptionState.error;
      controller.errorMessage = 'Service unavailable';

      controller.addSampleCaption();
      expect(controller.history.first.kind, 'caption');
      expect(controller.history.first.category, 'DEMO SAMPLE');
      expect(controller.captionState, CaptionState.ready);
      expect(controller.errorMessage, isNull);
    });

    test('clears only caption records', () {
      controller.addSampleCaption();
      controller.demoAlertsEnabled = true;
      controller.createDemoAlert('Doorbell');
      expect(controller.history.length, 2);

      controller.clearCaptions();
      expect(controller.history.length, 1);
      expect(controller.history.first.kind, 'alert');
    });
  });

  group('HearAssistController - Demo Sound Alerts', () {
    test('does nothing when demo alerts are disabled', () async {
      controller.demoAlertsEnabled = false;
      await controller.createDemoAlert('Alarm');
      expect(controller.history, isEmpty);
    });

    test('creates demo alert for specified category when enabled', () async {
      controller.setDemoAlerts(true);
      await controller.createDemoAlert('Doorbell');

      expect(controller.history.length, 1);
      final record = controller.history.first;
      expect(record.kind, 'alert');
      expect(record.category, 'Doorbell');
      expect(record.text, contains('door'));
    });

    test('respects history retention preference', () async {
      controller.setDemoAlerts(true);
      await controller.updateSettings(controller.settings.copyWith(retainHistory: false));

      await controller.createDemoAlert('Alarm');
      expect(controller.history, isEmpty);
    });
  });

  group('HearAssistController - History Search and Filtering', () {
    setUp(() {
      controller.setDemoAlerts(true);
      controller.createDemoAlert('Doorbell');
      controller.createDemoAlert('Alarm');
      controller.addSampleCaption();
    });

    test('filters by kind', () {
      controller.setHistoryFilter('all');
      expect(controller.filteredHistory.length, 3);

      controller.setHistoryFilter('caption');
      expect(controller.filteredHistory.length, 1);

      controller.setHistoryFilter('alert');
      expect(controller.filteredHistory.length, 2);
    });

    test('searches query across text and category', () {
      controller.setHistoryQuery('doorbell');
      expect(controller.filteredHistory.length, 1);
      expect(controller.filteredHistory.first.category, 'Doorbell');

      controller.setHistoryQuery('nonexistent');
      expect(controller.filteredHistory, isEmpty);
    });

    test('clears entire history', () async {
      await controller.clearHistory();
      expect(controller.history, isEmpty);
      expect(controller.filteredHistory, isEmpty);
      expect(store.readHistory(), isEmpty);
    });
  });
}
