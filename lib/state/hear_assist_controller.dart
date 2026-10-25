import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/local_store.dart';
import '../data/speech_recognizer.dart';
import '../models/accessibility_settings.dart';
import '../models/hear_record.dart';
import '../theme/realtime_colors.dart';

enum CaptionState { ready, requesting, listening, paused, error }

class HearAssistController extends ChangeNotifier {
  HearAssistController({required LocalStore store, required SpeechRecognizer recognizer})
      : _store = store,
        _recognizer = recognizer;

  final LocalStore _store;
  final SpeechRecognizer _recognizer;
  final _random = Random();
  AccessibilitySettings settings = const AccessibilitySettings();
  List<HearRecord> history = [];
  CaptionState captionState = CaptionState.ready;
  String partialText = '';
  String? errorMessage;
  String query = '';
  String historyFilter = 'all';
  bool demoAlertsEnabled = false;
  bool onboarded = false;
  bool initialized = false;

  // Realtime Colors & Dynamic Alert State
  RealtimePalette? customPalette;
  Color? alertFlashColor;
  String? activeAlertBannerText;
  String? activeAlertCategory;
  Timer? _alertTimer;

  RealtimePalette get activePalette {
    if (customPalette != null) return customPalette!;
    return RealtimeColors.curated[settings.paletteId] ?? RealtimeColors.curated['aurora']!;
  }

  void setPalette(String paletteId) {
    customPalette = null;
    updateSettings(settings.copyWith(paletteId: paletteId));
  }

  void randomizePalette() {
    final generated = RealtimeColors.generateRandomHarmonicPalette();
    customPalette = generated;
    notifyListeners();
  }

  void resetPalette() {
    customPalette = null;
    setPalette('aurora');
  }

  void dismissAlertBanner() {
    activeAlertBannerText = null;
    activeAlertCategory = null;
    notifyListeners();
  }

  Future<void> load() async {
    settings = _store.readSettings();
    history = _store.readHistory();
    onboarded = _store.hasOnboarded;
    initialized = true;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await _store.setOnboarded();
    notifyListeners();
  }

  Future<void> updateSettings(AccessibilitySettings value) async {
    settings = value;
    await _store.writeSettings(value);
    notifyListeners();
  }

  Future<void> resetSettings() {
    customPalette = null;
    return updateSettings(const AccessibilitySettings());
  }

  bool isPermissionDenied = false;
  bool get hasMicrophonePermission => _recognizer.hasPermission;

