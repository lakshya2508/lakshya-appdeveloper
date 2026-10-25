import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String words, bool isFinal);

/// Abstract speech recognizer contract.
/// Enables mock recognizers in unit/widget tests and decouples from native platform channels.
abstract class SpeechRecognizer {
  factory SpeechRecognizer() = DeviceSpeechRecognizer;

  bool get isListening;
  String? get lastError;
  bool get hasPermission => true;
  Future<bool> checkPermission() async => true;

  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  });

  Future<void> listen({required SpeechResultCallback onResult});
  Future<void> stop();
  Future<void> cancel();
}

/// Device speech recognition implementation using `speech_to_text`.
/// Note: Plugin sessions are designed for short/intermittent recognition (up to 55s)
/// and may stop on platform timeouts or audio pauses.
class DeviceSpeechRecognizer implements SpeechRecognizer {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _hasPermission = false;

  @override
  String? lastError;

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> checkPermission() async {
    try {
      _hasPermission = await _speech.hasPermission;
      return _hasPermission;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onStatus: onStatus,
        onError: (SpeechRecognitionError error) {
          lastError = error.errorMsg;
          onError(error.errorMsg);
        },
        debugLogging: false,
      );
      try {
        _hasPermission = await _speech.hasPermission;
      } catch (_) {}
      return _initialized;
    } catch (e) {
      lastError = e.toString();
      onError(e.toString());
      return false;
    }
  }

  @override
  Future<void> listen({required SpeechResultCallback onResult}) async {
    lastError = null;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) =>
            onResult(result.recognizedWords, result.finalResult),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 55),
          pauseFor: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}
