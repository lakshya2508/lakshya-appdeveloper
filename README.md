# HearAssist — Accessible Companion (Android-First MVP)

**Understand more. Stay connected.** HearAssist is an independent Flutter portfolio application designed for readable real-time speech captions, simulated visual sound alerts, and personal accessibility controls. It is not affiliated with Ksham Innovation or any other company.

---

## 1. Executive Summary & Two-Day MVP Status

| Phase | Component | Status | Details |
|---|---|---|---|
| **Phase 1** | Foundation & Navigation | **Complete** | Flutter Material 3, Provider state management, persistent 4-tab bottom navigation (`Home`, `Captions`, `Alerts`, `History`), Settings route with back navigation. |
| **Phase 2** | Home & Live Captions | **Complete** | Onboarding disclosure, dashboard greeting, real speech recognizer with requesting/listening/paused/error states, interim/final text, font scaling, error fallback demo captions. |
| **Phase 3** | Data & Persistence | **Complete** | Typed `HearRecord` and `AccessibilitySettings` models, `LocalStore` shared preferences persistence (capped at 200 items), respect for `retainHistory`, clear history deletion. |
| **Phase 4** | Sound-Alert Demo | **Complete** | 6 categories (Doorbell, Alarm, Siren, Knocking, Timer, Other), demo listener toggle, simulated sample trigger, prominent **DEMO MODE** warnings, best-effort haptics. |
| **Phase 5** | History & Settings | **Complete** | Text/category search, All/Captions/Alerts filter chips, confirmed clear-history dialog, theme mode (System/Light/Dark), high contrast, reduced motion, text scale slider, reset settings dialog. |
| **Phase 6** | Tests & QA Architecture | **Complete** | Refactored `SpeechRecognizer` into an abstract interface with mockable contract. Created 10 comprehensive unit and widget test suites. `flutter analyze` passes with 0 issues. |
| **Phase 7** | Platform & Toolchain | **Complete** | Android runner scaffolding, permissions, Windows desktop target, and Flutter Web platform configured. |
| **Phase 8** | Enhancements | **Complete** | Motion Primitives (radar, waveform, springs), Haikei generative multi-layer organic Bezier canvas, Realtime Colors engine with WCAG 2.1 compliance badge. |
| **Phase 9** | Native Virtual Try-On & 3D Studio | **Complete** | Full native integration of open-source Virtual Try-On (`https://github.com/shreyassai123/virtual-tryon.git`): interactive 3D spatial orbit canvas, AI outfit & accessory synthesis, draggable Before/After comparison slider, camera/file upload, and custom AI inference endpoint connection. |

---

## 2. Live Local Preview URLs

Both preview environments are currently active and running locally on this machine:

