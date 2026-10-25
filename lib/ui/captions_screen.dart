import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hear_assist_controller.dart';
import 'motion_primitives.dart';
import 'widgets.dart';

class CaptionsScreen extends StatelessWidget {
  const CaptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final listening = controller.captionState == CaptionState.listening;
    final paused = controller.captionState == CaptionState.paused;
    final entries = controller.history.where((record) => record.kind == 'caption').toList();
    final status = switch (controller.captionState) {
      CaptionState.ready => 'Ready to listen',
      CaptionState.requesting => 'Requesting speech service…',
      CaptionState.listening => 'Listening',
      CaptionState.paused => 'Paused',
      CaptionState.error => 'Speech service unavailable',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        const Eyebrow('Captions'),
        const SizedBox(height: 6),
        Text('Live captions', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        const Text('A readable view of the words around you.'),
        if (controller.isPermissionDenied || (controller.errorMessage != null && controller.errorMessage!.toLowerCase().contains('permission'))) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withAlpha(60),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic_off, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Microphone Permission Required',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage ??
                        'HearAssist requires microphone access to listen to real-time speech and generate live captions on your device.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: controller.requestMicrophonePermission,
                        icon: const Icon(Icons.mic, size: 16),
                        label: const Text('Request Microphone Permission'),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.addSampleCaption,
                        icon: const Icon(Icons.science_outlined, size: 16),
                        label: const Text('Show sample caption · DEMO'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          InfoBanner(text: controller.errorMessage!, warning: true),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(
              onPressed: controller.startListening,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: controller.addSampleCaption,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Show sample caption · DEMO'),
            ),
          ]),
        ],
        const SizedBox(height: 14),
        Card(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                MotionRadar(
                  active: listening,
                  size: 26,
                  color: listening ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(status, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Uses the device speech-recognition service. Sessions are designed for intermittent speech (up to 55s) and may stop on pauses.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]),
                ),
                if (controller.captionState == CaptionState.requesting)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ]),
            ),
            const Divider(height: 1),
            // Motion Primitive Equalizer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
              child: MotionWaveform(
                active: listening,
                barCount: 32,
                height: 38,
                primaryColor: Theme.of(context).colorScheme.primary,
                accentColor: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60, maxHeight: 380),
              child: entries.isEmpty && controller.partialText.isEmpty
                  ? const EmptyState(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      title: 'Your words will appear here',
                      message: 'Start captions to see recognized speech in a comfortable reading view.',
                      icon: Icons.closed_caption_outlined,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        ...entries.reversed.map((record) => _CaptionEntry(
                              text: record.text,
                              time: clockTime(record.timestamp),
                              demo: record.category == 'DEMO SAMPLE',
                            )),
                        if (controller.partialText.isNotEmpty)
                          _CaptionEntry(text: controller.partialText, time: 'NOW', partial: true),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!listening && !paused)
                    FilledButton.icon(
                      onPressed: controller.captionState == CaptionState.requesting ? null : controller.startListening,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start listening'),
                    ),
                  if (listening)
                    OutlinedButton.icon(onPressed: controller.pauseListening, icon: const Icon(Icons.pause), label: const Text('Pause')),
                  if (paused)
                    FilledButton.icon(onPressed: controller.resumeListening, icon: const Icon(Icons.play_arrow), label: const Text('Resume')),
                  if (listening || paused)
                    OutlinedButton.icon(onPressed: controller.stopListening, icon: const Icon(Icons.stop), label: const Text('Stop')),
                  TextButton.icon(onPressed: controller.clearCaptions, icon: const Icon(Icons.delete_outline), label: const Text('Clear transcript')),
                  // Text size quick controls
                  IconButton(
                    tooltip: 'Decrease text size',
                    icon: const Icon(Icons.text_decrease, size: 20),
                    onPressed: () {
                      final scale = (controller.settings.captionScale - 0.1).clamp(0.8, 1.7);
                      controller.updateSettings(controller.settings.copyWith(captionScale: double.parse(scale.toStringAsFixed(1))));
                    },
                  ),
                  Text('${(controller.settings.captionScale * 100).round()}%', style: Theme.of(context).textTheme.labelSmall),
                  IconButton(
                    tooltip: 'Increase text size',
                    icon: const Icon(Icons.text_increase, size: 20),
                    onPressed: () {
                      final scale = (controller.settings.captionScale + 0.1).clamp(0.8, 1.7);
                      controller.updateSettings(controller.settings.copyWith(captionScale: double.parse(scale.toStringAsFixed(1))));
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          text: 'Speech recognition is provided by the device service. Continuous streaming is not guaranteed. Availability, network use, and data handling vary by provider. HearAssist does not record or transmit audio.',
        ),
      ],
    );
  }
}

class _CaptionEntry extends StatelessWidget {
  const _CaptionEntry({required this.text, required this.time, this.partial = false, this.demo = false});
  final String text;
  final String time;
  final bool partial;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final scale = context.select<HearAssistController, double>((c) => c.settings.captionScale);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${demo ? 'DEMO SAMPLE · ' : ''}$time',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20 * scale,
                height: 1.5,
                fontStyle: partial ? FontStyle.italic : FontStyle.normal,
              ),
        ),
      ]),
    );
  }
}
