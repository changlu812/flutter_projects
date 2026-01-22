import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import 'event_detail_page.dart';

class WeekView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, idx) {
        final day = days[idx];
        final events = context
            .watch<EventService>()
            .events
            .where(
              (e) =>
                  e.startTime.year == day.year &&
                  e.startTime.month == day.month &&
                  e.startTime.day == day.day,
            )
            .toList();
        return ExpansionTile(
          title: Text('${day.year}-${day.month}-${day.day}'),
          children: events.isEmpty
              ? [ListTile(title: Text('无事件'))]
              : () {
                  final List<Widget> children = [];
                  for (final ev in events) {
                    children.add(
                      ListTile(
                        title: Text(ev.summary),
                        subtitle: Text(
                          '${DateFormat('HH:mm').format(ev.startTime)}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('删除事件？'),
                                    content: Text('确认删除 "${ev.summary}" 吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('删除'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (ok) {
                              await EventService.instance.deleteEvent(ev.uid);
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('已删除')));
                            }
                          },
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: ev),
                          ),
                        ),
                      ),
                    );
                  }
                  return children;
                }(),
        );
      },
    );
  }
}