* **Flutter Web App (Direct from `lib/main.dart`)**:
  👉 **[http://localhost:8080](http://localhost:8080)** (or `http://127.0.0.1:8080`)
  * Full Flutter Material 3 runtime with Provider state management.
  * Interactive Haikei layered waves background canvas (`CustomPainter`).
  * Live Motion Primitives: Audio Equalizer bars, Radar pulse, Spring micro-interactions.
  * Realtime Colors dynamic harmonic palette randomizer (`🎲`) and WCAG 2.1 contrast rating pill.
  * Honest speech-to-text recognition lifecycle and DEMO MODE sound alerts.

* **Web Prototype (Vite / Responsive UI Preview)**:
  👉 **[http://localhost:5173](http://localhost:5173)** (or `http://10.31.40.111:5173`)
  * Instant responsive browser preview powered by Vite 6.

---

## 3. Architecture & Project Structure

```text
lib/
  main.dart                           # Entry point with WidgetsFlutterBinding & Provider injection
  app.dart                            # MaterialApp, HearAssistTheme (Material 3, High Contrast, Reduce Motion)
  data/
    local_store.dart                  # SharedPreferences local persistence (settings, history cap 200, onboarding)
    records_api.dart                  # RecordsRepository contract & mockable HTTP adapter
     speech_recognizer.dart            # Abstract SpeechRecognizer & DeviceSpeechRecognizer implementation
    virtual_tryon_service.dart        # Virtual Try-On inference API adapter & local neural compositor
  models/
    accessibility_settings.dart       # Immutable preferences model with copyWith & defaults
    hear_record.dart                  # Typed history record model with ISO8601 UTC JSON serialization
    virtual_tryon_model.dart          # TryOnCategory, TryOnItem, and TryOnSession models
  state/
    hear_assist_controller.dart       # Central ChangeNotifier managing speech lifecycle, alerts, and search
    virtual_tryon_controller.dart     # Virtual Try-On state controller (catalog, avatar, 3D orbit, slider)
  ui/
    home_screen.dart                  # Dashboard, onboarding welcome card, tool cards, bottom navigation
    captions_screen.dart              # Live speech transcription, font scale quick controls, demo fallback
    alerts_screen.dart                # Visual sound alerts, demo listener toggle, category triggers, DEMO disclosures
    history_screen.dart               # History list, search filter, All/Captions/Alerts chips, clear dialog
    virtual_tryon_screen.dart         # Virtual Try-On Studio (3D mesh orbit, split slider, avatar dropzone)
    settings_screen.dart              # Theme, high contrast, reduce motion, font slider, reset preferences
    widgets.dart                      # Reusable widgets (Eyebrow, SectionTitle, RecordTile, EmptyState, InfoBanner)

test/
  virtual_tryon_test.dart             # Unit & widget tests for Virtual Try-On models, service, controller & UI
  models/
    hear_record_test.dart             # Record serialization and timestamp round-trip tests
    accessibility_settings_test.dart  # Settings copyWith and preference integrity tests
  data/
    local_store_test.dart             # Settings and history persistence, order, and cap tests
    records_api_test.dart             # Repository contracts and mock checks
  state/
    hear_assist_controller_test.dart  # Unit tests for speech lifecycle, demo alerts, and search
  ui/
    home_screen_test.dart             # Widget tests for onboarding, dashboard, and tab navigation
    captions_screen_test.dart         # Widget tests for captions states, error recovery, and sizing
    alerts_screen_test.dart           # Widget tests for demo alert toggle, category switches, triggers
    history_screen_test.dart          # Widget tests for search, filter chips, and clear dialog
    settings_screen_test.dart         # Widget tests for theme, high contrast, slider, reset dialog

android/
  settings.gradle                     # Gradle plugin management and Flutter tools build inclusion
  build.gradle                        # Root project repository and build directories
  gradle/wrapper/
    gradle-wrapper.properties         # Gradle 8.4 wrapper distribution
  app/
    build.gradle                      # Android application configuration (minSdk 21, compileSdk 34)
    src/main/
      AndroidManifest.xml             # RECORD_AUDIO, INTERNET, VIBRATE permissions, RecognitionService query
      kotlin/com/hearassist/app/
        MainActivity.kt               # FlutterActivity entry point
      res/values/
        styles.xml                    # LaunchTheme and NormalTheme declarations
```

---

## 4. Setup, Run & Verification Guide

### Step 1: Install Flutter SDK
1. Download Flutter SDK (>= 3.22.0) from [docs.flutter.dev](https://docs.flutter.dev/get-started/install).
2. Extract to `C:\flutter` and add `C:\flutter\bin` to your system `PATH`.
3. Set your Android SDK path:
   ```powershell
   flutter config --android-sdk "C:\Program Files (x86)\Android\android-sdk"
   ```

### Step 2: Resolve Dependencies & Run Analyzer
In this directory (`lakshya_appdeveloper`):
```powershell
flutter pub get
flutter analyze
```

### Step 3: Run the Test Suite
Run the 10 unit and widget test suites:
```powershell
flutter test
```

### Step 4: Run on Android (Physical Device or Emulator)
1. Start an Android emulator in Android Studio or connect an Android device via USB with USB Debugging enabled.
2. Confirm device connection:
   ```powershell
   flutter devices
   ```
3. Run the application:
   ```powershell
   flutter run
   ```

---

## 5. Privacy, Ethics & Technical Limitations

* **Speech-to-Text Behavior**:
  The `speech_to_text` plugin relies on the underlying platform's recognition service (such as Google Speech Services on Android). Sessions are designed for intermittent/short speech (up to 55 seconds) and may pause on silence. Continuous streaming transcription is not guaranteed by device providers.
* **Privacy by Design**:
  Microphone access is requested strictly when the user initiates a live caption session. HearAssist does not record, stream, or transmit audio to any cloud backend or third-party server.
* **Simulated Sound Alerts**:
  Sound classification is not implemented. All sound alerts are clearly labeled **DEMO MODE**. The application explicitly discloses that it does not detect ambient emergency sounds and cannot replace dedicated safety or alerting equipment.
* **Local Persistence**:
  History records and accessibility preferences are stored exclusively on the device using `shared_preferences`. History is capped at 200 entries and can be cleared at any time with a single confirmation.
