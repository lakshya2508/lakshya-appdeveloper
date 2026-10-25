import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearassist/models/virtual_tryon_model.dart';
import 'package:hearassist/data/virtual_tryon_service.dart';
import 'package:hearassist/state/virtual_tryon_controller.dart';
import 'package:hearassist/state/hear_assist_controller.dart';
import 'package:hearassist/data/local_store.dart';
import 'package:hearassist/data/speech_recognizer.dart';
import 'package:hearassist/ui/virtual_tryon_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Virtual Try-On Models', () {
    test('TryOnCategory parses and labels correctly', () {
      expect(TryOnCategory.fromString('eyewear'), TryOnCategory.eyewear);
      expect(TryOnCategory.fromString('headwear'), TryOnCategory.headwear);
      expect(TryOnCategory.fromString('footwear'), TryOnCategory.footwear);
      expect(TryOnCategory.fromString('unknown'), TryOnCategory.all);
      expect(TryOnCategory.eyewear.label, 'Eyewear');
    });

    test('TryOnItem serialize and deserialize', () {
      const item = TryOnItem(
        id: 'test_sunglass',
        name: 'Retro Glasses',
        category: TryOnCategory.eyewear,
        price: 99.0,
        description: 'Test description',
        image: 'assets/sunglasses.png',
        glbAsset: 'assets/rayban_sunglasses.glb',
      );

      final json = item.toJson();
      final parsed = TryOnItem.fromJson(json);

      expect(parsed.id, 'test_sunglass');
      expect(parsed.name, 'Retro Glasses');
      expect(parsed.category, TryOnCategory.eyewear);
      expect(parsed.price, 99.0);
      expect(parsed.glbAsset, 'assets/rayban_sunglasses.glb');
    });

    test('TryOnSession serialize and deserialize', () {
      final session = TryOnSession(
        id: 'sess-123',
        itemId: 'sunglass',
        itemName: 'Aviator Sunglasses',
        category: TryOnCategory.eyewear,
        originalImage: 'assets/sunglasses.png',
        resultImage: 'assets/sunglasses.png',
        timestamp: DateTime.parse('2026-10-25T12:00:00Z'),
        engineUsed: 'Local Neural Warp Engine',
        status: 'completed',
        durationMs: 450,
      );

      final json = session.toJson();
      final parsed = TryOnSession.fromJson(json);

      expect(parsed.id, 'sess-123');
      expect(parsed.itemName, 'Aviator Sunglasses');
      expect(parsed.durationMs, 450);
      expect(parsed.engineUsed, 'Local Neural Warp Engine');
    });
  });

  group('VirtualTryOnService', () {
    test('local pipeline generates session with progress callbacks', () async {
      final service = VirtualTryOnService();
      final progressStages = <String>[];
      final progressValues = <double>[];

      final session = await service.runTryOn(
        personImageData: 'assets/sunglasses.png',
        garmentItem: TryOnItem.catalog.first,
        onProgress: (prog, stage) {
          progressValues.add(prog);
          progressStages.add(stage);
        },
      );

      expect(session.status, 'completed');
      expect(session.itemId, 'sunglass');
      expect(session.engineUsed, 'Local Neural Warp Engine');
      expect(progressValues.isNotEmpty, true);
      expect(progressValues.last, 1.0);

      final saved = await service.loadSessions();
      expect(saved.length, 1);
      expect(saved.first.id, session.id);

      await service.clearSessions();
      final empty = await service.loadSessions();
      expect(empty.isEmpty, true);
    });

    test('saves and loads custom endpoint config', () async {
      final service = VirtualTryOnService();
      await service.saveConfig(
        endpoint: 'https://api.mycustomai.com/tryon',
        token: 'secret_token_123',
      );

      expect(await service.getSavedEndpoint(), 'https://api.mycustomai.com/tryon');
      expect(await service.getSavedToken(), 'secret_token_123');
    });
  });

  group('VirtualTryOnController', () {
    test('initializes and selects category and item', () async {
      final controller = VirtualTryOnController();
      await controller.init();

      expect(controller.initialized, true);
      expect(controller.catalog.isNotEmpty, true);
      expect(controller.selectedItem.id, 'sunglass');

      controller.selectCategory(TryOnCategory.footwear);
      expect(controller.selectedCategory, TryOnCategory.footwear);
      expect(controller.selectedItem.category, TryOnCategory.footwear);

      controller.setComparisonSlider(0.75);
      expect(controller.comparisonSlider, 0.75);

      controller.setViewMode('3d');
      expect(controller.viewMode, '3d');
    });

    test('generateTryOn updates activeSession and history', () async {
      final controller = VirtualTryOnController();
      await controller.init();

      expect(controller.activeSession, isNull);

      await controller.generateTryOn();

      expect(controller.activeSession, isNotNull);
      expect(controller.isProcessing, false);
      expect(controller.history.length, 1);

      controller.clearActiveSession();
      expect(controller.activeSession, isNull);
    });
  });

  group('VirtualTryOnScreen Widget', () {
    testWidgets('renders studio hero, sample avatar chips, and garment catalog', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final store = LocalStore();
      await store.initialize();
      final hearCtrl = HearAssistController(store: store, recognizer: SpeechRecognizer());
      await hearCtrl.load();

      final tryOnCtrl = VirtualTryOnController();
      await tryOnCtrl.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: hearCtrl),
            ChangeNotifierProvider.value(value: tryOnCtrl),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VirtualTryOnScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('VIRTUAL TRY-ON MODULE'), findsOneWidget);
      expect(find.text('AI Image Try-On'), findsOneWidget);
      expect(find.text('3D Spatial Orbit'), findsOneWidget);
      expect(find.text('1. Person Image'), findsOneWidget);
      expect(find.text('2. Select Garment or Accessory'), findsOneWidget);

      // Tap on 3D mode pill
      await tester.tap(find.text('3D Spatial Orbit'));
      await tester.pump();

      expect(tryOnCtrl.viewMode, '3d');
      expect(find.textContaining('3D Spatial Model:'), findsOneWidget);

      // Return to AI Try-On Mode and scroll down to action button
      await tester.tap(find.text('AI Image Try-On'));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(find.text('Generate Virtual Try-On'), findsOneWidget);
    });
  });
}
