import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../models/calendar_event.dart';
import '../services/event_service.dart';
import 'event_edit_page.dart';

class EventDetailPage extends StatelessWidget {
  final CalendarEvent event;
  const EventDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.summary),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventEditPage(event: event)),
              );
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final ok =
                  await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('删除事件？'),
                      content: Text('确认删除 "${event.summary}" 吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('删除'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (ok) {
                await EventService.instance.deleteEvent(event.uid);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('已删除')));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When: ${_fmt(event.startTime)} - ${_fmt(event.endTime)}'),
            SizedBox(height: 8),
            Text('Location: ${event.location}'),
            SizedBox(height: 8),
            Text('Description: ${event.description}'),
            SizedBox(height: 8),
            Text('农历: ${_lunar(event.startTime)}'),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  String _lunar(DateTime dt) {
    try {
      final solar = Solar.fromDate(dt);
      final lunar = solar.getLunar();
      return lunar.toString();
    } catch (e) {
      return '(农历计算失败)';
    }
  }
}
