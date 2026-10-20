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
      'rgv_ready_alerts',
      'RGV Ready Alerts',
      channelDescription: 'Heat, watering restrictions and hydration reminders',
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
    await _plugin.initialize(settings: settings);
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'rgv_ready_alerts',
        'RGV Ready Alerts',
        description: 'Heat, watering restrictions and hydration reminders',
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
      await _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
    } catch (_) {}
  }

  static Future<DateTime?> scheduleHydration(
      int minutes, String title, String body) async {
    try {
      await init();
      final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      await _plugin.zonedSchedule(
        id: 100,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'hydration:$minutes',
      );
      return when.toLocal();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancelHydration() async {
    try {
      await _plugin.cancel(id: 100);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
