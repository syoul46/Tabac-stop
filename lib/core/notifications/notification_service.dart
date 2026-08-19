import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/health/milestones.dart';

/// Notifications locales de Cairn. Deux seulement, et toutes deux ne tombent que
/// sur un **succès** : le rappel de fin de délai (T+10) et le franchissement d'un
/// **palier santé**. L'app ne parle jamais pour reprocher.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _delayEndId = 1;

  /// Base des ids des paliers santé (un id par palier : base + index). Réservé
  /// jusqu'à `_milestoneBase + kHealthMilestones.length`.
  static const _milestoneBase = 100;

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

  /// (Re)planifie les notifications des **paliers santé encore à venir** :
  /// pour chaque palier non atteint, une alarme à `dernière cigarette + seuil`.
  /// On les pose toutes (pas seulement la prochaine) pour qu'elles tombent même
  /// si l'app ne se rouvre jamais entre-temps ; à chaque nouvelle cigarette,
  /// [MilestoneNotifier] rappelle cette méthode qui ré-annule et replanifie.
  ///
  /// [lastLocal] = instant local de la dernière cigarette ; [abstinenceNow] sert
  /// à ne garder que les paliers pas encore franchis.
  Future<void> scheduleHealthMilestones({
    required DateTime lastLocal,
    required Duration abstinenceNow,
  }) async {
    await init();
    await cancelHealthMilestones();

    final upcoming = <(int, HealthMilestone)>[
      for (var i = 0; i < kHealthMilestones.length; i++)
        if (abstinenceNow < kHealthMilestones[i].after) (i, kHealthMilestones[i]),
    ];
    if (upcoming.isEmpty) return;

    await _ensurePermission();
    for (final (i, m) in upcoming) {
      final fireAt = lastLocal.add(m.after);
      final when = tz.TZDateTime.from(fireAt.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        id: _milestoneBase + i,
        title: '▲ ${m.altitudeMeters} m — ${m.title} sans fumer',
        body: m.fact,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'health',
            'Paliers santé',
            channelDescription: 'Un palier santé vient d’être franchi',
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
  }

  /// Annule toutes les notifications de paliers santé en attente.
  Future<void> cancelHealthMilestones() async {
    for (var i = 0; i < kHealthMilestones.length; i++) {
      await _plugin.cancel(id: _milestoneBase + i);
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
