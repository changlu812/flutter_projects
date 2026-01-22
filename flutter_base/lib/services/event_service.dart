import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

import '../models/calendar_event.dart';
import 'web_notifier_stub.dart'
    if (dart.library.html) 'web_notifier_web.dart'
    as web_notifier;

class EventService extends ChangeNotifier {
  EventService._privateConstructor();
  static final EventService instance = EventService._privateConstructor();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  List<CalendarEvent> events = [];
  // timers for web fallback notifications
  final Map<int, Timer> _webTimers = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await _initNotifications();
    await _setupTimezone();
    final raw = prefs.getString('events_json');
    if (raw != null) {
      try {
        final List<dynamic> arr = jsonDecode(raw);
        events = arr
            .map((e) => CalendarEvent.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        events = [];
      }
    }
    // schedule pending reminders
    for (var ev in events) {
      _scheduleIfNeeded(ev);
    }
  }

  Future<void> _initNotifications() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    await _notifications.initialize(
      InitializationSettings(android: android, iOS: ios),
    );
    // Request notification permission on platform-appropriate ways
    try {
      if (kIsWeb) {
        try {
          await web_notifier.WebNotifier.requestPermission();
        } catch (_) {}
      } else {
        try {
          await Permission.notification.request();
        } catch (_) {}
      }
    } catch (_) {}

    // Try to create an Android notification channel (best-effort)
    try {
      final androidImpl = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        try {
          final channel = AndroidNotificationChannel(
            'calendar_channel',
            'Calendar',
            description: 'Event reminders',
            importance: Importance.max,
          );
          // Some plugin versions expose createNotificationChannel
          if ((androidImpl as dynamic).createNotificationChannel != null) {
            try {
              await (androidImpl as dynamic).createNotificationChannel(channel);
            } catch (_) {}
          }
        } catch (e) {
          print('EventService: create channel failed: $e');
        }
      }
    } catch (e) {
      print('EventService: android channel setup error: $e');
    }

    // Request additional platform-specific permissions (defensive)
    try {
      // iOS / Darwin
      try {
        final iosImpl = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        try {
          await (iosImpl as dynamic)?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final arr = events.map((e) => e.toMap()).toList();
    await prefs.setString('events_json', jsonEncode(arr));
  }

  Future<void> addEvent(CalendarEvent e) async {
    events.add(e);
    await save();
    await _scheduleIfNeeded(e);
    notifyListeners();
  }

  Future<void> updateEvent(CalendarEvent e) async {
    final idx = events.indexWhere((el) => el.uid == e.uid);
    if (idx != -1) events[idx] = e;
    await save();
    await cancelNotificationForEvent(e);
    await _scheduleIfNeeded(e);
    notifyListeners();
  }

  Future<void> deleteEvent(String uid) async {
    final ev = events.firstWhere(
      (e) => e.uid == uid,
      orElse: () => throw 'not found',
    );
    events.removeWhere((e) => e.uid == uid);
    await save();
    await cancelNotificationForEvent(ev);
    notifyListeners();
  }

  int _notificationIdFromUid(String uid) => uid.hashCode & 0x7fffffff;

  Future<void> _scheduleIfNeeded(CalendarEvent e) async {
    if (e.reminderMinutes == null) return;
    final notifyTime = e.startTime.subtract(
      Duration(minutes: e.reminderMinutes!),
    );
    if (notifyTime.isBefore(DateTime.now())) {
      print(
        'EventService: notifyTime $notifyTime is in the past; skip scheduling',
      );
      return;
    }
    final id = _notificationIdFromUid(e.uid);
    final androidDetails = AndroidNotificationDetails(
      'calendar_channel',
      'Calendar',
      channelDescription: 'Event reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    if (kIsWeb) {
      // cancel existing timer if any
      _webTimers[id]?.cancel();
      final delay = notifyTime.difference(DateTime.now());
      print(
        'EventService(web): scheduling web timer id=$id in $delay for ${e.summary}',
      );
      _webTimers[id] = Timer(delay, () async {
        try {
          await web_notifier.WebNotifier.showNotification(
            e.summary,
            e.description,
          );
          print('EventService(web): fired web notification id=$id');
        } catch (ex) {
          print('EventService(web): failed to show notification id=$id -> $ex');
        } finally {
          _webTimers.remove(id);
        }
      });
      return;
    }
    try {
      print(
        'EventService: scheduling notification id=$id at $notifyTime for ${e.summary}',
      );
      await _notifications.zonedSchedule(
        id,
        e.summary,
        e.description,
        tz.TZDateTime.from(notifyTime, tz.local),
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      print('EventService: scheduled id=$id');
    } catch (ex) {
      print('EventService: failed to schedule id=$id -> $ex');
    }
  }

  Future<void> cancelNotificationForEvent(CalendarEvent e) async {
    final id = _notificationIdFromUid(e.uid);
    if (kIsWeb) {
      try {
        _webTimers[id]?.cancel();
        _webTimers.remove(id);
        print('EventService(web): cancelled timer id=$id for ${e.summary}');
      } catch (ex) {
        print('EventService(web): failed to cancel timer id=$id -> $ex');
      }
      return;
    }
    try {
      print('EventService: cancelling notification id=$id for ${e.summary}');
      await _notifications.cancel(id);
      print('EventService: cancelled id=$id');
    } catch (ex) {
      print('EventService: failed to cancel id=$id -> $ex');
    }
  }
}

// initialize timezone helper
Future<void> _setupTimezone() async {
  try {
    tzdata.initializeTimeZones();
    String timeZoneName = 'UTC';
    try {
      timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    } catch (_) {}
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  } catch (_) {}
}
