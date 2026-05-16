import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

enum ReminderStatus {
  scheduled,
  cancelled,
  failed
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  static const String _prefKey = 'movie_reminders';

  Future<void> init() async {
    if (_isInitialized) return;

    // 初始化時區
    tz.initializeTimeZones();
    
    // 初始化通知設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // 這裡可以處理點擊通知後的動作
      },
    );

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    debugPrint('✅ [ReminderService] 初始化完成');
  }

  /// 切換提醒狀態
  Future<ReminderStatus> toggleReminder(Movie movie) async {
    final String id = movie.atmoviesId ?? movie.id.toString();
    List<String> reminders = _prefs.getStringList(_prefKey) ?? [];

    if (reminders.contains(id)) {
      // 取消提醒
      reminders.remove(id);
      await _notificationsPlugin.cancel(id.hashCode);
      await _prefs.setStringList(_prefKey, reminders);
      debugPrint('🔕 [ReminderService] 已取消提醒: ${movie.title}');
      return ReminderStatus.cancelled;
    } else {
      // 設定提醒
      try {
        final scheduledDate = _parseReleaseDate(movie.releaseDate);
        reminders.add(id);
        await _scheduleNotification(id.hashCode, movie, scheduledDate);
        await _prefs.setStringList(_prefKey, reminders);
        debugPrint('🔔 [ReminderService] 已設定提醒: ${movie.title} ($scheduledDate)');
        return ReminderStatus.scheduled;
      } catch (e) {
        debugPrint('❌ [ReminderService] 設定提醒失敗: $e');
        return ReminderStatus.failed;
      }
    }
  }

  /// 檢查是否已設定提醒
  bool isReminded(String? id) {
    if (id == null) return false;
    List<String> reminders = _prefs.getStringList(_prefKey) ?? [];
    return reminders.contains(id);
  }

  /// 排程本地通知
  Future<void> _scheduleNotification(int notificationId, Movie movie, DateTime scheduledDate) async {
    // 將 DateTime 轉換為 TZDateTime (假設時區為台北)
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local)
        .add(const Duration(hours: 9)); // 上映當天早上 9:00 提醒

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '🎬 電影上映提醒',
      '您期待的「${movie.title}」今天正式上映囉！快來看看戲院場次吧。',
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'movie_release_channel',
          '電影上映提醒',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 解析上映日期 (格式: 2026-05-14)
  DateTime _parseReleaseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return DateTime.now().add(const Duration(days: 1)); // 保底
  }
}
