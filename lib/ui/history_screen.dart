import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hear_assist_controller.dart';
import 'widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<HearAssistController>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _clear(HearAssistController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This permanently deletes locally saved captions and demo alerts from this app.'),
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HearAssistController>();
    final records = controller.filteredHistory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        const Eyebrow('Your activity'),
        const SizedBox(height: 6),
        Text('History', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        const Text('A private local record of recent captions and demo alerts.'),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: controller.setHistoryQuery,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      controller.setHistoryQuery('');
                    },
                  )
                : null,
            hintText: 'Search captions and alerts',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final filter in const ['all', 'caption', 'alert'])
              ChoiceChip(
                label: Text(switch (filter) {
                  'all' => 'All (${controller.history.length})',
                  'caption' => 'Captions',
                  _ => 'Alerts',
                }),
                selected: controller.historyFilter == filter,
                onSelected: (_) => controller.setHistoryFilter(filter),
              ),
            const SizedBox(width: 4),
            if (controller.history.isNotEmpty)
              ActionChip(
                avatar: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear history'),
                onPressed: () => _clear(controller),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: records.isEmpty
                ? EmptyState(
                    title: controller.history.isEmpty ? 'Your history starts here' : 'No results found',
                    message: controller.history.isEmpty
                        ? 'Saved captions and demo alerts will appear here.'
                        : 'Try another search term or change the category filter.',
                    icon: Icons.history,
                  )
                : Column(
                    children: records.map((record) => RecordTile(record: record)).toList(),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          text: 'History is stored locally on this device (maximum 200 items). Clear it at any time using the button above.',
        ),
      ],
    );
  }
}
