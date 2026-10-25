import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_settings.dart';
import '../models/hear_record.dart';

class LocalStore {
  static const _historyKey = 'hearassist.history.v1';
  static const _settingsKey = 'hearassist.settings.v1';
  static const _onboardingKey = 'hearassist.onboarded.v1';
  late SharedPreferences _preferences;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  AccessibilitySettings readSettings() {
    final raw = _preferences.getString(_settingsKey);
    if (raw == null) return const AccessibilitySettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final categories = (json['categories'] as Map?)
          ?.map((key, value) => MapEntry(key.toString(), value == true));
      return AccessibilitySettings(
        themeMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == json['theme'],
          orElse: () => ThemeMode.system,
        ),
        paletteId: (json['paletteId'] as String?) ?? 'aurora',
        captionScale: (json['captionScale'] as num?)?.toDouble() ?? 1,
        highContrast: json['highContrast'] == true,
        reduceMotion: json['reduceMotion'] == true,
        vibration: json['vibration'] == true,
        retainHistory: json['retainHistory'] != false,
        categories: {...const AccessibilitySettings().categories, ...?categories},
      );
    } on Object {
      return const AccessibilitySettings();
    }
  }

  Future<void> writeSettings(AccessibilitySettings settings) async {
    await _preferences.setString(_settingsKey, jsonEncode({
      'theme': settings.themeMode.name,
      'paletteId': settings.paletteId,
      'captionScale': settings.captionScale,
      'highContrast': settings.highContrast,
      'reduceMotion': settings.reduceMotion,
      'vibration': settings.vibration,
      'retainHistory': settings.retainHistory,
      'categories': settings.categories,
    }));
  }

  List<HearRecord> readHistory() {
    final raw = _preferences.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => HearRecord.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } on Object {
      return [];
    }
  }

  Future<void> writeHistory(List<HearRecord> records) async {
    await _preferences.setString(
      _historyKey,
      jsonEncode(records.take(200).map((record) => record.toJson()).toList()),
    );
  }

  Future<void> clearHistory() async {
    await _preferences.remove(_historyKey);
  }

  bool get hasOnboarded => _preferences.getBool(_onboardingKey) ?? false;
  Future<void> setOnboarded() => _preferences.setBool(_onboardingKey, true);
  Future<void> resetOnboarding() => _preferences.remove(_onboardingKey);
}
