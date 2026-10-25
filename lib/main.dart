import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'data/speech_recognizer.dart';
import 'state/hear_assist_controller.dart';
import 'state/virtual_tryon_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore();
  await store.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HearAssistController(
            store: store,
            recognizer: SpeechRecognizer(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => VirtualTryOnController()..init(),
        ),
      ],
      child: const HearAssistApp(),
    ),
  );
}
