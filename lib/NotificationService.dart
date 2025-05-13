import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications system
  static Future<void> initNotifications() async {
    // Initialize timezone data
    tz_init.initializeTimeZones();

    // Configure platform specific settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS 9 and below notification clicked
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize notifications plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped
        print('Notification clicked: ${response.payload}');
      },
    );

    // Request iOS permissions
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Check and request exact alarm permissions (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Check initial permission status
        bool? hasPermission = await androidImplementation.canScheduleExactAlarms();

        // Request permission if not granted
        if (hasPermission != true) {
          await androidImplementation.requestExactAlarmsPermission();
          // Check again after request
          hasPermission = await androidImplementation.canScheduleExactAlarms();
        }

        return hasPermission ?? false;
      }
    }

    // For iOS or if Android checks fail, return true
    return true;
  }

  // Schedule a one-time notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    bool hasPermission = await requestExactAlarmPermission();

    // Choose appropriate scheduling mode based on permissions
    AndroidScheduleMode scheduleMode = hasPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF1E88E5),
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(body),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Schedule a recurring notification based on interval
  static Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required String interval,
    String? payload,
  }) async {
    bool hasPermission = await requestExactAlarmPermission();

    AndroidScheduleMode scheduleMode = hasPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Determine date time components based on interval
    DateTimeComponents? dateTimeComponents = getDateTimeComponents(interval);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _getNextInstanceOfDateTime(dateTime, interval),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF1E88E5),
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: dateTimeComponents,
      payload: payload,
    );

    // Special handling for "Tous les 2 jours" since it's not supported directly
    if (interval == 'Tous les 2 jours') {
      // Schedule a second notification for 2 days later
      await _notificationsPlugin.zonedSchedule(
        id + 1000, // Use a different ID
        title,
        body,
        _getNextInstanceOfDateTime(dateTime, interval).add(Duration(days: 2)),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    }
  }

  // Helper method to get DateTimeComponents based on interval
  static DateTimeComponents? getDateTimeComponents(String interval) {
    switch (interval) {
      case 'Chaque jour':
        return DateTimeComponents.time;
      case 'Chaque semaine':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'Tous les 2 jours':
      // This needs special handling
        return DateTimeComponents.time;
      default:
        return DateTimeComponents.time;
    }
  }

  // Helper method to calculate next notification time
  static tz.TZDateTime _getNextInstanceOfDateTime(DateTime dateTime, String interval) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      dateTime.hour,
      dateTime.minute,
    );

    // If the time has already passed today, schedule for the next appropriate day
    if (scheduledDate.isBefore(now)) {
      switch (interval) {
        case 'Chaque jour':
          scheduledDate = scheduledDate.add(Duration(days: 1));
          break;
        case 'Tous les 2 jours':
          scheduledDate = scheduledDate.add(Duration(days: 2));
          break;
        case 'Chaque semaine':
          scheduledDate = scheduledDate.add(Duration(days: 7));
          break;
        default:
          scheduledDate = scheduledDate.add(Duration(days: 1));
      }
    }

    return scheduledDate;
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);

    // Also cancel the +1000 ID used for "Tous les 2 jours"
    await _notificationsPlugin.cancel(id + 1000);
  }

  // Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Show an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

extension on AndroidFlutterLocalNotificationsPlugin {
  canScheduleExactAlarms() {}
}