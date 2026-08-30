import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin
      _notifications = FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _channelId = 'schedule_channel';
  static const String _channelName = 'Schedule Reminders';
  static const String _channelDescription =
      'Notifications for saved planting schedules';

  static const String _reviewChannelId =
      'expert_review_channel';
  static const String _reviewChannelName =
      'Expert Review Updates';
  static const String _reviewChannelDescription =
      'Notifications when an agriculturist reviews a submitted leaf image';

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

  static NotificationDetails get _reviewDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reviewChannelId,
          _reviewChannelName,
          channelDescription: _reviewChannelDescription,
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

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      final String? token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint(
          token == null
              ? 'FCM token unavailable.'
              : 'FCM token obtained.',
        );
      }

      if (token != null && token.isNotEmpty) {
        unawaited(_saveFcmToken(token));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'FCM token startup check skipped: $error',
        );
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (String refreshedToken) {
        if (kDebugMode) {
          debugPrint('FCM token refreshed.');
        }

        unawaited(_saveFcmToken(refreshedToken));
      },
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        final RemoteNotification? notification =
            message.notification;

        final String title =
            notification?.title ??
                message.data['title']?.toString() ??
                'Smart Squash';

        final String body =
            notification?.body ??
                message.data['body']?.toString() ??
                'You have a new notification.';

        await showExpertReviewNotification(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .remainder(2147483647),
          title: title,
          body: body,
        );
      },
    );
  }

  static Future<void> _saveFcmToken(
    String token,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (kDebugMode) {
        debugPrint(
          'FCM token not saved: no logged-in user.',
        );
      }
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'fcmToken': token,
          'fcmTokenUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('FCM token saved.');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Unable to save FCM token: $error',
        );
      }
    }
  }

  static Future<void> saveCurrentFcmToken() async {
    try {
      final String? token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 8));

      if (token != null && token.isNotEmpty) {
        await _saveFcmToken(token);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Unable to get current FCM token: $error',
        );
      }
    }
  }

  static Future<String?> getFcmToken() async {
    return _messaging.getToken();
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

  static Future<void> showExpertReviewNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _reviewDetails,
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
