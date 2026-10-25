import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hear_assist_controller.dart';
import 'haikei_background.dart';
import 'widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static const _categoryIcons = {
    'Doorbell': Icons.doorbell_outlined,
    'Alarm': Icons.alarm_outlined,
    'Siren': Icons.warning_amber_outlined,
    'Knocking': Icons.front_hand_outlined,
    'Timer': Icons.timer_outlined,
    'Other': Icons.sensors_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final settings = controller.settings;
    final alerts = controller.history.where((record) => record.kind == 'alert').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        const Eyebrow('Visual awareness · Demo mode'),
        const SizedBox(height: 6),
        Text('Sound alerts', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        const Text('Important sounds, made visible in simulated demo mode.'),
        const SizedBox(height: 10),
        const InfoBanner(
          text: 'DEMO MODE: Sample events are manually triggered. HearAssist does not detect real sounds or emergencies and cannot replace dedicated safety equipment.',
          warning: true,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                controller.activePalette.primary,
                controller.activePalette.primary.withAlpha(210),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: controller.activePalette.primary.withAlpha(60),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: CustomPaint(
                    painter: HaikeiLayeredWavesPainter(
                      progress: 0.7,
                      primary: controller.activePalette.primary,
                      secondary: controller.activePalette.secondary,
                      accent: controller.activePalette.accent,
                      alertFlashColor: controller.alertFlashColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.science_outlined, size: 14, color: Color(0xff76dfb7)),
                    const SizedBox(width: 6),
                    Text(
                      'SIMULATED SOUND EVENTS',
                      style: TextStyle(
                        color: controller.activePalette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text('See what a sound alert could feel like.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  const Text(
                    'Sound classification is not implemented. Trigger a sample event to explore the visual alert presentation and haptics.',
                    style: TextStyle(color: Color(0xffd2e5df)),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable demo listener', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(controller.demoAlertsEnabled ? 'Enabled · demo only' : 'Disabled', style: const TextStyle(color: Color(0xffd2e5df))),
                    value: controller.demoAlertsEnabled,
                    onChanged: controller.setDemoAlerts,
                    activeThumbColor: controller.activePalette.accent,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: controller.activePalette.accent,
                      foregroundColor: const Color(0xff104f4b),
                    ),
                    onPressed: controller.demoAlertsEnabled ? () => controller.createDemoAlert() : null,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Trigger random sample alert', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Choose what matters', subtitle: 'These preferences only filter demo events; they do not enable real sound detection.'),
              const SizedBox(height: 8),
              ...settings.categories.entries.map((entry) {
                final icon = _categoryIcons[entry.key] ?? Icons.notifications_outlined;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.demoAlertsEnabled && entry.value)
                        IconButton(
                          tooltip: 'Test ${entry.key} sample',
                          icon: const Icon(Icons.play_circle_outline, size: 22),
                          onPressed: () => controller.createDemoAlert(entry.key),
                        ),
                      Switch.adaptive(
                        value: entry.value,
                        onChanged: (value) {
                          final categories = Map<String, bool>.from(settings.categories)..[entry.key] = value;
                          controller.updateSettings(settings.copyWith(categories: categories));
                        },
                      ),
                    ],
                  ),
                );
              }),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Recent demo events'),
              const SizedBox(height: 8),
              if (alerts.isEmpty)
                const EmptyState(title: 'No alerts just yet', message: 'Enable demo mode, then trigger a sample event above.', icon: Icons.notifications_none)
              else
                ...alerts.take(5).map((record) => RecordTile(record: record)),
            ]),
          ),
        ),
      ],
    );
  }
}
