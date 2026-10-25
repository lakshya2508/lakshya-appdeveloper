import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hear_assist_controller.dart';
import '../theme/realtime_colors.dart';
import 'alerts_screen.dart';
import 'captions_screen.dart';
import 'haikei_background.dart';
import 'history_screen.dart';
import 'motion_primitives.dart';
import 'virtual_tryon_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    if (!controller.initialized) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!controller.onboarded) {
      return _WelcomeScreen(onContinue: controller.finishOnboarding);
    }

    final activePal = controller.activePalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contrast = RealtimeColors.evaluateContrast(
      activePal.ink(isDark),
      activePal.canvas(isDark),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('hearassist', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.5)),
        backgroundColor: Colors.transparent,
        actions: [
          // Realtime Colors Quick Switcher & Contrast Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activePal.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: activePal.primary.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '★ ${contrast.rating}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: activePal.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Randomize Realtime Palette (Dice)',
            onPressed: controller.randomizePalette,
            icon: const Text('🎲', style: TextStyle(fontSize: 17)),
          ),
          IconButton(
            tooltip: 'Open settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Motion Alert Pop-in Toast
          if (controller.activeAlertBannerText != null)
            MotionAlertBanner(
              category: controller.activeAlertCategory ?? 'Other',
              text: controller.activeAlertBannerText!,
              onDismiss: controller.dismissAlertBanner,
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                _Dashboard(onSelectTab: (index) => setState(() => _index = index)),
                const CaptionsScreen(),
                const AlertsScreen(),
                const HistoryScreen(),
                const VirtualTryOnScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(230),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.closed_caption_outlined), selectedIcon: Icon(Icons.closed_caption), label: 'Live captions'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications_active), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.auto_fix_high_outlined), selectedIcon: Icon(Icons.auto_fix_high), label: 'Try-On'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onSelectTab});
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final recent = controller.history.take(3).toList();
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 18 ? 'Good afternoon' : 'Good evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Eyebrow('${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}'),
        const SizedBox(height: 4),
        Text('$greeting, Alex 👋', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('Your space for a little more understanding.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        _HeroCard(
          palette: controller.activePalette,
          onStart: () => onSelectTab(1),
        ),
        const SizedBox(height: 14),
        const Eyebrow('Your tools'),
        const SizedBox(height: 4),
        const SectionTitle('A little help, right on time'),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final cards = [
            _ToolCard(
              icon: Icons.closed_caption_outlined,
              title: 'Live captions',
              body: 'Follow conversations as they happen with fluid text and animated audio waves.',
              label: 'Open captions',
              onTap: () => onSelectTab(1),
            ),
            _ToolCard(
              icon: Icons.notifications_active_outlined,
              title: 'Sound alerts · DEMO',
              body: 'Explore visual alerts for important sounds with real-time color pulses.',
              label: 'Explore alerts',
              onTap: () => onSelectTab(2),
            ),
            _ToolCard(
              icon: Icons.auto_fix_high_outlined,
              title: 'Virtual Try-On Studio',
              body: 'Preview eyewear, helmets, sneakers, and apparel with 3D model orbit & AI simulation.',
              label: 'Open studio',
              onTap: () => onSelectTab(4),
            ),
          ];
          if (constraints.maxWidth > 750) {
            return Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
            ]);
          }
          return Column(children: [
            cards[0],
            const SizedBox(height: 10),
            cards[1],
            const SizedBox(height: 10),
            cards[2],
          ]);
        }),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SectionTitle('Your latest moments'),
                TextButton(onPressed: () => onSelectTab(3), child: const Text('View history')),
              ]),
              if (recent.isEmpty)
                const EmptyState(title: 'Room for new moments', message: 'Your recent captions and alerts will appear here.', icon: Icons.history)
              else
                ...recent.map((record) => RecordTile(record: record)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner(text: 'Sound alerts in this prototype are simulated samples and cannot detect emergencies or replace safety equipment.'),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.palette, required this.onStart});
  final RealtimePalette palette;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            palette.primary.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withAlpha(70),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Embedded Haikei layered waves in Hero Card
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(
                painter: HaikeiLayeredWavesPainter(
                  progress: 0.4,
                  primary: palette.primary,
                  secondary: palette.secondary,
                  accent: palette.accent,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: palette.accent.withAlpha(150), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'YOUR COMPANION IS READY',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              const Text(
                'Stay in the moment.\nCatch every word.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Turn conversations into clear captions, right when you need them.',
                style: TextStyle(color: Color(0xffd2e5df), fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Audio Waveform Equalizer Preview inside Hero
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(45)),
                ),
                child: MotionWaveform(
                  barCount: 22,
                  active: true,
                  height: 24,
                  primaryColor: Colors.white,
                  accentColor: palette.accent,
                ),
              ),
              const SizedBox(height: 10),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: const Color(0xff104f4b),
                ),
                onPressed: onStart,
                icon: const Icon(Icons.closed_caption_outlined),
                label: const Text('Start listening', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Microphone permission is requested only when you start.',
                style: TextStyle(color: Color(0xccd2e5df), fontSize: 10),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.body, required this.label, required this.onTap});
  final IconData icon;
  final String title;
  final String body;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MotionSpringButton(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 9),
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ])),
              const Icon(Icons.arrow_outward, size: 17),
            ]),
          ),
        ),
      );
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.onContinue});
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(padding: const EdgeInsets.all(28), shrinkWrap: true, children: [
              Icon(Icons.hearing_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              const Eyebrow('A more connected moment'),
              const SizedBox(height: 8),
              Text('Welcome to HearAssist.', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              const Text('Readable captions, generative Haikei visual accents, and realtime adaptive colors designed for everyone.'),
              const SizedBox(height: 24),
              const InfoBanner(text: 'Microphone permission is requested only when you start captions. Device speech services may process audio according to their own policies.'),
              const SizedBox(height: 12),
              const InfoBanner(text: 'Sound alert events are simulated samples. This prototype cannot detect real sounds or emergencies.', warning: true),
              const SizedBox(height: 22),
              FilledButton(onPressed: onContinue, child: const Text('Let’s get started')),
            ]),
          ),
        ),
      );
}

String _weekday(int day) => const ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day];
String _month(int month) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month];
