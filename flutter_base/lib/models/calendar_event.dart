class CalendarEvent {
  final String uid;
  final String summary;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final int? reminderMinutes; // minutes before start to trigger reminder
  final String? recurrence; // RRULE string (optional)

  CalendarEvent({
    required this.uid,
    required this.summary,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.location,
    this.isAllDay = false,
    this.reminderMinutes,
    this.recurrence,
  });

  //从iCalendar vevent转换
  factory CalendarEvent.fromVEvent(Map<String, dynamic> vEvent) {
    return CalendarEvent(
      uid: vEvent['UID'] ?? '',
      summary: vEvent['SUMMARY'] ?? '',
      description: vEvent['DESCRIPTION'] ?? '',
      location: vEvent['LOCATION'] ?? '',
      startTime: DateTime.parse(vEvent['DTSTART']),
      endTime: DateTime.parse(vEvent['DTEND']),
      isAllDay: vEvent['DTSTART'].toString().length <= 8, //简单判断是否为全天事件
    );
  }

  static DateTime _parseDateTime(dynamic dateTimeStr) {
    if (dateTimeStr == null) return DateTime.now();

    String str = dateTimeStr.toString();
    try {
      if (str.length == 8) {
        return DateTime.parse(str);
      } else if (str.contains('T')) {
        return DateTime.parse(str.replaceAll('Z', ''));
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static bool _isAllDayEvent(dynamic dateTimeStr) {
    if (dateTimeStr == null) return false;

    String str = dateTimeStr.toString();
    return str.length == 8;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'summary': summary,
      'description': description,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
      'reminderMinutes': reminderMinutes,
      'recurrence': recurrence,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      uid: map['uid'] ?? '',
      summary: map['summary'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isAllDay: map['isAllDay'] ?? false,
      reminderMinutes: map['reminderMinutes'] != null
          ? (map['reminderMinutes'] as num).toInt()
          : null,
      recurrence: map['recurrence'],
    );
  }

  String toJson() => toMap().toString();
}
