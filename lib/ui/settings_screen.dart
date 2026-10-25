import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hear_assist_controller.dart';
import '../theme/realtime_colors.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearHistory(BuildContext context, HearAssistController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete local history?'),
        content: const Text('Saved captions and demo alerts will be permanently removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete history')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
    }
  }

  Future<void> _resetSettings(BuildContext context, HearAssistController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all preferences?'),
        content: const Text('This will restore all appearance, text sizing, and alert preferences to defaults.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset defaults')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.resetSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final settings = controller.settings;
    final activePalette = controller.activePalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contrast = RealtimeColors.evaluateContrast(
      activePalette.ink(isDark),
      activePalette.canvas(isDark),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Eyebrow('Make it yours'),
          const SizedBox(height: 4),
          Text('Comfort, your way.', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Appearance'),
                const SizedBox(height: 6),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: settings.themeMode,
                  decoration: const InputDecoration(labelText: 'Theme', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System theme')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.updateSettings(settings.copyWith(themeMode: value));
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('High contrast'),
                  subtitle: const Text('Strengthen text, surface, and border contrast.'),
                  value: settings.highContrast,
                  onChanged: (value) => controller.updateSettings(settings.copyWith(highContrast: value)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Reduce motion'),
                  subtitle: const Text('Disables transition animations and page motion.'),
                  value: settings.reduceMotion,
                  onChanged: (value) => controller.updateSettings(settings.copyWith(reduceMotion: value)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Reading comfort', subtitle: 'Caption text scale'),
                Row(children: [
                  const Text('A', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      min: 0.8,
                      max: 1.7,
                      divisions: 9,
                      value: settings.captionScale,
                      label: '${(settings.captionScale * 100).round()}%',
                      onChanged: (value) => controller.updateSettings(
                        settings.copyWith(captionScale: double.parse(value.toStringAsFixed(1))),
                      ),
                    ),
                  ),
                  Text('${(settings.captionScale * 100).round()}%', style: Theme.of(context).textTheme.labelLarge),
                ]),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '“Your captions will feel just right.”',
                    style: TextStyle(fontSize: 15 * settings.captionScale, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Sound alert categories', subtitle: 'These configure preferences for simulated demo alerts.'),
                ...settings.categories.entries.map((entry) => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.key),
                      value: entry.value,
                      onChanged: (value) {
                        final categories = Map<String, bool>.from(settings.categories)..[entry.key] = value;
                        controller.updateSettings(settings.copyWith(categories: categories));
                      },
                    )),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration feedback'),
                  subtitle: const Text('Uses device haptics for sample demo alerts where supported.'),
                  value: settings.vibration,
                  onChanged: (value) => controller.updateSettings(settings.copyWith(vibration: value)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Privacy & history'),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep local history'),
                  subtitle: const Text('Store captions and demo events locally on this device.'),
                  value: settings.retainHistory,
                  onChanged: (value) => controller.updateSettings(settings.copyWith(retainHistory: value)),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.mic_none),
                  title: Text('Microphone permission'),
                  subtitle: Text('Requested by the OS only when you start live captions. Manage or revoke in system settings.'),
                ),
                const InfoBanner(
                  text: 'The device speech-recognition service may process audio according to provider privacy terms. HearAssist does not record audio or connect to a remote backend.',
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _clearHistory(context, controller),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete local history'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Realtime Colors Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionTitle('Realtime Colors', subtitle: 'Dynamic harmonic palette engine'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activePalette.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: activePalette.primary.withAlpha(80)),
                      ),
                      child: Text(
                        '★ ${contrast.label}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: activePalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RealtimeColors.curated.entries.map((entry) {
                    final isSelected = controller.customPalette == null && settings.paletteId == entry.key;
                    final pal = entry.value;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => controller.setPalette(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? pal.primary.withAlpha(40) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? pal.primary : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [pal.primary, pal.accent],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pal.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.randomizePalette,
                        icon: const Text('🎲'),
                        label: const Text('Randomize Harmonic Colors'),
                      ),
                    ),
                    if (controller.customPalette != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: controller.resetPalette,
                        child: const Text('Reset Palette'),
                      ),
                    ],
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('About HearAssist'),
                const SizedBox(height: 8),
                Text('Understand more. Stay connected.', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('An independent portfolio companion app for inclusive technology. Enhanced with Motion Primitives, Haikei organic waves, and Realtime Colors.'),
                const SizedBox(height: 8),
                Text('Active Palette: ${activePalette.name} (${activePalette.tag})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('Version 1.0.0 · Flutter Mobile & Desktop MVP'),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _resetSettings(context, controller),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset preferences to defaults'),
          ),
        ],
      ),
    );
  }
}
