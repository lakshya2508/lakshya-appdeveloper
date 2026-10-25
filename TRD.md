# HearAssist — Technical Requirements Document

**Version:** 1.0  
**Status:** Draft for implementation  
**Product:** HearAssist — Accessible Companion  
**Tagline:** Understand more. Stay connected.  
**Platform target:** Flutter for Android and iOS  
**Project type:** Independent accessibility portfolio project

## 1. Purpose

HearAssist is a mobile companion intended to make nearby speech easier to follow through readable captions, provide a visual interface for sound-alert concepts, and let users adapt presentation to their accessibility preferences.

This document defines product behavior, technical architecture, privacy requirements, platform dependencies, and verification criteria. HearAssist is not an emergency detection system and must not be presented as a replacement for safety equipment. The project is independent and must not imply endorsement by Ksham Innovation or another company.

## 2. Goals and scope

### Goals

- Provide an accessible, calm, readable Flutter application using Material 3.
- Provide a real speech-recognition path where the device and speech service support it.
- Clearly disclose speech-service availability and platform/provider data handling.
- Provide clearly labeled sample experiences where genuine detection is unavailable.
- Keep user preferences and retained history on the device by default.
- Keep UI, state, models, persistence, and service integrations separate enough to maintain and test.

### In scope

- Onboarding, Home, Live Captions, Sound Alerts, History, and Settings.
- Android and iOS Flutter application source.
- Local preferences and history persistence.
- Device speech-recognition integration through a Flutter plugin.
- A manual sound-alert simulator.
- A configurable REST repository interface and documented JSON contract, with no live endpoint configured.
- Unit and widget test coverage for supported behavior.

### Out of scope for the initial release

- Real-world sound classification or emergency detection.
- Continuous/background microphone recording.
- Cloud accounts, transcript sync, or a production backend.
- Firebase, a hosted database, or secret API credentials.
- Camera capture, ARCore/ARKit tracking, or an AR feature presented as implemented.
- Regulatory or safety certification claims.

## 3. Users and use cases

Primary users are people who are deaf or hard of hearing, people who benefit from visual communication, and people who prefer large, high-contrast text and visual status cues.

Key use cases:

1. A user opens the app and learns what it does before granting permissions.
2. A user starts a caption session, grants microphone/speech permission if asked, and follows partial and finalized text.
3. A user pauses, resumes, stops, clears, or enlarges a caption transcript.
4. A user explores a manually triggered example alert and chooses which example categories are enabled.
5. A user searches or filters local caption and demo-alert history and deletes it.
6. A user changes theme, contrast, motion, caption size, vibration, and history-retention preferences.

## 4. Navigation and screen requirements

The application shall provide a persistent bottom navigation bar with four destinations: **Home**, **Captions**, **Alerts**, and **History**. **Settings** shall be reachable from Home and an app-bar settings action. Routes must support back navigation and retain appropriate in-memory state when switching tabs.

### 4.1 Onboarding

- Explain the caption and visual-alert objectives.
- Explain that microphone permission is requested only when the user starts captions.
- Disclose that device speech services may process audio under their own terms.
- Label sound-alert examples as simulated unless a real detector is integrated.
- Store completion locally so onboarding is not repeated on every launch.

### 4.2 Home

- Show a greeting, accessibility-mode summary, recent activity, and shortcuts to core features.
- Provide a prominent Start Listening action.
- Show microphone permission guidance without implying permission has been granted.
- Show clear listening states: Ready, Requesting, Listening, Paused, and Error.
- Only show an active listening indicator after the platform recognizer reports that it is listening.
- Show an explicit warning that demo alerts are not a safety system.

### 4.3 Live Captions

- Start and stop a supported device speech-recognition session.
- Show partial text when supported and timestamp finalized entries.
- Provide pause, resume, clear-transcript, and caption-size controls.
- Show meaningful denied-permission, unavailable-service, and runtime-error messages with retry guidance.
- Dispose of recognition resources when the owning controller is disposed.
- Do not claim that the plugin provides guaranteed continuous transcription. The selected speech plugin is designed for short/intermittent sessions; platform timeouts may end listening.
- If recognition is unavailable, offer only a user-triggered sample caption labeled as a demo. Sample text must never be represented as microphone transcription.

