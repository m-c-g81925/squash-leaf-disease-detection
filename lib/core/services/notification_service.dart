import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin
      _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'schedule_channel';
  static const String _channelName = 'Schedule Reminders';
  static const String _channelDescription =
      'Notifications for saved planting schedules';

  static NotificationDetails get _details =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      );

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
    );

    await _notifications.initialize(settings);

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final scheduled = tz.TZDateTime.local(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Smart Squash Test',
      'Notification is working!',
      _details,
    );
  }

  static Future<void>
      showScheduledTestNotification() async {
    final scheduled =
        tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 10),
    );

    await _notifications.zonedSchedule(
      1000,
      'Scheduled Test',
      'This scheduled notification is working!',
      scheduled,
      _details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
