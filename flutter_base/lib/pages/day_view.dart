import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../services/event_service.dart';
import 'event_detail_page.dart';

class DayView extends StatelessWidget {
  final DateTime day;
  DayView({DateTime? day}) : day = day ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
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
    final lunarStr = _lunar(day);
    return events.isEmpty
        ? Center(
            child: Text(
              '无事件（${DateFormat('yyyy-MM-dd').format(day)}）  农历:$lunarStr',
            ),
          )
        : ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, idx) {
              final ev = events[idx];
              return ListTile(
                title: Text(ev.summary),
                subtitle: Text(
                  '${DateFormat('HH:mm').format(ev.startTime)} - ${DateFormat('HH:mm').format(ev.endTime)}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final ok =
                        await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('删除事件？'),
                            content: Text('确认删除 "${ev.summary}" 吗？'),
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
                      await EventService.instance.deleteEvent(ev.uid);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('已删除')));
                    }
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailPage(event: ev)),
                ),
              );
            },
          );
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
