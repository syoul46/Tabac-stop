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
    // iOS : on ne demande **rien** à l'initialisation. La permission n'est
    // réclamée qu'au premier délai lancé (cf. [_ensurePermission]) — une
    // pop-up système au tout premier lancement ferait parler l'app avant
    // qu'elle ait quoi que ce soit à dire.
    //
    // Aucune modif d'`AppDelegate.swift` : le plugin s'enregistre lui-même
    // comme délégué d'`UNUserNotificationCenter`, ce qui est nécessaire pour
    // que la notif s'affiche **app au premier plan** — le cas courant ici,
    // puisque le rappel tombe pendant un délai que l'utilisateur regarde.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _inited = true;
  }

  Future<void> _ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    // Pas de badge : l'app ne compte rien sur son icône, jamais.
    await ios?.requestPermissions(alert: true, sound: true, badge: false);
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentBadge: false,
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
