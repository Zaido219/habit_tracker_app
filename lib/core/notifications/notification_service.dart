import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Habit reminders',
        channelDescription: 'Reminders for your habits',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: 0,
      title: 'Test notification',
      body: 'Notifications are working!',
      notificationDetails: details,
    );
  }

  static Future<void> showHabitDeletedNotification(String habitTitle) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_deleted_channel',
        'Habit deleted',
        channelDescription: 'Notifies when a habit is deleted',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Habit deleted',
      body: '"$habitTitle" and its history were removed.',
      notificationDetails: details,
    );
  }
}
