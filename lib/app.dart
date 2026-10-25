import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/hear_assist_controller.dart';
import 'theme/realtime_colors.dart';
import 'ui/alerts_screen.dart';
import 'ui/captions_screen.dart';
import 'ui/haikei_background.dart';
import 'ui/history_screen.dart';
import 'ui/home_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/virtual_tryon_screen.dart';

class HearAssistApp extends StatelessWidget {
  const HearAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final activePalette = controller.activePalette;

    return MaterialApp(
      title: 'HearAssist',
      debugShowCheckedModeBanner: false,
      themeMode: controller.settings.themeMode,
      theme: HearAssistTheme.create(
        activePalette,
        isDark: false,
        highContrast: controller.settings.highContrast,
        reduceMotion: controller.settings.reduceMotion,
      ),
      darkTheme: HearAssistTheme.create(
        activePalette,
        isDark: true,
        highContrast: controller.settings.highContrast,
        reduceMotion: controller.settings.reduceMotion,
      ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return HaikeiAmbientCanvas(
          palette: activePalette,
          isDark: isDark,
          alertFlashColor: controller.alertFlashColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/': (_) => const HomeScreen(),
        '/captions': (_) => const _FeatureRoute(title: 'Live captions', child: CaptionsScreen()),
        '/alerts': (_) => const _FeatureRoute(title: 'Sound alerts · Demo', child: AlertsScreen()),
        '/history': (_) => const _FeatureRoute(title: 'History', child: HistoryScreen()),
        '/settings': (_) => const SettingsScreen(),
        '/virtual-try-on': (_) => const _FeatureRoute(title: 'Virtual Try-On Studio', child: VirtualTryOnScreen()),
      },
    );
  }
}

class _FeatureRoute extends StatelessWidget {
  const _FeatureRoute({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: child,
      );
}

class HearAssistTheme {
  static ThemeData create(
    RealtimePalette palette, {
    required bool isDark,
    required bool highContrast,
    required bool reduceMotion,
  }) {
    final scheme = palette.toColorScheme(isDark, highContrast);
    final bgColor = Colors.transparent;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgColor,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: reduceMotion
          ? PageTransitionsTheme(builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoMotionTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.1),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -.4),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface.withAlpha(highContrast ? 255 : (isDark ? 230 : 240)),
        elevation: highContrast ? 0 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: highContrast ? scheme.outline : scheme.outlineVariant.withAlpha(80),
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _NoMotionTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