### 4.4 Sound Alerts

- Provide categories for Doorbell, Alarm, Siren, Knocking, Timer, and Other.
- Provide explicit demo enable/disable state and an intentional user-triggered sample event.
- Timestamp each sample and retain it only when local history retention is enabled.
- Optionally issue haptic feedback when the user has enabled vibration and the platform supports it.
- Label the feature DEMO MODE; do not say a sound was detected by a classifier.
- Display a notice that this does not detect emergencies or replace safety equipment.

### 4.5 History

- Display caption and alert records with timestamps and category/type.
- Support search by text/category and filters for All, Captions, and Alerts.
- Provide an empty state and a no-results state.
- Require confirmation before clearing all saved history.
- Keep no more than 200 records in the current local-store implementation.

### 4.6 Settings

Settings shall include:

- Theme: System, Light, or Dark.
- Caption text scale.
- High-contrast mode.
- Reduced-motion preference.
- Vibration preference.
- Per-category sound-alert preferences.
- Local history-retention preference.
- Microphone/speech permission guidance.
- Privacy information, clear-history action, and reset-to-defaults action.

Preference changes shall be applied to the visible UI and persisted locally where possible. Turning history retention off shall prevent newly created records from being written; previously saved history remains until deleted.

## 5. System architecture

### 5.1 Technology

- **UI and application logic:** Dart and Flutter, Material 3.
- **State management:** Provider with a `ChangeNotifier` application controller.
- **Speech recognition:** `speech_to_text` plugin, initialized lazily at caption start.
- **Local persistence:** `shared_preferences`, storing JSON-encoded preferences and records.
- **REST adapter:** Dart `HttpClient` example behind a repository interface; it is not wired to a live endpoint.
- **Testing:** `flutter_test` and Flutter lints.

### 5.2 Code organization

```text
lib/
  main.dart
  app.dart
  data/
    local_store.dart
    records_api.dart
    speech_recognizer.dart
  models/
    accessibility_settings.dart
    hear_record.dart
  state/
    hear_assist_controller.dart
  ui/
    home_screen.dart
    captions_screen.dart
    alerts_screen.dart
    history_screen.dart
    settings_screen.dart
    widgets.dart
test/
  data/
  models/
```

### 5.3 Data model

Every history record shall contain:

| Field | Type | Requirement |
|---|---|---|
| `id` | String | Unique local identifier |
| `kind` | String | `caption` or `alert` |
| `text` | String | Caption text or sample-alert description |
| `timestamp` | ISO-8601 date/time | Event creation time; serialized as UTC |
| `category` | String | Alert category, optional for captions |

The preference model shall contain theme mode, caption scale, high-contrast setting, reduced-motion setting, vibration setting, history-retention setting, and per-category alert preferences.

## 6. Speech-recognition and permission requirements

- Do not request microphone access on app launch or during onboarding.
- Start the platform recognition flow only after the user taps Start Listening.
- Declare Android `RECORD_AUDIO` and `INTERNET` permissions and a recognition-service query required by current Android package visibility rules.
- Declare iOS `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` purpose strings.
- Handle permission denial and recognition unavailability without crashing or displaying a false listening state.
- Explain that the plugin delegates recognition to device/platform services, which may use remote processing depending on device/provider configuration.
- No app-level audio recording or audio upload is in scope.
- Stop/cancel recognition on user stop and dispose/cancel the recognizer when its controller is disposed.

## 7. Local storage and privacy

- Store only user-selected preferences and caption/alert history needed for the product experience.
- Store preferences/history in app-local preferences as JSON; no account or cloud sync is configured.
- Cap history at 200 records and provide a user-controlled delete action.
- Do not store audio.
- Do not send transcripts to the example REST adapter unless a real endpoint is deliberately configured after consent and privacy review.
- `shared_preferences` is not an encrypted database. The app must not claim encrypted storage or regulatory compliance.
- The platform speech provider’s data policy is separate from HearAssist local storage and must be disclosed to the user.

