import 'package:flutter/material.dart';

import '../models/hear_record.dart';

String clockTime(DateTime time) => TimeOfDay.fromDateTime(time).formatFromContext();

extension _TimeLabel on TimeOfDay {
  String formatFromContext() => '${hourOfPeriod == 0 ? 12 : hourOfPeriod}:${minute.toString().padLeft(2, '0')} ${period == DayPeriod.am ? 'AM' : 'PM'}';
}

String fullDateTime(DateTime time) =>
    '${time.month}/${time.day}/${time.year} · ${clockTime(time)}';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      );
}

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record});
  final HearRecord record;

  @override
  Widget build(BuildContext context) {
    final isCaption = record.kind == 'caption';
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: isCaption ? scheme.secondaryContainer : scheme.tertiaryContainer,
        child: Icon(isCaption ? Icons.closed_caption_outlined : Icons.notifications_active_outlined),
      ),
      title: Text(record.category.isEmpty ? (isCaption ? 'Caption' : 'Demo alert') : record.category),
      subtitle: Text(record.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(clockTime(record.timestamp), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
  });
  final String title;
  final String message;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: warning ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(warning ? Icons.info_outline : Icons.privacy_tip_outlined, size: 18),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}
