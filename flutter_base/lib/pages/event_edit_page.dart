import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import '../models/calendar_event.dart';
import '../services/event_service.dart';

class EventEditPage extends StatefulWidget {
  final CalendarEvent? event;
  EventEditPage({this.event});
  @override
  _EventEditPageState createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtl;
  late TextEditingController _descCtl;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(Duration(hours: 1));
  int? _reminder;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtl = TextEditingController(text: e?.summary ?? '');
    _descCtl = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _start = e.startTime;
      _end = e.endTime;
      _reminder = e.reminderMinutes;
    }
  }

  String _fmt(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());

  String _lunar(DateTime dt) {
    try {
      final solar = Solar.fromDate(dt);
      final lunar = solar.getLunar();
      return lunar.toString();
    } catch (e) {
      return '(农历计算失败)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? '添加事件' : '编辑事件')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: InputDecoration(labelText: '标题'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入标题' : null,
              ),
              TextFormField(
                controller: _descCtl,
                decoration: InputDecoration(labelText: '描述'),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Start: ${_fmt(_start)}')),
                  SizedBox(width: 8),
                  Text('农历: ${_lunar(_start)}'),
                  TextButton(
                    onPressed: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (dt != null)
                        setState(
                          () => _start = DateTime(
                            dt.year,
                            dt.month,
                            dt.day,
                            _start.hour,
                            _start.minute,
                          ),
                        );
                    },
                    child: Text('Pick Date'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_start),
                      );
                      if (t != null)
                        setState(
                          () => _start = DateTime(
                            _start.year,
                            _start.month,
                            _start.day,
                            t.hour,
                            t.minute,
                          ),
                        );
                    },
                    child: Text('Pick Time'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('End: ${_fmt(_end)}')),
                  SizedBox(width: 8),
                  Text('农历: ${_lunar(_end)}'),
                  TextButton(
                    onPressed: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: _end,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (dt != null)
                        setState(
                          () => _end = DateTime(
                            dt.year,
                            dt.month,
                            dt.day,
                            _end.hour,
                            _end.minute,
                          ),
                        );
                    },
                    child: Text('Pick Date'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_end),
                      );
                      if (t != null)
                        setState(
                          () => _end = DateTime(
                            _end.year,
                            _end.month,
                            _end.day,
                            t.hour,
                            t.minute,
                          ),
                        );
                    },
                    child: Text('Pick Time'),
                  ),
                ],
              ),
              TextFormField(
                initialValue: _reminder?.toString() ?? '',
                decoration: InputDecoration(labelText: '提醒（提前多少分钟，可选）'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return '请输入有效的正整数';
                  return null;
                },
                onChanged: (v) =>
                    _reminder = v.isEmpty ? null : int.tryParse(v),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final id =
                      widget.event?.uid ??
                      DateTime.now().microsecondsSinceEpoch.toString();
                  final ev = CalendarEvent(
                    uid: id,
                    summary: _titleCtl.text.trim(),
                    description: _descCtl.text.trim(),
                    location: '',
                    startTime: _start,
                    endTime: _end,
                    reminderMinutes: _reminder,
                  );
                  if (widget.event == null) {
                    await EventService.instance.addEvent(ev);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('已添加事件')));
                  } else {
                    await EventService.instance.updateEvent(ev);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('已更新事件')));
                  }
                  Navigator.pop(context);
                },
                child: Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