## 8. REST/JSON contract

No live API endpoint is specified. The repository example uses a configurable base URI and an 8-second timeout.

- `GET /records` returns a JSON array of records.
- `POST /records` accepts a JSON record and may return the created record.
- Handle non-2xx status codes, malformed JSON, empty responses, and timeouts explicitly.
- Never hardcode credentials or present local mock results as server responses.

Example record:

```json
{
  "id": "record-123",
  "kind": "caption",
  "text": "The meeting starts at ten.",
  "timestamp": "2026-10-12T10:30:00.000Z",
  "category": ""
}
```

## 9. Accessibility and UX quality

- Use semantic Material controls with meaningful labels and keyboard/screen-reader support.
- Maintain clear focus indication and adequate touch targets.
- Respect the system theme and support light/dark appearance.
- Make caption scale affect both the transcript and the preview.
- Make high contrast alter color/surface treatment and reduced motion disable route transitions.
- Provide readable error, warning, and empty states; do not communicate state through color alone.
- Test layouts with system text scaling and narrow phone widths.

## 10. Error handling and lifecycle

- Permission denied: explain how to enable permission in system settings; do not repeatedly prompt without user action.
- Speech service unavailable: provide retry and a separately labeled sample caption.
- Recognition runtime error: show an actionable message, return to a non-listening state, and allow retry.
- Local persistence failure: keep the UI usable for the current session and do not claim data was saved.
- REST timeout/status/JSON error: surface a recoverable error and retry action if remote requests are later exposed in the UI.
- Clear or stop actions must be safe when tapped repeatedly.
- Cancel active recognition during controller disposal and do not update disposed widgets.

## 11. Testing and acceptance criteria

### Automated tests

- Record model JSON round-trip and malformed input behavior.
- Settings defaults/copy behavior and local persistence.
- History persistence, ordering, cap, search, and filters.
- Controller state transitions, recognition errors, and demo-alert creation using a mockable speech interface.
- Widget rendering/navigation, onboarding completion, caption controls, demo alert controls, settings effects, and empty-history state.

### Manual device verification

- Android and iOS permission grant/denial and service unavailable behavior.
- Speech pause/time-limit behavior and resource cleanup after leaving the screen/app.
- Light/dark theme, high contrast, large system text, reduced motion, small/large screens, and screen-reader labels.
- Demo event creation and no-event state.
- History search, filtering, retention disabled, and deletion confirmation.
- Slow/unavailable network if a real API is later connected.

### Acceptance conditions

- All four bottom-nav destinations and the Settings route are reachable and usable.
- Every primary control performs an operation or has an explicit demo/unavailable label.
- Listening UI reflects actual recognizer callbacks only.
- Settings persist and visibly affect the interface.
- Captions/alerts follow the documented storage and privacy behavior.
- No real sound detection, emergency capability, or AR tracking is claimed unless implemented and tested.
- Builds and test results are reported accurately for the toolchain/device used.

## 12. Current implementation and verification status

The Flutter source and model/local-store tests are present in this repository. The current machine did not have Flutter, Dart, Android SDK, or Gradle available, so Flutter dependency resolution, analysis, tests, and native builds have **not** been run. The repository includes the app-level Android manifest and iOS permission strings/entry point, but requires generated Gradle and Xcode runner scaffolding before it is a directly installable application. The README documents how to generate a Flutter shell, copy the app source into it, merge permissions, and run the project.

The JavaScript prototype that was initially created is not the target product and its earlier test/build results do not verify this Flutter source.

## 13. Future roadmap

1. Generate Android/iOS runner projects and validate on physical devices.
2. Improve speech-session UX around platform-imposed pauses/time limits; do not imply always-on captioning.
3. Evaluate an on-device sound-classification model using representative data and measured error rates before exposing real alerts.
4. Add a backend only if required, with explicit consent, authentication, retention/deletion policy, and API tests.
5. Consider Kotlin/Swift platform channels only where plugin capabilities are insufficient.
6. Explore optional AR only with actual camera permission handling and verified ARCore/ARKit tracking; otherwise keep the feature conceptual.