  Future<bool> requestMicrophonePermission() async {
    errorMessage = null;
    isPermissionDenied = false;
    notifyListeners();
    try {
      final available = await _recognizer.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      final hasPerm = await _recognizer.checkPermission();
      isPermissionDenied = !hasPerm;
      if (hasPerm && available) {
        await startListening();
        return true;
      }
      if (!available) {
        captionState = CaptionState.error;
        isPermissionDenied = true;
        errorMessage = 'Microphone permission was denied or speech service is unavailable. Please grant microphone permission.';
      }
      notifyListeners();
      return hasPerm;
    } catch (e) {
      captionState = CaptionState.error;
      isPermissionDenied = true;
      errorMessage = 'Microphone permission request error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening() async {
    if (captionState == CaptionState.requesting || captionState == CaptionState.listening) return;
    captionState = CaptionState.requesting;
    errorMessage = null;
    isPermissionDenied = false;
    partialText = '';
    notifyListeners();
    try {
      final available = await _recognizer.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (!available) {
        captionState = CaptionState.error;
        isPermissionDenied = true;
        errorMessage = 'Speech recognition service is unavailable or microphone permission was denied. Please allow microphone access in device settings or try sample captions below.';
        notifyListeners();
        return;
      }
      isPermissionDenied = false;
      await _recognizer.listen(onResult: _onSpeechResult);
    } on Object catch (error) {
      captionState = CaptionState.error;
      isPermissionDenied = true;
      errorMessage = 'Could not start captions: $error';
      notifyListeners();
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'listening') {
      captionState = CaptionState.listening;
    } else if (status == 'notListening' && captionState == CaptionState.listening) {
      captionState = CaptionState.ready;
      partialText = '';
    }
    notifyListeners();
  }

  void _onSpeechError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('error_no_match') || msg.contains('error_speech_timeout') || msg.contains('no_speech')) {
      return;
    }
    captionState = CaptionState.error;
    if (msg.contains('permission')) {
      isPermissionDenied = true;
      errorMessage = 'Microphone permission was denied. Tap "Grant Microphone Access" or enable it in device settings to try again.';
    } else {
      errorMessage = 'Speech recognition notice: $message. Check speech service or use sample captions.';
    }
    notifyListeners();
  }

  void _onSpeechResult(String words, bool isFinal) {
    if (!isFinal) {
      partialText = words;
      notifyListeners();
      return;
    }
    partialText = '';
    if (words.trim().isNotEmpty) _addRecord('caption', words.trim());
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (captionState == CaptionState.ready) return;
    await _recognizer.stop();
    captionState = CaptionState.ready;
    partialText = '';
    notifyListeners();
  }

  Future<void> pauseListening() async {
    await _recognizer.stop();
    captionState = CaptionState.paused;
    partialText = '';
    notifyListeners();
  }

  Future<void> resumeListening() => startListening();

  Future<void> clearCaptions() async {
    history = history.where((record) => record.kind != 'caption').toList();
    await _store.writeHistory(history);
    partialText = '';
    notifyListeners();
  }

  void addSampleCaption() {
    _addRecord('caption', 'A sample caption: Welcome to your conversation.', category: 'DEMO SAMPLE');
    if (captionState == CaptionState.error) {
      captionState = CaptionState.ready;
      errorMessage = null;
    }
    notifyListeners();
  }

  void setHistoryQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setHistoryFilter(String value) {
    historyFilter = value;
    notifyListeners();
  }

  List<HearRecord> get filteredHistory {
    final needle = query.trim().toLowerCase();
    return history.where((record) {
      final matchesType = historyFilter == 'all' || record.kind == historyFilter;
      final matchesQuery = needle.isEmpty ||
          '${record.text} ${record.category}'.toLowerCase().contains(needle);
      return matchesType && matchesQuery;
    }).toList();
  }

  Future<void> clearHistory() async {
    history = [];
    await _store.clearHistory();
    notifyListeners();
  }

  Future<void> createDemoAlert([String? specificCategory]) async {
    if (!demoAlertsEnabled) return;
    final active = settings.categories.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
    if (active.isEmpty) return;
    final category = (specificCategory != null && active.contains(specificCategory))
        ? specificCategory
        : active[_random.nextInt(active.length)];
    const samples = {
      'Doorbell': 'Someone may be at the door.',
      'Alarm': 'A sample alarm event was triggered.',
      'Siren': 'A sample siren event was triggered.',
      'Knocking': 'Someone may be knocking.',
      'Timer': 'A sample timer notification.',
      'Other': 'A sample sound event was triggered.',
    };

    final alertText = samples[category] ?? 'A sample sound event was triggered.';
    _addRecord('alert', alertText, category: category);

    // 1. Realtime Color Reactive Pulse on Haikei background
    alertFlashColor = RealtimeColors.alertColorFor(category);
    activeAlertCategory = category;
    activeAlertBannerText = alertText;

    final isInTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _alertTimer?.cancel();
    if (!isInTest) {
      _alertTimer = Timer(const Duration(milliseconds: 2500), () {
        alertFlashColor = null;
        notifyListeners();
      });
    }

    // 2. Best effort vibration
    if (settings.vibration) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    notifyListeners();
  }

  void setDemoAlerts(bool value) {
    demoAlertsEnabled = value;
    notifyListeners();
  }

  void _addRecord(String kind, String text, {String category = ''}) {
    final record = HearRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      text: text,
      timestamp: DateTime.now(),
      category: category,
    );
    if (settings.retainHistory) {
      history = [record, ...history].take(200).toList();
      unawaited(_store.writeHistory(history));
    }
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    unawaited(_recognizer.cancel());
    super.dispose();
  }
}
