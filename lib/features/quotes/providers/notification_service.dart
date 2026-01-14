/* import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:quotevault/features/quotes/providers/quotes_list_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      await _createAndroidChannel();
      await _requestAndroidPermissions();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await _requestApplePermissions();
    }
  }

  // ------------------------------------------------------------
  // PERMISSIONS
  // ------------------------------------------------------------
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Android 13+ notification permission
    await androidPlugin?.requestNotificationsPermission();

    // Android 14+ exact alarms (safe to call)
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> _requestApplePermissions() async {
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
  }

  // ------------------------------------------------------------
  // ANDROID CHANNEL
  // ------------------------------------------------------------
  Future<void> _createAndroidChannel() async {
    // Create main channel
    const mainChannel = AndroidNotificationChannel(
      'daily_quote_channel',
      'Daily Quotes',
      description: 'Daily inspirational quotes',
      importance: Importance.high,
    );

    // Create refresh channel
    const refreshChannel = AndroidNotificationChannel(
      'quote_refresh_channel',
      'Quote Refresh',
      description: 'Refresh quotes at scheduled time',
      importance: Importance.high,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(mainChannel);
    await androidPlugin?.createNotificationChannel(refreshChannel);
  }

  // ------------------------------------------------------------
  // DAILY SCHEDULE
  // ------------------------------------------------------------
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.cancel(id);

    const androidDetails = AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quotes',
      channelDescription: 'Daily inspirational quotes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ------------------------------------------------------------
  // QUOTE REFRESH
  // ------------------------------------------------------------
  Future<void> scheduleQuoteRefresh({
    required int id,
    required DateTime scheduledTime,
  }) async {
    try {
      final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'quote_refresh_channel',
        'Quote Refresh',
        channelDescription: 'Refresh quotes at scheduled time',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id,
        'Time for a New Quote!',
        'Tap to refresh your daily quote',
        tzScheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'refresh_quote',
        matchDateTimeComponents: DateTimeComponents.time, // ✅ ONLY HERE
      );

      debugPrint('✅ Quote refresh scheduled for ${tzScheduled.toLocal()}');
    } catch (e) {
      debugPrint('❌ Error scheduling quote refresh: $e');
    }
  }

  // ------------------------------------------------------------
  // INSTANT NOTIFICATION
  // ------------------------------------------------------------
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_quote_channel',
        'Daily Quotes',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
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
    );

    await _plugin.show(999, title, body, details, payload: payload);
  }

  // ------------------------------------------------------------
  // TEST NOTIFICATION (10 seconds)
  // ------------------------------------------------------------
  Future<void> scheduleTestNotification() async {
    final testTime = DateTime.now().add(const Duration(seconds: 10));

    await scheduleDailyNotification(
      id: 999,
      title: 'Test - QuoteVault',
      body:
          'Test notification working! Time: ${DateFormat('hh:mm a').format(DateTime.now())}',
      time: TimeOfDay.fromDateTime(testTime),
    );

    debugPrint('📱 Test notification scheduled for 10 seconds from now');
  }

  // ------------------------------------------------------------
  // CANCEL METHODS
  // ------------------------------------------------------------
  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  // ------------------------------------------------------------
  // TAP HANDLER
  // ------------------------------------------------------------

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == 'refresh_quote') {
      QuoteRefreshBus.instance.trigger();
    }
  }

  // ------------------------------------------------------------
  // DEBUG
  // ------------------------------------------------------------
  Future<void> logPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('📋 Pending Notifications (${pending.length}):');
    for (final n in pending) {
      debugPrint('  ⏰ ID: ${n.id} | Title: ${n.title}');
    }
  }

  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_quote_channel',
        'Daily Quotes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation:
      // UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
 */