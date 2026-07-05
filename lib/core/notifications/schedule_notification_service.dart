import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hru_atms/features/home/data/teacher_dashboard_repository.dart';
import 'package:hru_atms/features/home/data/student_dashboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ScheduleNotificationService {
  ScheduleNotificationService._();

  static const testAlarmNotificationId = 990001;

  static final ScheduleNotificationService instance =
      ScheduleNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windows = WindowsInitializationSettings(
      appName: 'HRU ATMS',
      appUserModelId: 'com.hru.hru_atms',
      guid: '4f10c26a-f22b-4a6b-95ec-27d79e7e7112',
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      windows: windows,
    );
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestFullScreenIntentPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<DateTime?> scheduleTestAlarm({
    Duration delay = const Duration(minutes: 1),
  }) async {
    if (kIsWeb) return null;
    await initialize();

    final scheduledAt = DateTime.now().add(delay);
    const id = testAlarmNotificationId;
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: 'HRU alarm test',
      body: 'This is your scheduled alarm test.',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hru_alarm_tests',
          'HRU alarm tests',
          channelDescription: 'Clock-style alarm test notifications.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(
          subtitle: 'Alarm test',
          duration: WindowsNotificationDuration.long,
          scenario: WindowsNotificationScenario.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'test_alarm',
    );

    return scheduledAt;
  }

  Future<void> cancelTestAlarm() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: testAlarmNotificationId);
  }

  Future<void> scheduleTeacherSessionReminders(
    List<TeacherSession> sessions,
  ) async {
    if (kIsWeb) return;
    await initialize();

    final now = DateTime.now();
    for (final session in sessions) {
      final start = session.startTime?.toLocal();
      if (start == null) continue;

      await _scheduleTeacherReminder(
        session: session,
        start: start,
        now: now,
        offset: const Duration(hours: 24),
        label: 'tomorrow',
        idOffset: 100000,
      );
      await _scheduleTeacherReminder(
        session: session,
        start: start,
        now: now,
        offset: const Duration(hours: 5),
        label: 'in 5 hours',
        idOffset: 200000,
      );
      await _scheduleTeacherReminder(
        session: session,
        start: start,
        now: now,
        offset: const Duration(hours: 3),
        label: 'in 3 hours',
        idOffset: 300000,
      );
    }
  }

  Future<void> scheduleTeacherDailyScheduleAlarms(
    List<TeacherSession> sessions,
  ) async {
    if (kIsWeb) return;
    await initialize();

    final grouped = <String, List<TeacherSession>>{};
    for (final session in sessions) {
      final start = session.startTime?.toLocal();
      if (start == null || start.isBefore(DateTime.now())) continue;
      grouped.putIfAbsent(_dateKey(start), () => []).add(session);
    }

    for (final entry in grouped.entries) {
      final day = DateTime.parse(entry.key);
      await _scheduleDailyAlarm(
        role: 'teacher',
        date: day,
        count: entry.value.length,
        firstTitle: entry.value.first.subjectName,
        idBase: 1700000,
      );
    }
  }

  Future<void> scheduleStudentScheduleReminders(
    List<DashboardSchedule> schedules,
  ) async {
    if (kIsWeb) return;
    await initialize();

    final now = DateTime.now();
    for (final schedule in schedules) {
      final start = _studentScheduleStart(schedule);
      if (start == null) continue;

      await _scheduleStudentReminder(
        schedule: schedule,
        start: start,
        now: now,
        offset: const Duration(hours: 24),
        label: 'tomorrow',
        idOffset: 400000,
      );
      await _scheduleStudentReminder(
        schedule: schedule,
        start: start,
        now: now,
        offset: const Duration(hours: 1),
        label: 'in 1 hour',
        idOffset: 500000,
      );
      await _scheduleStudentReminder(
        schedule: schedule,
        start: start,
        now: now,
        offset: Duration.zero,
        label: 'now',
        idOffset: 600000,
      );
    }
  }

  Future<void> scheduleStudentDailyScheduleAlarms(
    List<DashboardSchedule> schedules,
  ) async {
    if (kIsWeb) return;
    await initialize();

    final grouped = <String, List<DashboardSchedule>>{};
    for (final schedule in schedules) {
      final start = _studentScheduleStart(schedule);
      if (start == null || start.isBefore(DateTime.now())) continue;
      grouped.putIfAbsent(_dateKey(start), () => []).add(schedule);
    }

    for (final entry in grouped.entries) {
      final day = DateTime.parse(entry.key);
      await _scheduleDailyAlarm(
        role: 'student',
        date: day,
        count: entry.value.length,
        firstTitle: entry.value.first.title,
        idBase: 1600000,
      );
    }
  }

  Future<void> _scheduleTeacherReminder({
    required TeacherSession session,
    required DateTime start,
    required DateTime now,
    required Duration offset,
    required String label,
    required int idOffset,
  }) async {
    final reminderTime = start.subtract(offset);
    if (!reminderTime.isAfter(now)) return;

    final id = _notificationId(session.id, idOffset);
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Upcoming class at ${_time(start)}',
      body: '${session.subjectName} starts $label. Room ${session.room}.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'teacher_schedule_alarm_reminders_v2',
          'Teacher schedule alarm reminders',
          channelDescription:
              'Alarm alerts teachers before upcoming class sessions.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(
          subtitle: 'Teacher schedule reminder',
          duration: WindowsNotificationDuration.long,
          scenario: WindowsNotificationScenario.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'teacher_session:${session.id}:$label',
    );
  }

  Future<void> _scheduleStudentReminder({
    required DashboardSchedule schedule,
    required DateTime start,
    required DateTime now,
    required Duration offset,
    required String label,
    required int idOffset,
  }) async {
    final reminderTime = start.subtract(offset);
    if (!reminderTime.isAfter(now)) return;

    final id = _studentNotificationId(schedule, idOffset);
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: label == 'now'
          ? 'Class starts now'
          : 'Upcoming class at ${_time(start)}',
      body: '${schedule.title} starts $label. Room ${schedule.room}.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'student_schedule_alarm_reminders_v2',
          'Student schedule alarm reminders',
          channelDescription:
              'Alarm alerts students before upcoming class sessions.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(
          subtitle: 'Student schedule reminder',
          duration: WindowsNotificationDuration.long,
          scenario: WindowsNotificationScenario.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'student_schedule:${schedule.date}:${schedule.time}:$label',
    );
  }

  Future<void> _scheduleDailyAlarm({
    required String role,
    required DateTime date,
    required int count,
    required String firstTitle,
    required int idBase,
  }) async {
    final now = DateTime.now();
    final alarmTime = DateTime(date.year, date.month, date.day, 6, 30);
    var scheduledAt = alarmTime;

    if (_isSameDay(date, now) && !alarmTime.isAfter(now)) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'daily_schedule_alarm_${role}_${_dateKey(date)}';
      if (prefs.getBool(key) == true) return;
      scheduledAt = now.add(const Duration(minutes: 1));
      await prefs.setBool(key, true);
    }

    if (!scheduledAt.isAfter(now)) return;

    final id = idBase + _dateKey(date).hashCode.abs() % 100000;
    final title = role == 'teacher'
        ? 'Today teaching schedule'
        : 'Today class schedule';
    final body = count == 1
        ? 'You have 1 class today: $firstTitle.'
        : 'You have $count classes today. First: $firstTitle.';

    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_schedule_alarm_v1',
          'Daily schedule alarms',
          channelDescription:
              'Daily alarm summary for today schedule and class sessions.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(
          subtitle: 'Daily schedule alarm',
          duration: WindowsNotificationDuration.long,
          scenario: WindowsNotificationScenario.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: '${role}_daily_schedule:${_dateKey(date)}',
    );
  }

  int _notificationId(int sessionId, int offset) => 900000 + offset + sessionId;

  int _studentNotificationId(DashboardSchedule schedule, int offset) {
    return 1200000 +
        offset +
        schedule.date.hashCode.abs() % 10000 +
        schedule.time.hashCode.abs() % 10000 +
        schedule.title.hashCode.abs() % 10000;
  }

  DateTime? _studentScheduleStart(DashboardSchedule schedule) {
    if (schedule.date.isEmpty || schedule.time.isEmpty) return null;
    if (schedule.time == 'TBD') return null;
    final time = schedule.time.length == 5
        ? '${schedule.time}:00'
        : schedule.time;
    return DateTime.tryParse('${schedule.date} $time')?.toLocal();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
