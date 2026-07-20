import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task_model.dart';

/// Schedules on-device reminders for tasks. Everything here runs locally
/// via the OS notification system — no push server, no Firebase, no cost.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> scheduleTaskReminder(TaskModel task, {int minutesBefore = 10}) async {
    await init();
    final scheduledTime = task.startTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      task.id.hashCode,
      'Atlas يذكّرك',
      '${task.title} تبدأ خلال $minutesBefore دقائق',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chronos_tasks',
          'تذكيرات المهام',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
