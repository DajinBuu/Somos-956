import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'somos_956',
      'Somos 956',
      channelDescription: 'Appointment reminders and community alerts',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_inited) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    try {
      await _plugin.initialize(settings: settings);
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'somos_956',
        'Somos 956',
        description: 'Appointment reminders and community alerts',
        importance: Importance.max,
      ));
      await android?.requestNotificationsPermission();
    } catch (_) {}

    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.toString()));
    } catch (_) {}
    _inited = true;
  }

  static Future<void> showNow(String title, String body, {int id = 1}) async {
    try {
      await _plugin.show(
          id: id, title: title, body: body, notificationDetails: _details);
    } catch (_) {}
  }

  /// Schedule a reminder [minutesBefore] ahead of [when], defaulting to one day
  /// before an appointment if that window has passed.
  static Future<DateTime?> scheduleVisitReminder(
    int id,
    DateTime when,
    String title,
    String body, {
    int minutesBefore = 1440,
  }) async {
    try {
      await init();
      var fireAt = when.subtract(Duration(minutes: minutesBefore));
      if (fireAt.isBefore(DateTime.now())) {
        fireAt = DateTime.now().add(const Duration(minutes: 5));
      }
      final tzWhen = tz.TZDateTime.from(fireAt, tz.local);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzWhen,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return fireAt;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
