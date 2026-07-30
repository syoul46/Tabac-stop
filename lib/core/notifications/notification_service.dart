import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales de Cairn. Une seule : le rappel de fin de délai à T+10.
/// L'app parle rarement — cette notif ne tombe que sur un succès en cours.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _delayEndId = 1;

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    _inited = true;
  }

  Future<void> _ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Planifie le rappel « tu as tenu 10 min » à l'instant [whenLocal].
  Future<void> scheduleDelayEnd(
    DateTime whenLocal, {
    required String bossName,
  }) async {
    await init();
    await _ensurePermission();
    // Instant absolu (UTC) → l'alarme tombe au bon moment quel que soit le fuseau.
    final when = tz.TZDateTime.from(whenLocal.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id: _delayEndId,
      title: 'Tu as tenu 10 minutes',
      body: '$bossName pouvait attendre — une pierre de plus sur le cairn.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'delay',
          'Délais',
          channelDescription: 'Rappel de fin de délai',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Annule le rappel (délai rompu ou app fermée sur rupture).
  Future<void> cancelDelayEnd() => _plugin.cancel(id: _delayEndId);
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
