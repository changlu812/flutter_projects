import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../services/event_service.dart';
// ignore: unused_import
import '../models/calendar_event.dart';
import 'event_detail_page.dart';

class MonthView extends StatefulWidget {
  final DateTime? initialDate;
  const MonthView({this.initialDate});
  @override
  _MonthViewState createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  late DateTime _focused;
  DateTime? _selected;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focused = widget.initialDate ?? DateTime.now();
  }

  String _shortLunar(DateTime date) {
    try {
      final solar = Solar.fromDate(date);
      final lunar = solar.getLunar();
      final dyn = lunar as dynamic;
      final candidates = [
        () => dyn.getDayInChinese?.call(),
        () => dyn.getDay?.call(),
        () => dyn.getDayString?.call(),
      ];
      for (final fn in candidates) {
        try {
          final v = fn();
          if (v is String && v.isNotEmpty) return v;
        } catch (_) {}
      }
      final s = lunar.toString();
      final reg = RegExp(r'(初[一二三四五六七八九十]|十[一二三四五六七八九]|廿[一二三四五六七八九十]|三十)');
      final m = reg.firstMatch(s);
      if (m != null) return m.group(0) ?? s;
      return s.length <= 4 ? s : s.substring(s.length - 4);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          calendarFormat: _calendarFormat,
          onFormatChanged: (f) => setState(() => _calendarFormat = f),
          selectedDayPredicate: (day) => isSameDay(_selected, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selected = selectedDay;
              _focused = focusedDay;
            });
          },
        ),
        // Display lunar day for selected date below calendar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '农历: ${_shortLunar(_selected ?? _focused)}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(child: _buildListForDay(_selected ?? _focused)),
      ],
    );
  }

  Widget _buildListForDay(DateTime day) {
    final events = context.watch<EventService>().events.where((e) {
      return e.startTime.year == day.year &&
          e.startTime.month == day.month &&
          e.startTime.day == day.day;
    }).toList();
    if (events.isEmpty) return Center(child: Text('无事件'));
    return ListView.builder(
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
}
