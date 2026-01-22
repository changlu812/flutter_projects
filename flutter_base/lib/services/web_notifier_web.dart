import 'dart:html' as html;

class WebNotifier {
  static Future<bool> requestPermission() async {
    try {
      final p = await html.Notification.requestPermission();
      return p == 'granted';
    } catch (_) {
      return false;
    }
  }

  static Future<void> showNotification(String title, String body) async {
    try {
      if (html.Notification.supported) {
        html.Notification(title, body: body);
      }
    } catch (_) {}
  }
}
