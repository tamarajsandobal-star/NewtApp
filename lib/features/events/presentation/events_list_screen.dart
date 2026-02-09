import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/async_value_widget.dart';
import '../data/event_repository.dart';
import '../domain/event_model.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: AsyncValueWidget<List<Event>>(
        value: eventsAsync,
        data: (events) {
           if (events.isEmpty) {
               return const Center(child: Text("No upcoming events found."));
           }
           return ListView.builder(
             itemCount: events.length,
             padding: const EdgeInsets.all(16),
             itemBuilder: (context, index) {
               final event = events[index];
               return Card(
                 margin: const EdgeInsets.only(bottom: 16),
                 child: ListTile(
                   contentPadding: const EdgeInsets.all(16),
                   title: Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const SizedBox(height: 8),
                       Text("${event.city} • ${_formatDate(event.startAt)}"),
                       const SizedBox(height: 8),
                       Wrap(
                         spacing: 8,
                         children: event.tags.map((t) => Chip(label: Text(t))).toList(),
                       )
                     ],
                   ),
                   onTap: () {
                     // Navigate to details (not implemented fully, showing dialog for MVP)
                     _showEventDetails(context, event, ref);
                   },
                 ),
               );
             },
           );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create Event not implemented in MVP")));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month} ${d.hour}:${d.minute}";
  }

  void _showEventDetails(BuildContext context, Event event, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(event.description),
            const SizedBox(height: 24),
            Text("Safety Info:", style: Theme.of(context).textTheme.titleMedium),
            ...event.safetyFlags.entries.map((e) => Text("• ${e.key}: ${e.value}")),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                 // Mock UID
                 await ref.read(eventRepositoryProvider).rsvp(event.id, 'testUid', 'going');
                 if (context.mounted) {
                     Navigator.of(context).pop();
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RSVP Sent!")));
                 }
              },
              child: const Text("RSVP: I'm Going"),
            )
          ],
        ),
      ),
    );
  }
}
